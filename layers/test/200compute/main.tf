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
    key     = "terraform.antonio.200compute.tfstate"
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

# SGs
## PublicWebAlbSg

resource "aws_security_group" "web_alb_sg" {
  name_prefix = "antonio-${var.environment}-alb-sg-"
  description = "Public Web Traffic"
  vpc_id      = data.terraform_remote_state.tf_000base.outputs.base_network_vpc_id

  tags = merge(
    local.tags,
    map("Name", "antonio-${var.environment}-alb-sg")
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "web_alb_sg_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_alb_sg.id
}

resource "aws_security_group_rule" "web_alb_sg_ingress_tcp_80_all" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_alb_sg.id
  description       = "Ingress from 0.0.0.0/0 (TCP:80)"
}

resource "aws_security_group_rule" "web_alb_sg_ingress_tcp_443_all" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_alb_sg.id
  description       = "Ingress from 0.0.0.0/0 (TCP:443)"
}

# PrivateWebEc2Sg
##

resource "aws_security_group" "web_ec2_sg" {
  name_prefix = "antonio-${var.environment}-web-sg-"
  description = "Access to Web instance(s)"
  vpc_id      = data.terraform_remote_state.tf_000base.outputs.base_network_vpc_id

  tags = merge(
    local.tags,
    map("Name", "antonio-${var.environment}-web-sg")
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "web_ec2_sg_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_ec2_sg.id
}

resource "aws_security_group_rule" "web_ec2_sg_ingress_tcp_80_web_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web_alb_sg.id
  security_group_id        = aws_security_group.web_ec2_sg.id
  description              = "Ingress from PublicWebAlbSg (TCP:80)"
}

resource "aws_security_group_rule" "web_ec2_sg_ingress_tcp_22_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion_ec2_sg.id
  security_group_id        = aws_security_group.web_ec2_sg.id
  description              = "Ingress from PublicBastionEc2Sg (TCP:22)"
}

# PrivateRdsSg
##

resource "aws_security_group_rule" "rds_sg_ingress_tcp_5432_web_ec2" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web_ec2_sg.id
  security_group_id        = data.terraform_remote_state.tf_100data.outputs.sg_rds_id
  description              = "Ingress from antonio-${var.environment}-web-sg (TCP:5432)"
}

# PublicBastionEc2Sg

resource "aws_security_group" "bastion_ec2_sg" {
  name_prefix = "antonio-${var.environment}-bastion-sg-"
  description = "Access to Admin Users"
  vpc_id      = data.terraform_remote_state.tf_000base.outputs.base_network_vpc_id

  tags = merge(
    local.tags,
    map("Name", "antonio-${var.environment}-bastion-sg")
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "bastion_ec2_sg_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion_ec2_sg.id
}

resource "aws_security_group_rule" "bastion_ec2_sg_ingress_tcp_22_1" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["119.9.63.38/32"]
  security_group_id = aws_security_group.bastion_ec2_sg.id
  description       = "Ingress from 119.9.63.38/32 (TCP:22)"
}

resource "aws_security_group_rule" "bastion_ec2_sg_ingress_tcp_22_2" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["54.255.132.126/32"]
  security_group_id = aws_security_group.bastion_ec2_sg.id
  description       = "Ingress from 54.255.132.126/32 (TCP:22)"
}

######## ACM Self Signed ########

resource "tls_private_key" "self" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_self_signed_cert" "self" {
  key_algorithm         = "RSA"
  private_key_pem       = tls_private_key.self.private_key_pem
  validity_period_hours = 2160

  subject {
    common_name         = "self.antonio.com"
    organization        = "Antonio"
    organizational_unit = "Partner Cloud"
  }

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "self" {
  private_key      = tls_private_key.self.private_key_pem
  certificate_body = tls_self_signed_cert.self.cert_pem
}

# ALB

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"

  name = "antonio-syd-${var.environment}-alb"

  load_balancer_type = "application"

  vpc_id          = data.terraform_remote_state.tf_000base.outputs.base_network_vpc_id
  subnets         = data.terraform_remote_state.tf_000base.outputs.base_network_public_subnets
  security_groups = [aws_security_group.web_alb_sg.id]

  target_groups = [
    {
      backend_port       = 80
      backend_protocol   = "HTTP"
      name               = "antonio-syd-${var.environment}-tg"
      stickiness_enabled = true
      health_check_path  = "/"
    }
  ]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = aws_acm_certificate.self.arn
      target_group_index = 0
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = "Test"
  }
}

resource "aws_route53_record" "zone_record_alias" {
  name    = module.alb.this_lb_dns_name
  type    = "A"
  zone_id = data.terraform_remote_state.tf_000base.outputs.internal_hosted_zone_id

  alias {
    evaluate_target_health = true
    name                   = module.alb.this_lb_dns_name
    zone_id                = module.alb.this_lb_zone_id
  }
}

# ECS Cluster

resource "aws_ecs_cluster" "ecs-cluster" {
  name = var.ecs_cluster_name

  tags = local.tags
}

resource "aws_iam_role" "ecs_role_task_assume" {
  name = "ecsfargate_task_assume"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs_task_assume_policy" {
  name = "ecsfargate_task_assume_policy"
  role = aws_iam_role.ecs_role_task_assume.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

# ECR

resource "aws_ecr_repository" "ecr_repo" {
  name = var.ecr_name
}

resource "aws_ecr_lifecycle_policy" "ecr_lifecycle_policy" {
  repository = aws_ecr_repository.ecr_repo.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire images older than 14 days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 14
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

resource "aws_ecr_repository_policy" "ecr_repo_policy" {
  repository = aws_ecr_repository.ecr_repo.name

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "new policy",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:DeleteRepository",
                "ecr:BatchDeleteImage",
                "ecr:SetRepositoryPolicy",
                "ecr:DeleteRepositoryPolicy"
            ]
        }
    ]
}
EOF
}
