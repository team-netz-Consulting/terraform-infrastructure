terraform {
 required_providers {
      alteon = {
            source = "Radware/alteon"
      }
      vault = {
          source = "hashicorp/vault"
     }
 }
}

provider "alteon" {
  username = var.alteon_username
  password = var.alteon_password
  Ip="10.2.0.213"
}
