provider "aws" {
  access_key          = var.aws_access_key
  secret_key          = var.aws_secret_key
  region              = var.region
  version             = "~> 2.0"
  allowed_account_ids = ["${var.aws_account_id}"]
}

data "aws_caller_identity" "current" {}

locals {
  # Add additional tags in the below map
  tags = {
    Environment = "${var.environment}"
  }
}

resource "aws_s3_bucket" "state" {
  bucket        = "${data.aws_caller_identity.current.account_id}-build-state-bucket-antonio-ecs-fargate-v12"
  force_destroy = true

  tags = local.tags

  lifecycle_rule {
    id      = "Expire30"
    enabled = true

    noncurrent_version_expiration {
      days = 30
    }

    expiration {
      days = 30
    }
  }

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}
