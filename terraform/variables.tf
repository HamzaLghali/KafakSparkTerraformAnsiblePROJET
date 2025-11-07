variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "spark-kafka-cluster"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

# Existing VPC and Subnet IDs (since you already have them)
variable "existing_vpc_id" {
  description = "ID of your existing VPC"
  type        = string
}

variable "existing_public_subnet_id" {
  description = "ID of your existing public subnet"
  type        = string
}

variable "existing_private_subnet_id" {
  description = "ID of your existing private subnet"
  type        = string
}

variable "existing_bastion_sg_id" {
  description = "ID of your existing bastion security group (optional)"
  type        = string
  default     = ""
}

variable "existing_master_sg_id" {
  description = "ID of your existing master security group (optional, leave empty to create new)"
  type        = string
  default     = ""
}

variable "existing_worker_sg_id" {
  description = "ID of your existing worker security group (optional, leave empty to create new)"
  type        = string
  default     = ""
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair to use for EC2 instances"
  type        = string
  # You need to create this key pair in AWS EC2 console first
}

variable "your_ip" {
  description = "Your IP address for SSH access (CIDR format, e.g., 1.2.3.4/32)"
  type        = string
  # Get your IP: curl ifconfig.me
}

variable "ami_id" {
  description = "AMI ID for Red Hat or Amazon Linux 2"
  type        = string
  # Red Hat 9: Use AWS marketplace or find latest RHEL AMI
  # Amazon Linux 2023: ami-0fff1b9a61dec8a5f (us-east-1)
  default     = "ami-0fff1b9a61dec8a5f" # Amazon Linux 2023 in us-east-1
}

variable "bastion_instance_type" {
  description = "Instance type for bastion host"
  type        = string
  default     = "t3.small"
}

variable "master_instance_type" {
  description = "Instance type for master node"
  type        = string
  default     = "t3.medium"
}

variable "worker_instance_type" {
  description = "Instance type for worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}
