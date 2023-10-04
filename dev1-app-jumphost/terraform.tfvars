
# bastion
key_name        = "jumphost"
hardware        = "a1.medium"
ami             = "ami-0d43d68939ee00e60"          // ubuntu 20.04

# image
docker_image    = "docker-images"
docker_tag      = "latest"                         // ecr aws registry // dockerhub var >> "wpbase_v1" 

# ecs fargate
task_cpu        = 1024
task_memory     = 3072

# app required
db_name          = "dev_test"
app_home         = "example.com"
app_siteurl      = "example2.com"

# aws
sg              = "sg-9asdffsf5"                   
vpc             = "vpc-43dafsb"                   
domain          = "example.domain.com"     
zone            = "Z1Hasdfs5"         
