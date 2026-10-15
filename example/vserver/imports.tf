# Datei        : imports.tf
# Dateiversion : 2026.10.12.1026

/*
###############################################################################
# Datei        : import.tf
# Zweck        : Wiederherstellung eines verlorenen Terraform-States
# Voraussetzung: Terraform >= 1.7
#
# Nur verwenden, wenn die Objekte bereits auf dem NetScaler ADC existieren.
# Vorher ADC-Backup erstellen und zunächst ausschließlich terraform plan nutzen.
###############################################################################


#
# Statische Basisobjekte
#

import {
  to = citrixadc_service.dummy_always_up
  id = "svc_dummy_always_up"
}

import {
  to = citrixadc_lbvserver.dummy_reset
  id = "lvs_dummy_reset"
}

import {
  to = citrixadc_responderpolicy.tcp_reset
  id = "rpp_tcp_reset"
}

import {
  to = citrixadc_netprofile.service_network
  id = var.netprofile_name
}


#
# Zentrale Monitore
# Import-ID: <monitorname>
#

import {
  for_each = var.monitors

  to = citrixadc_lbmonitor.monitor[each.key]
  id = each.key
}

#
# Lokale und Remote-Servicegroup-Monitor-Bindings
# Import-ID: <servicegroup>,<monitorname>
#

import {
  for_each = local.local_monitor_bindings

  to = citrixadc_servicegroup_lbmonitor_binding.local[each.key]
  id = format(
    "%s,%s",
    local.port_configs[each.value.port_key].local_servicegroup,
    each.value.monitor_name
  )
}

import {
  for_each = local.remote_monitor_bindings

  to = citrixadc_servicegroup_lbmonitor_binding.remote[each.key]
  id = format(
    "%s,%s",
    local.remote_port_configs[each.value.port_key].remote_servicegroup,
    each.value.monitor_name
  )
}

#
# Serverobjekte
#

import {
  for_each = local.servers

  to = citrixadc_server.server[each.key]
  id = each.value.name
}

#
# Lokale und Remote-Servicegroups
#

import {
  for_each = local.port_configs

  to = citrixadc_servicegroup.local[each.key]
  id = each.value.local_servicegroup
}

import {
  for_each = local.remote_port_configs

  to = citrixadc_servicegroup.remote[each.key]
  id = each.value.remote_servicegroup
}

#
# Lokale und Remote-LB-vServer
#

import {
  for_each = local.remote_port_configs

  to = citrixadc_lbvserver.remote[each.key]
  id = each.value.remote_lbvserver
}

import {
  for_each = local.port_configs

  to = citrixadc_lbvserver.local[each.key]
  id = each.value.local_lbvserver
}

#
# Content-Switching-Actions und -Policies
#

import {
  for_each = local.cs_port_configs

  to = citrixadc_csaction.port[each.key]
  id = each.value.cs_action
}

import {
  for_each = local.cs_port_configs

  to = citrixadc_cspolicy.port[each.key]
  id = each.value.cs_policy
}

#
# Content-Switch-vServer
#

import {
  for_each = local.cs_vservers

  to = citrixadc_csvserver.service[each.key]
  id = each.value.name
}

#
# Statische Bindings
# Import-ID: <lbvserver>,<service|policy>
#

import {
  to = citrixadc_lbvserver_service_binding.dummy_service
  id = "lvs_dummy_reset,svc_dummy_always_up"
}

import {
  to = citrixadc_lbvserver_responderpolicy_binding.dummy_reset
  id = "lvs_dummy_reset,rpp_tcp_reset"
}

#
# Lokale Servicegroup-Member-Bindings
# Import-ID: <servicegroup>,<servername>,<port>
#

import {
  for_each = local.local_member_bindings

  to = citrixadc_servicegroup_servicegroupmember_binding.local[each.key]

  id = format(
    "%s,%s,%d",
    each.value.servicegroupname,
    each.value.server_name,
    each.value.port
  )
}

#
# Remote-Servicegroup-Member-Bindings
#

import {
  for_each = local.remote_member_bindings

  to = citrixadc_servicegroup_servicegroupmember_binding.remote[each.key]

  id = format(
    "%s,%s,%d",
    each.value.servicegroupname,
    each.value.server_name,
    each.value.port
  )
}

#
# Lokale LB-vServer-Servicegroup-Bindings
# Import-ID: <lbvserver>,<servicegroup>
#

import {
  for_each = local.port_configs

  to = citrixadc_lbvserver_servicegroup_binding.local[each.key]

  id = format(
    "%s,%s",
    each.value.local_lbvserver,
    each.value.local_servicegroup
  )
}

#
# Remote-LB-vServer-Servicegroup-Bindings
#

import {
  for_each = local.remote_port_configs

  to = citrixadc_lbvserver_servicegroup_binding.remote[each.key]

  id = format(
    "%s,%s",
    each.value.remote_lbvserver,
    each.value.remote_servicegroup
  )
}

#
# Content-Switch-vServer-CSPolicy-Bindings
# Import-ID: <csvserver>,<cspolicy>
#

import {
  for_each = local.cs_policy_bindings

  to = citrixadc_csvserver_cspolicy_binding.port[each.key]

  id = format(
    "%s,%s",
    each.value.csvserver,
    each.value.policyname
  )
}
*/