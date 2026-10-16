# Datei        : variables.tf
# Dateiversion : 2026.10.12.1342

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

variable "netprofile_name" {
  description = "Bereits vorhandenes NetProfile für die Servicegroups"
  type        = string
  default     = "netprf_servicenetz_snip"
}

variable "netprofile_srcip" {
  type = string
}

variable "dummy_service_ip" {
  description = "Interne Service-IP fuer den immer aktiven Dummy-Service"
  type        = string
  default     = "1.2.3.4"
}

variable "default_lb_vserver" {
  description = "Default-LB-vServer des Content Switches"
  type        = string
  default     = "lvs_dummy_reset"
}

# -----------------------------------------------------------------------------
# Save-Konfiguration
# -----------------------------------------------------------------------------

variable "nssave_timestamp" {
  description = "Manuell gepflegter Zeitstempel zum Auslösen des Speicherns der NetScaler-Konfiguration."
  type        = string
}

 