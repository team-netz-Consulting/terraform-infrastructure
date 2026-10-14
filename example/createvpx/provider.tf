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
  alias                = "sdx1"
  host                 = var.netscaler_host
  username             = var.netscaler_username
  password             = var.netscaler_password
  ssl_verify           = !var.netscaler_insecure_skip_verify
}

# Ohne zweite SDX wird dieser ungenutzte Provider mit SDX-1-Werten konfiguriert.
provider "netscalersdx" {
  alias      = "sdx2"
  host       = var.sdx2 != null ? var.sdx2.host : var.netscaler_host
  username   = var.sdx2 != null ? var.sdx2.username : var.netscaler_username
  password   = var.sdx2 != null ? var.sdx2.password : var.netscaler_password
  ssl_verify = var.sdx2 != null ? !var.sdx2.insecure_skip_verify : !var.netscaler_insecure_skip_verify
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
