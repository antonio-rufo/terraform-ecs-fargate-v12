provider "aws" {
  access_key          = var.aws_access_key
  secret_key          = var.aws_secret_key
  region              = var.region
  version             = "~> 2.17"
  allowed_account_ids = ["${var.aws_account_id}"]
}

provider "random" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}

provider "tls" {
  version = "~> 2.1.1"
}

terraform {
  backend "s3" {
    bucket  = "130541009828-build-state-bucket-antonio-ecs-fargate-v12"
    key     = "terraform.antonio.300fargate.tfstate"
    region  = "ap-southeast-2"
    encrypt = "true"
  }
}

data "terraform_remote_state" "tf_000base" {
  backend = "s3"
  config = {
    bucket = "130541009828-build-state-bucket-antonio-ecs-fargate-v12"
    key    = "terraform.antonio.000base.tfstate"
    region = "ap-southeast-2"
  }
}

data "terraform_remote_state" "tf_100data" {
  backend = "s3"
  config = {
    bucket = "130541009828-build-state-bucket-antonio-ecs-fargate-v12"
    key    = "terraform.antonio.100data.tfstate"
    region = "ap-southeast-2"
  }
}

data "terraform_remote_state" "tf_200compute" {
  backend = "s3"
  config = {
    bucket = "130541009828-build-state-bucket-antonio-ecs-fargate-v12"
    key    = "terraform.antonio.200compute.tfstate"
    region = "ap-southeast-2"
  }
}


# data "aws_availability_zone" "current" {}

data "terraform_remote_state" "main_state" {
  backend = "local"
  config = {
    path = "../../_main/terraform.tfstate"
  }
}

locals {

  tags = {
    Environment     = var.environment
    ServiceProvider = "Antonio-Test"
  }
}

# ECS FARGATE

data "template_file" "ecs_task_definition_template" {
  template = "${file("task_definition.json")}"

  vars = {
    task_definition_name = var.ecs_service_name
    ecs_service_name     = var.ecs_service_name
    image_url            = var.image_url
    memory               = var.memory
    container_port       = var.container_port
    region               = var.region
  }
}

resource "aws_ecs_task_definition" "antonio-task-definition" {
  container_definitions    = data.template_file.ecs_task_definition_template.rendered
  family                   = var.ecs_service_name
  cpu                      = var.cpu
  memory                   = var.memory
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.fargate_iam_role.arn
  task_role_arn            = aws_iam_role.fargate_iam_role.arn
}

resource "aws_iam_role" "fargate_iam_role" {
  name               = "${var.ecs_service_name}-IAM-Role"
  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
  {
    "Effect": "Allow",
    "Principal": {
      "Service": ["ecs.amazonaws.com", "ecs-tasks.amazonaws.com"]
    },
    "Action": "sts:AssumeRole"
  }
  ]
}
EOF
}

resource "aws_iam_role_policy" "fargate_iam_role_policy" {
  name = "${var.ecs_service_name}-IAM-Role-Policy"
  role = aws_iam_role.fargate_iam_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:*",
        "ecr:*",
        "logs:*",
        "cloudwatch:*",
        "elasticloadbalancing:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_ecs_service" "ecs_service" {
  name            = var.ecs_service_name
  task_definition = aws_ecs_task_definition.antonio-task-definition.arn
  desired_count   = var.desired_task_number
  cluster         = data.terraform_remote_state.tf_200compute.outputs.ecs_cluster_id
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.terraform_remote_state.tf_000base.outputs.base_network_private_subnets
    security_groups  = [data.terraform_remote_state.tf_200compute.outputs.web_ec2_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    container_name   = var.ecs_service_name
    container_port   = var.container_port
    target_group_arn = data.terraform_remote_state.tf_200compute.outputs.target_group_arn
  }
}

resource "aws_cloudwatch_log_group" "antonio_log_group" {
  name = "/ecs/antonio-nginx-LogGroup"
}
