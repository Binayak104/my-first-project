#!/bin/bash

# Deploy CloudFormation stack in us-east-1 region
aws cloudformation create-stack \
  --stack-name my-web-server \
  --template-body file://ec2-web-server.yaml \
  --parameters ParameterKey=KeyName,ParameterValue=key-23-10-2025 \
  --region us-east-1

echo "Stack creation initiated in us-east-1 region"
echo "Waiting for stack to complete..."

# Wait for stack creation to complete
aws cloudformation wait stack-create-complete \
  --stack-name my-web-server \
  --region us-east-1

echo ""
echo "Stack created successfully!"
echo ""

# Get outputs
aws cloudformation describe-stacks \
  --stack-name my-web-server \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
  --output table
