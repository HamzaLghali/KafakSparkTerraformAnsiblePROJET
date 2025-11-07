# Quick Start - Using Existing VPC

Since you already have a VPC, public subnet, private subnet, and bastion host, this Terraform will only create:
- 1 Master node (in private subnet)
- 2 Worker nodes (in private subnet)
- Security groups for master and workers
- IAM role for S3 access

## Step 1: Get Your Existing Resource IDs

Run these commands to find your existing resources:

```bash
# Get your VPC ID
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' --output table

# Get your subnet IDs
aws ec2 describe-subnets --query 'Subnets[*].[SubnetId,Tags[?Key==`Name`].Value|[0],CidrBlock]' --output table

# Get your bastion security group ID (optional)
aws ec2 describe-security-groups --query 'SecurityGroups[*].[GroupId,GroupName,Description]' --output table
```

## Step 2: Create terraform.tfvars

```bash
cd ~/terraform
cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars
```

Fill in these REQUIRED values:

```hcl
existing_vpc_id            = "vpc-xxxxx"      # From step 1
existing_public_subnet_id  = "subnet-xxxxx"   # From step 1
existing_private_subnet_id = "subnet-xxxxx"   # From step 1
ssh_key_name              = "your-key-name"   # Your EC2 key pair
your_ip                   = "1.2.3.4/32"      # Your IP (curl ifconfig.me)
```

## Step 3: Deploy

```bash
terraform init
terraform plan    # Review what will be created
terraform apply   # Type 'yes' to create
```

## Step 4: Update Ansible Inventory

```bash
terraform output -raw ansible_inventory > ../ansible/inventories/hosts.ini
```

## Step 5: Run Ansible

```bash
cd ../ansible
ansible-playbook -i inventories/hosts.ini playbooks/site.yml
```

## What Gets Created

✅ Security Groups:
   - master-sg (for master node)
   - worker-sg (for worker nodes)
   - bastion-sg (only if existing_bastion_sg_id is not provided)

✅ IAM Resources:
   - ec2-s3-role (for S3 access)
   - ec2-profile (instance profile)

✅ EC2 Instances:
   - 1 x t3.medium (master) - Zookeeper, Kafka, Spark Master
   - 2 x t3.medium (workers) - Spark Workers

❌ NOT Created (using existing):
   - VPC
   - Subnets
   - Internet Gateway
   - NAT Gateway
   - Bastion host

## Troubleshooting

### Can't find VPC ID?
```bash
aws ec2 describe-vpcs
```

### Can't find subnet IDs?
```bash
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-xxxxx"
```

### Check your current region
```bash
aws configure get region
```
