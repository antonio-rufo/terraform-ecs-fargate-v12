output "sg_rds_id" {
  description = "ID of the RDS security group."
  value       = "${aws_security_group.rds.id}"
}

output "rds_endpoint" {
  description = "RDS Database Endpoint"
  value       = "${module.db.this_db_instance_endpoint}"
}
