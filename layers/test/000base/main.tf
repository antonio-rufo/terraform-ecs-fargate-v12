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
    key     = "terraform.antonio.000base.tfstate"
    region  = "ap-southeast-2"
    encrypt = "true"
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

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "172.21.0.0/16"

  azs              = ["ap-southeast-2a", "ap-southeast-2b"]
  private_subnets  = ["172.21.0.0/21", "172.21.8.0/21"]
  public_subnets   = ["172.21.168.0/22", "172.21.172.0/22"]
  database_subnets = ["172.21.16.0/21", "172.21.24.0/21"]

  enable_nat_gateway = true
  tags               = local.tags
  # tags = {
  #   Terraform   = "true"
  #   Environment = "dev"
  # }
}

resource "aws_route53_zone" "internal_zone" {
  comment = "Hosted zone for ${var.environment}"
  name    = "${lower(var.environment)}.local"
  tags    = local.tags

  vpc {
    vpc_id = module.vpc.vpc_id
  }
}
