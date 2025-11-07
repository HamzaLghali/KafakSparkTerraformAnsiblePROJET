# Spark Kafka Cluster on AWS

Distributed data processing cluster using Apache Spark and Apache Kafka on AWS EC2 instances.

## Architecture

- **Bastion Host**: Jump server in public subnet (RHEL-based)
- **Master Node**: Runs Zookeeper, Kafka broker, and Spark master (Ubuntu)
- **Worker Nodes**: 2x Spark workers for distributed processing (Ubuntu)

## Infrastructure

- **Region**: eu-north-1 (Stockholm)
- **VPC**: Existing VPC with public and private subnets
- **NAT Gateway**: Provides internet access for private subnet instances
- **Security Groups**: Layered security with bastion access pattern

## Technologies

- **Terraform**: Infrastructure as Code
- **Ansible**: Configuration management
- **Apache Spark 3.5.0**: Distributed computing
- **Apache Kafka 3.6.1**: Stream processing
- **Apache Zookeeper**: Distributed coordination
- **Java 11**: Runtime environment

## Directory Structure

```
.
├── terraform/          # Infrastructure provisioning
│   ├── provider.tf
│   ├── variables.tf
│   ├── vpc.tf
│   ├── security_groups.tf
│   ├── ec2.tf
│   └── outputs.tf
├── ansible/           # Configuration management
│   ├── inventories/
│   ├── group_vars/
│   ├── playbooks/
│   └── roles/
├── SETUP_STEPS.md     # Step-by-step deployment guide
└── TECHNICAL_DETAILS.md   # Comprehensive technical documentation
```

## Quick Start

### Prerequisites

- AWS account with CLI configured
- SSH key pair created in AWS
- Existing VPC with public and private subnets

### Deployment

1. **Deploy Infrastructure**
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

2. **Configure Cluster**
   ```bash
   cd ansible
   ansible-playbook -i inventories/hosts.ini playbooks/site.yml
   ```

3. **Verify Services**
   ```bash
   # On master node
   sudo systemctl status zookeeper kafka spark-master
   
   # On worker nodes
   sudo systemctl status spark-worker
   ```

## Documentation

- **SETUP_STEPS.md**: Complete command-by-command deployment guide
- **TECHNICAL_DETAILS.md**: Architecture, configuration, and operational details

## Costs

Estimated monthly cost (24/7 operation):
- EC2 instances: ~$90/month
- NAT Gateway: ~$32/month
- Storage: ~$15/month
- **Total**: ~$137/month

Stop instances when not in use to reduce costs.

## Security

- Private subnet instances isolated from internet
- Bastion host as single entry point
- IAM roles for S3 access (no hardcoded credentials)
- Security groups with least-privilege access

## Author

**Hamza Lghali**  
vanhamzalghali@gmail.com

## License

This project is for educational and development purposes.
