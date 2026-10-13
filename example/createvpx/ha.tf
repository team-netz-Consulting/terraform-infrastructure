# Quelle: https://registry.terraform.io/providers/citrix/citrixadc/latest/docs/resources/hanode
# Zwei neue VPX im selben Netz: Standard-HA mit aktivierter Synchronisation.
# Erst provisionieren; HA erst nach Erreichbarkeit beider NITRO-APIs aktivieren.
locals {
  ha_nodes_exist = alltrue([for name in var.ha.nodes : contains(keys(var.vpx_instances), name)])
  ha_node1_ip   = try(coalesce(var.vpx_instances[var.ha.nodes[0]].ipv4_address, var.vpx_instances[var.ha.nodes[0]].ip_address), "127.0.0.1")
  ha_node2_ip   = try(coalesce(var.vpx_instances[var.ha.nodes[1]].ipv4_address, var.vpx_instances[var.ha.nodes[1]].ip_address), "127.0.0.1")
}

# HA-Einstellungen werden nicht synchronisiert: auf jedem ADC den Peer anlegen.
resource "citrixadc_hanode" "node1_peer" {
  count    = var.ha.enabled ? 1 : 0
  provider = citrixadc.ha_node1

  hanode_id       = var.ha.peer_id
  ipaddress       = local.ha_node2_ip
  rpcnodepassword = var.rpc_node_password

  depends_on = [null_resource.wait_for_nitro]

  lifecycle {
    precondition {
      condition     = local.ha_nodes_exist
      error_message = "Beide HA-Nodes müssen als Schlüssel in vpx_instances vorhanden sein."
    }
    precondition {
      condition     = local.ha_node1_ip != local.ha_node2_ip
      error_message = "Die beiden HA-Nodes benötigen unterschiedliche NSIPs."
    }
    precondition {
      condition     = length(trimspace(var.adc_username)) > 0 && length(var.adc_password) > 0 && length(var.rpc_node_password) > 0
      error_message = "Für HA müssen adc_username, adc_password und rpc_node_password befüllt werden."
    }
  }
}

resource "citrixadc_hanode" "node2_peer" {
  count    = var.ha.enabled ? 1 : 0
  provider = citrixadc.ha_node2

  hanode_id       = var.ha.peer_id
  ipaddress       = local.ha_node1_ip
  rpcnodepassword = var.rpc_node_password

  depends_on = [citrixadc_hanode.node1_peer]
}

# Gemeinsame SNIP nur auf dem aktiven ADC verwalten; HA synchronisiert sie.
# Quelle: https://registry.terraform.io/providers/citrix/citrixadc/latest/docs/resources/nsip
resource "citrixadc_nsip" "ha_snip" {
  count    = var.ha.enabled && var.ha.snip != null ? 1 : 0
  provider = citrixadc.ha_node1

  ipaddress = var.ha.snip.ip_address
  netmask   = var.ha.snip.netmask
  type      = "SNIP"

  depends_on = [citrixadc_hanode.node2_peer]
}
