output "network_vpc_id" {
  description = "Id of the VPC"
  value       = try(aws_vpc.network_vpc.id, null)
}

output "network_vpc_cidr" {
  description = "cidr of the VPC"
  value       = try(local.settings.vpc_cidr_range, null)
}

output "network_public_subnets" {
  description = "Id of the public subnets"
  value       = try({ for k, v in aws_subnet.network_public_subnets : k => v.id }, null)
}

output "network_application_subnets" {
  description = "Id of the application subnets"
  value       = try({ for k, v in aws_subnet.network_application_subnets : k => v.id }, null)
}

output "network_database_subnets" {
  description = "Id of the database subnets"
  value       = try({ for k, v in aws_subnet.network_database_subnets : k => v.id }, null)
}
