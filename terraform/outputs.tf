# ============================================================================
# OUTPUTS
# ============================================================================

# Commented out - using existing bastion
# output "bastion_public_ip" {
#   description = "Public IP of bastion host"
#   value       = aws_instance.bastion.public_ip
# }
#
# output "bastion_private_ip" {
#   description = "Private IP of bastion host"
#   value       = aws_instance.bastion.private_ip
# }

output "master_private_ip" {
  description = "Private IP of master node"
  value       = aws_instance.master.private_ip
}

output "worker_private_ips" {
  description = "Private IPs of worker nodes"
  value       = aws_instance.worker[*].private_ip
}

output "vpc_id" {
  description = "VPC ID (existing)"
  value       = data.aws_vpc.existing.id
}

# Commented out - using existing bastion
# output "ssh_bastion_command" {
#   description = "Command to SSH into bastion"
#   value       = "ssh -i ~/.ssh/${var.ssh_key_name}.pem ec2-user@${aws_instance.bastion.public_ip}"
# }
#
# output "ssh_master_command" {
#   description = "Command to SSH into master via bastion"
#   value       = "ssh -i ~/.ssh/${var.ssh_key_name}.pem -J ec2-user@${aws_instance.bastion.public_ip} ec2-user@${aws_instance.master.private_ip}"
# }

output "master_instance_id" {
  description = "Instance ID of master node"
  value       = aws_instance.master.id
}

output "worker_instance_ids" {
  description = "Instance IDs of worker nodes"
  value       = aws_instance.worker[*].id
}

output "ansible_inventory" {
  description = "Ansible inventory content"
  value = templatefile("${path.module}/templates/hosts.ini.tpl", {
    master_private_ip  = aws_instance.master.private_ip
    worker_private_ips = aws_instance.worker[*].private_ip
  })
}
