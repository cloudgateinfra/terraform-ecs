# Terraform ECS Environments

Infra for a containerized app hosted on AWS using ECS with FARGATE for auto scaling and EFS for auto disk scaling.
This sets up the infra as deploys are done separately alligned to ecs cluster and services terra resource names which corrspond to their AWS resource names.

AWS CLI and GH actions pipelines for deploys can be found here: 
- https://github.com/cloudgateinfra/gh-workflows

## Overview

The Terraform `main.tf` for each env sets up the following resources:

- ECS Task Definition
- IAM Role for ECS Tasks
- IAM Policy for ECS to read secrets from the Secrets Manager
- IAM Role Policy Attachments
- ECS Cluster/Service/Tasks
- Application Load Balancer (ALB)
- ALB Target Group
- ALB Listener
- ECS Service
- EFS Mount
- Bastion ec2
- RDS DB
- ACM cert config

It also imports the following declared resources or data sources:

- Default VPC
- Default Subnets
- Provided Security Group

## Setup
1. in your local terminal set these values in your `~/.profile`:
2. below will be used for secrets and sensitive vars via our declared vars in `variables.tf`:
```
# TF local Env Vars: aws api access example.org
 export AWS_ACCESS_KEY_ID=459384508390kdjfkd
 export AWS_SECRET_ACCESS_KEY=945889ddkfjdkjf
 export TF_VAR_docker_username=dockeruser24
 export TF_VAR_docker_password=example123
 export TF_VAR_db_pw=dafsdaflkajdf
 export TF_VAR_db_username=dbuser1
 ```
 3. Source .profile: `source ~/.profile`
 ** *use a space before each export local tfvar line as this hides the values from all logs/text outputs* **
 ** *for prod/team use ACM or other secrets manager if need to use on cloud with deploy roles* **
 4. In `terraform.tfvars` make sure to set registered domain name variable to `test.com` or whatever you would like the dns alb cname record to be pointed to.
 5. In `main.tf` for "local vars" section, make sure ACM cert is the correct ARN of the SSL cert you would like to use for the env for `certificate_arn` local variable.

## Vars

- `variables.tf`: declared vars for use throughout the `main.tf`
- `terraform.tfvars`: env vars that are different between envs but usually remain the same
- `.profile secret tfvars`: tfvars declared in variables.tf but values set in `~/.profile` in meantime
- `local.vars`: vars that do not need to be declared but can be easily set for new env creation in the main.tf (ecs cluster etc.)

## Usage

1. Copy any env and delete the `.terraform` and `.terraform.lock` files. Change name of env dir
2. IMPORTANT: change key path at beginning of `main.tf` to prevent overwriting existing state files in a S3 bucket backend
3. Change local vars as needed
4. Change terraform.tfvars as needed
5. Make sure your `~/.profile` contains AWS secrets and relavant TF_VAR secrets as env export vars to match the noted vars that need to be set here via `variables.tf` comments
6. run `terraform init` sets up backend s3 state via key path we set in `main.tf` and checks modules/code
7. run `terraform apply` to view infra to be created and enter no to stop or yes to actually create the cloud resouces

