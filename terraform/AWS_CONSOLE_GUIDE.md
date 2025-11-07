# AWS Console Guide - Finding Your Resource IDs

Since you already have VPC, subnets, bastion, and security groups, here's how to find their IDs using the AWS Console.

## Step 1: Find Your VPC ID

1. Go to **AWS Console** → **VPC** → **Your VPCs**
2. Look for your VPC (probably named something like "spark-vpc" or "default")
3. Copy the **VPC ID** (format: `vpc-xxxxxxxxxxxxx`)

## Step 2: Find Your Subnet IDs

1. Go to **AWS Console** → **VPC** → **Subnets**
2. Look for your subnets:
   - **Public Subnet**: Should have "public" in the name or be associated with a route table that has an Internet Gateway
   - **Private Subnet**: Should have "private" in the name or be associated with a route table that has a NAT Gateway
3. Copy both **Subnet IDs** (format: `subnet-xxxxxxxxxxxxx`)

**How to tell public from private:**
- Click on the subnet → Look at the **Route Table** tab
- **Public subnet**: Has a route to `0.0.0.0/0` pointing to an **Internet Gateway (igw-xxx)**
- **Private subnet**: Has a route to `0.0.0.0/0` pointing to a **NAT Gateway (nat-xxx)**

## Step 3: Find Your Security Group IDs (Optional)

1. Go to **AWS Console** → **EC2** → **Security Groups** (left sidebar)
2. Look for security groups for:
   - **Bastion**: Usually allows SSH (port 22) from your IP
   - **Master**: May have rules for Kafka, Zookeeper, Spark
   - **Worker**: May have rules for Spark workers
3. Copy the **Security Group IDs** (format: `sg-xxxxxxxxxxxxx`)

**Note**: If your security groups aren't configured for Spark/Kafka yet, you can:
- **Option A**: Leave them empty in terraform.tfvars and let Terraform create new ones
- **Option B**: Provide the IDs and manually add the required rules later

## Step 4: Find Your SSH Key Pair Name

1. Go to **AWS Console** → **EC2** → **Key Pairs** (left sidebar under "Network & Security")
2. Note the **Name** of your key pair (e.g., "my-key", "bastion-key")
3. This is the name you'll use in `ssh_key_name` variable (NOT the filename)

## Step 5: Get Your Public IP

Run this from your bastion:
```bash
curl ifconfig.me
```

Or Google: "what is my ip"

## Step 6: Create terraform.tfvars

```bash
cd ~/terraform
cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars
```

Fill in the values you found:

```hcl
# From Step 1
existing_vpc_id = "vpc-0123456789abcdef0"

# From Step 2
existing_public_subnet_id  = "subnet-0123456789abcdef0"
existing_private_subnet_id = "subnet-0123456789abcdef1"

# From Step 3 (or leave empty to create new)
existing_bastion_sg_id = "sg-0123456789abcdef0"  # or ""
existing_master_sg_id  = ""  # Leave empty to create new
existing_worker_sg_id  = ""  # Leave empty to create new

# From Step 4
ssh_key_name = "my-key-pair"

# From Step 5
your_ip = "1.2.3.4/32"

# AMI (use default for Amazon Linux 2023)
ami_id = "ami-0fff1b9a61dec8a5f"  # us-east-1
```

## Quick Reference: What Terraform Will Create

Based on what you leave empty:

| Variable | Empty ("") | Filled In (ID) |
|----------|-----------|----------------|
| `existing_bastion_sg_id` | Creates new bastion SG | Uses your existing bastion SG |
| `existing_master_sg_id` | Creates new master SG with Kafka/Spark rules | Uses your existing master SG |
| `existing_worker_sg_id` | Creates new worker SG with Spark rules | Uses your existing worker SG |

**Recommendation for new accounts**: Leave security group IDs empty so Terraform creates properly configured ones.

## Example Complete terraform.tfvars

```hcl
aws_region   = "us-east-1"
project_name = "spark-kafka-cluster"

# Your resources (REQUIRED)
existing_vpc_id            = "vpc-0a1b2c3d4e5f67890"
existing_public_subnet_id  = "subnet-0a1b2c3d4e5f67890"
existing_private_subnet_id = "subnet-0a1b2c3d4e5f67891"

# Let Terraform create security groups (RECOMMENDED for new accounts)
existing_bastion_sg_id = ""
existing_master_sg_id  = ""
existing_worker_sg_id  = ""

# Your credentials
ssh_key_name = "my-ec2-key"
your_ip      = "203.0.113.42/32"

# AMI (Amazon Linux 2023 in us-east-1)
ami_id = "ami-0fff1b9a61dec8a5f"

# Instance types
master_instance_type = "t3.medium"
worker_instance_type = "t3.medium"
worker_count         = 2

# Your private subnet CIDR (for security group rules)
private_subnet_cidr = "10.0.2.0/24"  # Check your actual CIDR in VPC console
```

## Verify Your Private Subnet CIDR

1. Go to **AWS Console** → **VPC** → **Subnets**
2. Click on your **private subnet**
3. Look for **IPv4 CIDR** (e.g., `10.0.2.0/24`)
4. Update `private_subnet_cidr` in terraform.tfvars

## Ready to Deploy!

```bash
cd ~/terraform
terraform init
terraform plan    # Review what will be created
terraform apply   # Type 'yes' to create resources
```

## After Deployment

Update Ansible inventory:
```bash
terraform output -raw ansible_inventory > ../ansible/inventories/hosts.ini
```

Run Ansible:
```bash
cd ../ansible
ansible-playbook -i inventories/hosts.ini playbooks/site.yml
```
