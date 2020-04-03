output "target_group_arn" {
  description = "The Target Group ARN for the ALB"
  value       = "${module.alb.target_group_arns[0]}"
}

output "ecs_cluster_id" {
  description = "The ID of the cluster"
  value       = "${aws_ecs_cluster.ecs-cluster.id}"
}

output "ecs_cluster_arn" {
  description = "The ARN of the cluster"
  value       = "${aws_ecs_cluster.ecs-cluster.arn}"
}

output "web_ec2_sg_id" {
  description = "The ARN of the cluster"
  value       = "${aws_security_group.web_ec2_sg.id}"
}

output "ecr_repository_name" {
  value       = "${element(coalescelist(aws_ecr_repository.ecr_repo.*.name, list("")), 0)}"
  description = "Name of the ECR repository"
}

output "ecr_repository_registry_id" {
  value       = "${element(coalescelist(aws_ecr_repository.ecr_repo.*.registry_id, list("")), 0)}"
  description = "Name of the ECR repository"
}

output "ecr_repository_registry_url" {
  value       = "${element(coalescelist(aws_ecr_repository.ecr_repo.*.repository_url, list("")), 0)}"
  description = "URL of the ECR repository"
}
