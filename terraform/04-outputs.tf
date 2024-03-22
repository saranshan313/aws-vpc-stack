output "ecs_vpc_id" {
  description = "Id of the VPC"
  value       = try(aws_vpc.ecs_vpc.id, null)
}

output "ecs_public_subnets" {
  description = "Id of the public subnets"
  value       = try({ for k, v in aws_subnet.ecs_public_subnets : k => v.id }, null)
}

output "ecs_application_subnets" {
  description = "Id of the application subnets"
  value       = try({ for k, v in aws_subnet.ecs_application_subnets : k => v.id }, null)
}

output "ecs_database_subnets" {
  description = "Id of the database subnets"
  value       = try({ for k, v in aws_subnet.ecs_database_subnets : k => v.id }, null)
}
