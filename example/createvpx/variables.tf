variable "netscaler_host" {
  description = "NITRO-API-Endpunkt der NetScaler-SDX-Appliance"
  type        = string
}

variable "netscaler_username" {
  type      = string
  sensitive = true
}

variable "netscaler_password" {
  type      = string
  sensitive = true
}

variable "netscaler_insecure_skip_verify" {
  type    = bool
  default = false
}

variable "vpx_instances" {
  description = "VPX-Instanzen, indiziert nach eindeutigem Instanznamen"
  type = map(object({
    ip_address                 = string
    ipv4_address               = optional(string)
    netmask                    = string
    gateway                    = string
    if_internal_ip_enabled     = optional(bool, false)
    config_type                = optional(number, 0)
    image_name                 = optional(string, "NSVPX-XEN-14.1-73.33_nc_64.xva")
    profile_name               = optional(string, "ns_nsroot_vpx")
    description                = optional(string, "from tf")
    license                    = optional(string, "Platinum")
    throughput_allocation_mode = optional(number, 0)
    throughput                 = optional(number, 1000)
    max_burst_throughput       = optional(number, 0)
    burst_priority             = optional(number, 0)
    number_of_acu              = optional(number, 6000)
    number_of_scu              = optional(number, 6000)
    vm_memory_total            = optional(number, 4096)
    pps                        = optional(number, 1000000)
    number_of_cores            = optional(number, 2)
    l2_enabled                 = optional(bool, false)
    if_0_1                     = optional(bool, false)
    vlan_id_0_1                = optional(number, 0)
    if_0_2                     = optional(bool, false)
    vlan_id_0_2                = optional(number, 0)
    nsvlan_id                  = optional(number, 2)
    vlan_type                  = optional(number, 1)
    nsvlan_tagged              = optional(bool, false)
    nsvlan_interfaces          = optional(list(string), ["LA/1"])
    network_interfaces = optional(list(object({
      port_name            = string
      device_channel_name  = string
      mac_mode             = optional(string, "default")
      receiveuntagged      = optional(bool, true)
      vlan_whitelist_array = optional(list(number), [])
      is_vlan_applied      = optional(bool, false)
    })), [
    {
      port_name            = "LA/1"
      device_channel_name  = "LA/1"
      mac_mode             = "default"
      receiveuntagged      = true
      vlan_whitelist_array = []
      is_vlan_applied      = false
    },
    {
      port_name            = "LA/2"
      device_channel_name  = "LA/2"
      mac_mode             = "default"
      receiveuntagged      = true
      vlan_whitelist_array = []
      is_vlan_applied      = false
    },
    {
      port_name            = "LA/3"
      device_channel_name  = "LA/3"
      mac_mode             = "default"
      receiveuntagged      = true
      vlan_whitelist_array = []
      is_vlan_applied      = false
    }
  ])
  }))
}

variable "adc_username" {
  description = "NITRO-Benutzer auf beiden VPX, entsprechend dem SDX-Profil"
  type        = string
  default     = "nsroot"
}

variable "adc_password" {
  description = "NITRO-Passwort auf beiden VPX; nicht das SDX-Passwort"
  type        = string
  sensitive   = true
  default     = ""
  nullable    = false
}

variable "rpc_node_password" {
  description = "Gemeinsames RPC-Passwort für die HA-Peer-Konfiguration"
  type        = string
  sensitive   = true
  default     = ""
  nullable    = false
}

variable "adc_insecure_skip_verify" {
  description = "TLS-Zertifikatsprüfung der VPX überspringen"
  type        = bool
  default     = false
}

variable "ha" {
  description = "Optionales HA-Paar aus zwei VPX-Namen im selben Netz (ohne INC)"
  type = object({
    enabled = optional(bool, false)
    nodes   = tuple([string, string])
    peer_id = optional(number, 1)
    snip = optional(object({
      ip_address = string
      netmask    = string
    }))
  })
  default = {
    enabled = false
    nodes   = ["adc123", "adc124"]
    peer_id = 1
    snip    = null
  }
  nullable = false

  validation {
    condition     = var.ha.nodes[0] != var.ha.nodes[1]
    error_message = "Für HA müssen zwei unterschiedliche VPX-Namen angegeben werden."
  }

  validation {
    condition     = var.ha.peer_id >= 1 && var.ha.peer_id <= 64 && floor(var.ha.peer_id) == var.ha.peer_id
    error_message = "Die HA-Peer-ID muss eine ganze Zahl zwischen 1 und 64 sein."
  }
}
