
terraform {
  required_version = ">= 1.0"

  required_providers {
    autocloud = {
      source  = "autoclouddev/autocloud"
      version = "~> 0.13.0"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
