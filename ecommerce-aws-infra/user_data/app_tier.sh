#!/bin/bash
# App Tier User Data Script
# This script initializes the application server instances

set -e

# Update system packages
yum update -y

# Install CloudWatch agent
wget https://s3.${region}.amazonaws.com/amazoncloudwatch-agent-${region}/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Install Node.js and npm
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Install other dependencies
yum install -y python3 python3-pip git

# Install PostgreSQL client
yum install -y postgresql15

# Create application directory
mkdir -p /opt/app
cd /opt/app

# Create a sample Node.js application
cat > /opt/app/server.js <<'NODEJS'
const http = require('http');
const port = 8080;

const server = http.createServer((req, res) => {
    // Health check endpoint
    if (req.url === '/api/health') {
        res.writeHead(200, {'Content-Type': 'text/plain'});
        res.end('healthy\n');
        return;
    }

    // Sample API endpoint
    if (req.url === '/api/status') {
        res.writeHead(200, {'Content-Type': 'application/json'});
        res.end(JSON.stringify({
            status: 'running',
            environment: '${environment}',
            timestamp: new Date().toISOString()
        }));
        return;
    }

    // Default response
    res.writeHead(404, {'Content-Type': 'text/plain'});
    res.end('Not Found\n');
});

server.listen(port, () => {
    console.log(`Application server running on port $${port}`);
});
NODEJS

# Create package.json
cat > /opt/app/package.json <<'EOF'
{
  "name": "ecommerce-app",
  "version": "1.0.0",
  "description": "E-Commerce Application Server",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "pg": "^8.11.0",
    "redis": "^4.6.0"
  }
}
EOF

# Install Node.js dependencies
npm install

# Create systemd service
cat > /etc/systemd/system/app.service <<'EOF'
[Unit]
Description=E-Commerce Application
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/app
ExecStart=/usr/bin/node /opt/app/server.js
Restart=on-failure
Environment="DB_ENDPOINT=${db_endpoint}"
Environment="CACHE_ENDPOINT=${cache_endpoint}"
Environment="DB_SECRET_ARN=${db_secret_arn}"
Environment="AWS_REGION=${region}"

[Install]
WantedBy=multi-user.target
EOF

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/app.log",
            "log_group_name": "${cloudwatch_group}",
            "log_stream_name": "{instance_id}/application"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "ECommerce/AppTier",
    "metrics_collected": {
      "cpu": {
        "measurement": [{"name": "cpu_usage_idle", "rename": "CPU_IDLE", "unit": "Percent"}],
        "totalcpu": false
      },
      "disk": {
        "measurement": [{"name": "used_percent", "rename": "DISK_USED", "unit": "Percent"}],
        "resources": ["*"]
      },
      "mem": {
        "measurement": [{"name": "mem_used_percent", "rename": "MEM_USED", "unit": "Percent"}]
      }
    }
  }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json

# Start and enable application service
systemctl daemon-reload
systemctl start app
systemctl enable app

# Signal completion
echo "App tier initialization complete"
