# Technical Documentation - Spark Kafka Cluster Architecture

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Infrastructure Components](#infrastructure-components)
3. [Terraform Details](#terraform-details)
4. [Ansible Details](#ansible-details)
5. [Security Configuration](#security-configuration)
6. [Service Configuration](#service-configuration)
7. [Networking](#networking)
8. [IAM and Permissions](#iam-and-permissions)

---

## Architecture Overview

### High-Level Architecture

This is a distributed data processing cluster designed for real-time stream processing using Apache Kafka and Apache Spark.

**Architecture Pattern:** Hub and Spoke with Bastion
- **Control Plane:** Bastion host in public subnet (management layer)
- **Data Plane:** Master + Workers in private subnet (processing layer)

**Key Features:**
- ✅ **High Availability:** Distributed workers for fault tolerance
- ✅ **Scalability:** Horizontal scaling via worker nodes
- ✅ **Security:** Private subnet isolation with bastion access
- ✅ **S3 Integration:** IAM role-based access to S3 buckets
- ✅ **Infrastructure as Code:** Terraform for reproducible infrastructure
- ✅ **Configuration Management:** Ansible for automated software deployment

---

## Infrastructure Components

### 1. Bastion Host
**Purpose:** SSH gateway and Ansible control node

**Specifications:**
- **Instance Type:** t3.small
- **OS:** RHEL-based (Red Hat Enterprise Linux)
- **Location:** Public subnet (subnet-0a0a5d9cf662dd381)
- **IP Address:** 10.0.13.122 (private), has public IP
- **Security Group:** sg-0ebcf91b3e3abc4c1 (ansible-bastion-sg)

**Software:**
- Ansible 2.x
- Terraform 1.x
- AWS CLI v2
- Python 3.12
- Git

**Purpose in Architecture:**
- Entry point for all SSH access
- Runs Ansible playbooks to configure cluster
- Stores SSH keys for accessing private instances
- Acts as jump host for accessing private subnet

---

### 2. Master Node
**Purpose:** Coordination and message brokering

**Specifications:**
- **Instance Type:** t3.medium (2 vCPU, 4 GB RAM)
- **OS:** Ubuntu (AMI: ami-0705384c0b33c194c)
- **Location:** Private subnet (subnet-0968e7f834411717e)
- **IP Address:** 10.0.136.17 (private only, no public IP)
- **Security Group:** sg-052db11f6e080eef4 (kafka-spark-master-sg)
- **Instance ID:** i-083657b80007ea86e
- **Storage:** 50 GB gp3 EBS volume

**Services Running:**

1. **Apache Zookeeper** (Port 2181)
   - **Purpose:** Distributed coordination service for Kafka
   - **Data Directory:** /var/lib/zookeeper
   - **Configuration:** /etc/zookeeper/zookeeper.properties
   - **Role:** Maintains Kafka cluster metadata, leader election, configuration management

2. **Apache Kafka** (Port 9092)
   - **Purpose:** Distributed streaming platform
   - **Version:** 3.6.1
   - **Scala Version:** 2.13
   - **Home Directory:** /opt/kafka
   - **Log Directory:** /var/lib/kafka-logs
   - **Broker ID:** 1
   - **Role:** Message broker for real-time data pipelines

3. **Apache Spark Master** (Ports 7077, 8080)
   - **Purpose:** Cluster manager for Spark jobs
   - **Version:** 3.5.0
   - **Home Directory:** /opt/spark
   - **Port 7077:** Spark master communication
   - **Port 8080:** Web UI for monitoring
   - **Role:** Schedules and distributes Spark jobs to workers

**Why Master Node is Critical:**
- Single point of coordination (in this simple setup)
- All Kafka messages flow through it
- Spark job scheduling happens here
- Zookeeper maintains cluster state

---

### 3. Worker Nodes (x2)
**Purpose:** Distributed processing and computation

**Worker 1 Specifications:**
- **Instance Type:** t3.medium (2 vCPU, 4 GB RAM)
- **OS:** Ubuntu
- **IP Address:** 10.0.137.14
- **Instance ID:** i-0b3d8475f3c803aed
- **Security Group:** sg-09ec1280749c7ce01
- **Storage:** 50 GB gp3 EBS volume

**Worker 2 Specifications:**
- **Instance Type:** t3.medium (2 vCPU, 4 GB RAM)
- **OS:** Ubuntu
- **IP Address:** 10.0.128.219
- **Instance ID:** i-0cbd44cdc9eac8c67
- **Security Group:** sg-09ec1280749c7ce01
- **Storage:** 50 GB gp3 EBS volume

**Services Running:**

1. **Apache Spark Worker**
   - **Purpose:** Executes Spark tasks
   - **Cores:** 2 CPU cores per worker
   - **Memory:** 4g allocated
   - **Home Directory:** /opt/spark
   - **Work Directory:** /opt/spark/work
   - **Role:** Processes data in parallel

**Worker Node Characteristics:**
- Stateless (can be added/removed dynamically)
- Connect to Spark master on startup
- Execute executor processes for Spark jobs
- Can run your Scala applications

---

## Terraform Details

### Infrastructure as Code Structure

**Files Created:**

1. **provider.tf** - AWS Provider Configuration
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

2. **variables.tf** - Input Variables
- Defines all configurable parameters
- Includes defaults for instance types, AMIs, counts
- Separates configuration from implementation

3. **vpc.tf** - Network Configuration
- **Status:** Commented out (using existing VPC)
- **Original purpose:** Create VPC, subnets, IGW, NAT Gateway
- **Current approach:** Uses data sources to reference existing resources

4. **security_groups.tf** - Firewall Rules
```hcl
# Creates worker security group only
# Uses existing bastion and master security groups
# Implements least-privilege access
```

5. **ec2.tf** - Compute Resources
```hcl
# Creates:
# - IAM role for S3 access
# - IAM instance profile
# - 1 Master instance
# - 2 Worker instances
```

6. **outputs.tf** - Output Values
```hcl
# Exports:
# - Instance IPs
# - Instance IDs
# - Ansible inventory template
```

### Terraform State Management

**State File:** `/home/ec2-user/terraform/terraform.tfstate`
- Contains current infrastructure state
- Maps resources to real AWS infrastructure
- **Critical:** Don't delete or manually edit
- **Sensitive:** Contains resource IDs and metadata

**State Operations:**
```bash
terraform state list        # List all resources
terraform state show <res>  # Show resource details
terraform refresh          # Update state from AWS
```

### Resource Dependencies

```
IAM Role → Instance Profile → EC2 Instances
                              ↓
                         Security Groups
                              ↓
                           Subnets (existing)
                              ↓
                           VPC (existing)
```

---

## Ansible Details

### Ansible Architecture

**Control Node:** Bastion (10.0.13.122)
**Managed Nodes:** Master + 2 Workers

### Configuration Files

1. **ansible.cfg** - Ansible Behavior
```ini
[defaults]
inventory = ./inventories/hosts.ini
roles_path = ./roles
host_key_checking = False     # Disable host key checking
retry_files_enabled = False   # Don't create .retry files
gathering = smart             # Cache facts
```

2. **inventories/hosts.ini** - Inventory
```ini
# Defines host groups
# Maps hostnames to IP addresses
# Sets connection parameters (ansible_user, etc.)
```

3. **group_vars/all.yml** - Global Variables
```yaml
# Variables applied to ALL hosts
# Includes: versions, paths, ports, credentials
```

4. **group_vars/master.yml** - Master Variables
```yaml
# Master-specific configuration
# Kafka broker ID, Spark master settings
```

5. **group_vars/workers.yml** - Worker Variables
```yaml
# Worker-specific configuration
# Spark worker cores, memory allocation
```

### Ansible Roles

#### Role: common
**Purpose:** Base system configuration for all nodes

**Tasks:**
1. Update system packages (apt for Ubuntu, yum for RHEL)
2. Install common tools (wget, curl, git, vim, htop, etc.)
3. Create application user (`spark`) and group
4. Set system limits (file descriptors, processes)
5. Configure firewall (disable for development)

**Why Important:**
- Ensures consistent base configuration
- Creates required users and groups
- Sets up system for high-performance applications

**Variables:**
- `app_user`: spark
- `app_group`: spark

---

#### Role: java
**Purpose:** Install Java Development Kit

**Tasks:**
1. Detect OS family (Debian vs RedHat)
2. Install OpenJDK 11
3. Set JAVA_HOME environment variable
4. Add Java to system PATH

**Why Java 11:**
- Compatible with Spark 3.5.0
- Long-term support version
- Required by Kafka and Spark

**Configuration:**
- JAVA_HOME: `/usr/lib/jvm/java-11-openjdk` (Ubuntu)
- Added to `/etc/profile.d/java.sh`

---

#### Role: zookeeper
**Purpose:** Install and configure Apache Zookeeper

**Tasks:**
1. Create data directory (`/var/lib/zookeeper`)
2. Create myid file (identifies this Zookeeper instance)
3. Configure zookeeper.properties
4. Create systemd service
5. Enable and start service

**Configuration:**
```properties
dataDir=/var/lib/zookeeper
clientPort=2181
tickTime=2000
initLimit=10
syncLimit=5
```

**Why These Settings:**
- `tickTime`: Basic time unit (2 seconds)
- `initLimit`: Time for follower to connect to leader
- `syncLimit`: Time for follower to sync with leader
- `autopurge`: Automatic cleanup of old snapshots

**Systemd Service:**
- Starts after network
- Runs as `spark` user
- Auto-restarts on failure

---

#### Role: kafka
**Purpose:** Install and configure Apache Kafka

**Tasks:**
1. Download Kafka 3.6.1
2. Extract to `/opt/kafka`
3. Create log directory
4. Configure server.properties
5. Create systemd service
6. Enable and start service

**Key Configuration:**
```properties
broker.id=1
listeners=PLAINTEXT://:9092
log.dirs=/var/lib/kafka-logs
num.partitions=1
zookeeper.connect=localhost:2181
```

**Why These Settings:**
- `broker.id`: Unique identifier for this Kafka broker
- `listeners`: Accept connections on port 9092
- `num.partitions`: Default partitions for new topics
- `log.retention.hours=168`: Keep messages for 7 days

**Dependencies:**
- Requires Zookeeper running first
- Systemd `Requires=zookeeper.service`

---

#### Role: spark
**Purpose:** Install and configure Apache Spark

**Tasks:**
1. Download Spark 3.5.0 with Hadoop 3
2. Extract to `/opt/spark`
3. Create work directories
4. Configure spark-defaults.conf
5. Configure spark-env.sh
6. Install AWS SDK JARs for S3 access
7. Create master service (on master node)
8. Create worker service (on worker nodes)

**Master Configuration (spark-env.sh):**
```bash
SPARK_MASTER_HOST=10.0.136.17
SPARK_MASTER_PORT=7077
SPARK_MASTER_WEBUI_PORT=8080
```

**Worker Configuration (spark-env.sh):**
```bash
SPARK_WORKER_CORES=2
SPARK_WORKER_MEMORY=4g
SPARK_WORKER_INSTANCES=1
```

**Spark Defaults (spark-defaults.conf):**
```properties
spark.master = spark://10.0.136.17:7077
spark.executor.memory = 2g
spark.driver.memory = 2g

# S3 Integration
spark.hadoop.fs.s3a.impl = org.apache.hadoop.fs.s3a.S3AFileSystem
spark.hadoop.fs.s3a.aws.credentials.provider = 
  com.amazonaws.auth.InstanceProfileCredentialsProvider
```

**Why S3 Integration:**
- Read/write data from S3 buckets
- Use IAM role for authentication (no keys in code)
- Enables data lake architecture

**S3 JAR Dependencies:**
- hadoop-aws-3.3.4.jar
- aws-java-sdk-bundle-1.12.262.jar

---

### Ansible Playbook Flow

**Playbook:** `playbooks/site.yml`

```yaml
Play 1: Display Information (all hosts)
  - Shows which host is being configured

Play 2: Configure Bastion
  - Apply: common role
  - Install: ansible (optional)

Play 3: Configure Master
  - Apply: common, java, zookeeper, kafka, spark roles
  - Result: Full master node with all services

Play 4: Configure Workers
  - Apply: common, java, spark roles
  - Result: Spark workers ready to connect

Play 5: Verification
  - Check services are running
  - Display final status
```

**Execution Order:**
1. Bastion first (fastest, in public subnet)
2. Master second (many services to install)
3. Workers in parallel (independent of each other)
4. Verification last

---

## Security Configuration

### Security Groups

#### ansible-bastion-sg (sg-0ebcf91b3e3abc4c1)
**Purpose:** Protect bastion host

**Inbound Rules:**
- SSH (22) from YOUR_IP (0.0.0.0/0 in current config)

**Outbound Rules:**
- All traffic allowed (for downloading packages, accessing AWS APIs)

**Best Practice:** Restrict YOUR_IP to actual public IP (/32)

---

#### kafka-spark-master-sg (sg-052db11f6e080eef4)
**Purpose:** Protect master node

**Inbound Rules:**
- SSH (22) from bastion security group
- Zookeeper (2181) from private subnet (10.0.128.0/20)
- Kafka (9092) from private subnet
- Spark Master (7077) from private subnet
- Spark Web UI (8080) from bastion SG and private subnet
- All traffic from self (cluster communication)

**Outbound Rules:**
- All traffic allowed

**Why These Rules:**
- SSH only from bastion (jump host pattern)
- Services accessible from workers
- Web UI accessible from bastion for monitoring
- Self-referencing for internal cluster communication

---

#### spark-kafka-cluster-worker-sg (sg-09ec1280749c7ce01)
**Purpose:** Protect worker nodes

**Inbound Rules:**
- SSH (22) from bastion security group
- All traffic from master security group
- All traffic from self (worker-to-worker)

**Outbound Rules:**
- All traffic allowed

**Why These Rules:**
- SSH only from bastion
- Spark master needs to communicate with workers on dynamic ports
- Workers communicate with each other for data shuffling

---

### SSH Key Management

**Key Pair Name:** kafka-spark-keypair
**Key Location:** `/home/ec2-user/kafka-spark-keypair.pem`
**Permissions:** 400 (read-only by owner)

**Fingerprint in AWS:** 7a:13:f4:0f:1b:dc:b1:af:40:5b:cb:f6:ef:fc:e3:76:cd:af:56:94

**Security Best Practices:**
1. Never commit private keys to version control
2. Use different keys for different environments
3. Rotate keys periodically
4. Store keys in secure location (AWS Secrets Manager, etc.)

---

### IAM Roles and Policies

#### EC2 Role: spark-kafka-cluster-ec2-s3-role

**Purpose:** Allow EC2 instances to access S3 without credentials

**Trust Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Action": "sts:AssumeRole",
    "Effect": "Allow",
    "Principal": {
      "Service": "ec2.amazonaws.com"
    }
  }]
}
```

**Permissions Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ],
    "Resource": "arn:aws:s3:::*"
  }]
}
```

**Why IAM Role:**
- No hardcoded credentials in code
- Automatic credential rotation
- Fine-grained permissions
- Audit trail via CloudTrail

**Instance Profile:** spark-kafka-cluster-ec2-profile
- Attaches role to EC2 instances
- Provides temporary credentials via instance metadata

---

## Service Configuration

### Apache Zookeeper

**Version:** Bundled with Kafka 3.6.1
**Port:** 2181
**Data Directory:** /var/lib/zookeeper

**Configuration File:** `/etc/zookeeper/zookeeper.properties`
```properties
dataDir=/var/lib/zookeeper
clientPort=2181
maxClientCnxns=0          # No limit on connections
tickTime=2000             # 2-second heartbeat
initLimit=10              # 10 ticks for init
syncLimit=5               # 5 ticks for sync
autopurge.snapRetainCount=3
autopurge.purgeInterval=1  # Cleanup every hour
```

**myid File:** `/var/lib/zookeeper/myid`
- Contains: `1`
- Identifies this Zookeeper instance in cluster

**Systemd Service:** `/etc/systemd/system/zookeeper.service`
```ini
[Unit]
Description=Apache Zookeeper
After=network.target

[Service]
Type=simple
User=spark
ExecStart=/opt/kafka/bin/zookeeper-server-start.sh /etc/zookeeper/zookeeper.properties
ExecStop=/opt/kafka/bin/zookeeper-server-stop.sh
Restart=on-failure
RestartSec=10
```

**Management Commands:**
```bash
sudo systemctl start zookeeper
sudo systemctl stop zookeeper
sudo systemctl restart zookeeper
sudo systemctl status zookeeper
sudo journalctl -u zookeeper -f
```

**Health Check:**
```bash
echo stat | nc localhost 2181
# Should show Zookeeper statistics
```

---

### Apache Kafka

**Version:** 3.6.1
**Scala Version:** 2.13
**Port:** 9092
**Home:** /opt/kafka
**Logs:** /var/lib/kafka-logs

**Configuration File:** `/opt/kafka/config/server.properties`
```properties
# Broker Configuration
broker.id=1
listeners=PLAINTEXT://:9092
advertised.listeners=PLAINTEXT://10.0.136.17:9092

# Network Threads
num.network.threads=3
num.io.threads=8

# Log Configuration
log.dirs=/var/lib/kafka-logs
num.partitions=1
num.recovery.threads.per.data.dir=1

# Replication
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1

# Retention
log.retention.hours=168      # 7 days
log.segment.bytes=1073741824 # 1GB segments

# Zookeeper
zookeeper.connect=localhost:2181
zookeeper.connection.timeout.ms=18000
```

**Why These Settings:**
- `broker.id=1`: Unique identifier
- `listeners`: Internal communication
- `advertised.listeners`: Address clients should use
- `num.partitions=1`: Default for new topics (can override)
- `log.retention.hours=168`: Keep data for 7 days
- `replication.factor=1`: Single broker (no replication)

**Systemd Service:** `/etc/systemd/system/kafka.service`
```ini
[Unit]
Description=Apache Kafka
After=zookeeper.service
Requires=zookeeper.service

[Service]
Type=simple
User=spark
Environment="KAFKA_HEAP_OPTS=-Xmx1G -Xms1G"
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
ExecStop=/opt/kafka/bin/kafka-server-stop.sh
Restart=on-failure
```

**Management Commands:**
```bash
# Service management
sudo systemctl start kafka
sudo systemctl status kafka

# Create topic
/opt/kafka/bin/kafka-topics.sh --create \
  --topic my-topic \
  --bootstrap-server localhost:9092 \
  --partitions 3 \
  --replication-factor 1

# List topics
/opt/kafka/bin/kafka-topics.sh --list \
  --bootstrap-server localhost:9092

# Describe topic
/opt/kafka/bin/kafka-topics.sh --describe \
  --topic my-topic \
  --bootstrap-server localhost:9092

# Console producer
/opt/kafka/bin/kafka-console-producer.sh \
  --topic my-topic \
  --bootstrap-server localhost:9092

# Console consumer
/opt/kafka/bin/kafka-console-consumer.sh \
  --topic my-topic \
  --from-beginning \
  --bootstrap-server localhost:9092
```

---

### Apache Spark

**Version:** 3.5.0
**Hadoop Version:** 3
**Home:** /opt/spark

**Configuration File:** `/opt/spark/conf/spark-defaults.conf`
```properties
spark.master = spark://10.0.136.17:7077
spark.eventLog.enabled = true
spark.eventLog.dir = /opt/spark/logs
spark.executor.memory = 2g
spark.driver.memory = 2g

# S3 Configuration
spark.hadoop.fs.s3a.impl = org.apache.hadoop.fs.s3a.S3AFileSystem
spark.hadoop.fs.s3a.aws.credentials.provider = 
  com.amazonaws.auth.InstanceProfileCredentialsProvider
spark.hadoop.fs.s3a.endpoint = s3.eu-north-1.amazonaws.com
```

**Environment File:** `/opt/spark/conf/spark-env.sh`

*Master node:*
```bash
export SPARK_MASTER_HOST=10.0.136.17
export SPARK_MASTER_PORT=7077
export SPARK_MASTER_WEBUI_PORT=8080
```

*Worker nodes:*
```bash
export SPARK_WORKER_CORES=2
export SPARK_WORKER_MEMORY=4g
export SPARK_WORKER_INSTANCES=1
```

**Spark Master Service:** `/etc/systemd/system/spark-master.service`
```ini
[Unit]
Description=Apache Spark Master
After=network.target

[Service]
Type=forking
User=spark
ExecStart=/opt/spark/sbin/start-master.sh
ExecStop=/opt/spark/sbin/stop-master.sh
Restart=on-failure
```

**Spark Worker Service:** `/etc/systemd/system/spark-worker.service`
```ini
[Unit]
Description=Apache Spark Worker
After=network.target

[Service]
Type=forking
User=spark
ExecStart=/opt/spark/sbin/start-worker.sh spark://10.0.136.17:7077
ExecStop=/opt/spark/sbin/stop-worker.sh
Restart=on-failure
```

**Management Commands:**
```bash
# Service management
sudo systemctl start spark-master
sudo systemctl start spark-worker
sudo systemctl status spark-master

# Submit job
/opt/spark/bin/spark-submit \
  --master spark://10.0.136.17:7077 \
  --class com.example.MyApp \
  /path/to/my-app.jar

# Spark shell
/opt/spark/bin/spark-shell \
  --master spark://10.0.136.17:7077

# Read from S3
val df = spark.read.text("s3a://my-bucket/data.txt")
df.show()

# Write to S3
df.write.parquet("s3a://my-bucket/output/")
```

**Web UI:**
- Access via port forwarding from bastion
- URL: http://10.0.136.17:8080
- Shows: Active workers, running applications, completed jobs

---

## Networking

### VPC Configuration

**VPC ID:** vpc-0eed7af6a5360f7c8
**CIDR Block:** 10.0.0.0/16
**Region:** eu-north-1 (Stockholm)

**Features Enabled:**
- DNS hostnames: Yes
- DNS resolution: Yes

---

### Subnets

#### Public Subnet
**Subnet ID:** subnet-0a0a5d9cf662dd381
**CIDR:** 10.0.0.0/20
**Available IPs:** ~4000
**Purpose:** Bastion host
**Internet Access:** Via Internet Gateway

#### Private Subnet
**Subnet ID:** subnet-0968e7f834411717e
**CIDR:** 10.0.128.0/20
**Available IPs:** ~4000
**Purpose:** Master + Workers
**Internet Access:** Via NAT Gateway

---

### Routing

**Public Subnet Route Table:**
```
Destination: 10.0.0.0/16 → local
Destination: 0.0.0.0/0 → Internet Gateway
```

**Private Subnet Route Table:**
```
Destination: 10.0.0.0/16 → local
Destination: 0.0.0.0/0 → NAT Gateway
```

---

### Network Flow Examples

#### SSH to Master from Bastion
```
Laptop → Bastion (SSH 22)
         ↓
Bastion → Master (SSH 22 via private subnet)
```

#### Spark Job Submission
```
Master (Spark Master) → Worker 1 (Spark Worker via port 7077)
                     → Worker 2 (Spark Worker via port 7077)
```

#### Kafka Message Flow
```
Producer → Master:9092 (Kafka Broker)
           ↓
Master:2181 (Zookeeper coordinates)
           ↓
Consumer ← Master:9092 (Kafka Broker)
```

#### S3 Data Access
```
Worker → NAT Gateway → Internet Gateway → S3 Endpoint
         (Uses IAM role for authentication)
```

---

## Performance Tuning

### Instance Sizing

**t3.medium Specifications:**
- 2 vCPUs (Intel Xeon, up to 3.1 GHz)
- 4 GB RAM
- Up to 5 Gigabit network
- Burstable performance

**Why t3.medium:**
- Good balance of cost and performance
- Suitable for development and small production workloads
- Can handle moderate data processing

**When to Scale Up:**
- **Master:** Upgrade to t3.large or c5.xlarge for more Kafka throughput
- **Workers:** Upgrade to c5.2xlarge for more Spark processing power
- **Add workers:** Scale horizontally for more parallelism

---

### JVM Tuning

**Kafka JVM Settings:**
```bash
KAFKA_HEAP_OPTS=-Xmx1G -Xms1G
```
- 1GB heap for Kafka broker
- Fixed heap size (min=max) prevents GC overhead

**Spark Worker Settings:**
```bash
SPARK_WORKER_MEMORY=4g
```
- 4GB total memory per worker
- Spark manages memory for executors

**Recommendations for Production:**
- Kafka: Use at least 4-8GB heap for high throughput
- Spark: Allocate 80% of system memory to Spark

---

### Network Optimization

**Current Setup:**
- Enhanced networking enabled (ENA)
- Up to 5 Gbps network bandwidth

**Tuning Opportunities:**
- Use Placement Groups for low latency
- Enable Jumbo Frames (MTU 9001) in VPC
- Use cluster placement group for tight coupling

---

## Monitoring and Observability

### Service Monitoring

**Systemd Status:**
```bash
systemctl status zookeeper
systemctl status kafka
systemctl status spark-master
systemctl status spark-worker
```

**Logs:**
```bash
journalctl -u zookeeper -f
journalctl -u kafka -f
journalctl -u spark-master -f
```

---

### Kafka Monitoring

**Built-in Tools:**
```bash
# Consumer lag
/opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --describe --group my-consumer-group

# Topic stats
/opt/kafka/bin/kafka-run-class.sh kafka.tools.GetOffsetShell \
  --broker-list localhost:9092 \
  --topic my-topic
```

**JMX Metrics:** Port 9999 (can be enabled)

---

### Spark Monitoring

**Web UI:** http://10.0.136.17:8080
- Shows active/completed applications
- Worker status
- Resource utilization

**Metrics:**
- Job duration
- Task distribution
- Memory usage per executor
- Shuffle read/write

**Event Logs:** /opt/spark/logs
- Enable with `spark.eventLog.enabled=true`
- View history with Spark History Server

---

### Recommended Monitoring Stack

For Production, add:
1. **Prometheus** - Metrics collection
2. **Grafana** - Visualization
3. **CloudWatch** - AWS metrics and logs
4. **Kafka Manager** - Kafka cluster management UI
5. **Spark History Server** - Historical Spark job analysis

---

## Backup and Disaster Recovery

### Critical Data to Backup

1. **Zookeeper Data:**
   - Location: /var/lib/zookeeper
   - Contains: Cluster metadata
   - Backup: Daily snapshots to S3

2. **Kafka Logs:**
   - Location: /var/lib/kafka-logs
   - Contains: Message data
   - Strategy: Set retention policy, use Kafka MirrorMaker for replication

3. **Terraform State:**
   - Location: /home/ec2-user/terraform/terraform.tfstate
   - Critical: Infrastructure definition
   - Backup: Store in S3 with versioning

4. **Ansible Playbooks:**
   - Location: /home/ec2-user/ansible/
   - Version control: Git repository

---

### Disaster Recovery Plan

**Scenario: Master Node Failure**
1. Launch new instance from AMI
2. Run Ansible playbook to reconfigure
3. Restore Zookeeper data from backup
4. Kafka will rebuild from replicas (if configured)

**Scenario: Worker Node Failure**
1. Spark automatically reschedules tasks
2. Launch new worker
3. Worker auto-connects to master

**RTO/RPO Targets:**
- Recovery Time Objective: < 1 hour
- Recovery Point Objective: < 15 minutes (depends on Kafka retention)

---

## Scaling Strategies

### Horizontal Scaling (Add More Workers)

**Steps:**
1. Update Terraform variable `worker_count = 3`
2. Run `terraform apply`
3. New worker instances created automatically
4. Run Ansible playbook for new workers
5. Workers auto-register with Spark master

**Benefits:**
- More parallel processing
- Higher throughput
- Better fault tolerance

---

### Vertical Scaling (Bigger Instances)

**Steps:**
1. Update Terraform variable `worker_instance_type = "c5.2xlarge"`
2. Run `terraform apply`
3. Terraform will replace instances
4. Ansible reconfigures new instances

**Benefits:**
- More memory per worker
- Faster CPU for compute-intensive tasks

---

### Kafka Scaling

**Add More Brokers:**
1. Launch new instance
2. Configure with unique broker.id
3. Update producer/consumer configs with new broker list

**Increase Partitions:**
```bash
/opt/kafka/bin/kafka-topics.sh --alter \
  --topic my-topic \
  --partitions 10 \
  --bootstrap-server localhost:9092
```

---

## Cost Optimization

### Current Monthly Costs (24/7 operation)

| Resource | Type | Quantity | Monthly Cost |
|----------|------|----------|--------------|
| Master | t3.medium | 1 | $30 |
| Workers | t3.medium | 2 | $60 |
| EBS Volumes | gp3 50GB | 3 | $15 |
| NAT Gateway | - | 1 | $32 |
| Data Transfer | - | ~100GB | $9 |
| **Total** | | | **~$146/month** |

### Cost Savings Strategies

1. **Stop instances when not in use:**
   ```bash
   # Stop all
   aws ec2 stop-instances --instance-ids i-xxx i-yyy i-zzz
   # Savings: ~$90/month (keep NAT Gateway for bastion)
   ```

2. **Use Spot Instances for workers:**
   - Save up to 70% on worker costs
   - Workers are stateless, can tolerate interruptions
   - Update Terraform to use spot instances

3. **Reserved Instances:**
   - 1-year commitment: 40% savings
   - 3-year commitment: 60% savings
   - Good for master node (always running)

4. **Right-size instances:**
   - Monitor utilization with CloudWatch
   - Downgrade if CPU < 40% consistently

5. **Optimize storage:**
   - gp3 instead of gp2 (same cost, better performance)
   - Delete old Kafka logs
   - Archive to S3 Glacier

---

## Troubleshooting Guide

### Common Issues and Solutions

#### Issue: Zookeeper won't start
**Symptoms:** `systemctl status zookeeper` shows failed
**Solutions:**
```bash
# Check logs
sudo journalctl -u zookeeper -n 100

# Common causes:
# - Port 2181 already in use
# - Permissions on /var/lib/zookeeper
# - Java not found

# Fix permissions
sudo chown -R spark:spark /var/lib/zookeeper
```

#### Issue: Kafka won't start
**Symptoms:** Kafka service fails, logs show Zookeeper connection error
**Solutions:**
```bash
# Verify Zookeeper is running
systemctl status zookeeper
echo stat | nc localhost 2181

# Check Kafka logs
sudo journalctl -u kafka -n 100

# Verify network connectivity
telnet localhost 2181
```

#### Issue: Spark workers not connecting
**Symptoms:** Web UI shows no workers
**Solutions:**
```bash
# On worker: Check if master is reachable
telnet 10.0.136.17 7077

# Check worker logs
sudo journalctl -u spark-worker -n 100

# Verify security group allows traffic
aws ec2 describe-security-groups --group-ids sg-09ec1280749c7ce01
```

#### Issue: Can't SSH to instances
**Symptoms:** Permission denied (publickey)
**Solutions:**
```bash
# Verify key file
ls -la /home/ec2-user/kafka-spark-keypair.pem
chmod 400 /home/ec2-user/kafka-spark-keypair.pem

# Check username (ubuntu, not ec2-user)
ssh -i /home/ec2-user/kafka-spark-keypair.pem ubuntu@10.0.136.17

# Verify security group
aws ec2 describe-security-groups --group-ids sg-xxx
```

#### Issue: Out of memory errors in Spark
**Symptoms:** Executor lost, OOM in logs
**Solutions:**
```bash
# Increase executor memory
spark-submit --executor-memory 3g --driver-memory 2g

# Reduce parallelism
spark-submit --executor-cores 1

# Partition data better
df.repartition(100)
```

---

## Best Practices

### Security
✅ Use IAM roles instead of access keys
✅ Enable CloudTrail for audit logging
✅ Restrict security group rules to minimum required
✅ Use private subnets for sensitive workloads
✅ Rotate SSH keys regularly
✅ Enable VPC Flow Logs

### High Availability
✅ Use multiple Availability Zones
✅ Set up Kafka replication (replication factor > 1)
✅ Use Auto Scaling Groups for workers
✅ Monitor services with CloudWatch alarms
✅ Set up automated backups

### Performance
✅ Use EBS-optimized instances
✅ Enable enhanced networking
✅ Tune JVM heap sizes based on load
✅ Monitor and optimize Spark job configurations
✅ Use appropriate partition strategies

### Operations
✅ Use Infrastructure as Code (Terraform)
✅ Automate configuration (Ansible)
✅ Version control all code and configs
✅ Document architecture and runbooks
✅ Implement CI/CD for deployments
✅ Regular testing of disaster recovery

---

## Glossary

**Bastion Host:** Fortified server for secure access to private network

**Broker:** Kafka server that stores and serves messages

**Consumer:** Application that reads messages from Kafka

**Driver:** Spark process that coordinates job execution

**Executor:** Spark process that runs tasks on worker nodes

**IAM Role:** AWS identity with permissions attached

**Leader/Follower:** Zookeeper cluster roles for high availability

**NAT Gateway:** Allows private subnet instances to access internet

**Partition:** Division of Kafka topic for parallelism

**Producer:** Application that sends messages to Kafka

**Replication Factor:** Number of copies of data in Kafka

**Security Group:** Virtual firewall for EC2 instances

**Shuffle:** Spark operation that redistributes data across workers

**Systemd:** Linux service manager

**Topic:** Kafka category for messages

**Worker:** Machine that executes Spark tasks

**Zookeeper:** Coordination service for distributed systems

---

**Last Updated:** November 7, 2025  
**Version:** 1.0  
**Author:** Infrastructure Automation Team
