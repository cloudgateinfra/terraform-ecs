
# bastion
key_name        = "jumphost"
hardware        = "a1.medium"
ami             = "ami-0d43d68939ee00e60"          // ubuntu 20.04

# image
docker_image    = "gcewebmkt/devops-docker-images"
docker_tag      = "latest"                         // ecr aws registry // dockerhub var >> "wpbase_v1" 

# ecs fargate
task_cpu        = 1024
task_memory     = 3072

# wp required
db_name         = "dev_test"
wp_home         = "wmkt-gcu-www-dev.gce-labs.com"
wp_siteurl      = "wmkt-gcu-www-dev.gce-labs.com"

# aws
sg              = "sg-9f6ba8c5"                    // default aws vpc security group for wmkt-gcu-www-dev.gce-labs.com
vpc             = "vpc-43ca503b"                   // default vpc :warning there is another default vpc for some reason
domain          = "wmkt-gcu-www-dev.gce-labs.com"     
zone            = "Z1H1FL5HABSF5"         
