terraform {
  backend "s3" {
    profile = "default"
    bucket  = "dscso-tfstate-insa"
    key     = "task1/terraform.tfstate"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  # AWS_PROFILE
#  profile = "default"
  region = var.region
}