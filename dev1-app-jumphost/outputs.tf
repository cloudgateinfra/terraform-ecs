output "rds_endpoint" {
  value       = aws_db_instance.mysql.endpoint
}

output "bastion_host_ip" {
  value       = aws_instance.bastion.public_ip
}

output "alb_dns_name" {
  value       = aws_alb.my_alb.dns_name
}

output "default_vpc_id" {
  value = data.aws_vpc.default.id
}

output "default_vpc_arn" {
  value = data.aws_vpc.default.arn
}
