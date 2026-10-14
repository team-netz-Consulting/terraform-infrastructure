# Datei        : provider.tf
# Dateiversion : 2026.10.12.1342

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    #https://releases.hashicorp.com/terraform-provider-null/3.2.4/
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    citrixadc = {
      source = "citrix/citrixadc"
    }
    netscalersdx = {
      source = "netscaler/netscalersdx"
    }
  }
}


provider "netscalersdx" {
  host                 = var.sdx1.host
  username             = var.sdx1.username != null ? var.sdx1.username : var.netscaler_username
  password             = var.sdx1.password != null ? var.sdx1.password : var.netscaler_password
  ssl_verify           = false
}

# Ohne zweite SDX wird dieser ungenutzte Provider mit SDX-1-Werten konfiguriert.
provider "netscalersdx" {
  alias      = "sdx2"
  host       = var.sdx2 != null ? var.sdx2.host : var.sdx1.host
  username   = var.sdx2 != null ? (var.sdx2.username != null ? var.sdx2.username : var.netscaler_username) : (var.sdx1.username != null ? var.sdx1.username : var.netscaler_username)
  password   = var.sdx2 != null ? (var.sdx2.password != null ? var.sdx2.password : var.netscaler_password) : (var.sdx1.password != null ? var.sdx1.password : var.netscaler_password)
  ssl_verify = false
}

# Die ADC-Provider verbinden sich direkt mit den VPX, nicht mit der SDX.
provider "citrixadc" {
  alias                = "ha_node1"
  endpoint             = "https://${local.ha_node1_ip}"
  username             = var.adc_username
  password             = var.adc_password
  insecure_skip_verify = var.adc_insecure_skip_verify
}

provider "citrixadc" {
  alias                = "ha_node2"
  endpoint             = "https://${local.ha_node2_ip}"
  username             = var.adc_username
  password             = var.adc_password
  insecure_skip_verify = var.adc_insecure_skip_verify
}
