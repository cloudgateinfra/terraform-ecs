# all set in terraform.tfvars otherwise noted as local tfvar in .profile

variable "region" {
  default     = "us-west-2"
}

variable "vpc" {
}

variable "key_name" {
  description = "bastion ssh key"
  type        = string
}

variable "ami" {
  type        = string
}

variable "hardware" {
  type        = string
}

variable "docker_image" {
  type        = string
}

variable "docker_tag" {
  type        = string
}

# set in .profile as local tfvar
variable "docker_username" {
  type        = string
}

# set in .profile as local tfvar
variable "docker_password" {
  type        = string
  sensitive   = true
}

# set in .profile as local tfvar
variable "db_username" {
  type        = string
}

# set in .profile as local tfvar
variable "db_pw" {
  description = "db password"
  sensitive   = true
}

variable "db_name" {
  type        = string
}

variable "sg" {
  description = "AWS Security Group"
}

variable "domain" {
  description = "Domain Name"
}

variable "zone" {
  description = "AWS Zone"
}

variable "task_cpu" {
  description = "CPU to allocate to the ECS task"
  type        = string
}

variable "task_memory" {
  description = "memory to allocate to the ECS task"
  type        = string
}

# set in .profile as local tfvar
variable "auth_key" {
  type        = string
}

# set in .profile as local tfvar
variable "secure_auth_key" {
  type        = string
}

# set in .profile as local tfvar
variable "logged_in_key" {
  type        = string
}

# set in .profile as local tfvar
variable "nonce_key" {
  type        = string
}

# set in .profile as local tfvar
variable "auth_salt" {
  type        = string
}

# set in .profile as local tfvar
variable "secure_auth_salt" {
  type        = string
}

# set in .profile as local tfvar
variable "logged_in_salt" {
  type        = string
}

# set in .profile as local tfvar
variable "nonce_salt" {
  type        = string
}

variable "wp_home" {
  type        = string
}

variable "wp_siteurl" {
  type        = string
}

