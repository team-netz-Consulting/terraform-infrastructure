module "sdx1" {
  source = "./modules/vpx"
  providers = {
    netscalersdx = netscalersdx
  }
  vpx_instances = { for name, instance in var.vpx_instances : name => instance if instance.sdx == "sdx1" }
}

module "sdx2" {
  source = "./modules/vpx"
  providers = {
    netscalersdx = netscalersdx.sdx2
  }
  sdx_configured = var.sdx2 != null
  vpx_instances  = { for name, instance in var.vpx_instances : name => instance if instance.sdx == "sdx2" }
}

# Bestehende VPX bleiben zunächst auf SDX 1 und behalten ihre State-Zuordnung.
moved {
  from = netscalersdx_provision_vpx.vpxdevice
  to   = module.sdx1.netscalersdx_provision_vpx.vpxdevice
}

output "vpx_instance_ids" {
  value = merge(module.sdx1.instance_ids, module.sdx2.instance_ids)

}
