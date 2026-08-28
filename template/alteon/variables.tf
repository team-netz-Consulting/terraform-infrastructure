# Die Anmeldedaten werden ueber TF_VAR_alteon_username und
# TF_VAR_alteon_password bereitgestellt.
variable "alteon_username" {
  type      = string
  sensitive = true
}

variable "alteon_password" {
  type      = string
  sensitive = true
}
