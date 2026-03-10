terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Local backend — this stack is the prerequisite for all others.
  # Keep terraform.tfstate safe (e.g. in a password manager or versioned separately).
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "ai-demo"
      ManagedBy = "terraform"
      Stack     = "bootstrap"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  prefix     = "ai-demo"
  account_id = data.aws_caller_identity.current.account_id
}
