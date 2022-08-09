terraform {
  cloud {
    organization = "keinuma"
    workspaces {
      name = "sample-workspace"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "ap-northeast-1"
}

module "server" {
    source = "./server"

    product_name = var.product_name
    environment  = var.environment
}
