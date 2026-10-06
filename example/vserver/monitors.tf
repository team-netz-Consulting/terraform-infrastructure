/*
 * Gemeinsame Monitore für CS- und LB-Services.
 * Intervalle und Antwortzeitlimits werden in Sekunden angegeben.
 * Ohne destip/destport wird das jeweilige Servicegroup-Mitglied geprüft.
 * Zeiteinheiten nur zusammen mit dem zugehörigen optionalen Wert senden.
 */
resource "citrixadc_lbmonitor" "monitor" {
  for_each = var.monitors

  monitorname    = each.key
  type           = each.value.type
  interval       = each.value.interval
  units3         = each.value.interval != null ? "SEC" : null
  resptimeout    = each.value.resptimeout
  units4         = each.value.resptimeout != null ? "SEC" : null
  retries        = each.value.retries
  destip         = each.value.destip
  destport       = each.value.destport
  secure         = each.value.secure
  httprequest    = each.value.httprequest
  respcode       = each.value.respcode
  customheaders  = each.value.customheaders
  send           = each.value.send
  recv           = each.value.recv
  lrtm           = each.value.lrtm
  successretries = each.value.successretries
  downtime       = each.value.downtime
  units2         = each.value.downtime != null ? "SEC" : null
  query          = each.value.query
  querytype      = each.value.querytype
  scriptname     = each.value.scriptname
  dispatcherip   = each.value.dispatcherip
  dispatcherport = each.value.dispatcherport
  password       = each.value.password
  basedn         = each.value.basedn
  binddn         = each.value.binddn
  filter         = each.value.filter
}

resource "citrixadc_servicegroup_lbmonitor_binding" "local" {
  for_each = local.local_monitor_bindings

  servicegroupname = citrixadc_servicegroup.local[each.value.port_key].servicegroupname
  monitorname      = try(citrixadc_lbmonitor.monitor[each.value.monitor_name].monitorname, each.value.monitor_name)

  lifecycle {
    precondition {
      condition     = contains(keys(var.monitors), each.value.monitor_name)
      error_message = "Monitor '${each.value.monitor_name}' muss in der zentralen monitors-Map definiert sein."
    }
  }
}

resource "citrixadc_servicegroup_lbmonitor_binding" "remote" {
  for_each = local.remote_monitor_bindings

  servicegroupname = citrixadc_servicegroup.remote[each.value.port_key].servicegroupname
  monitorname      = try(citrixadc_lbmonitor.monitor[each.value.monitor_name].monitorname, each.value.monitor_name)

  lifecycle {
    precondition {
      condition     = contains(keys(var.monitors), each.value.monitor_name)
      error_message = "Monitor '${each.value.monitor_name}' muss in der zentralen monitors-Map definiert sein."
    }
  }
}
