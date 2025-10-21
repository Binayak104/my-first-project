# E-Commerce 3-Tier AWS Infrastructure

This Terraform configuration provisions a highly available, scalable, and secure 3-tier e-commerce infrastructure on AWS.

## Architecture Overview

### 3-Tier Architecture

1. **Presentation Tier (Web Layer)**
   - Public-facing web servers behind Application Load Balancer
   - Auto Scaling Group for dynamic scaling
   - Nginx web servers serving static content and proxying API requests
   - CloudFront CDN for global content delivery

2. **Application Tier (Business Logic Layer)**
   - Private application servers behind internal ALB
   - Auto Scaling Group for handling business logic
   - Node.js application servers (customizable)
   - Access to database and cache layers

3. **Data Tier (Database Layer)**
   - RDS PostgreSQL with Multi-AZ deployment
   - Read replica for scaling read operations
   - ElastiCache Redis cluster for session management and caching
   - Automated backups and point-in-time recovery

## Key Features

### Security
- **Network Isolation**: VPC with public and private subnets across multiple AZs
- **Security Groups**: Least-privilege access controls between tiers
- **Network ACLs**: Additional layer of security at subnet level
- **WAF**: Web Application Firewall protecting against common web exploits
- **Encryption**: Data encryption at rest (RDS, ElastiCache, S3, EBS) and in transit
- **Secrets Management**: Database credentials stored in AWS Secrets Manager
- **VPC Flow Logs**: Network traffic monitoring and analysis

### High Availability
- **Multi-AZ Deployment**: Resources distributed across 3 availability zones
- **Auto Scaling**: Automatic scaling based on CPU and request metrics
- **RDS Multi-AZ**: Automatic failover for database
- **ElastiCache Multi-AZ**: Automatic failover for cache layer
- **Multiple NAT Gateways**: One per AZ for high availability

### Scalability
- **Auto Scaling Groups**: Horizontal scaling for web and app tiers
- **RDS Read Replicas**: Scale database read operations
- **ElastiCache Cluster**: Distributed caching
- **CloudFront CDN**: Global content distribution
- **Application Load Balancers**: Distribute traffic across instances

### Monitoring & Observability
- **CloudWatch Dashboards**: Centralized monitoring
- **CloudWatch Alarms**: Proactive alerting for critical metrics
- **CloudWatch Logs**: Centralized log aggregation
- **SNS Notifications**: Email alerts for critical events
- **VPC Flow Logs**: Network traffic analysis
- **Enhanced Monitoring**: Detailed metrics for RDS and EC2

### Backup & Disaster Recovery
- **AWS Backup**: Automated backup plans with retention policies
- **RDS Automated Backups**: Point-in-time recovery
- **S3 Versioning**: Version control for static assets
- **Cross-AZ Redundancy**: Data replication across availability zones

## Prerequisites

- AWS Account with appropriate permissions
- Terraform >= 1.5.0
- AWS CLI configured with credentials
- (Optional) SSL certificate in AWS Certificate Manager for HTTPS

## Directory Structure

```
ecommerce-aws-infra/
├── README.md                    # This file
├── versions.tf                  # Terraform and provider versions
├── variables.tf                 # Input variables
├── terraform.tfvars.example    # Example variable values
├── vpc.tf                      # VPC and networking resources
├── security_groups.tf          # Security groups and NACLs
├── iam.tf                      # IAM roles and policies
├── alb.tf                      # Application Load Balancers
├── asg.tf                      # Auto Scaling Groups
├── rds.tf                      # RDS database
├── elasticache.tf              # ElastiCache Redis
├── s3.tf                       # S3 buckets
├── cloudfront.tf               # CloudFront distribution
├── waf.tf                      # WAF rules
├── monitoring.tf               # CloudWatch monitoring and alarms
├── backup.tf                   # AWS Backup configuration
├── outputs.tf                  # Output values
└── user_data/
    ├── web_tier.sh             # Web tier initialization script
    └── app_tier.sh             # App tier initialization script
```

## Quick Start

### 1. Clone and Navigate

```bash
cd ecommerce-aws-infra
```

### 2. Create terraform.tfvars

Copy the example file and customize:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:

```hcl
aws_region   = "us-east-1"
environment  = "prod"
project_name = "ecommerce"

# Optional: Configure SSL certificate
ssl_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxx"

# Optional: Configure custom domain
domain_name = "www.example.com"

# Configure alert email
alarm_email = "devops@example.com"
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review the Plan

```bash
terraform plan
```

### 5. Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted to confirm.

### 6. Get Outputs

After deployment, view the outputs:

```bash
terraform output
```

## Important Outputs

After deployment, you'll get:

- **application_url**: Primary application URL (ALB DNS or custom domain)
- **cloudfront_url**: CloudFront CDN URL
- **public_alb_dns_name**: Direct ALB DNS name
- **rds_endpoint**: Database endpoint
- **elasticache_primary_endpoint**: Redis cache endpoint
- **db_secret_arn**: ARN to retrieve database credentials
- **redis_auth_secret_arn**: ARN to retrieve Redis auth token

## Configuration

### Cost Optimization

For development/testing environments, you can reduce costs by:

1. Reducing instance sizes:
   ```hcl
   web_tier_instance_type = "t3.small"
   app_tier_instance_type = "t3.medium"
   db_instance_class = "db.t3.medium"
   ```

2. Reducing Auto Scaling capacity:
   ```hcl
   web_tier_min_size = 1
   web_tier_desired_capacity = 2
   ```

3. Using single-AZ ElastiCache (not recommended for production)

### Production Recommendations

1. **Enable deletion protection** (enabled by default for prod environment)
2. **Use SSL certificates** - Upload to ACM and provide ARN
3. **Configure custom domain** in CloudFront
4. **Review and customize WAF rules** based on your traffic patterns
5. **Adjust Auto Scaling thresholds** based on your application metrics
6. **Configure S3 backend** for state management:

```hcl
# Uncomment in versions.tf
backend "s3" {
  bucket         = "your-terraform-state-bucket"
  key            = "ecommerce/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-state-lock"
}
```

## Accessing Resources

### Retrieve Database Credentials

```bash
aws secretsmanager get-secret-value \
  --secret-id $(terraform output -raw db_secret_arn) \
  --query SecretString \
  --output text | jq .
```

### Retrieve Redis Auth Token

```bash
aws secretsmanager get-secret-value \
  --secret-id $(terraform output -raw redis_auth_secret_arn) \
  --query SecretString \
  --output text | jq .
```

### Connect to EC2 Instances (via SSM)

```bash
# List instances
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=ecommerce" \
  --query 'Reservations[].Instances[].InstanceId'

# Connect to instance
aws ssm start-session --target <instance-id>
```

### View CloudWatch Dashboard

```bash
aws cloudwatch get-dashboard \
  --dashboard-name $(terraform output -raw cloudwatch_dashboard_name)
```

## Monitoring

### CloudWatch Alarms

The following alarms are configured:

- **ALB**: Target response time, 5XX errors, healthy host count
- **RDS**: CPU utilization, storage space, memory
- **ElastiCache**: CPU, memory usage, evictions
- **WAF**: Blocked requests
- **Application**: Error count from logs

All alarms send notifications to the configured SNS topic.

### Logs

Logs are aggregated in CloudWatch Log Groups:

- `/aws/ecommerce/{environment}/application` - Application logs
- `/aws/vpc/ecommerce-{environment}` - VPC Flow Logs
- `/aws/elasticache/ecommerce-{environment}` - ElastiCache logs
- `aws-waf-logs-ecommerce-{environment}` - WAF logs

## Backup and Recovery

### Automated Backups

- **Daily backups**: 30-day retention
- **Weekly backups**: 90-day retention (archived to cold storage after 30 days)
- **Monthly backups**: 365-day retention (archived to cold storage after 90 days)

### Manual Backup

To create a manual backup:

```bash
# RDS snapshot
aws rds create-db-snapshot \
  --db-instance-identifier $(terraform output -raw rds_endpoint | cut -d: -f1) \
  --db-snapshot-identifier manual-snapshot-$(date +%Y%m%d)
```

### Restore from Backup

Use AWS Backup console or CLI to restore from backup vault.

## Security Best Practices

1. **Rotate Secrets Regularly**: Use AWS Secrets Manager rotation
2. **Review Security Groups**: Regularly audit and minimize open ports
3. **Enable MFA**: For AWS account access
4. **Use IAM Roles**: Never use access keys on EC2 instances
5. **Enable CloudTrail**: For audit logging (not included, add separately)
6. **Review WAF Logs**: Monitor for attack patterns
7. **Keep Systems Updated**: Regularly patch OS and applications

## Customization

### Adding Custom Application Code

1. Modify `user_data/web_tier.sh` and `user_data/app_tier.sh`
2. Add deployment scripts to pull from S3 or git repository
3. Update health check paths in ALB target groups

### Adding Additional Services

You can extend this infrastructure by adding:

- Amazon SQS for message queuing
- Amazon SNS for pub/sub messaging
- Amazon OpenSearch for search functionality
- AWS Lambda for serverless functions
- Amazon ECS/EKS for containerized workloads

## Troubleshooting

### Instances Failing Health Checks

1. Check security group rules
2. Verify application is listening on correct port
3. Check CloudWatch logs for application errors
4. Verify user data script execution

### Database Connection Issues

1. Verify security group allows traffic from app tier
2. Check database credentials in Secrets Manager
3. Verify RDS instance is in running state
4. Check VPC routing and NAT Gateway

### High Costs

1. Review CloudWatch metrics for over-provisioned resources
2. Check Auto Scaling metrics - may be scaling too aggressively
3. Review S3 lifecycle policies
4. Consider Reserved Instances for predictable workloads

## Cost Estimate

Approximate monthly costs (us-east-1, production configuration):

- **VPC**: NAT Gateways (~$100)
- **EC2**: Auto Scaling instances (~$300-600 depending on load)
- **RDS**: Multi-AZ PostgreSQL (~$400-800 depending on instance size)
- **ElastiCache**: Redis cluster (~$150-300)
- **ALB**: 2 Load Balancers (~$50)
- **S3**: Storage and transfers (~$50-200)
- **CloudFront**: Data transfer (~varies by traffic)
- **CloudWatch**: Metrics and logs (~$50)
- **Backups**: Storage (~$50-200)

**Total: ~$1,150 - $2,450/month** (varies significantly based on traffic and scaling)

## Cleanup

To destroy all resources:

```bash
# Review what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy
```

**Warning**: This will delete all data. Ensure backups are taken if needed.

## Support and Contributions

For issues or questions:
1. Review CloudWatch logs
2. Check AWS Service Health Dashboard
3. Review Terraform state for resource status

## License

This infrastructure code is provided as-is for educational and production use.

## Additional Resources

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

**Note**: This is a production-ready infrastructure template. Always review and customize based on your specific requirements, compliance needs, and budget constraints.
