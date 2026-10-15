# Datei        : servers.tf
# Dateiversion : 2026.10.12.1342

locals {
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
}
