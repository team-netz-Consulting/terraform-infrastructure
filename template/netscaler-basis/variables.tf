# Endpoint und Anmeldedaten koennen als TF_VAR_netscaler_endpoint,
# TF_VAR_netscaler_username und TF_VAR_netscaler_password gesetzt werden.
variable "netscaler_endpoint" {
  description = "NITRO-API-Endpunkt des NetScaler ADC, zum Beispiel https://192.0.2.1"
  type        = string
}

variable "netscaler_username" {
  type      = string
  sensitive = true
}

variable "netscaler_password" {
  type      = string
  sensitive = true
}

variable "netscaler_insecure_skip_verify" {
  description = "TLS-Pruefung nur bei nicht vertrauenswuerdigen ADC-Zertifikaten deaktivieren"
  type        = bool
  default     = false
}
