/*
###############################################################################
# Datei      : main.tf
# Zweck      : Definition der NetScaler-ADC-Ressourcen
#
# NetScaler-Ressourcen werden mit dem Praefix "citrixadc_" angelegt.
# �nderungen
# -----------------------------------------------------------------------------
# Datum       CH-Nummer     Bearbeiter        Beschreibung
# -----------------------------------------------------------------------------
# 2026-09-07  CHM-001234     M. Schwenke       Initiale Erstellung
# YYYY-MM-DD  CHM-XXXXXX     <Name>            <Beschreibung>
# YYYY-MM-DD  CHM-XXXXXX     <Name>            <Beschreibung>
#
# Hinweis:
# Nach jeder Änderung den Zeitstempel in terraform_data.always_run anpassen.
#
# Die Ressource "always_run" dient dazu, Änderungen an der Konfiguration
# eindeutig zu kennzeichnen. Durch die Anpassung des Wertes in "input" wird
# Terraform bei jedem Change eine Änderung erkennen und den aktuellen Stand
# im State aktualisieren. Der Zeitstempel sollte im Format YYYYMMDDHHMM
# gepflegt werden und entspricht idealerweise dem Zeitpunkt der letzten
# freigegebenen �nderung (CH-Nummer).
###############################################################################
*/

/*
resource "citrixadc_nsfeature" "nsfeature" {
  sp = "true"
  lb = "true"
  cs = "true"
  ssl = "true"
  gslb = "true"
  rewrite = "true"
  responder = "true"
  appflow = "true"
  ch = "true"
}

resource "citrixadc_nsip" "_10_96_32_31" {
  ipaddress = "10.96.32.31"
  netmask = "255.255.255.0"
  vserver = "DISABLED"
}


resource "citrixadc_netprofile" "netprf_servicenetz_snip" {
  name = "netprf_servicenetz_snip"
  srcip = "10.96.32.31"
  mbf = "DISABLED"
  depends_on = [citrixadc_nsip._10_96_32_31]
}
*/

# -----------------------------------------------------------------------------
# GSLB Location
# -----------------------------------------------------------------------------

resource "citrixadc_location" "locations" {
  for_each = var.locations

  ipfrom            = each.value.ipfrom
  ipto              = each.value.ipto
  preferredlocation = each.value.preferredlocation
}


resource "citrixadc_service" "adns_udp" {
  name = "adns_udp"
  ip = var.adns_service_ip
  servicetype = "ADNS"
  port = "53"
}

resource "citrixadc_service" "adns_tcp" {
  name = "adns_tcp"
  ip = var.adns_service_ip
  servicetype = "ADNS_TCP"
  port = "53"
}

resource "citrixadc_gslbsite" "local_gslbsite" {
  sitetype = "LOCAL"
  sitepassword = var.gslb_site_local.password
  sitename = var.gslb_site_local.name
  siteipaddress = var.gslb_site_local.ip
  publicip = var.gslb_site_local.ip
}

resource "citrixadc_gslbsite" "remote_gslbsite" {
  sitetype = "REMOTE"
  sitepassword = var.gslb_site_remote.password
  sitename = var.gslb_site_remote.name
  siteipaddress = var.gslb_site_remote.ip
  publicip = var.gslb_site_remote.ip
}
