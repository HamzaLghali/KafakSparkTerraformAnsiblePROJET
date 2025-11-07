# Terraform EC2 Infrastructure

This Terraform configuration creates the complete AWS infrastructure for the Spark/Kafka cluster.

## Prerequisites

1. **AWS Account** with proper credentials configured
2. **Terraform** installed (v1.0+)
3. **SSH Key Pair** created in AWS EC2 console
4. **Your Public IP** address

## Quick Start

### 1. Configure AWS Credentials

```bash
# Option 1: AWS CLI (if installed)
aws configure

# Option 2: Environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

### 2. Create SSH Key Pair

If you don't have one:
```bash
# In AWS Console: EC2 → Key Pairs → Create Key Pair
# Or via CLI:
aws ec2 create-key-pair --key-name spark-cluster-key --query 'KeyMaterial' --output text > ~/.ssh/spark-cluster-key.pem
chmod 400 ~/.ssh/spark-cluster-key.pem
```

### 3. Get Your Public IP

```bash
curl ifconfig.me
# Note this IP - you'll need it
```

### 4. Create terraform.tfvars

Create a file named `terraform.tfvars`:

```hcl
aws_region       = "us-east-1"
project_name     = "spark-kafka-cluster"
ssh_key_name     = "spark-cluster-key"  # Your key pair name in AWS
your_ip          = "1.2.3.4/32"         # Your IP from step 3
ami_id           = "ami-0fff1b9a61dec8a5f"  # Amazon Linux 2023 (us-east-1)

# Optional: customize instance types
# bastion_instance_type = "t3.small"
# master_instance_type  = "t3.medium"
# worker_instance_type  = "t3.medium"
# worker_count          = 2
```

### 5. Initialize and Deploy

```bash
cd ~/terraform

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy infrastructure
terraform apply
```

Type `yes` when prompted.

## After Deployment

### Get Instance IPs

```bash
terraform output
```

This will show:
- Bastion public IP
- Master private IP
- Worker private IPs
- SSH commands

### Auto-Update Ansible Inventory

```bash
# Generate and save Ansible inventory
terraform output -raw ansible_inventory > ../ansible/inventories/hosts.ini

# Verify
cat ../ansible/inventories/hosts.ini
```

### SSH to Bastion

```bash
# Get the command
terraform output ssh_bastion_command

# Or manually
ssh -i ~/.ssh/spark-cluster-key.pem ec2-user@<BASTION_PUBLIC_IP>
```

### Copy SSH Key to Bastion

So Ansible can access private nodes:

```bash
# From your local machine
scp -i ~/.ssh/spark-cluster-key.pem ~/.ssh/spark-cluster-key.pem ec2-user@<BASTION_PUBLIC_IP>:~/.ssh/
```

### Run Ansible

Once on the bastion:

```bash
cd ~/ansible
ansible-playbook -i inventories/hosts.ini playbooks/site.yml
```

## What Gets Created

- **VPC**: 10.0.0.0/16
- **Public Subnet**: 10.0.1.0/24 (for bastion)
- **Private Subnet**: 10.0.2.0/24 (for master & workers)
- **Internet Gateway**: For public subnet
- **NAT Gateway**: For private subnet outbound access
- **Security Groups**: Proper firewall rules
- **IAM Role**: For S3 access
- **EC2 Instances**:
  - 1 Bastion (t3.small, public)
  - 1 Master (t3.medium, private)
  - 2 Workers (t3.medium, private)

## Costs Estimate (us-east-1)

- **t3.small** (bastion): ~$15/month
- **t3.medium** x3 (master + 2 workers): ~$100/month
- **NAT Gateway**: ~$32/month + data transfer
- **EBS Storage** (150GB total): ~$15/month
- **Data Transfer**: Varies

**Total: ~$162/month** (running 24/7)

💡 **Save money**: Stop instances when not in use!

## Management Commands

### View Current State

```bash
terraform show
```

### Update Infrastructure

After changing variables:

```bash
terraform plan
terraform apply
```

### Add More Workers

Edit `terraform.tfvars`:
```hcl
worker_count = 3
```

Then:
```bash
terraform apply
```

### Destroy Everything

**WARNING**: This deletes all resources!

```bash
terraform destroy
```

## Troubleshooting

### Error: InvalidKeyPair

```
Error: InvalidKeyPair.NotFound
```

**Fix**: Make sure the key pair exists in AWS:
```bash
aws ec2 describe-key-pairs --key-names your-key-name
```

### Error: UnauthorizedOperation

**Fix**: Check your AWS credentials:
```bash
aws sts get-caller-identity
```

### SSH Connection Refused

**Fix**: Wait 1-2 minutes after creation for instances to boot.

### Ansible Can't Connect

**Fix**: Make sure SSH key is on bastion:
```bash
ls -la ~/.ssh/
```

## File Structure

```
terraform/
├── provider.tf           # AWS provider configuration
├── variables.tf          # Input variables
├── vpc.tf               # VPC and networking
├── security_groups.tf   # Security groups
├── ec2.tf               # EC2 instances and IAM
├── outputs.tf           # Output values
├── templates/
│   └── hosts.ini.tpl    # Ansible inventory template
├── terraform.tfvars     # Your variable values (create this)
└── README.md           # This file
```

## State Management

Terraform stores state in `terraform.tfstate`. This file contains:
- All resource IDs
- Current infrastructure state

**Important**:
- Don't delete this file
- Don't commit to Git (contains sensitive data)
- Consider using remote state (S3 backend) for team collaboration

## Advanced: Remote State (Optional)

For team use, store state in S3:

```hcl
# Add to provider.tf
terraform {
  backend "s3" {
    bucket = "my-terraform-state-bucket"
    key    = "spark-cluster/terraform.tfstate"
    region = "us-east-1"
  }
}
```

## Integration with Ansible

The Terraform output automatically generates an Ansible inventory:

```bash
# Option 1: Redirect to file
terraform output -raw ansible_inventory > ../ansible/inventories/hosts.ini

# Option 2: Use dynamic inventory (advanced)
# Create a script to query Terraform output
```

## Security Best Practices

1. **Restrict SSH access**: Only allow your IP in `your_ip` variable
2. **Use strong key pairs**: 2048-bit or higher RSA keys
3. **Enable CloudTrail**: Audit all AWS API calls
4. **Use IAM roles**: Not access keys on instances (already configured)
5. **Regular updates**: Keep AMIs and packages updated
6. **Backup**: Important data to S3
7. **Monitor**: Set up CloudWatch alarms

## Next Steps

1. Deploy infrastructure with Terraform
2. Copy SSH key to bastion
3. Update Ansible inventory automatically
4. Run Ansible playbook to configure software
5. Deploy your Scala application
6. Test the cluster

## Support

Check Terraform docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
