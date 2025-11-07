# ============================================================================
# SECURITY GROUPS
# ============================================================================

# Use existing security groups or create new ones
locals {
  bastion_sg_id = var.existing_bastion_sg_id != "" ? var.existing_bastion_sg_id : aws_security_group.bastion_new[0].id
  master_sg_id  = var.existing_master_sg_id != "" ? var.existing_master_sg_id : aws_security_group.master[0].id
  worker_sg_id  = var.existing_worker_sg_id != "" ? var.existing_worker_sg_id : aws_security_group.worker[0].id
}

# Security Group for Bastion - COMMENTED OUT (using existing bastion)
# Uncomment if you need to create a new bastion security group
/*
resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = data.aws_vpc.existing.id

  # SSH from your IP
  ingress {
    description = "SSH from your IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.your_ip]
  }

  # All outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-bastion-sg"
    Project = var.project_name
  }
}
*/

# Create new bastion SG only if not provided
resource "aws_security_group" "bastion_new" {
  count = var.existing_bastion_sg_id == "" ? 1 : 0

  name        = "${var.project_name}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = data.aws_vpc.existing.id

  ingress {
    description = "SSH from your IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.your_ip]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-bastion-sg"
    Project = var.project_name
  }
}

# Security Group for Master Node
# Create only if existing_master_sg_id is not provided
resource "aws_security_group" "master" {
  count = var.existing_master_sg_id == "" ? 1 : 0

  name        = "${var.project_name}-master-sg"
  description = "Security group for master node"
  vpc_id      = data.aws_vpc.existing.id

  # SSH from bastion
  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [local.bastion_sg_id]
  }

  # Zookeeper from private subnet
  ingress {
    description = "Zookeeper"
    from_port   = 2181
    to_port     = 2181
    protocol    = "tcp"
    cidr_blocks = [var.private_subnet_cidr]
  }

  # Kafka from private subnet
  ingress {
    description = "Kafka"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = [var.private_subnet_cidr]
  }

  # Spark Master from private subnet
  ingress {
    description = "Spark Master"
    from_port   = 7077
    to_port     = 7077
    protocol    = "tcp"
    cidr_blocks = [var.private_subnet_cidr]
  }

  # Spark Master Web UI from bastion
  ingress {
    description     = "Spark Master Web UI"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [local.bastion_sg_id]
  }

  # Spark Master Web UI from private subnet
  ingress {
    description = "Spark Master Web UI from workers"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.private_subnet_cidr]
  }

  # All traffic from within the security group (for cluster communication)
  ingress {
    description = "Internal cluster communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # All outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-master-sg"
    Project = var.project_name
  }
}

# Security Group for Worker Nodes
# Create only if existing_worker_sg_id is not provided
resource "aws_security_group" "worker" {
  count = var.existing_worker_sg_id == "" ? 1 : 0

  name        = "${var.project_name}-worker-sg"
  description = "Security group for worker nodes"
  vpc_id      = data.aws_vpc.existing.id

  # SSH from bastion
  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [local.bastion_sg_id]
  }

  # Spark Worker ports from master
  ingress {
    description     = "Spark Worker from master"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [local.master_sg_id]
  }

  # All traffic from within the security group (worker to worker)
  ingress {
    description = "Internal worker communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # All traffic from master security group
  ingress {
    description     = "All from master"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [local.master_sg_id]
  }

  # All outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-worker-sg"
    Project = var.project_name
  }
}
