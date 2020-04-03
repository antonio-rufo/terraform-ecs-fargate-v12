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
    key     = "terraform.antonio.100data.tfstate"
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

# RDS Security Groups
### PrivateRdsSg

resource "aws_security_group" "rds" {
  name_prefix = "antonio-${var.environment}-rds-sg-"
  description = "Access to RDS Database"
  vpc_id      = data.terraform_remote_state.tf_000base.outputs.base_network_vpc_id

  tags = merge(
    local.tags,
    map("Name", "antonio-${var.environment}-rds-sg")
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "rds_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds.id
}

# RDS Database

resource "random_string" "rds_password" {
  length  = 20
  lower   = true
  upper   = true
  number  = true
  special = false
}

resource "aws_ssm_parameter" "rds_password" {
  name  = "${lower(var.environment)}-rds-password"
  type  = "SecureString"
  value = random_string.rds_password.result

  lifecycle {
    ignore_changes = all
  }
}

# RDS Database

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 2.0"

  identifier = "bc-${lower(var.environment)}"

  engine            = "postgres"
  engine_version    = "11.6"
  instance_class    = "db.t3.small"
  allocated_storage = 5

  name     = "testdb"
  username = "testuser"
  password = random_string.rds_password.result
  port     = "5432"

  vpc_security_group_ids = [aws_security_group.rds.id]

  maintenance_window = "Sat:18:00-Sat:18:30"
  backup_window      = "02:00-03:00"

  tags = {
    Owner       = "user"
    Environment = "dev"
  }

  # DB subnet group
  subnet_ids = data.terraform_remote_state.tf_000base.outputs.base_network_data_subnets

  # DB parameter group
  family = "postgres11"

  # # DB option group
  major_engine_version = "11"

  # # Snapshot name upon DB deletion
  # final_snapshot_identifier = "demodb"

  # Database Deletion Protection
  deletion_protection = false

  skip_final_snapshot = true

  allow_major_version_upgrade = false
  storage_encrypted           = true
  multi_az                    = false

}

resource "aws_route53_record" "zone_record_alias" {

  name    = "${module.db.this_db_instance_name}.${data.terraform_remote_state.tf_000base.outputs.internal_hosted_name}"
  records = [module.db.this_db_instance_endpoint]
  ttl     = "300"
  type    = "CNAME"
  zone_id = data.terraform_remote_state.tf_000base.outputs.internal_hosted_zone_id
}
