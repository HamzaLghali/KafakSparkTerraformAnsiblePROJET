exit
ls
cat fike
cat file
cd ansible/
ansible-playbook -i inventories/hosts.ini playbooks/site.yml
# First, find your instance IPs
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],PrivateIpAddress]' --output table
aws ec2 describe-vpcs
cd ~/terraform && terraform plan
ls
exit
cat ~/ansible/group_vars/master.yml ~/ansible/group_vars/workers.yml
cd ~/ansible && ansible all -m ping -i inventories/hosts.ini
ps aux | grep ansible-playbook
ls -la /home/ec2-user/kafka-spark-keypair.pem
ssh -i /home/ec2-user/kafka-spark-keypair.pem -o StrictHostKeyChecking=no ubuntu@10.0.136.17 "echo 'SSH test successful'"
