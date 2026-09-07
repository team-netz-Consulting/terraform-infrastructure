terraform {
  required_providers {
    citrixadc = {
      source = "citrix/citrixadc"
    }
    vault = {
      source = "hashicorp/vault"
    }
  }
}

provider "citrixadc" {
  endpoint             = var.netscaler_endpoint
  username             = var.netscaler_username
  password             = var.netscaler_password
  insecure_skip_verify = var.netscaler_insecure_skip_verify
}
