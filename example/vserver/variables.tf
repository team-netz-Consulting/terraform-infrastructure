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

variable "cs_services" {
  description = "Service-, Portgruppen- und Backend-Konfiguration"
  default     = {}

  type = map(object({
    stage       = string
    environment = string
    cs_vip      = string
    local_site  = string
    remote_site = string
    monitors    = optional(set(string), [])

    portgroups = map(object({
      ports    = set(number)
      monitors = optional(set(string))

      local_members = list(object({
        server_name = string
        server_ip   = string
      }))

      remote_members = list(object({
        server_name = string
        server_ip   = string
      }))
    }))
  }))

  validation {
    condition = alltrue(flatten([
      for service in values(var.cs_services) : [
        for portgroup in values(service.portgroups) :
        length(portgroup.local_members) > 0
      ]
    ]))

    error_message = "Jede Portgruppe benötigt mindestens ein lokales Servicegroup-Mitglied."
  }

  validation {
    condition = alltrue(flatten([
      for service in values(var.cs_services) : [
        for portgroup in values(service.portgroups) :
        length(portgroup.local_members) ==
        length(toset([
          for member in portgroup.local_members :
          member.server_name
        ]))
      ]
    ]))

    error_message = "Ein lokaler Server darf innerhalb einer Portgruppe nicht doppelt vorkommen."
  }

  validation {
    condition = alltrue(flatten([
      for service in values(var.cs_services) : [
        for portgroup in values(service.portgroups) :
        length(portgroup.remote_members) ==
        length(toset([
          for member in portgroup.remote_members :
          member.server_name
        ]))
      ]
    ]))

    error_message = "Ein Remote-Server darf innerhalb einer Portgruppe nicht doppelt vorkommen."
  }
}

variable "lb_services" {
  description = "Direkte LB-Services ohne Content Switch; lb_vip wird pro Port am lokalen LB-vServer verwendet"

  default = {}

  type = map(object({
    stage       = string
    environment = string
    lb_vip      = string
    local_site  = string
    remote_site = string
    monitors    = optional(set(string), [])

    portgroups = map(object({
      ports    = set(number)
      monitors = optional(set(string))

      local_members = list(object({
        server_name = string
        server_ip   = string
      }))

      remote_members = list(object({
        server_name = string
        server_ip   = string
      }))
    }))
  }))

  validation {
    condition = alltrue(flatten([
      for service in values(var.lb_services) : [
        for portgroup in values(service.portgroups) :
        length(portgroup.local_members) > 0
      ]
    ]))

    error_message = "Jede Portgruppe benötigt mindestens ein lokales Servicegroup-Mitglied."
  }

  validation {
    condition = alltrue(flatten([
      for service in values(var.lb_services) : [
        for portgroup in values(service.portgroups) :
        length(portgroup.local_members) ==
        length(toset([
          for member in portgroup.local_members :
          member.server_name
        ]))
      ]
    ]))

    error_message = "Ein lokaler Server darf innerhalb einer Portgruppe nicht doppelt vorkommen."
  }

  validation {
    condition = alltrue(flatten([
      for service in values(var.lb_services) : [
        for portgroup in values(service.portgroups) :
        length(portgroup.remote_members) ==
        length(toset([
          for member in portgroup.remote_members :
          member.server_name
        ]))
      ]
    ]))

    error_message = "Ein Remote-Server darf innerhalb einer Portgruppe nicht doppelt vorkommen."
  }
}

variable "monitors" {
  description = "Zentrale Monitor-Definitionen; der Map-Schlüssel ist der Monitorname auf dem ADC. HTTPS: type = HTTP und secure = YES."
  default     = {}

  type = map(object({
    type           = string
    interval       = optional(number)
    resptimeout    = optional(number)
    retries        = optional(number)
    destip         = optional(string)
    destport       = optional(number)
    secure         = optional(string)
    httprequest    = optional(string)
    respcode       = optional(list(string))
    customheaders  = optional(string)
    send           = optional(string)
    recv           = optional(string)
    lrtm           = optional(string)
    successretries = optional(number)
    downtime       = optional(number)
    query          = optional(string)
    querytype      = optional(string)
    scriptname     = optional(string)
    dispatcherip   = optional(string)
    dispatcherport = optional(number)
    password       = optional(string)
    basedn         = optional(string)
    binddn         = optional(string)
    filter         = optional(string)
  }))
}
