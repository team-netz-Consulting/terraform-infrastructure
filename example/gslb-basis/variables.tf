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

variable "netscaler_insecure_skip_verify" {
  description = "TLS-Pruefung nur bei nicht vertrauenswuerdigen ADC-Zertifikaten deaktivieren"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# GSLB Location
# -----------------------------------------------------------------------------

variable "locations" {
  description = "Location-Eintraege mit Start-IP, End-IP und Location-Namen (preferredLocation). Die Map-Schluessel dienen als stabile Terraform-IDs."

  type                = map(object({
    ipfrom            = string
    ipto              = string
    preferredlocation = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for location in var.locations :
      can(cidrnetmask("${location.ipfrom}/32")) &&
      can(cidrnetmask("${location.ipto}/32")) &&
      try(trimspace(location.preferredlocation) != "", false)
    ])
    error_message = "Jede Location benoetigt gueltige IPv4-Adressen fuer ipfrom und ipto sowie einen nicht leeren Namen."
  }
}


variable "adns_service_ip" {
  description = "IP Adresse fuer den ADNS"
  type      = string
}

variable "gslb_site_local" {
  description = "Parameter der lokalen GSLB-Site"
  type = object({
    ip       = string
    name     = string
    password = string
  })
  sensitive = true
  nullable  = false

  validation {
    condition     = length(trimspace(var.gslb_site_local.password)) > 0
    error_message = "Das lokale GSLB-Site-Passwort darf nicht leer sein."
  }
}

variable "gslb_site_remote" {
  description = "Parameter der entfernten GSLB-Site"
  type = object({
    ip       = string
    name     = string
    password = string
  })
  sensitive = true
  nullable  = false

  validation {
    condition     = length(trimspace(var.gslb_site_remote.password)) > 0
    error_message = "Das entfernte GSLB-Site-Passwort darf nicht leer sein."
  }
}
