# GitHub Setup Guide

## Push Code to GitHub

Your code is ready to push! Follow these steps:

### 1. Create GitHub Repository

Go to [github.com/new](https://github.com/new) and create a new repository:
- Repository name: `spark-kafka-aws-cluster` (or your preferred name)
- Description: "Distributed Spark/Kafka cluster on AWS with Terraform and Ansible"
- **Keep it Private** (contains infrastructure details)
- **DO NOT** initialize with README (you already have one)

### 2. Push Your Code

After creating the repository on GitHub, run these commands:

```bash
# Add remote (replace HamzaLghali with your GitHub username)
git remote add origin https://github.com/HamzaLghali/spark-kafka-aws-cluster.git

# Push to GitHub
git push -u origin main
```

### 3. Authenticate

When prompted:
- **Username**: HamzaLghali
- **Password**: Use a **Personal Access Token** (not your password)

#### Create Personal Access Token:
1. Go to: https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Name: "AWS EC2 Bastion"
4. Expiration: 90 days (or as needed)
5. Select scopes: `repo` (full control of private repositories)
6. Click "Generate token"
7. **Copy the token** (you won't see it again!)
8. Use this token as your password when pushing

### 4. Verify

After pushing, visit:
```
https://github.com/HamzaLghali/spark-kafka-aws-cluster
```

Your code should be visible!

---

## Alternative: SSH Authentication (Recommended)

Instead of HTTPS + tokens, you can use SSH keys:

### Generate SSH Key on Bastion
```bash
ssh-keygen -t ed25519 -C "vanhamzalghali@gmail.com"
# Press Enter for default location
# Press Enter for no passphrase (or set one)

# Display public key
cat ~/.ssh/id_ed25519.pub
```

### Add Key to GitHub
1. Copy the public key output
2. Go to: https://github.com/settings/keys
3. Click "New SSH key"
4. Title: "AWS Bastion Host"
5. Paste the public key
6. Click "Add SSH key"

### Push with SSH
```bash
# Remove HTTPS remote if already added
git remote remove origin

# Add SSH remote
git remote add origin git@github.com:HamzaLghali/spark-kafka-aws-cluster.git

# Push
git push -u origin main
```

---

## Repository Structure

Your repository contains:

```
spark-kafka-aws-cluster/
├── README.md                    # Project overview
├── SETUP_STEPS.md              # Step-by-step deployment guide
├── TECHNICAL_DETAILS.md        # Comprehensive technical documentation
├── .gitignore                  # Excludes sensitive files
├── terraform/                  # Infrastructure as Code
│   ├── *.tf files
│   └── terraform.tfvars.example
└── ansible/                    # Configuration management
    ├── playbooks/
    ├── roles/
    ├── inventories/
    └── group_vars/
```

**Note:** Sensitive files (`.pem`, `terraform.tfstate`, `terraform.tfvars`) are **excluded** by `.gitignore`

---

## After Pushing

### Clone on Another Machine
```bash
git clone https://github.com/HamzaLghali/spark-kafka-aws-cluster.git
cd spark-kafka-aws-cluster
```

### Make Changes
```bash
# Edit files
git add .
git commit -m "Update: description of changes"
git push
```

### Pull Latest Changes
```bash
git pull origin main
```

---

## Security Reminders

✅ **DO:**
- Keep repository **private** (contains AWS resource IDs)
- Use `.gitignore` to exclude sensitive files
- Document security groups and access patterns
- Use IAM roles instead of access keys

❌ **DON'T:**
- Commit `.pem` files
- Commit `terraform.tfstate`
- Commit `terraform.tfvars` with actual AWS IDs
- Share repository URL publicly
- Commit AWS access keys

---

## Current Git Status

```bash
# Check current status
git status

# View commit history
git log --oneline

# See remote repository
git remote -v
```

Your code is committed locally and ready to push! 🚀
