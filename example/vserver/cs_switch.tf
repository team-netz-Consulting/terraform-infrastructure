# Datei        : cs_switch.tf
# Dateiversion : 2026.10.12.1342

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

locals {
  # Nur Portkonfigurationen für Content Switching.
  cs_port_configs = {
    for port_key, config in local.port_configs :
    port_key => config if config.uses_cs
  }

  /*
   * Ein Content-Switch-vServer pro Service.
   */
  cs_vservers = {
    for service_name, service in var.cs_services :
    service_name => {
      service_name = service_name
      name = format(
        "csv_%s_%s_%s_%s_tcp_any",
        service.stage,
        service.environment,
        service_name,
        service.local_site
      )
      ipv46             = service.cs_vip
      local_site        = service.local_site
      default_lbvserver = var.default_lb_vserver
    }
  }

  /*
   * Stabile Policy-Prioritäten pro Service.
   *
   * Die Schlüssel werden sortiert, damit sich Prioritäten nicht allein
   * aufgrund der Reihenfolge in terraform.tfvars ändern.
   *
   * Prioritäten:
   * 100, 110, 120, 130, ...
   */
  policy_priorities = {
    for service_name, service in var.cs_services :
    service_name => {
      for index, port_key in sort([
        for candidate_key, config in local.cs_port_configs :
        candidate_key
        if config.service_name == service_name
      ]) :
      port_key => 100 + (index * 10)
    }
  }

  /*
   * Fertige CS-Policy-Bindings.
   */
  cs_policy_bindings = {
    for port_key, config in local.cs_port_configs :
    port_key => {
      port_key     = port_key
      service_name = config.service_name
      csvserver    = local.cs_vservers[config.service_name].name
      policyname   = config.cs_policy
      priority = local.policy_priorities[
        config.service_name
      ][port_key]
    }
  }
}
