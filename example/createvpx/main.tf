# Datei        : main.tf
# Dateiversion : 2026.10.12.1342

resource "netscalersdx_provision_vpx" "vpxdevice" {
  for_each = var.vpx_instances

  name                       = each.key
  ip_address                 = each.value.ip_address
  ipv4_address               = coalesce(each.value.ipv4_address, each.value.ip_address)
  netmask                    = each.value.netmask
  gateway                    = each.value.gateway
  if_internal_ip_enabled     = each.value.if_internal_ip_enabled
  config_type                = each.value.config_type
  image_name                 = each.value.image_name
  profile_name               = each.value.profile_name
  description                = each.value.description
  license                    = each.value.license
  throughput_allocation_mode = each.value.throughput_allocation_mode
  throughput                 = each.value.throughput
  max_burst_throughput       = each.value.max_burst_throughput
  burst_priority             = each.value.burst_priority
  number_of_acu              = each.value.number_of_acu
  number_of_scu              = each.value.number_of_scu
  vm_memory_total            = each.value.vm_memory_total
  pps                        = each.value.pps
  number_of_cores            = each.value.number_of_cores
  l2_enabled                 = each.value.l2_enabled
  if_0_1                     = each.value.if_0_1
  vlan_id_0_1                = each.value.vlan_id_0_1
  if_0_2                     = each.value.if_0_2
  vlan_id_0_2                = each.value.vlan_id_0_2
  nsvlan_id                  = each.value.nsvlan_id
  vlan_type                  = each.value.vlan_type
  nsvlan_tagged              = each.value.nsvlan_tagged
  nsvlan_interfaces          = each.value.nsvlan_interfaces
  network_interfaces         = each.value.network_interfaces
}
