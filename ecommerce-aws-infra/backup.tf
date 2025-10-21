# AWS Backup Vault
resource "aws_backup_vault" "main" {
  name = "${var.project_name}-${var.environment}-backup-vault"

  tags = {
    Name = "${var.project_name}-${var.environment}-backup-vault"
  }
}

# AWS Backup Plan
resource "aws_backup_plan" "main" {
  name = "${var.project_name}-${var.environment}-backup-plan"

  # Daily backups with 30-day retention
  rule {
    rule_name         = "daily-backups"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 2 * * ? *)" # 2 AM UTC daily

    lifecycle {
      delete_after = 30
    }

    recovery_point_tags = {
      Environment = var.environment
      Frequency   = "daily"
    }
  }

  # Weekly backups with 90-day retention
  rule {
    rule_name         = "weekly-backups"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 3 ? * SUN *)" # 3 AM UTC every Sunday

    lifecycle {
      delete_after       = 90
      cold_storage_after = 30
    }

    recovery_point_tags = {
      Environment = var.environment
      Frequency   = "weekly"
    }
  }

  # Monthly backups with 365-day retention
  rule {
    rule_name         = "monthly-backups"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 4 1 * ? *)" # 4 AM UTC on 1st of each month

    lifecycle {
      delete_after       = 365
      cold_storage_after = 90
    }

    recovery_point_tags = {
      Environment = var.environment
      Frequency   = "monthly"
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-backup-plan"
  }
}

# IAM Role for AWS Backup
resource "aws_iam_role" "backup_role" {
  name = "${var.project_name}-${var.environment}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-backup-role"
  }
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "backup_restore_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# Backup Selection for RDS
resource "aws_backup_selection" "rds_backup" {
  name         = "${var.project_name}-${var.environment}-rds-backup"
  plan_id      = aws_backup_plan.main.id
  iam_role_arn = aws_iam_role.backup_role.arn

  resources = [
    aws_db_instance.main.arn
  ]
}

# Backup Selection for EBS volumes (EC2 instances)
resource "aws_backup_selection" "ebs_backup" {
  name         = "${var.project_name}-${var.environment}-ebs-backup"
  plan_id      = aws_backup_plan.main.id
  iam_role_arn = aws_iam_role.backup_role.arn

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Backup"
    value = "true"
  }
}

# Backup notifications
resource "aws_backup_vault_notifications" "main" {
  backup_vault_name   = aws_backup_vault.main.name
  sns_topic_arn       = aws_sns_topic.alerts.arn
  backup_vault_events = [
    "BACKUP_JOB_STARTED",
    "BACKUP_JOB_COMPLETED",
    "BACKUP_JOB_FAILED",
    "RESTORE_JOB_STARTED",
    "RESTORE_JOB_COMPLETED",
    "RESTORE_JOB_FAILED"
  ]
}

# Backup Vault Lock (optional - for compliance)
# Uncomment for production environments with compliance requirements
# resource "aws_backup_vault_lock_configuration" "main" {
#   backup_vault_name   = aws_backup_vault.main.name
#   changeable_for_days = 3
#   min_retention_days  = 7
# }
