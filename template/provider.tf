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

variable "username" {
  type      = string
  sensitive = true
}

variable "password" {
  type      = string
  sensitive = true
}

provider "alteon" {
  username = var.username
  password = var.password
  Ip="10.2.0.213"
}
