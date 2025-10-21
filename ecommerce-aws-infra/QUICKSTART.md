# Quick Start Guide

## Prerequisites

1. **Install Terraform**
   ```bash
   # macOS
   brew install terraform
   
   # Linux
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

2. **Configure AWS Credentials**
   ```bash
   aws configure
   ```
   
   Or export credentials:
   ```bash
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   export AWS_DEFAULT_REGION="us-east-1"
   ```

## Step-by-Step Deployment

### 1. Prepare Configuration

Create your `terraform.tfvars` file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
aws_region   = "us-east-1"
environment  = "prod"
project_name = "ecommerce"
alarm_email  = "your-email@example.com"

# Optional: Add SSL certificate for HTTPS
# ssl_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxx"
```

### 2. Initialize Terraform

```bash
cd ecommerce-aws-infra
terraform init
```

Expected output:
```
Initializing the backend...
Initializing provider plugins...
Terraform has been successfully initialized!
```

### 3. Validate Configuration

```bash
terraform validate
```

Expected output:
```
Success! The configuration is valid.
```

### 4. Plan Deployment

Review what will be created:

```bash
terraform plan -out=tfplan
```

This will show:
- ~180-200 resources to be created
- Estimated deployment time: 30-40 minutes

### 5. Apply Configuration

Deploy the infrastructure:

```bash
terraform apply tfplan
```

Or directly:

```bash
terraform apply
```

Type `yes` when prompted.

### 6. Get Outputs

After successful deployment:

```bash
# View all outputs
terraform output

# Get specific output
terraform output application_url
terraform output cloudfront_url
terraform output rds_endpoint
```

## Post-Deployment Steps

### 1. Verify SNS Email Subscription

Check your email for AWS SNS subscription confirmation and click the confirmation link.

### 2. Access Database Credentials

```bash
# Get database credentials
aws secretsmanager get-secret-value \
  --secret-id $(terraform output -raw db_secret_arn) \
  --query SecretString --output text | jq .
```

### 3. Access Redis Auth Token

```bash
# Get Redis credentials
aws secretsmanager get-secret-value \
  --secret-id $(terraform output -raw redis_auth_secret_arn) \
  --query SecretString --output text | jq .
```

### 4. Test Application

```bash
# Test ALB endpoint
curl http://$(terraform output -raw public_alb_dns_name)/health

# Test CloudFront endpoint
curl https://$(terraform output -raw cloudfront_distribution_domain_name)/
```

### 5. View CloudWatch Dashboard

```bash
# Open in browser
echo "https://console.aws.amazon.com/cloudwatch/home?region=$(terraform output -raw aws_region)#dashboards:name=$(terraform output -raw cloudwatch_dashboard_name)"
```

## Deployment Timeline

| Step | Duration | Description |
|------|----------|-------------|
| VPC & Networking | 3-5 min | VPC, subnets, IGW, NAT gateways |
| Security Groups | 1-2 min | Security groups and NACLs |
| IAM Roles | 1 min | IAM roles and policies |
| RDS Database | 10-15 min | Multi-AZ RDS and read replica |
| ElastiCache | 5-10 min | Redis cluster |
| Load Balancers | 3-5 min | Public and internal ALBs |
| Auto Scaling | 2-3 min | ASG and launch templates |
| EC2 Instances | 3-5 min | Instance launch and user data |
| S3 & CloudFront | 2-3 min | S3 buckets and CDN |
| WAF | 1-2 min | WAF rules |
| Monitoring | 1-2 min | CloudWatch alarms and dashboard |
| **Total** | **30-40 min** | Complete deployment |

## Common Issues & Solutions

### Issue 1: "Error creating VPC"
**Solution**: Check AWS region and account limits for VPCs

```bash
aws ec2 describe-account-attributes --region us-east-1
```

### Issue 2: "Error creating RDS instance"
**Solution**: Check if you have sufficient RDS instance quota

```bash
aws service-quotas list-service-quotas \
  --service-code rds \
  --query 'Quotas[?QuotaName==`DB instances`]'
```

### Issue 3: "Error creating NAT Gateway"
**Solution**: Check Elastic IP quota (need 3 for Multi-AZ)

```bash
aws ec2 describe-account-attributes \
  --attribute-names max-elastic-ips
```

### Issue 4: Terraform state lock error
**Solution**: If using S3 backend with DynamoDB locking

```bash
# Force unlock (use carefully)
terraform force-unlock <lock-id>
```

### Issue 5: "NoSuchBucket" error for S3
**Solution**: S3 bucket names must be globally unique. Change project_name in terraform.tfvars

## Updating Infrastructure

### Update Instance Count

Edit `terraform.tfvars`:
```hcl
web_tier_desired_capacity = 5  # Increase from 3 to 5
```

Apply changes:
```bash
terraform apply
```

### Update Instance Type

Edit `terraform.tfvars`:
```hcl
web_tier_instance_type = "t3.large"  # Upgrade from t3.medium
```

Apply changes (will trigger rolling update):
```bash
terraform apply
```

### Update Database

Edit `terraform.tfvars`:
```hcl
db_instance_class = "db.r6g.2xlarge"  # Upgrade
```

Apply changes (will cause brief downtime for Multi-AZ):
```bash
terraform apply
```

## Accessing Resources

### SSH to EC2 Instances (via SSM)

```bash
# List instances
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=ecommerce" \
  --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name]' \
  --output table

# Connect to instance (no SSH key needed)
aws ssm start-session --target i-1234567890abcdef0
```

### Connect to RDS

```bash
# Get database endpoint
DB_ENDPOINT=$(terraform output -raw rds_endpoint)

# Get credentials
DB_CREDS=$(aws secretsmanager get-secret-value \
  --secret-id $(terraform output -raw db_secret_arn) \
  --query SecretString --output text)

DB_USER=$(echo $DB_CREDS | jq -r .username)
DB_PASS=$(echo $DB_CREDS | jq -r .password)
DB_NAME=$(echo $DB_CREDS | jq -r .dbname)

# Connect using psql (from bastion or EC2 instance)
psql -h $DB_ENDPOINT -U $DB_USER -d $DB_NAME
```

### Connect to Redis

```bash
# Get Redis endpoint
REDIS_ENDPOINT=$(terraform output -raw elasticache_primary_endpoint)

# Get auth token
REDIS_AUTH=$(aws secretsmanager get-secret-value \
  --secret-id $(terraform output -raw redis_auth_secret_arn) \
  --query SecretString --output text | jq -r .auth_token)

# Connect using redis-cli (from app tier instance)
redis-cli -h $REDIS_ENDPOINT -a $REDIS_AUTH --tls
```

## Monitoring

### View Logs

```bash
# Application logs
aws logs tail /aws/ecommerce/prod/application --follow

# VPC Flow Logs
aws logs tail /aws/vpc/ecommerce-prod --follow

# WAF logs
aws logs tail aws-waf-logs-ecommerce-prod --follow
```

### Check Alarms

```bash
# List all alarms
aws cloudwatch describe-alarms \
  --alarm-name-prefix ecommerce-prod

# Get alarm state
aws cloudwatch describe-alarms \
  --alarm-names "ecommerce-prod-alb-5xx-errors" \
  --query 'MetricAlarms[0].StateValue'
```

### View Metrics

```bash
# ALB request count (last hour)
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name RequestCount \
  --dimensions Name=LoadBalancer,Value=$(terraform output -raw public_alb_arn | cut -d: -f6-) \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

## Backup & Recovery

### Manual Database Backup

```bash
# Create RDS snapshot
aws rds create-db-snapshot \
  --db-instance-identifier ecommerce-prod-db \
  --db-snapshot-identifier manual-snapshot-$(date +%Y%m%d-%H%M%S)
```

### Restore from Backup

```bash
# List available backups
aws backup list-recovery-points-by-backup-vault \
  --backup-vault-name ecommerce-prod-backup-vault

# Restore using AWS Backup console or CLI
```

### Export Data

```bash
# Export RDS to S3 (requires IAM role setup)
aws rds start-export-task \
  --export-task-identifier export-$(date +%Y%m%d) \
  --source-arn $(terraform output -raw rds_arn) \
  --s3-bucket-name $(terraform output -raw s3_backups_bucket_name) \
  --iam-role-arn arn:aws:iam::ACCOUNT_ID:role/rds-s3-export-role \
  --kms-key-id arn:aws:kms:REGION:ACCOUNT_ID:key/KEY_ID
```

## Cleanup

### Destroy All Resources

**WARNING**: This will delete all data. Backup first!

```bash
# Review what will be destroyed
terraform plan -destroy

# Destroy infrastructure
terraform destroy
```

Type `yes` when prompted.

### Selective Cleanup

To remove specific resources, comment them out in the .tf files and run:

```bash
terraform apply
```

### Clean Terraform State

```bash
# Remove local state files
rm -rf .terraform
rm terraform.tfstate*
rm .terraform.lock.hcl
```

## Cost Management

### Estimate Costs

Before deployment:

```bash
# Use Infracost (optional tool)
brew install infracost
infracost breakdown --path .
```

### Monitor Costs

```bash
# Get cost for last month
aws ce get-cost-and-usage \
  --time-period Start=$(date -d 'last month' +%Y-%m-01),End=$(date +%Y-%m-01) \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --group-by Type=TAG,Key=Project
```

### Reduce Costs

**Development Environment**:

```hcl
# terraform.tfvars
environment = "dev"
web_tier_instance_type = "t3.small"
app_tier_instance_type = "t3.medium"
db_instance_class = "db.t3.medium"
web_tier_desired_capacity = 1
app_tier_desired_capacity = 1
enable_waf = false
```

## Next Steps

1. **Deploy Application Code**
   - Update user data scripts with your application
   - Set up CI/CD pipeline
   - Configure application environment variables

2. **Configure Domain**
   - Point domain to CloudFront or ALB
   - Update Route 53 records
   - Configure SSL certificate

3. **Set Up CI/CD**
   - AWS CodePipeline
   - GitHub Actions
   - GitLab CI/CD

4. **Implement Monitoring**
   - Application Performance Monitoring (APM)
   - Distributed tracing
   - Custom metrics

5. **Security Hardening**
   - Enable AWS CloudTrail
   - Configure AWS Config
   - Set up AWS GuardDuty
   - Implement AWS Security Hub

## Support

For issues or questions:
- Check CloudWatch logs for application errors
- Review Terraform plan output for infrastructure issues
- Verify AWS service quotas and limits
- Check AWS Service Health Dashboard

## Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Reference Architectures](https://aws.amazon.com/architecture/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
