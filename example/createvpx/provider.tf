# Datei        : provider.tf
# Dateiversion : 2026.10.12.1342

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    netscalersdx = {
      source = "netscaler/netscalersdx"
    }
  }
}

provider "netscalersdx" {
  
  host                 = var.netscaler_host
  username             = var.netscaler_username
  password             = var.netscaler_password
  ssl_verify           = false 
}
