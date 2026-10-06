netscaler_endpoint = "https://192.168.101.88"
netscaler_username = "nsroot"
netscaler_password = "Server2016"


# -----------------------------------------------------------------------------
# Custom Locations: add location <IPfrom> <IPto> <preferredLocation>
# Beispiele einkommentieren und IP-Bereiche sowie Location-Namen anpassen.
# Fuer weitere Bereiche jeweils einen eigenen, stabilen Map-Schluessel verwenden.
# -----------------------------------------------------------------------------
locations = {
   frankfurt = {
     ipfrom = "192.0.2.0"
     ipto   = "192.0.2.255"
     preferredlocation = "EU.DE.HE.Frankfurt.*"
  }

  # berlin = {
  #   ipfrom = "198.51.100.0"
  #   ipto   = "198.51.100.255"
  #   name   = "EU.DE.BE.Berlin"
  # }
}

# Optionale Attribute koennen entfallen; dann gelten die Provider-/ADC-Defaults.
# MÄIR wird als MIR (Multiple IP Response) ueber das Attribut mir konfiguriert.
netscaler_insecure_skip_verify = false

adns_service_ip = "192.168.101.96"

gslb_site_local = {
  name = "voh_xy_loc"
  ip = "10.1.2.50"
  password = "test"
}

gslb_site_remote = {
  name = "nue_xy_rem"
  ip = "10.1.5.50"
  password = "test"
}