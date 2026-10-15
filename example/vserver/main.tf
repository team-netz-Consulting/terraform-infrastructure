# Datei        : main.tf
# Dateiversion : 2026.10.12.1342

/*
###############################################################################
# Datei      : main.tf
# Zweck      : Definition der NetScaler-ADC-Ressourcen
#
# NetScaler-Ressourcen werden mit dem Praefix "citrixadc_" angelegt.
# Templateversion: 2026.09.03.1440
###############################################################################
*/

# -----------------------------------------------------------------------------
# Erstelle dummy LB
# -----------------------------------------------------------------------------

resource "citrixadc_service" "dummy_always_up" {
  name          = "svc_dummy_always_up"
  ip            = var.dummy_service_ip
  servicetype   = "TCP"
  port          = 1
  healthmonitor = "NO"
}

resource "citrixadc_lbvserver" "dummy_reset" {
  name            = "lvs_dummy_reset"
  servicetype     = "TCP"
  ipv46           = "0.0.0.0"
  port            = 0
  persistencetype = "NONE"
}

resource "citrixadc_responderpolicy" "tcp_reset" {
  name        = "rpp_tcp_reset"
  rule        = "true"
  action      = "RESET"
  undefaction = "RESET"
}

resource "citrixadc_lbvserver_service_binding" "dummy_service" {
  name        = citrixadc_lbvserver.dummy_reset.name
  servicename = citrixadc_service.dummy_always_up.name
}

resource "citrixadc_lbvserver_responderpolicy_binding" "dummy_reset" {
  name                   = citrixadc_lbvserver.dummy_reset.name
  policyname             = citrixadc_responderpolicy.tcp_reset.name
  priority               = 100
  gotopriorityexpression = "END"
  bindpoint              = "REQUEST"
}

# -----------------------------------------------------------------------------
# NetProfiles
# -----------------------------------------------------------------------------

resource "citrixadc_netprofile" "service_network" {
  name  = var.netprofile_name
  srcip = var.netprofile_srcip

  lifecycle {
    precondition {
      condition     = length(setintersection(toset(keys(var.cs_services)), toset(keys(var.lb_services)))) == 0
      error_message = "Servicenamen müssen über cs_services und lb_services hinweg eindeutig sein."
    }
  }
}


/*
 * Validierungen
 */

/*
 * Ein Servername darf nicht mit unterschiedlichen IP-Adressen
 * verwendet werden.
 */
check "unique_server_ip_per_name" {
  assert {
    condition = length(local.server_ip_conflicts) == 0

    error_message = format(
      "Folgende Servernamen wurden mit unterschiedlichen IP-Adressen definiert: %s",
      join(", ", keys(local.server_ip_conflicts))
    )
  }
}


/*
 * Serverobjekte
 *
 * Jeder Servername wird nur einmal angelegt, auch wenn der Server
 * in mehreren Portgruppen oder auf mehreren Ports verwendet wird.
 */
resource "citrixadc_server" "server" {
  for_each = local.servers

  name      = each.value.name
  ipaddress = each.value.ip
}


/*
 * Lokale Servicegroups
 *
 * Es wird eine lokale Servicegroup pro Service, Portgruppe und Port
 * erzeugt.
 */
resource "citrixadc_servicegroup" "local" {
  for_each = local.port_configs

  servicegroupname = each.value.local_servicegroup
  servicetype      = "TCP"
  netprofile       = citrixadc_netprofile.service_network.name
}


/*
 * Remote-Servicegroups
 *
 * Diese Ressourcen werden nur erzeugt, wenn die jeweilige Portgruppe
 * mindestens einen Eintrag in remote_members besitzt.
 */
resource "citrixadc_servicegroup" "remote" {
  for_each = local.remote_port_configs

  servicegroupname = each.value.remote_servicegroup
  servicetype      = "TCP"
  netprofile       = citrixadc_netprofile.service_network.name
}


/*
 * Lokale Servicegroup-Member-Bindings
 *
 * Für jeden lokalen Member sowie jeden Port wird ein eigenes Binding
 * erzeugt.
 */
resource "citrixadc_servicegroup_servicegroupmember_binding" "local" {
  for_each = local.local_member_bindings

  servicegroupname = citrixadc_servicegroup.local[
    each.value.port_key
  ].servicegroupname

  servername = citrixadc_server.server[
    each.value.server_name
  ].name

  port = each.value.port
}


/*
 * Remote-Servicegroup-Member-Bindings
 *
 * Bei remote_members = [] entstehen keine Remote-Bindings.
 */
resource "citrixadc_servicegroup_servicegroupmember_binding" "remote" {
  for_each = local.remote_member_bindings

  servicegroupname = citrixadc_servicegroup.remote[
    each.value.port_key
  ].servicegroupname

  servername = citrixadc_server.server[
    each.value.server_name
  ].name

  port = each.value.port
}


/*
 * Remote-LB-vServer
 *
 * Diese LB-vServer werden ausschließlich für Portgruppen mit
 * mindestens einem Remote-Member erzeugt.
 */
resource "citrixadc_lbvserver" "remote" {
  for_each = local.remote_port_configs

  name            = each.value.remote_lbvserver
  servicetype     = "TCP"
  ipv46           = "0.0.0.0"
  port            = 0
  lbmethod        = "LRTM"
  backuplbmethod  = "LEASTCONNECTION"
  persistencetype = "SOURCEIP"
}


/*
 * Bindings zwischen Remote-LB-vServern und Remote-Servicegroups.
 */
resource "citrixadc_lbvserver_servicegroup_binding" "remote" {
  for_each = local.remote_port_configs

  name = citrixadc_lbvserver.remote[
    each.key
  ].name

  servicegroupname = citrixadc_servicegroup.remote[
    each.key
  ].servicegroupname
}


/*
 * Lokale LB-vServer
 *
 * Ein lokaler LB-vServer wird immer erzeugt.
 *
 * Existiert für die Portgruppe ein Remote-Backend, wird der
 * entsprechende Remote-LB-vServer als Backup eingetragen.
 *
 * Bei remote_members = [] wird backupvserver auf null gesetzt.
 */
resource "citrixadc_lbvserver" "local" {
  for_each = local.port_configs

  name            = each.value.local_lbvserver
  servicetype     = "TCP"
  ipv46           = each.value.lb_vip
  port            = each.value.uses_cs ? 0 : each.value.port
  lbmethod        = "LRTM"
  backuplbmethod  = "LEASTCONNECTION"
  persistencetype = "SOURCEIP"

  backupvserver = each.value.has_remote ? (
    citrixadc_lbvserver.remote[each.key].name
  ) : null
}


/*
 * Bindings zwischen lokalen LB-vServern und lokalen Servicegroups.
 */
resource "citrixadc_lbvserver_servicegroup_binding" "local" {
  for_each = local.port_configs

  name = citrixadc_lbvserver.local[
    each.key
  ].name

  servicegroupname = citrixadc_servicegroup.local[
    each.key
  ].servicegroupname
}


/*
 * Content-Switching-Actions
 *
 * Für jeden Port wird eine Action erzeugt, die auf den lokalen
 * LB-vServer zeigt.
 */
resource "citrixadc_csaction" "port" {
  for_each = local.cs_port_configs

  name = each.value.cs_action

  targetlbvserver = citrixadc_lbvserver.local[
    each.key
  ].name
}


/*
 * Content-Switching-Policies
 *
 * Die Policy prüft den Zielport der eingehenden TCP-Verbindung.
 */
resource "citrixadc_cspolicy" "port" {
  for_each = local.cs_port_configs

  policyname = each.value.cs_policy
  rule       = "CLIENT.TCP.DSTPORT.EQ(${each.value.port})"

  action = citrixadc_csaction.port[
    each.key
  ].name
}


/*
 * Content-Switch-vServer
 *
 * Pro Service wird genau ein Content-Switch-vServer erzeugt.
 *
 * Der CLI-Port "*" wird über die NITRO API als Port 65535
 * dargestellt.
 */
resource "citrixadc_csvserver" "service" {
  for_each = local.cs_vservers

  name             = each.value.name
  servicetype      = "TCP"
  ipv46            = each.value.ipv46
  port             = 65535
  persistencetype  = "NONE"
  lbvserverbinding = citrixadc_lbvserver.dummy_reset.name
}


/*
 * Content-Switching-Policy-Bindings
 *
 * Die Prioritäten werden in locals.tf stabil berechnet:
 *
 * 100, 110, 120, 130, ...
 */
resource "citrixadc_csvserver_cspolicy_binding" "port" {
  for_each = local.cs_policy_bindings

  name = citrixadc_csvserver.service[
    each.value.service_name
  ].name

  policyname = citrixadc_cspolicy.port[
    each.value.port_key
  ].policyname

  priority = each.value.priority
}


# -----------------------------------------------------------------------------

# Save-Konfiguration

# -----------------------------------------------------------------------------

/*
resource "citrixadc_nsconfig_save" "tf_save" {

  timestamp = var.nssave_timestamp

  # Will not error when save is already in progress
  concurrent_save_ok = true

  # Set to non zero value to retry the save config operation
  # Will throw error if limit is surpassed
  concurrent_save_retries = 1

  # Time interval between save retries
  concurrent_save_interval = "10s"

  # Total timeout for all retries
  concurrent_save_timeout = "5m"
}
*/