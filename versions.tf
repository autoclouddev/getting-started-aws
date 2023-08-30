
terraform {
  required_version = ">= 1.0, < 1.6.0"

  required_providers {
    autocloud = {
      source  = "autoclouddev/autocloud"
      version = "0.13.0"
    }
  }
}
