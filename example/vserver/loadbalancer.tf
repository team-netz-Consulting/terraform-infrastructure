# Datei        : loadbalancer.tf
# Dateiversion : 2026.10.12.1342

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

locals {
  backend_services = concat(
    [for name, service in var.cs_services : merge(service, {
      service_name = name
      service_key  = "cs:${name}"
      uses_cs      = true
      lb_vip       = "0.0.0.0"
    })],
    [for name, service in var.lb_services : merge(service, {
      service_name = name
      service_key  = "lb:${name}"
      uses_cs      = false
    })]
  )
  /*
   * Eine Konfiguration pro:
   *
   * Service + Portgruppe + Port
   *
   * Beispiel:
   * cs:artera1:portgroup001:10300
   */
  port_configs = merge([
    for service in local.backend_services : merge([
      for portgroup_name, portgroup in service.portgroups : {
        for port in portgroup.ports :
        "${service.service_key}:${portgroup_name}:${port}" => {
          service_name   = service.service_name
          portgroup_name = portgroup_name
          port           = port
          uses_cs        = service.uses_cs
          lb_vip         = service.lb_vip

          local_site  = service.local_site
          remote_site = service.remote_site

          local_members  = portgroup.local_members
          remote_members = portgroup.remote_members

          # null erbt die Service-Liste; [] deaktiviert explizite Bindings.
          monitors = portgroup.monitors != null ? portgroup.monitors : service.monitors

          /*
           * Der Remote-Teil wird nur erzeugt, wenn mindestens ein
           * Remote-Mitglied vorhanden ist.
           */
          has_remote = length(portgroup.remote_members) > 0

          local_servicegroup = format(
            "lsg_%s_%s_%s_%s_%s_tcp_%d",
            service.stage,
            service.environment,
            service.service_name,
            portgroup_name,
            service.local_site,
            port
          )

          remote_servicegroup = format(
            "lsg_%s_%s_%s_%s_%s_tcp_%d",
            service.stage,
            service.environment,
            service.service_name,
            portgroup_name,
            service.remote_site,
            port
          )

          local_lbvserver = format(
            "lvs_%s_%s_%s_%s_%s_tcp_%d",
            service.stage,
            service.environment,
            service.service_name,
            portgroup_name,
            service.local_site,
            port
          )

          remote_lbvserver = format(
            "lvs_%s_%s_%s_%s_%s_tcp_%d",
            service.stage,
            service.environment,
            service.service_name,
            portgroup_name,
            service.remote_site,
            port
          )

          cs_action = format(
            "csa_%s_%s_%s_%s_%s_tcp_%d",
            service.stage,
            service.environment,
            service.service_name,
            portgroup_name,
            service.local_site,
            port
          )

          cs_policy = format(
            "csp_%s_%s_%s_%s_%s_tcp_%d",
            service.stage,
            service.environment,
            service.service_name,
            portgroup_name,
            service.local_site,
            port
          )
        }
      }
    ]...)
  ]...)
  /*
   * Einzelne Bindings für alle lokalen Servicegroup-Mitglieder.
   *
   * Beispielschlüssel:
   * cs:artera1:portgroup001:10300:local:srv_jurzwiese2a93
   */
  local_member_bindings = merge([
    for port_key, config in local.port_configs : {
      for member in config.local_members :
      "${port_key}:local:${member.server_name}" => {
        port_key         = port_key
        service_name     = config.service_name
        portgroup_name   = config.portgroup_name
        servicegroupname = config.local_servicegroup
        server_name      = member.server_name
        server_ip        = member.server_ip
        port             = config.port
      }
    }
  ]...)

  /*
   * Einzelne Bindings für alle Remote-Servicegroup-Mitglieder.
   *
   * Bei remote_members = [] entsteht für diese Portgruppe kein Binding.
   */
  remote_member_bindings = merge([
    for port_key, config in local.remote_port_configs : {
      for member in config.remote_members :
      "${port_key}:remote:${member.server_name}" => {
        port_key         = port_key
        service_name     = config.service_name
        portgroup_name   = config.portgroup_name
        servicegroupname = config.remote_servicegroup
        server_name      = member.server_name
        server_ip        = member.server_ip
        port             = config.port
      }
    }
  ]...)

  /*
   * Nur Konfigurationen, die mindestens einen Remote-Member haben.
   *
   * Diese Map muss als for_each für folgende Remote-Ressourcen verwendet
   * werden:
   *
   * - citrixadc_servicegroup.remote
   * - citrixadc_lbvserver.remote
   * - citrixadc_lbvserver_servicegroup_binding.remote
   */
  remote_port_configs = {
    for port_key, config in local.port_configs :
    port_key => config
    if config.has_remote
  }
}
