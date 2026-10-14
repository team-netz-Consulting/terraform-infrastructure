output "instance_ids" {
  description = "IDs der provisionierten VPX für die HA-Bereitschaftsprüfung"
  value       = { for name, instance in netscalersdx_provision_vpx.vpxdevice : name => instance.id }
}
