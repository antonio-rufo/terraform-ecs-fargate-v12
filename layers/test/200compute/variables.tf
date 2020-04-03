# "aws" provider variables
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_account_id" {
  description = "The account ID you are building into."
  type        = string
}

variable "environment" {
  description = "The name of the environment, e.g. Production, Development, etc."
  type        = string
  default     = "Development"
}

variable "region" {
  description = "The AWS region the state should reside in."
  type        = string
}

variable "ecs_cluster_name" {
  description = "The environment we are building for."
  type        = string
}

variable "ecr_name" {
  description = "The name of the container repo (ECR) we'll be using"
  type        = string
}
