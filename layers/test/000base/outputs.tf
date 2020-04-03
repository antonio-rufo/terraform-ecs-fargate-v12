output "base_network_data_subnets" {
  description = "The data subnets of the Base Network."
  value       = "${module.vpc.database_subnets}"
}

output "base_network_nat_gateway_eip" {
  description = "The NAT gateway EIP(s) of the Base Network."
  value       = "${module.vpc.nat_public_ips}"
}

output "base_network_private_route_tables" {
  description = "The private route tables of the Base Network."
  value       = "${module.vpc.private_route_table_ids}"
}

output "base_network_private_subnets" {
  description = "The private subnets of the Base Network."
  value       = "${module.vpc.private_subnets}"
}

output "base_network_public_route_tables" {
  description = "The public route tables of the Base Network."
  value       = "${module.vpc.public_route_table_ids}"
}

output "base_network_public_subnets" {
  description = "The public subnets of the Base Network."
  value       = "${module.vpc.public_subnets}"
}

output "base_network_vpc_id" {
  description = "The VPC ID of the Base Network."
  value       = "${module.vpc.vpc_id}"
}

output "internal_hosted_name" {
  description = "Hosted Zone Name"
  value       = aws_route53_zone.internal_zone.name
}

output "internal_hosted_zone_id" {
  description = "Hosted Zone ID"
  value       = aws_route53_zone.internal_zone.id
}
