# Ansible EC2 Infrastructure Setup

This Ansible project automates the deployment and configuration of a distributed data processing infrastructure on AWS EC2 instances, including:
- Bastion host (Ansible control node)
- Master node (Zookeeper, Kafka, Spark Master)
- Worker nodes (Spark Workers)

## Architecture

```
Public Subnet:
  - Bastion Host (t3.small) - SSH gateway and Ansible control

Private Subnet:
  - Master Node (t3.medium) - Zookeeper, Kafka Broker, Spark Master
  - Worker Node 1 (t3.medium) - Spark Worker
  - Worker Node 2 (t3.medium) - Spark Worker
```

## Prerequisites

1. **EC2 Instances**: Launch 4 EC2 instances (Red Hat based) with the architecture above
2. **SSH Key**: Have your SSH private key ready (`~/.ssh/your-key.pem`)
3. **Security Groups**: Configure security groups to allow:
   - SSH (22) from bastion to all private nodes
   - Zookeeper (2181) on master
   - Kafka (9092) on master
   - Spark Master (7077, 8080) on master
   - Inter-node communication between all private nodes

## Configuration Steps

### 1. Update Inventory File

Edit `inventories/hosts.ini` and replace the placeholder IP addresses:

```ini
<BASTION_PUBLIC_IP> - Your bastion's public IP
<MASTER_PRIVATE_IP> - Master node's private IP
<WORKER1_PRIVATE_IP> - Worker 1's private IP
<WORKER2_PRIVATE_IP> - Worker 2's private IP
```

### 2. Update SSH Key Path

Edit `group_vars/all.yml` and set your SSH key path:

```yaml
ansible_ssh_private_key_file: ~/.ssh/your-key.pem
```

### 3. Update AWS Configuration

In `group_vars/all.yml`, update:

```yaml
aws_region: "us-east-1"  # Your AWS region
s3_bucket_name: "your-bucket-name"  # Your S3 bucket
```

### 4. Verify Connectivity

From your local machine or bastion:

```bash
cd /home/ec2-user/ansible
ansible all -m ping
```

## Deployment

### Deploy Everything

```bash
cd /home/ec2-user/ansible
ansible-playbook -i inventories/hosts.ini playbooks/site.yml
```

### Deploy Specific Components

**Configure only the bastion:**
```bash
ansible-playbook -i inventories/hosts.ini playbooks/site.yml --limit bastion
```

**Configure only the master node:**
```bash
ansible-playbook -i inventories/hosts.ini playbooks/site.yml --limit master
```

**Configure only worker nodes:**
```bash
ansible-playbook -i inventories/hosts.ini playbooks/site.yml --limit workers
```

### Run Specific Roles

**Install only Java:**
```bash
ansible-playbook -i inventories/hosts.ini playbooks/site.yml --tags java
```

## Directory Structure

```
ansible/
├── ansible.cfg              # Ansible configuration
├── inventories/
│   └── hosts.ini           # Inventory file with host definitions
├── group_vars/
│   ├── all.yml             # Variables for all hosts
│   ├── master.yml          # Master node specific variables
│   └── workers.yml         # Worker nodes specific variables
├── playbooks/
│   └── site.yml            # Main playbook
└── roles/
    ├── common/             # Base system configuration
    ├── java/               # Java installation
    ├── zookeeper/          # Zookeeper setup
    ├── kafka/              # Kafka broker setup
    └── spark/              # Spark master and worker setup
```

## Services Overview

### Master Node Services

- **Zookeeper**: Port 2181
  - Service: `sudo systemctl status zookeeper`
  - Logs: `/var/lib/zookeeper`

- **Kafka**: Port 9092
  - Service: `sudo systemctl status kafka`
  - Logs: `/var/lib/kafka-logs`
  - Create topic: `{{ kafka_home }}/bin/kafka-topics.sh --create --topic test --bootstrap-server localhost:9092`

- **Spark Master**: Port 7077 (Web UI: 8080)
  - Service: `sudo systemctl status spark-master`
  - Web UI: `http://<MASTER_PRIVATE_IP>:8080`

### Worker Node Services

- **Spark Worker**
  - Service: `sudo systemctl status spark-worker`
  - Connected to master on startup

## Testing the Setup

### 1. Test Zookeeper

```bash
# On master node
echo stat | nc localhost 2181
```

### 2. Test Kafka

```bash
# Create a topic
/opt/kafka/bin/kafka-topics.sh --create --topic test-topic \
  --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1

# List topics
/opt/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092
```

### 3. Test Spark

```bash
# Submit a test job
/opt/spark/bin/spark-submit --master spark://<MASTER_PRIVATE_IP>:7077 \
  --class org.apache.spark.examples.SparkPi \
  /opt/spark/examples/jars/spark-examples_2.12-3.5.0.jar 100
```

### 4. Test S3 Integration

```bash
# Spark with S3
/opt/spark/bin/spark-shell --master spark://<MASTER_PRIVATE_IP>:7077

# In Spark shell:
val data = spark.read.text("s3a://your-bucket-name/path/to/file.txt")
data.show()
```

## Troubleshooting

### Check Service Status

```bash
# On master
sudo systemctl status zookeeper
sudo systemctl status kafka
sudo systemctl status spark-master

# On workers
sudo systemctl status spark-worker
```

### View Logs

```bash
# Zookeeper logs
sudo journalctl -u zookeeper -f

# Kafka logs
sudo journalctl -u kafka -f

# Spark Master logs
sudo journalctl -u spark-master -f
/opt/spark/logs/

# Spark Worker logs
sudo journalctl -u spark-worker -f
```

### SSH Connection Issues

If you can't connect to private nodes through bastion:
1. Ensure bastion's SSH key has access to private nodes
2. Test manual SSH: `ssh -J ec2-user@<BASTION_IP> ec2-user@<PRIVATE_IP>`
3. Check security groups allow SSH from bastion

### Service Start Issues

```bash
# Restart services in order
sudo systemctl restart zookeeper
sleep 5
sudo systemctl restart kafka
sleep 5
sudo systemctl restart spark-master
```

## IAM Role for S3 Access

Ensure your EC2 instances have an IAM role with this policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::your-bucket-name/*",
        "arn:aws:s3:::your-bucket-name"
      ]
    }
  ]
}
```

## Customization

### Change Spark Memory

Edit `group_vars/workers.yml`:

```yaml
spark_worker_cores: 4
spark_worker_memory: "8g"
```

### Change Kafka Configuration

Edit `roles/kafka/templates/server.properties.j2` for custom Kafka settings.

### Change Java Version

Edit `group_vars/all.yml`:

```yaml
java_version: "17"  # Change to desired version
```

## Maintenance

### Update Configuration

After changing variables or templates, rerun the playbook:

```bash
ansible-playbook -i inventories/hosts.ini playbooks/site.yml
```

### Add More Workers

1. Add new worker entries to `inventories/hosts.ini`
2. Run: `ansible-playbook -i inventories/hosts.ini playbooks/site.yml --limit workers`

## Security Considerations

- Keep bastion host as the only publicly accessible instance
- Use security groups to restrict traffic between nodes
- Regularly update SSH keys
- Enable CloudWatch monitoring for all instances
- Consider using AWS Systems Manager Session Manager instead of SSH

## Next Steps

1. Deploy your Scala application to worker nodes
2. Set up Kafka UI on the master node for monitoring
3. Configure Spark job scheduling
4. Set up log aggregation (e.g., CloudWatch Logs)
5. Implement backup strategies for Kafka and Zookeeper data
