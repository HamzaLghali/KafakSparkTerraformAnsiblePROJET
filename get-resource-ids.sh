#!/bin/bash
# Script to find your AWS resource IDs

echo "=== Finding VPC and Subnet IDs ==="
echo ""

echo "VPC ID:"
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,CidrBlock,Tags[?Key==`Name`].Value|[0]]' --output table

echo ""
echo "Subnets:"
aws ec2 describe-subnets --query 'Subnets[*].[SubnetId,VpcId,CidrBlock,AvailabilityZone,Tags[?Key==`Name`].Value|[0]]' --output table

echo ""
echo "Your Bastion Instance Info:"
aws ec2 describe-instances --instance-ids i-06cf6eda24794efe9 --query 'Reservations[0].Instances[0].[VpcId,SubnetId,PrivateIpAddress]' --output table
