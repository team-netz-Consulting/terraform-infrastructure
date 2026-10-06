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
   * Alle lokalen und Remote-Mitglieder aus allen Services und Portgruppen.
   *
   * Die Liste wird verwendet, um:
   * - Serverobjekte zu erzeugen,
   * - mehrfach verwendete Server zu deduplizieren,
   * - unterschiedliche IP-Adressen für denselben Namen zu erkennen.
   */
  all_members = flatten([
    for service in local.backend_services : flatten([
      for portgroup_name, portgroup in service.portgroups : concat(
        [
          for member in portgroup.local_members : {
            service_name = service.service_name
            portgroup    = portgroup_name
            location     = "local"
            site         = service.local_site
            server_name  = member.server_name
            server_ip    = member.server_ip
          }
        ],
        [
          for member in portgroup.remote_members : {
            service_name = service.service_name
            portgroup    = portgroup_name
            location     = "remote"
            site         = service.remote_site
            server_name  = member.server_name
            server_ip    = member.server_ip
          }
        ]
      )
    ])
  ])

  /*
   * Gruppierung nach Servername.
   *
   * Ein Server kann beispielsweise in mehreren Portgruppen verwendet werden,
   * darf als NetScaler-Serverobjekt aber nur einmal angelegt werden.
   */
  server_groups = {
    for member in local.all_members :
    member.server_name => member...
  }

  /*
   * Deduplizierte Serverobjekte für citrixadc_server.
   */
  servers = {
    for server_name, members in local.server_groups :
    server_name => {
      name = server_name
      ip   = members[0].server_ip
    }
  }

  /*
   * Ermittlung von Servernamen, die mit unterschiedlichen IP-Adressen
   * konfiguriert wurden.
   *
   * Diese Map kann in main.tf mit einem check-Block validiert werden.
   */
  server_ip_conflicts = {
    for server_name, members in local.server_groups :
    server_name => distinct([
      for member in members :
      member.server_ip
    ])
    if length(distinct([
      for member in members :
      member.server_ip
    ])) > 1
  }

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
   * Nur Konfigurationen, die mindestens einen Remote-Member haben.
   *
   * Diese Map muss als for_each für folgende Remote-Ressourcen verwendet
   * werden:
   *
   * - citrixadc_servicegroup.remote
   * - citrixadc_lbvserver.remote
   * - citrixadc_lbvserver_servicegroup_binding.remote
   */
  cs_port_configs = {
    for port_key, config in local.port_configs :
    port_key => config if config.uses_cs
  }

  remote_port_configs = {
    for port_key, config in local.port_configs :
    port_key => config
    if config.has_remote
  }

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

  # Ein Binding pro Servicegroup und Monitor, unabhängig von der Listenreihenfolge.
  local_monitor_bindings = merge([
    for port_key, config in local.port_configs : {
      for monitor in config.monitors :
      jsonencode([port_key, monitor]) => {
        port_key     = port_key
        monitor_name = monitor
      }
    }
  ]...)

  remote_monitor_bindings = merge([
    for port_key, config in local.remote_port_configs : {
      for monitor in config.monitors :
      jsonencode([port_key, monitor]) => {
        port_key     = port_key
        monitor_name = monitor
      }
    }
  ]...)

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
