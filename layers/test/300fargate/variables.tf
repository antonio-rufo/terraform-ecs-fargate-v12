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

variable "image_url" {
  description = "Tagged container image URL"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS Service name"
  type        = string
}

variable "memory" {
  description = "Container memory allocation to be used"
  type        = string
}

variable "container_port" {
  description = "Container port to be used"
  type        = string
}

variable "cpu" {
  description = "Container CPU allocation to be used"
  type        = string
}

variable "desired_task_number" {
  description = "Number of tasks"
  type        = string
}
