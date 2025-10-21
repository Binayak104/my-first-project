# E-Commerce 3-Tier Architecture

## Architecture Diagram

```
                                    Internet
                                       │
                                       │
                        ┌──────────────▼──────────────┐
                        │     CloudFront (CDN)        │
                        │          + WAF              │
                        └──────────────┬──────────────┘
                                       │
                        ┌──────────────▼──────────────┐
                        │      Route 53 (DNS)         │
                        └──────────────┬──────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                                    VPC                                        │
│                              10.0.0.0/16                                      │
│                                                                               │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                         PUBLIC SUBNETS                                  │ │
│  │              (AZ-1, AZ-2, AZ-3 - Multi-AZ)                             │ │
│  │                                                                         │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │ │
│  │  │            Internet Gateway                                      │  │ │
│  │  └───────────────────────┬─────────────────────────────────────────┘  │ │
│  │                          │                                             │ │
│  │  ┌───────────────────────▼────────────────────────────────────────┐  │ │
│  │  │      Public Application Load Balancer (ALB)                     │  │ │
│  │  │      - HTTPS/HTTP Listeners                                     │  │ │
│  │  │      - SSL Termination                                          │  │ │
│  │  └───────────────────────┬─────────────────────────────────────────┘  │ │
│  │                          │                                             │ │
│  │  ┌───────────────────────▼────────────────────────────────────────┐  │ │
│  │  │    NAT Gateways (3 - one per AZ for HA)                        │  │ │
│  │  └─────────────────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                  │                                           │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                    WEB TIER - PRIVATE SUBNETS                          │ │
│  │              (AZ-1, AZ-2, AZ-3 - Multi-AZ)                             │ │
│  │                                                                         │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │ │
│  │  │         Web Tier Auto Scaling Group                             │  │ │
│  │  │  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐               │  │ │
│  │  │  │ Nginx  │  │ Nginx  │  │ Nginx  │  │ Nginx  │  (2-10 inst)  │  │ │
│  │  │  │ Server │  │ Server │  │ Server │  │ Server │               │  │ │
│  │  │  └────────┘  └────────┘  └────────┘  └────────┘               │  │ │
│  │  │                                                                  │  │ │
│  │  │  - Serve static content                                         │  │ │
│  │  │  - Reverse proxy to App Tier                                    │  │ │
│  │  │  - CloudWatch Agent for monitoring                              │  │ │
│  │  └─────────────────────────┬───────────────────────────────────────┘  │ │
│  └────────────────────────────┼───────────────────────────────────────────┘ │
│                                │                                             │
│  ┌────────────────────────────▼───────────────────────────────────────────┐ │
│  │                  APPLICATION TIER - PRIVATE SUBNETS                     │ │
│  │              (AZ-1, AZ-2, AZ-3 - Multi-AZ)                             │ │
│  │                                                                         │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │ │
│  │  │     Internal Application Load Balancer (ALB)                    │  │ │
│  │  └───────────────────────┬─────────────────────────────────────────┘  │ │
│  │                          │                                             │ │
│  │  ┌───────────────────────▼─────────────────────────────────────────┐  │ │
│  │  │       Application Tier Auto Scaling Group                       │  │ │
│  │  │  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐               │  │ │
│  │  │  │Node.js │  │Node.js │  │Node.js │  │Node.js │  (2-10 inst)  │  │ │
│  │  │  │  API   │  │  API   │  │  API   │  │  API   │               │  │ │
│  │  │  └────────┘  └────────┘  └────────┘  └────────┘               │  │ │
│  │  │                                                                  │  │ │
│  │  │  - Business logic processing                                    │  │ │
│  │  │  - Database queries                                             │  │ │
│  │  │  - Cache operations                                             │  │ │
│  │  └─────────────────────────┬───────────────────────────────────────┘  │ │
│  └────────────────────────────┼───────────────────────────────────────────┘ │
│                                │                                             │
│  ┌────────────────────────────▼───────────────────────────────────────────┐ │
│  │                    DATABASE TIER - PRIVATE SUBNETS                      │ │
│  │              (AZ-1, AZ-2, AZ-3 - Multi-AZ)                             │ │
│  │                                                                         │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │ │
│  │  │            RDS PostgreSQL (Multi-AZ)                            │  │ │
│  │  │  ┌──────────────────┐         ┌──────────────────┐             │  │ │
│  │  │  │  Primary (AZ-1)  │◄───────►│ Standby (AZ-2)   │             │  │ │
│  │  │  └──────────────────┘         └──────────────────┘             │  │ │
│  │  │  ┌──────────────────┐                                           │  │ │
│  │  │  │ Read Replica     │  (Scale read operations)                 │  │ │
│  │  │  └──────────────────┘                                           │  │ │
│  │  │                                                                  │  │ │
│  │  │  - Automated backups                                            │  │ │
│  │  │  - Encryption at rest                                           │  │ │
│  │  │  - Performance Insights                                         │  │ │
│  │  └──────────────────────────────────────────────────────────────────┘  │ │
│  │                                                                         │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │ │
│  │  │         ElastiCache Redis (Multi-AZ with Failover)             │  │ │
│  │  │  ┌──────────────────┐         ┌──────────────────┐             │  │ │
│  │  │  │ Primary (AZ-1)   │◄───────►│ Replica (AZ-2)   │             │  │ │
│  │  │  └──────────────────┘         └──────────────────┘             │  │ │
│  │  │                                                                  │  │ │
│  │  │  - Session storage                                              │  │ │
│  │  │  - Application caching                                          │  │ │
│  │  │  - Encryption at rest & in transit                              │  │ │
│  │  └──────────────────────────────────────────────────────────────────┘  │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                                                               │
└───────────────────────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────────────────────┐
│                         SUPPORTING SERVICES                                    │
├───────────────────────────────────────────────────────────────────────────────┤
│                                                                                │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐              │
│  │   S3 Buckets    │  │ Secrets Manager │  │   CloudWatch    │              │
│  │                 │  │                 │  │                 │              │
│  │  - Assets       │  │  - DB Password  │  │  - Logs         │              │
│  │  - Logs         │  │  - Redis Auth   │  │  - Metrics      │              │
│  │  - Backups      │  │                 │  │  - Alarms       │              │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘              │
│                                                                                │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐              │
│  │   AWS Backup    │  │   SNS Topics    │  │  EventBridge    │              │
│  │                 │  │                 │  │                 │              │
│  │  - RDS          │  │  - Alerts       │  │  - Event Rules  │              │
│  │  - EBS          │  │  - Notifications│  │  - Automation   │              │
│  │  - Schedules    │  │                 │  │                 │              │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘              │
│                                                                                │
└────────────────────────────────────────────────────────────────────────────────┘
```

## Traffic Flow

### 1. User Request Flow (Read Operation)
```
User → CloudFront (CDN) → WAF → Public ALB → Web Tier ASG (Nginx) 
  → Internal ALB → App Tier ASG (Node.js) → ElastiCache (Redis) [Cache Hit]
  → Response back through the chain
```

### 2. Database Write Flow
```
User → CloudFront → WAF → Public ALB → Web Tier → Internal ALB 
  → App Tier → RDS Primary → [Synchronous replication to Standby]
  → Response back
```

### 3. Database Read Flow (with Read Replica)
```
User → CloudFront → WAF → Public ALB → Web Tier → Internal ALB 
  → App Tier → RDS Read Replica → Response back
```

### 4. Static Content Delivery
```
User → CloudFront → S3 Assets Bucket → Response (Cached at Edge)
```

## Network Architecture

### Subnet Design (per AZ)

| Subnet Type | CIDR Range    | Purpose                    | Internet Access |
|-------------|---------------|----------------------------|-----------------|
| Public      | 10.0.x.0/24   | ALB, NAT Gateway           | Direct via IGW  |
| Web Private | 10.0.(x+10).0/24 | Web tier EC2 instances  | Via NAT Gateway |
| App Private | 10.0.(x+20).0/24 | App tier EC2 instances  | Via NAT Gateway |
| DB Private  | 10.0.(x+30).0/24 | RDS, ElastiCache        | Via NAT Gateway |

## Security Layers

### Layer 1: Network (VPC & Subnets)
- VPC isolation
- Private subnets for all compute and data
- Public subnets only for load balancers and NAT

### Layer 2: WAF (Web Application Firewall)
- Rate limiting (2000 requests/5min per IP)
- AWS Managed Rule Sets:
  - Common Rule Set (OWASP Top 10)
  - Known Bad Inputs
  - SQL Injection Protection
  - Bot Control
  - IP Reputation List

### Layer 3: Security Groups
- **Public ALB SG**: Allow 80/443 from internet
- **Web Tier SG**: Allow 80/443 only from Public ALB SG
- **Internal ALB SG**: Allow 80/443 only from Web Tier SG
- **App Tier SG**: Allow 8080/8443 only from Internal ALB SG
- **Database SG**: Allow 3306/5432 only from App Tier SG
- **ElastiCache SG**: Allow 6379/11211 only from App Tier SG

### Layer 4: Network ACLs
- Stateless firewall at subnet level
- Additional defense layer
- Separate NACLs for public, private, and database subnets

### Layer 5: Encryption
- **At Rest**: RDS, ElastiCache, S3, EBS (AES-256)
- **In Transit**: TLS 1.2+ for all connections
- **Secrets**: AWS Secrets Manager with automatic rotation

### Layer 6: IAM
- Instance profiles with least-privilege policies
- No access keys on EC2 instances
- SSM Session Manager for secure access (no SSH keys)

## High Availability Features

### Compute Tier (Web & App)
- Auto Scaling Groups across 3 AZs
- Health checks via ALB
- Automatic replacement of unhealthy instances
- Target tracking scaling policies

### Load Balancers
- Cross-zone load balancing enabled
- Connection draining during scaling
- Sticky sessions for session persistence
- Health checks with automatic rerouting

### Database Tier
- RDS Multi-AZ with automatic failover (< 2 minutes)
- Read replicas for read scaling
- Automated backups with point-in-time recovery
- Enhanced monitoring and Performance Insights

### Caching Tier
- ElastiCache Multi-AZ with automatic failover
- Redis cluster mode for scalability
- Automated backups

### Networking
- Multiple NAT Gateways (one per AZ)
- Route table per AZ for isolation
- Redundant paths to internet

## Scalability Features

### Horizontal Scaling
- **Web Tier**: 2-10 instances based on CPU/requests
- **App Tier**: 2-10 instances based on CPU/requests
- **ElastiCache**: Redis cluster with sharding
- **RDS**: Read replicas for read scaling

### Vertical Scaling
- Instance types configurable
- RDS storage auto-scaling (100GB → 500GB)
- Can upgrade instance classes with minimal downtime

### Global Scaling
- CloudFront for global content delivery
- Edge caching reduces origin load
- Configurable cache behaviors per content type

## Monitoring & Observability

### Metrics
- ALB: Request count, response time, error rates
- EC2: CPU, memory, disk, network
- RDS: Connections, CPU, IOPS, replication lag
- ElastiCache: CPU, memory, evictions, hit rate

### Logs
- VPC Flow Logs
- ALB Access Logs
- Application Logs
- WAF Logs
- ElastiCache Slow Logs

### Alarms
- CPU utilization > 80%
- Memory usage > 90%
- Disk space < 10GB
- ALB 5XX errors > 10
- Target response time > 1s
- Unhealthy hosts < 1

### Dashboards
- CloudWatch unified dashboard
- Real-time metrics visualization
- Historical trend analysis

## Backup & Disaster Recovery

### RDS Backups
- Automated daily backups (7-day retention)
- Manual snapshots (as needed)
- Point-in-time recovery
- Cross-region backup replication (optional)

### AWS Backup Service
- Centralized backup management
- Daily (30 days), Weekly (90 days), Monthly (365 days)
- Lifecycle policies to cold storage
- Cross-region backup copies (optional)

### S3 Versioning
- Version control for all S3 objects
- Lifecycle policies for cost optimization
- Replication to another region (optional)

### Recovery Objectives
- **RTO** (Recovery Time Objective): < 1 hour
- **RPO** (Recovery Point Objective): < 5 minutes (for RDS)

## Cost Optimization

### Right-Sizing
- T3 instances with burst capability
- Configurable instance sizes per tier
- Auto Scaling to match demand

### Storage Optimization
- gp3 EBS volumes (better price/performance)
- S3 lifecycle policies (IA, Glacier)
- RDS storage auto-scaling

### Reserved Capacity
- Consider Reserved Instances for baseline capacity
- Savings Plans for flexible commitment
- Spot Instances for non-critical workloads (not included)

### Monitoring
- Cost allocation tags
- CloudWatch dashboard for resource utilization
- Right-sizing recommendations

## Deployment Considerations

### Prerequisites
1. SSL certificate in ACM (for HTTPS)
2. Domain name (for custom domain)
3. AWS account with appropriate permissions
4. Terraform installed locally

### Initial Deployment Time
- **Terraform Apply**: ~25-30 minutes
- **Instance Initialization**: ~5-10 minutes
- **Total**: ~35-40 minutes

### Update Strategy
- Blue/Green deployment via ASG
- Rolling updates with connection draining
- Database migrations via maintenance window

## Compliance & Best Practices

### AWS Well-Architected Framework Alignment

✅ **Operational Excellence**
- Infrastructure as Code (Terraform)
- Automated monitoring and alerting
- Centralized logging

✅ **Security**
- Defense in depth
- Encryption at rest and in transit
- Least-privilege access
- Secrets management

✅ **Reliability**
- Multi-AZ deployment
- Auto-healing (Auto Scaling)
- Automated backups
- Disaster recovery plan

✅ **Performance Efficiency**
- Auto Scaling based on demand
- Caching layers (ElastiCache, CloudFront)
- Read replicas for database scaling
- Right-sized instances

✅ **Cost Optimization**
- Auto Scaling to match demand
- Storage lifecycle policies
- Reserved capacity options
- Cost monitoring

### Industry Standards
- HTTPS/TLS 1.2+ enforced
- Secrets rotation supported
- Audit logging (CloudTrail recommended)
- Backup and retention policies

## Future Enhancements

### Potential Additions
1. **Amazon ECS/EKS** - Container orchestration
2. **AWS Lambda** - Serverless functions
3. **Amazon SQS** - Message queuing
4. **Amazon OpenSearch** - Search and analytics
5. **AWS Certificate Manager** - Automated SSL rotation
6. **AWS Systems Manager** - Parameter Store, Patch Manager
7. **AWS Shield Advanced** - Enhanced DDoS protection
8. **Multi-Region Deployment** - Global presence
9. **Blue/Green Deployment** - Zero-downtime updates
10. **Database Read Replicas in other regions** - Global reads

---

This architecture provides a solid foundation for a scalable, secure, and highly available e-commerce platform on AWS.
