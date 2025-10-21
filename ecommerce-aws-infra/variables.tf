variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "ecommerce"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for multi-AZ deployment"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# EC2 Configuration
variable "web_tier_instance_type" {
  description = "Instance type for web tier"
  type        = string
  default     = "t3.medium"
}

variable "app_tier_instance_type" {
  description = "Instance type for application tier"
  type        = string
  default     = "t3.large"
}

variable "web_tier_min_size" {
  description = "Minimum number of instances in web tier ASG"
  type        = number
  default     = 2
}

variable "web_tier_max_size" {
  description = "Maximum number of instances in web tier ASG"
  type        = number
  default     = 10
}

variable "web_tier_desired_capacity" {
  description = "Desired number of instances in web tier ASG"
  type        = number
  default     = 3
}

variable "app_tier_min_size" {
  description = "Minimum number of instances in app tier ASG"
  type        = number
  default     = 2
}

variable "app_tier_max_size" {
  description = "Maximum number of instances in app tier ASG"
  type        = number
  default     = 10
}

variable "app_tier_desired_capacity" {
  description = "Desired number of instances in app tier ASG"
  type        = number
  default     = 3
}

# RDS Configuration
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.r6g.xlarge"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "ecommercedb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 100
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage for RDS autoscaling in GB"
  type        = number
  default     = 500
}

variable "db_backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

# ElastiCache Configuration
variable "elasticache_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.r6g.large"
}

variable "elasticache_num_cache_nodes" {
  description = "Number of cache nodes"
  type        = number
  default     = 2
}

# Monitoring
variable "enable_enhanced_monitoring" {
  description = "Enable enhanced monitoring"
  type        = bool
  default     = true
}

variable "alarm_email" {
  description = "Email address for CloudWatch alarms"
  type        = string
  default     = "devops@example.com"
}

# Security
variable "enable_waf" {
  description = "Enable WAF for ALB"
  type        = bool
  default     = true
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the application"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Restrict this in production
}

# SSL Certificate
variable "ssl_certificate_arn" {
  description = "ARN of SSL certificate for HTTPS (leave empty to create HTTP listener)"
  type        = string
  default     = ""
}

# Domain Configuration
variable "domain_name" {
  description = "Domain name for CloudFront distribution"
  type        = string
  default     = ""
}
