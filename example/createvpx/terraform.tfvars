netscaler_host     = "https://192.168.101.88"
netscaler_username = "nsroot"
netscaler_password = "Server2016"

netscaler_insecure_skip_verify = false

# Für eine zweite SDX diesen Block ausfüllen und aktivieren.
# sdx2 = {
#   host                 = "https://<SDX-2-IP>"
#   username             = "nsroot"
#   password             = ""
#   insecure_skip_verify = false
# }

# Ein Eintrag erstellt eine VPX; zwei Einträge erstellen zwei VPX.
vpx_instances = {
  adc123 = {
    sdx                        = "sdx1"
    ip_address                 = "10.1.1.195"
    ipv4_address               = "10.1.1.195"
    netmask                    = "255.255.255.0"
    gateway                    = "10.1.1.1"
    if_internal_ip_enabled     = false
    config_type                = 0
    image_name                 = "NSVPX-XEN-14.1-73.33_nc_64.xva"
    profile_name               = "ns_nsroot_vpx"
    description                = "from tf"
    license                    = "Platinum"
    throughput_allocation_mode = 0
    throughput                 = 1000
    max_burst_throughput       = 0
    burst_priority             = 0
    number_of_acu              = 6000
    number_of_scu              = 6000
    vm_memory_total            = 4096
    pps                        = 1000000
    number_of_cores            = 2
    l2_enabled                 = false
    if_0_1                     = false
    vlan_id_0_1                = 0
    if_0_2                     = false
    vlan_id_0_2                = 0
    nsvlan_id                  = 2
    vlan_type                  = 1
    nsvlan_tagged              = false
    nsvlan_interfaces          = ["LA/1"]

    network_interfaces = [
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
      },
    ]
  }
  adc124 = {
    sdx                        = "sdx1" # Für eine andere SDX auf "sdx2" setzen.
    ip_address                 = "10.1.1.196"
    ipv4_address               = "10.1.1.196"
    netmask                    = "255.255.255.0"
    gateway                    = "10.1.1.1"
    if_internal_ip_enabled     = false
    config_type                = 0
    image_name                 = "NSVPX-XEN-14.1-73.33_nc_64.xva"
    profile_name               = "ns_nsroot_vpx"
    description                = "from tf"
    license                    = "Platinum"
    throughput_allocation_mode = 0
    throughput                 = 1000
    max_burst_throughput       = 0
    burst_priority             = 0
    number_of_acu              = 6000
    number_of_scu              = 6000
    vm_memory_total            = 4096
    pps                        = 1000000
    number_of_cores            = 2
    l2_enabled                 = false
    if_0_1                     = false
    vlan_id_0_1                = 0
    if_0_2                     = false
    vlan_id_0_2                = 0
    nsvlan_id                  = 2
    vlan_type                  = 1
    nsvlan_tagged              = false
    nsvlan_interfaces          = ["LA/1"]

    network_interfaces = [
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
      },
    ]
  }
}

# Zugangsdaten der VPX aus dem SDX-Profil (nicht der SDX-Appliance).
adc_username             = "nsroot"
adc_password             = "" # Hier lokal das VPX-Passwort eintragen.
adc_insecure_skip_verify = false
rpc_node_password        = "" # Hier lokal das gemeinsame RPC-Passwort eintragen.

# Erst nach dem Start beider VPX auf true setzen.
ha = {
  enabled = true
  nodes   = ["adc123", "adc124"]
  peer_id = 1
  # Optional, für HA im selben Netz:
  snip = {
     ip_address = "10.1.1.197" # Durch die gewünschte freie SNIP ersetzen.
     netmask    = "255.255.255.0"
  }
}
