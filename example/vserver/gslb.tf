# Datei        : gslb.tf
# Dateiversion : 2026.10.12.1342

variable "gslb_services" {
  description = "GSLB-vServer mit Services an vorhandenen GSLB-Sites und automatisch erzeugten Domain- und Service-Bindings."
  default     = {}
  type = map(object({
    stage           = string
    environment     = string
    servicetype     = optional(string, "TCP")
    dnsrecordtype   = optional(string, "A")
    lbmethod        = optional(string, "ROUNDROBIN")
    backuplbmethod  = optional(string)
    persistencetype = optional(string, "NONE")
    edr             = optional(string)
    mir             = optional(string)
    ecs             = optional(string)

    services = map(object({
      site          = string
      ip            = string
      port          = number
      publicip      = optional(string)
      publicport    = optional(number)
      healthmonitor = optional(string, "YES")
      weight        = optional(number, 1)
      order         = optional(number)
    }))

    gslb_domains = map(object({
      domainname = string
      ttl        = optional(number, 60)
    }))
  }))

  validation {
    condition = alltrue([
      for service in var.gslb_services :
      length(service.services) > 0 && length(service.gslb_domains) > 0
    ])
    error_message = "Jeder GSLB-vServer benötigt mindestens einen Service und eine Domain."
  }

  validation {
    condition = alltrue(flatten([
      for service in var.gslb_services : [
        for member in service.services :
        can(cidrhost("${member.ip}/${strcontains(member.ip, ":") ? 128 : 32}", 0)) &&
        trimspace(member.site) != "" &&
        member.port >= 1 && member.port <= 65535 && floor(member.port) == member.port &&
        member.weight >= 1 && member.weight <= 100 && floor(member.weight) == member.weight
      ]
    ]))
    error_message = "GSLB-Services benötigen eine gültige IP, einen Site-Namen, einen ganzzahligen Port (1–65535) und ein Gewicht (1–100)."
  }

  validation {
    condition = alltrue(flatten([
      for service in var.gslb_services : [
        for domain in service.gslb_domains :
        trimspace(domain.domainname) != "" && domain.ttl >= 1 && floor(domain.ttl) == domain.ttl
      ]
    ]))
    error_message = "GSLB-Domains benötigen einen Namen und eine positive ganzzahlige TTL."
  }
}

locals {
  gslb_vservers = {
    for name, service in var.gslb_services : name => merge(service, {
      name = "gslb_vs_${service.stage}_${service.environment}_${name}_${lower(service.servicetype)}"
    })
  }

  gslb_members = merge({}, [
    for name, service in local.gslb_vservers : {
      for member_name, member in service.services : jsonencode([name, member_name]) => merge(member, {
        vserver     = name
        servicetype = service.servicetype
        sitename    = "${member.site}_xy_${member_name == "remote" ? "rem" : "loc"}"
        name        = "glsb_svc_${service.stage}_${service.environment}_${name}_${member_name}_${member.site}"
        # _${lower(service.servicetype)}_${member.port}"
      })
    }
  ]...)

  gslb_domains = merge({}, [
    for name, service in local.gslb_vservers : {
      for domain_name, domain in service.gslb_domains : jsonencode([name, domain_name]) => merge(domain, {
        vserver = name
      })
    }
  ]...)
}

resource "citrixadc_gslbvserver" "service" {
  for_each = local.gslb_vservers

  name            = each.value.name
  servicetype     = each.value.servicetype
  dnsrecordtype   = each.value.dnsrecordtype
  lbmethod        = each.value.lbmethod
  backuplbmethod  = each.value.backuplbmethod
  persistencetype = each.value.persistencetype
  edr             = each.value.edr
  mir             = each.value.mir
  ecs             = each.value.ecs
}

resource "citrixadc_gslbservice" "service" {
  for_each = local.gslb_members

  servicename   = each.value.name
  servicetype   = each.value.servicetype
  sitename      = each.value.sitename
  ip            = each.value.ip
  port          = each.value.port
  publicip      = each.value.publicip
  publicport    = each.value.publicport
  healthmonitor = each.value.healthmonitor
}

resource "citrixadc_gslbvserver_domain_binding" "service" {
  for_each = local.gslb_domains

  name       = citrixadc_gslbvserver.service[each.value.vserver].name
  domainname = each.value.domainname
  ttl        = each.value.ttl
}

resource "citrixadc_gslbvserver_gslbservice_binding" "service" {
  for_each = local.gslb_members

  name        = citrixadc_gslbvserver.service[each.value.vserver].name
  servicename = citrixadc_gslbservice.service[each.key].servicename
  weight      = each.value.weight
  order       = each.value.order
}
