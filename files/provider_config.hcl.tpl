terraform {
  required_version = ">= 1.0, < 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  # By default, the AWS provider will use whatever authentication mechanism is configured in your shell environment.
  # See the offical AWS provider documentation for details on how to configure AWS access for Terraform:
  #
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration
}
