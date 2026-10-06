netscaler_endpoint = "https://192.168.101.88"
netscaler_username = "nsroot"
netscaler_password = "Server2016"

netprofile_name  = "test"
netprofile_srcip = "192.168.101.90"

default_lb_vserver = "lvs_dummy_reset"

# -----------------------------------------------------------------------------
# CS Services
# -----------------------------------------------------------------------------
cs_services = {
  webshop1 = {
    stage       = "eng"
    environment = "kub"
    cs_vip      = "192.168.101.91"
    local_site  = "voh"
    remote_site = "nue"

    monitors= ["mon_tcp"]

    portgroups = {
      portgroup001 = {
        ports = [10301, 10302, 10303, 10304, 10305, 10306, 10307, 10309]

        local_members = [
          {
            server_name = "srv_winserv21"
            server_ip   = "10.1.2.21"
          },
          {
            server_name = "srv_winserv22"
            server_ip   = "10.1.2.22"
          }
        ]

        remote_members = [
          {
            server_name = "srv_winserv93"
            server_ip   = "10.1.5.34"
          },
          {
            server_name = "srv_winserv94"
            server_ip   = "10.1.5.35"
          }
        ]
      }

      portgroup002 = {
        ports = [10308]
        monitors= []

        local_members = [
          {
            server_name = "srv_winapp93"
            server_ip   = "10.1.2.20"
          }
        ]

        # Hier die zur Portgruppe 002 gehörenden Remote-Server eintragen.
        remote_members = []
      }
    }
  },
  webshop2 = {
    stage       = "eng"
    environment = "kub"
    cs_vip      = "192.168.101.93"
    local_site  = "voh"
    remote_site = "nue"

    portgroups = {
      portgroup001 = {
        ports = [10501, 10502, 10503, 10504, 10505, 10506, 10507, 10509]

        local_members = [
          {
            server_name = "srv_winserv21"
            server_ip   = "10.1.2.21"
          },
          {
            server_name = "srv_winserv22"
            server_ip   = "10.1.2.22"
          }
        ]

        remote_members = [
          {
            server_name = "srv_winserv93"
            server_ip   = "10.1.5.34"
          },
          {
            server_name = "srv_winserv94"
            server_ip   = "10.1.5.35"
          }
        ]
      }

      portgroup002 = {
        ports = [10508]

        local_members = [
          {
            server_name = "srv_winapp93"
            server_ip   = "10.1.2.20"
          }
        ]

        # Hier die zur Portgruppe 002 gehörenden Remote-Server eintragen.
        remote_members = []
      }
    }
  }
}

# -----------------------------------------------------------------------------
# LB Services
# -----------------------------------------------------------------------------
lb_services = {
  example = {
    stage       = "eng"
    environment = "kub"
    lb_vip      = "192.168.101.93"
    local_site  = "voh"
    remote_site = "nue"
    monitors    = ["mon_tcp", "mon_http_health"]

    portgroups = {
      portgroup001 = {
        ports = [80] # Beispielport für TCP

        # Ohne monitors wird die Service-Liste übernommen.
        # monitors = ["mon_tcp"] # Ersetzt die Service-Liste für diese Portgruppe.
        # monitors = []          # Keine expliziten Monitor-Bindings.

        local_members = [
          {
            server_name = "srv_192_168_101_100"
            server_ip   = "192.168.101.100"
          },
          {
            server_name = "srv_192_168_101_101"
            server_ip   = "192.168.101.101"
          }
        ]

        remote_members = []
      }
    }
  }
}

# -----------------------------------------------------------------------------
# Monitors
# -----------------------------------------------------------------------------

monitors = {
  mon_tcp = {
    type        = "TCP"
    interval    = 5
    resptimeout = 2
    retries     = 3
    lrtm        = "ENABLED"
  }

  mon_http_health = {
    type        = "HTTP"
    httprequest = "GET /"
    respcode    = ["200"]
    interval    = 5
    resptimeout = 2
    retries     = 3
    lrtm        = "ENABLED"
  }
}


# -----------------------------------------------------------------------------
# GSLB Services
# -----------------------------------------------------------------------------
# Namensschema (servicetype wird kleingeschrieben):
# GSLB-vServer: gslb_vs_<stage>_<environment>_<service>_<servicetype>
# GSLB-Service: glsb_svc_<stage>_<environment>_<service>_<member>_<site>
# Die folgende Konfiguration erzeugt:
#   gslb_vs_ent_rz1_webshop1_tcp
#   glsb_svc_ent_rz1_webshop1_local_voh
#   glsb_svc_ent_rz1_webshop1_remote_nue

gslb_services = {
  webshop1 = {
    stage         = "ent"
    environment   = "rz1"
    servicetype   = "TCP"
    dnsrecordtype = "A"
    lbmethod      = "ROUNDROBIN"
    edr           = "ENABLED"
    tolerance     = "0"

    # Die GSLB-Sites müssen auf dem ADC bereits vorhanden sein.
    # IP und Port bezeichnen den jeweiligen CS-/LB-vServer.
    services = {
      local = {
        site   = "voh"
        ip     = "192.168.101.91"
        port   = 65535
        weight = 1
      }
      remote = {
        site   = "nue"
        ip     = "192.0.2.91" # Remote-VIP vor Verwendung anpassen.
        port   = 65535
        weight = 1
      }
    }

    gslb_domains = {
      primary = {
        domainname = "webshop1.example.com"
        ttl        = 60
      }
    }
  }  
}
