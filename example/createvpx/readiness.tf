# Beide NITRO-APIs müssen bereit sein, bevor HA eingerichtet wird.
resource "null_resource" "wait_for_nitro" {
  count = var.ha.enabled ? 1 : 0

  triggers = {
    endpoints = jsonencode([local.ha_node1_ip, local.ha_node2_ip])
    instances = sha256(jsonencode(var.vpx_instances))
    script    = filesha256("${path.module}/scripts/wait_for_nitro.py")
    tls       = tostring(var.adc_insecure_skip_verify)
  }

  depends_on = [netscalersdx_provision_vpx.vpxdevice]

  lifecycle {
    replace_triggered_by = [netscalersdx_provision_vpx.vpxdevice]

    precondition {
      condition     = local.ha_nodes_exist && local.ha_node1_ip != local.ha_node2_ip
      error_message = "Für die NITRO-Prüfung müssen zwei VPX mit unterschiedlichen NSIPs vorhanden sein."
    }
    precondition {
      condition     = length(trimspace(var.adc_username)) > 0 && length(var.adc_password) > 0
      error_message = "Für die NITRO-Prüfung müssen adc_username und adc_password befüllt werden."
    }
  }

  provisioner "local-exec" {
    command = "python3 \"${path.module}/scripts/wait_for_nitro.py\""
    environment = {
      NITRO_ENDPOINTS = jsonencode(["https://${local.ha_node1_ip}", "https://${local.ha_node2_ip}"])
      NITRO_USERNAME  = var.adc_username
      NITRO_PASSWORD  = var.adc_password
      NITRO_INSECURE  = tostring(var.adc_insecure_skip_verify)
    }
  }
}
