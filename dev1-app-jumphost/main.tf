
provider "aws" {
  region = var.region
}

terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket      = "dev1-terra-envs"                 // change bucket for desired state locations
    key         = "dev1example/terraform.tfstate"   // change key path here for new env
    region      = "us-west-2"
    encrypt     = true
  }
}

# VPC and subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security group
data "aws_security_group" "default" {
  id = var.sg
}

resource "aws_ecr_repository" "my_repository" {
  name                 = local.ecr_repo
  image_tag_mutability = "MUTABLE"
}

resource "aws_db_instance" "mysql" {
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  allocated_storage      = 150
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.m5.large"      // "db.t2.micro"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_pw
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true               // set false for prod
  publicly_accessible    = false              // use bastion host via runner to access db
}

resource "aws_security_group" "rds_sg" {
  name        = "RDS MySQL Security Group"
  description = "MySQL Ports for specific IP"
  vpc_id      = var.vpc //data.aws_vpc.default.id
}

resource "aws_cloudwatch_log_group" "my_log_group" {
  name = "/ecs/${local.ecs_service_name}"
}

# Bastion ec2 server 
resource "aws_instance" "bastion" {
  ami                   = var.ami
  instance_type         = var.hardware
  key_name              = var.key_name
  
  security_groups       = [data.aws_security_group.default.name]
  iam_instance_profile  = aws_iam_instance_profile.bastion_instance_profile.name

  tags = {
    Name = "Bastion Host"
  }
}

resource "aws_iam_instance_profile" "bastion_instance_profile" {
  name = "BastionInstanceProfile"
  role = aws_iam_role.bastion_role.name
}

# Bastion Role and S3 Policy
resource "aws_iam_role" "bastion_role" {
  name = "BastionS3AccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_policy" "bastion_s3_access" {
  name        = "BastionS3AccessPolicy"
  description = "Allows S3 read access for the bastion host"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::prod-db-dump",
          "arn:aws:s3:::prod-db-dump/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bastion_admin_attachment" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role" "ecs_role" {
  name               = local.ecs_role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Attach IAM Policy to ECS Role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role                     = aws_iam_role.ecs_role.name
  policy_arn               = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "my_task" {
  family                   = local.ecs_task_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = "arn:aws:iam::754247443598:role/AssumeRoleAdministrator"

  volume {
    name      = local.efs_mnt_name
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.mnt_efs.id
    }
  }

  container_definitions    = jsonencode(
    [
      {
        "name" : local.ecs_container_name,
        "image" : "${aws_ecr_repository.my_repository.repository_url}:${var.docker_tag}", // ecr registry

        "mountPoints": [
          {
            "sourceVolume": local.efs_mnt_name,
            "containerPath": "/var/www/html"
          }
        ],

        "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
            "awslogs-group": "${aws_cloudwatch_log_group.my_log_group.name}",
            "awslogs-region": var.region,
            "awslogs-stream-prefix": "ecs"
          }
        },

        "essential" : true,
        "portMappings" : [
          {
            "containerPort" : local.port80,
            "hostPort" : local.port80
          }
        ],

        # via application.php local still uses .env 
        # "environment" : [
        #   {
        #     "name" : "DB_HOST",
        #     "value" : aws_db_instance.mysql.endpoint
        #   },
        #   {
        #     "name" : "DB_USER",
        #     "value" : var.db_username
        #   },
        #   {
        #     "name" : "DB_PASSWORD",
        #     "value" : var.db_pw
        #   },
        #   {
        #     "name" : "DB_NAME",
        #     "value" : var.db_name
        #   },
        # ]
      }
    ]
  )
}

resource "aws_ecs_cluster" "my_cluster" {
  name = local.ecs_cluster_name
}

# efs filesystem
resource "aws_efs_file_system" "mnt_efs" {
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
}

resource "aws_efs_mount_target" "mnt_efs_mount" {
  count              = length(data.aws_subnets.default.ids)
  file_system_id     = aws_efs_file_system.mnt_efs.id
  subnet_id          = data.aws_subnets.default.ids[count.index]
  security_groups    = [var.sg]
}

# network
resource "aws_alb" "my_alb" {
  name               = local.ecs_alb_name
  subnets            = data.aws_subnets.default.ids
  security_groups    = [var.sg] 
}

resource "aws_alb_target_group" "my_alb_target_group" {
  name               = local.ecs_alb_tg_name
  port               = local.port80
  protocol           = "HTTP"
  vpc_id             = data.aws_vpc.default.id
  target_type        = "ip"
}

resource "aws_alb_listener" "my_alb_listener" {
  load_balancer_arn  = aws_alb.my_alb.arn
  port               = local.port80
  protocol           = "HTTP" #change to HTTPS for ssl termination 
  # ssl_policy         = "ELBSecurityPolicy-2016-08"
  # certificate_arn    = local.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.my_alb_target_group.arn
  }
}

resource "aws_ecs_service" "my_service" {
  name               = local.ecs_service_name
  cluster            = aws_ecs_cluster.my_cluster.id
  task_definition    = aws_ecs_task_definition.my_task.arn
  desired_count      = 2
  launch_type        = "FARGATE"

  network_configuration {
    assign_public_ip = true
    subnets          = data.aws_subnets.default.ids
    security_groups  = [var.sg] //[data.aws_security_group.default.id]
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.my_alb_target_group.arn
    container_name   = local.ecs_container_name
    container_port   = local.port80             // using fargate, but if not, could cause port conflicts in ecs
  }

  deployment_minimum_healthy_percent = 100 // for testing omit; for always one container present enable
  depends_on         = [aws_alb_listener.my_alb_listener]
}

# resource "aws_route53_record" "alb" { // had to manually create alias A record for root domain to point to ALB resource
#   zone_id                  = var.zone
#   name                     = var.domain
#   type                     = "A"

#   alias {
#     name                   = "my-alb-360061898.us-west-2.elb.amazonaws.com"
#     zone_id                = var.zone
#     evaluate_target_health = false
#   }
# }

resource "aws_security_group_rule" "allow_https_from_anywhere" {
  security_group_id  = var.sg //data.aws_security_group.default.id
  type               = "ingress"
  from_port          = 443
  to_port            = 443
  protocol           = "tcp"
  cidr_blocks        = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_http_to_ecs" {
  security_group_id  = var.sg //data.aws_security_group.default.id
  type               = "ingress"
  from_port          = 80
  to_port            = 80
  protocol           = "tcp"
  cidr_blocks        = ["0.0.0.0/0"]
}

# Updating RDS Security Group to allow connections from Bastion Host
resource "aws_security_group_rule" "allow_mysql_from_bastion" {
  type        = "ingress"
  from_port   = 3306
  to_port     = 3306
  protocol    = "tcp"

  source_security_group_id = var.sg //data.aws_security_group.default.id
  security_group_id = aws_security_group.rds_sg.id
}

# NFS file system for efs mount
resource "aws_security_group_rule" "allow_ecs_to_efs" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = var.sg //data.aws_security_group.default.id
  security_group_id        = var.sg //data.aws_security_group.default.id
}

#local vars
locals {
  port80             = 80                       // for container SSL termination/alb target group
  port443            = 443                      // for ALB listener via SSL

  ecs_service_name   = "my_service"             // i.e. "ecs_service27"
  ecs_container_name = "my_container"           // i.e. "ecs_container68"
  ecs_alb_name       = "my-alb"                 // i.e. "ecs_alb_45"
  ecs_alb_tg_name    = "my-alb-target-group"    // i.e. "ecs_alb_tg_45"
  ecs_cluster_name   = "my_cluster"             // i.e. "ecs_cluster_example"
  ecr_repo           = "my_app_images"          // i.e. "example_images_repo"
  ecs_task_family    = "my_family"              // i.e. "example_family4"
  efs_mnt_name       = "my_efs"
  ecs_role_name      = "my_ecs_role"

  certificate_arn    = "arn:aws:acm:us-west-2:77777777777:certificate/ghfghfh-jhkh-ffgg-ghfghf-fsdgsdgsd"
}
