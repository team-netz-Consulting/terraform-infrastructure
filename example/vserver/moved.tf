# Migration der bestehenden CS-Instanzen auf Schlüssel mit cs:-Präfix.
# NetScaler-Objektnamen bleiben unverändert.

moved {
  from = citrixadc_csaction.port["artera1:portgroup001:10301"]
  to   = citrixadc_csaction.port["cs:artera1:portgroup001:10301"]
}

moved {
  from = citrixadc_csaction.port["artera1:portgroup001:10302"]
  to   = citrixadc_csaction.port["cs:artera1:portgroup001:10302"]
}

moved {
  from = citrixadc_csaction.port["artera1:portgroup001:10303"]
  to   = citrixadc_csaction.port["cs:artera1:portgroup001:10303"]
}

moved {
  from = citrixadc_csaction.port["artera1:portgroup001:10304"]
  to   = citrixadc_csaction.port["cs:artera1:portgroup001:10304"]
}

moved {
  from = citrixadc_csaction.port["artera1:portgroup001:10305"]
  to   = citrixadc_csaction.port["cs:artera1:portgroup001:10305"]
}

moved {
  from = citrixadc_csaction.port["artera1:portgroup001:10306"]
  to   = citrixadc_csaction.port["cs:artera1:portgroup001:10306"]
}

moved {
  from = citrixadc_csaction.port["artera1:portgroup001:10307"]
  to   = citrixadc_csaction.port["cs:artera1:portgroup001:10307"]
}

moved {
  from = citrixadc_csaction.port["artera1:portgroup001:10309"]
  to   = citrixadc_csaction.port["cs:artera1:portgroup001:10309"]
}

moved {
  from = citrixadc_csaction.port["artera1:portgroup002:10308"]
  to   = citrixadc_csaction.port["cs:artera1:portgroup002:10308"]
}

moved {
  from = citrixadc_csaction.port["fgtera1:portgroup001:10401"]
  to   = citrixadc_csaction.port["cs:fgtera1:portgroup001:10401"]
}

moved {
  from = citrixadc_csaction.port["fgtera1:portgroup001:10402"]
  to   = citrixadc_csaction.port["cs:fgtera1:portgroup001:10402"]
}

moved {
  from = citrixadc_csaction.port["fgtera1:portgroup001:10403"]
  to   = citrixadc_csaction.port["cs:fgtera1:portgroup001:10403"]
}

moved {
  from = citrixadc_csaction.port["fgtera1:portgroup001:10404"]
  to   = citrixadc_csaction.port["cs:fgtera1:portgroup001:10404"]
}

moved {
  from = citrixadc_csaction.port["fgtera1:portgroup001:10405"]
  to   = citrixadc_csaction.port["cs:fgtera1:portgroup001:10405"]
}

moved {
  from = citrixadc_csaction.port["fgtera1:portgroup001:10406"]
  to   = citrixadc_csaction.port["cs:fgtera1:portgroup001:10406"]
}

moved {
  from = citrixadc_csaction.port["fgtera1:portgroup001:10407"]
  to   = citrixadc_csaction.port["cs:fgtera1:portgroup001:10407"]
}

moved {
  from = citrixadc_csaction.port["fgtera1:portgroup001:10409"]
  to   = citrixadc_csaction.port["cs:fgtera1:portgroup001:10409"]
}

moved {
  from = citrixadc_csaction.port["fgtera1:portgroup002:10408"]
  to   = citrixadc_csaction.port["cs:fgtera1:portgroup002:10408"]
}

moved {
  from = citrixadc_csaction.port["fgtera2:portgroup001:10501"]
  to   = citrixadc_csaction.port["cs:fgtera2:portgroup001:10501"]
}

moved {
  from = citrixadc_csaction.port["fgtera2:portgroup001:10502"]
  to   = citrixadc_csaction.port["cs:fgtera2:portgroup001:10502"]
}

moved {
  from = citrixadc_csaction.port["fgtera2:portgroup001:10503"]
  to   = citrixadc_csaction.port["cs:fgtera2:portgroup001:10503"]
}

moved {
  from = citrixadc_csaction.port["fgtera2:portgroup001:10504"]
  to   = citrixadc_csaction.port["cs:fgtera2:portgroup001:10504"]
}

moved {
  from = citrixadc_csaction.port["fgtera2:portgroup001:10505"]
  to   = citrixadc_csaction.port["cs:fgtera2:portgroup001:10505"]
}

moved {
  from = citrixadc_csaction.port["fgtera2:portgroup001:10506"]
  to   = citrixadc_csaction.port["cs:fgtera2:portgroup001:10506"]
}

moved {
  from = citrixadc_csaction.port["fgtera2:portgroup001:10507"]
  to   = citrixadc_csaction.port["cs:fgtera2:portgroup001:10507"]
}

moved {
  from = citrixadc_csaction.port["fgtera2:portgroup001:10509"]
  to   = citrixadc_csaction.port["cs:fgtera2:portgroup001:10509"]
}

moved {
  from = citrixadc_csaction.port["fgtera2:portgroup002:10508"]
  to   = citrixadc_csaction.port["cs:fgtera2:portgroup002:10508"]
}

moved {
  from = citrixadc_cspolicy.port["artera1:portgroup001:10301"]
  to   = citrixadc_cspolicy.port["cs:artera1:portgroup001:10301"]
}

moved {
  from = citrixadc_cspolicy.port["artera1:portgroup001:10302"]
  to   = citrixadc_cspolicy.port["cs:artera1:portgroup001:10302"]
}

moved {
  from = citrixadc_cspolicy.port["artera1:portgroup001:10303"]
  to   = citrixadc_cspolicy.port["cs:artera1:portgroup001:10303"]
}

moved {
  from = citrixadc_cspolicy.port["artera1:portgroup001:10304"]
  to   = citrixadc_cspolicy.port["cs:artera1:portgroup001:10304"]
}

moved {
  from = citrixadc_cspolicy.port["artera1:portgroup001:10305"]
  to   = citrixadc_cspolicy.port["cs:artera1:portgroup001:10305"]
}

moved {
  from = citrixadc_cspolicy.port["artera1:portgroup001:10306"]
  to   = citrixadc_cspolicy.port["cs:artera1:portgroup001:10306"]
}

moved {
  from = citrixadc_cspolicy.port["artera1:portgroup001:10307"]
  to   = citrixadc_cspolicy.port["cs:artera1:portgroup001:10307"]
}

moved {
  from = citrixadc_cspolicy.port["artera1:portgroup001:10309"]
  to   = citrixadc_cspolicy.port["cs:artera1:portgroup001:10309"]
}

moved {
  from = citrixadc_cspolicy.port["artera1:portgroup002:10308"]
  to   = citrixadc_cspolicy.port["cs:artera1:portgroup002:10308"]
}

moved {
  from = citrixadc_cspolicy.port["fgtera1:portgroup001:10401"]
  to   = citrixadc_cspolicy.port["cs:fgtera1:portgroup001:10401"]
}

moved {
  from = citrixadc_cspolicy.port["fgtera1:portgroup001:10402"]
  to   = citrixadc_cspolicy.port["cs:fgtera1:portgroup001:10402"]
}

moved {
  from = citrixadc_cspolicy.port["fgtera1:portgroup001:10403"]
  to   = citrixadc_cspolicy.port["cs:fgtera1:portgroup001:10403"]
}

moved {
  from = citrixadc_cspolicy.port["fgtera1:portgroup001:10404"]
  to   = citrixadc_cspolicy.port["cs:fgtera1:portgroup001:10404"]
}

moved {
  from = citrixadc_cspolicy.port["fgtera1:portgroup001:10405"]
  to   = citrixadc_cspolicy.port["cs:fgtera1:portgroup001:10405"]
}

moved {
  from = citrixadc_cspolicy.port["fgtera1:portgroup001:10406"]
  to   = citrixadc_cspolicy.port["cs:fgtera1:portgroup001:10406"]
}

moved {
  from = citrixadc_cspolicy.port["fgtera1:portgroup001:10407"]
  to   = citrixadc_cspolicy.port["cs:fgtera1:portgroup001:10407"]
}

moved {
  from = citrixadc_cspolicy.port["fgtera1:portgroup001:10409"]
  to   = citrixadc_cspolicy.port["cs:fgtera1:portgroup001:10409"]
}

moved {
  from = citrixadc_cspolicy.port["fgtera1:portgroup002:10408"]
  to   = citrixadc_cspolicy.port["cs:fgtera1:portgroup002:10408"]
}

moved {
  from = citrixadc_cspolicy.port["fgtera2:portgroup001:10501"]
  to   = citrixadc_cspolicy.port["cs:fgtera2:portgroup001:10501"]
}

moved {
  from = citrixadc_cspolicy.port["fgtera2:portgroup001:10502"]
  to   = citrixadc_cspolicy.port["cs:fgtera2:portgroup001:10502"]
}

moved {
  from = citrixadc_cspolicy.port["fgtera2:portgroup001:10503"]
  to   = citrixadc_cspolicy.port["cs:fgtera2:portgroup001:10503"]
}

moved {
  from = citrixadc_cspolicy.port["fgtera2:portgroup001:10504"]
  to   = citrixadc_cspolicy.port["cs:fgtera2:portgroup001:10504"]
}

moved {
  from = citrixadc_cspolicy.port["fgtera2:portgroup001:10505"]
  to   = citrixadc_cspolicy.port["cs:fgtera2:portgroup001:10505"]
}

moved {
  from = citrixadc_cspolicy.port["fgtera2:portgroup001:10506"]
  to   = citrixadc_cspolicy.port["cs:fgtera2:portgroup001:10506"]
}

moved {
  from = citrixadc_cspolicy.port["fgtera2:portgroup001:10507"]
  to   = citrixadc_cspolicy.port["cs:fgtera2:portgroup001:10507"]
}

moved {
  from = citrixadc_cspolicy.port["fgtera2:portgroup001:10509"]
  to   = citrixadc_cspolicy.port["cs:fgtera2:portgroup001:10509"]
}

moved {
  from = citrixadc_cspolicy.port["fgtera2:portgroup002:10508"]
  to   = citrixadc_cspolicy.port["cs:fgtera2:portgroup002:10508"]
}

moved {
  from = citrixadc_csvserver_cspolicy_binding.port["artera1:portgroup001:10301"]
  to   = citrixadc_csvserver_cspolicy_binding.port["cs:artera1:portgroup001:10301"]
}

moved {
  from = citrixadc_csvserver_cspolicy_binding.port["artera1:portgroup001:10302"]
  to   = citrixadc_csvserver_cspolicy_binding.port["cs:artera1:portgroup001:10302"]
}

moved {
  from = citrixadc_csvserver_cspolicy_binding.port["artera1:portgroup001:10303"]
  to   = citrixadc_csvserver_cspolicy_binding.port["cs:artera1:portgroup001:10303"]
}

moved {
  from = citrixadc_csvserver_cspolicy_binding.port["artera1:portgroup001:10304"]
  to   = citrixadc_csvserver_cspolicy_binding.port["cs:artera1:portgroup001:10304"]
}

moved {
  from = citrixadc_csvserver_cspolicy_binding.port["artera1:portgroup001:10305"]
  to   = citrixadc_csvserver_cspolicy_binding.port["cs:artera1:portgroup001:10305"]
}

moved {
  from = citrixadc_csvserver_cspolicy_binding.port["artera1:portgroup001:10306"]
  to   = citrixadc_csvserver_cspolicy_binding.port["cs:artera1:portgroup001:10306"]
}

moved {
  from = citrixadc_csvserver_cspolicy_binding.port["artera1:portgroup001:10307"]
  to   = citrixadc_csvserver_cspolicy_binding.port["cs:artera1:portgroup001:10307"]
}

moved {
  from = citrixadc_csvserver_cspolicy_binding.port["artera1:portgroup001:10309"]
  to   = citrixadc_csvserver_cspolicy_binding.port["cs:artera1:portgroup001:10309"]
}

moved {
  from = citrixadc_csvserver_cspolicy_binding.port["artera1:portgroup002:10308"]
  to   = citrixadc_csvserver_cspolicy_binding.port["cs:artera1:portgroup002:10308"]
}

moved {
  from = citrixadc_csvserver_cspolicy_binding.port["fgtera1:portgroup001:10401"]
  to   = citrixadc_csvserver_cspolicy_binding.port["cs:fgtera1:portgroup001:10401"]
}

moved {
  from = citrixadc_csvserver_cspolicy_binding.port["fgtera1:portgroup001:10402"]
  to   = citrixadc_csvserver_cspolicy_binding.port["cs:fgtera1:portgroup001:10402"]
}

moved {
  from = citrixadc_csvserver_cspolicy_binding.port["fgtera1:portgroup001:10403"]
  to   = citrixadc_csvserver_cspolicy_binding.port["cs:fgtera1:portgroup001:10403"]
}

moved {
  from = citrixadc_csvserver_cspolicy_binding.port["fgtera1:portgroup001:10404"]
  to   = citrixadc_csvserver_cspolicy_binding.port["cs:fgtera1:portgroup001:10404"]
}

moved {
  from = citrixadc_csvserver_cspolicy_binding.port["fgtera1:portgroup001:10405"]
  to   = citrixadc_csvserver_cspolicy_binding.port["cs:fgtera1:portgroup001:10405"]
}

moved {
  from = citrixadc_csvserver_cspolicy_binding.port["fgtera1:portgroup001:10406"]
  to   = citrixadc_csvserver_cspolicy_binding.port["cs:fgtera1:portgroup001:10406"]
}

moved {
  from = citrixadc_csvserver_cspolicy_binding.port["fgtera1:portgroup001:10407"]
  to   = citrixadc_csvserver_cspolicy_binding.port["cs:fgtera1:portgroup001:10407"]
}

moved {
  from = citrixadc_csvserver_cspolicy_binding.port["fgtera1:portgroup001:10409"]
  to   = citrixadc_csvserver_cspolicy_binding.port["cs:fgtera1:portgroup001:10409"]
}

moved {
  from = citrixadc_csvserver_cspolicy_binding.port["fgtera1:portgroup002:10408"]
  to   = citrixadc_csvserver_cspolicy_binding.port["cs:fgtera1:portgroup002:10408"]
}

moved {
  from = citrixadc_csvserver_cspolicy_binding.port["fgtera2:portgroup001:10501"]
  to   = citrixadc_csvserver_cspolicy_binding.port["cs:fgtera2:portgroup001:10501"]
}

moved {
  from = citrixadc_csvserver_cspolicy_binding.port["fgtera2:portgroup001:10502"]
  to   = citrixadc_csvserver_cspolicy_binding.port["cs:fgtera2:portgroup001:10502"]
}

moved {
  from = citrixadc_csvserver_cspolicy_binding.port["fgtera2:portgroup001:10503"]
  to   = citrixadc_csvserver_cspolicy_binding.port["cs:fgtera2:portgroup001:10503"]
}

moved {
  from = citrixadc_csvserver_cspolicy_binding.port["fgtera2:portgroup001:10504"]
  to   = citrixadc_csvserver_cspolicy_binding.port["cs:fgtera2:portgroup001:10504"]
}

moved {
  from = citrixadc_csvserver_cspolicy_binding.port["fgtera2:portgroup001:10505"]
  to   = citrixadc_csvserver_cspolicy_binding.port["cs:fgtera2:portgroup001:10505"]
}

moved {
  from = citrixadc_csvserver_cspolicy_binding.port["fgtera2:portgroup001:10506"]
  to   = citrixadc_csvserver_cspolicy_binding.port["cs:fgtera2:portgroup001:10506"]
}

moved {
  from = citrixadc_csvserver_cspolicy_binding.port["fgtera2:portgroup001:10507"]
  to   = citrixadc_csvserver_cspolicy_binding.port["cs:fgtera2:portgroup001:10507"]
}

moved {
  from = citrixadc_csvserver_cspolicy_binding.port["fgtera2:portgroup001:10509"]
  to   = citrixadc_csvserver_cspolicy_binding.port["cs:fgtera2:portgroup001:10509"]
}

moved {
  from = citrixadc_csvserver_cspolicy_binding.port["fgtera2:portgroup002:10508"]
  to   = citrixadc_csvserver_cspolicy_binding.port["cs:fgtera2:portgroup002:10508"]
}

moved {
  from = citrixadc_lbvserver.local["artera1:portgroup001:10301"]
  to   = citrixadc_lbvserver.local["cs:artera1:portgroup001:10301"]
}

moved {
  from = citrixadc_lbvserver.local["artera1:portgroup001:10302"]
  to   = citrixadc_lbvserver.local["cs:artera1:portgroup001:10302"]
}

moved {
  from = citrixadc_lbvserver.local["artera1:portgroup001:10303"]
  to   = citrixadc_lbvserver.local["cs:artera1:portgroup001:10303"]
}

moved {
  from = citrixadc_lbvserver.local["artera1:portgroup001:10304"]
  to   = citrixadc_lbvserver.local["cs:artera1:portgroup001:10304"]
}

moved {
  from = citrixadc_lbvserver.local["artera1:portgroup001:10305"]
  to   = citrixadc_lbvserver.local["cs:artera1:portgroup001:10305"]
}

moved {
  from = citrixadc_lbvserver.local["artera1:portgroup001:10306"]
  to   = citrixadc_lbvserver.local["cs:artera1:portgroup001:10306"]
}

moved {
  from = citrixadc_lbvserver.local["artera1:portgroup001:10307"]
  to   = citrixadc_lbvserver.local["cs:artera1:portgroup001:10307"]
}

moved {
  from = citrixadc_lbvserver.local["artera1:portgroup001:10309"]
  to   = citrixadc_lbvserver.local["cs:artera1:portgroup001:10309"]
}

moved {
  from = citrixadc_lbvserver.local["artera1:portgroup002:10308"]
  to   = citrixadc_lbvserver.local["cs:artera1:portgroup002:10308"]
}

moved {
  from = citrixadc_lbvserver.local["fgtera1:portgroup001:10401"]
  to   = citrixadc_lbvserver.local["cs:fgtera1:portgroup001:10401"]
}

moved {
  from = citrixadc_lbvserver.local["fgtera1:portgroup001:10402"]
  to   = citrixadc_lbvserver.local["cs:fgtera1:portgroup001:10402"]
}

moved {
  from = citrixadc_lbvserver.local["fgtera1:portgroup001:10403"]
  to   = citrixadc_lbvserver.local["cs:fgtera1:portgroup001:10403"]
}

moved {
  from = citrixadc_lbvserver.local["fgtera1:portgroup001:10404"]
  to   = citrixadc_lbvserver.local["cs:fgtera1:portgroup001:10404"]
}

moved {
  from = citrixadc_lbvserver.local["fgtera1:portgroup001:10405"]
  to   = citrixadc_lbvserver.local["cs:fgtera1:portgroup001:10405"]
}

moved {
  from = citrixadc_lbvserver.local["fgtera1:portgroup001:10406"]
  to   = citrixadc_lbvserver.local["cs:fgtera1:portgroup001:10406"]
}

moved {
  from = citrixadc_lbvserver.local["fgtera1:portgroup001:10407"]
  to   = citrixadc_lbvserver.local["cs:fgtera1:portgroup001:10407"]
}

moved {
  from = citrixadc_lbvserver.local["fgtera1:portgroup001:10409"]
  to   = citrixadc_lbvserver.local["cs:fgtera1:portgroup001:10409"]
}

moved {
  from = citrixadc_lbvserver.local["fgtera1:portgroup002:10408"]
  to   = citrixadc_lbvserver.local["cs:fgtera1:portgroup002:10408"]
}

moved {
  from = citrixadc_lbvserver.local["fgtera2:portgroup001:10501"]
  to   = citrixadc_lbvserver.local["cs:fgtera2:portgroup001:10501"]
}

moved {
  from = citrixadc_lbvserver.local["fgtera2:portgroup001:10502"]
  to   = citrixadc_lbvserver.local["cs:fgtera2:portgroup001:10502"]
}

moved {
  from = citrixadc_lbvserver.local["fgtera2:portgroup001:10503"]
  to   = citrixadc_lbvserver.local["cs:fgtera2:portgroup001:10503"]
}

moved {
  from = citrixadc_lbvserver.local["fgtera2:portgroup001:10504"]
  to   = citrixadc_lbvserver.local["cs:fgtera2:portgroup001:10504"]
}

moved {
  from = citrixadc_lbvserver.local["fgtera2:portgroup001:10505"]
  to   = citrixadc_lbvserver.local["cs:fgtera2:portgroup001:10505"]
}

moved {
  from = citrixadc_lbvserver.local["fgtera2:portgroup001:10506"]
  to   = citrixadc_lbvserver.local["cs:fgtera2:portgroup001:10506"]
}

moved {
  from = citrixadc_lbvserver.local["fgtera2:portgroup001:10507"]
  to   = citrixadc_lbvserver.local["cs:fgtera2:portgroup001:10507"]
}

moved {
  from = citrixadc_lbvserver.local["fgtera2:portgroup001:10509"]
  to   = citrixadc_lbvserver.local["cs:fgtera2:portgroup001:10509"]
}

moved {
  from = citrixadc_lbvserver.local["fgtera2:portgroup002:10508"]
  to   = citrixadc_lbvserver.local["cs:fgtera2:portgroup002:10508"]
}

moved {
  from = citrixadc_lbvserver.remote["artera1:portgroup001:10301"]
  to   = citrixadc_lbvserver.remote["cs:artera1:portgroup001:10301"]
}

moved {
  from = citrixadc_lbvserver.remote["artera1:portgroup001:10302"]
  to   = citrixadc_lbvserver.remote["cs:artera1:portgroup001:10302"]
}

moved {
  from = citrixadc_lbvserver.remote["artera1:portgroup001:10303"]
  to   = citrixadc_lbvserver.remote["cs:artera1:portgroup001:10303"]
}

moved {
  from = citrixadc_lbvserver.remote["artera1:portgroup001:10304"]
  to   = citrixadc_lbvserver.remote["cs:artera1:portgroup001:10304"]
}

moved {
  from = citrixadc_lbvserver.remote["artera1:portgroup001:10305"]
  to   = citrixadc_lbvserver.remote["cs:artera1:portgroup001:10305"]
}

moved {
  from = citrixadc_lbvserver.remote["artera1:portgroup001:10306"]
  to   = citrixadc_lbvserver.remote["cs:artera1:portgroup001:10306"]
}

moved {
  from = citrixadc_lbvserver.remote["artera1:portgroup001:10307"]
  to   = citrixadc_lbvserver.remote["cs:artera1:portgroup001:10307"]
}

moved {
  from = citrixadc_lbvserver.remote["artera1:portgroup001:10309"]
  to   = citrixadc_lbvserver.remote["cs:artera1:portgroup001:10309"]
}

moved {
  from = citrixadc_lbvserver.remote["fgtera1:portgroup001:10401"]
  to   = citrixadc_lbvserver.remote["cs:fgtera1:portgroup001:10401"]
}

moved {
  from = citrixadc_lbvserver.remote["fgtera1:portgroup001:10402"]
  to   = citrixadc_lbvserver.remote["cs:fgtera1:portgroup001:10402"]
}

moved {
  from = citrixadc_lbvserver.remote["fgtera1:portgroup001:10403"]
  to   = citrixadc_lbvserver.remote["cs:fgtera1:portgroup001:10403"]
}

moved {
  from = citrixadc_lbvserver.remote["fgtera1:portgroup001:10404"]
  to   = citrixadc_lbvserver.remote["cs:fgtera1:portgroup001:10404"]
}

moved {
  from = citrixadc_lbvserver.remote["fgtera1:portgroup001:10405"]
  to   = citrixadc_lbvserver.remote["cs:fgtera1:portgroup001:10405"]
}

moved {
  from = citrixadc_lbvserver.remote["fgtera1:portgroup001:10406"]
  to   = citrixadc_lbvserver.remote["cs:fgtera1:portgroup001:10406"]
}

moved {
  from = citrixadc_lbvserver.remote["fgtera1:portgroup001:10407"]
  to   = citrixadc_lbvserver.remote["cs:fgtera1:portgroup001:10407"]
}

moved {
  from = citrixadc_lbvserver.remote["fgtera1:portgroup001:10409"]
  to   = citrixadc_lbvserver.remote["cs:fgtera1:portgroup001:10409"]
}

moved {
  from = citrixadc_lbvserver.remote["fgtera2:portgroup001:10501"]
  to   = citrixadc_lbvserver.remote["cs:fgtera2:portgroup001:10501"]
}

moved {
  from = citrixadc_lbvserver.remote["fgtera2:portgroup001:10502"]
  to   = citrixadc_lbvserver.remote["cs:fgtera2:portgroup001:10502"]
}

moved {
  from = citrixadc_lbvserver.remote["fgtera2:portgroup001:10503"]
  to   = citrixadc_lbvserver.remote["cs:fgtera2:portgroup001:10503"]
}

moved {
  from = citrixadc_lbvserver.remote["fgtera2:portgroup001:10504"]
  to   = citrixadc_lbvserver.remote["cs:fgtera2:portgroup001:10504"]
}

moved {
  from = citrixadc_lbvserver.remote["fgtera2:portgroup001:10505"]
  to   = citrixadc_lbvserver.remote["cs:fgtera2:portgroup001:10505"]
}

moved {
  from = citrixadc_lbvserver.remote["fgtera2:portgroup001:10506"]
  to   = citrixadc_lbvserver.remote["cs:fgtera2:portgroup001:10506"]
}

moved {
  from = citrixadc_lbvserver.remote["fgtera2:portgroup001:10507"]
  to   = citrixadc_lbvserver.remote["cs:fgtera2:portgroup001:10507"]
}

moved {
  from = citrixadc_lbvserver.remote["fgtera2:portgroup001:10509"]
  to   = citrixadc_lbvserver.remote["cs:fgtera2:portgroup001:10509"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.local["artera1:portgroup001:10301"]
  to   = citrixadc_lbvserver_servicegroup_binding.local["cs:artera1:portgroup001:10301"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.local["artera1:portgroup001:10302"]
  to   = citrixadc_lbvserver_servicegroup_binding.local["cs:artera1:portgroup001:10302"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.local["artera1:portgroup001:10303"]
  to   = citrixadc_lbvserver_servicegroup_binding.local["cs:artera1:portgroup001:10303"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.local["artera1:portgroup001:10304"]
  to   = citrixadc_lbvserver_servicegroup_binding.local["cs:artera1:portgroup001:10304"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.local["artera1:portgroup001:10305"]
  to   = citrixadc_lbvserver_servicegroup_binding.local["cs:artera1:portgroup001:10305"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.local["artera1:portgroup001:10306"]
  to   = citrixadc_lbvserver_servicegroup_binding.local["cs:artera1:portgroup001:10306"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.local["artera1:portgroup001:10307"]
  to   = citrixadc_lbvserver_servicegroup_binding.local["cs:artera1:portgroup001:10307"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.local["artera1:portgroup001:10309"]
  to   = citrixadc_lbvserver_servicegroup_binding.local["cs:artera1:portgroup001:10309"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.local["artera1:portgroup002:10308"]
  to   = citrixadc_lbvserver_servicegroup_binding.local["cs:artera1:portgroup002:10308"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.local["fgtera1:portgroup001:10401"]
  to   = citrixadc_lbvserver_servicegroup_binding.local["cs:fgtera1:portgroup001:10401"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.local["fgtera1:portgroup001:10402"]
  to   = citrixadc_lbvserver_servicegroup_binding.local["cs:fgtera1:portgroup001:10402"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.local["fgtera1:portgroup001:10403"]
  to   = citrixadc_lbvserver_servicegroup_binding.local["cs:fgtera1:portgroup001:10403"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.local["fgtera1:portgroup001:10404"]
  to   = citrixadc_lbvserver_servicegroup_binding.local["cs:fgtera1:portgroup001:10404"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.local["fgtera1:portgroup001:10405"]
  to   = citrixadc_lbvserver_servicegroup_binding.local["cs:fgtera1:portgroup001:10405"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.local["fgtera1:portgroup001:10406"]
  to   = citrixadc_lbvserver_servicegroup_binding.local["cs:fgtera1:portgroup001:10406"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.local["fgtera1:portgroup001:10407"]
  to   = citrixadc_lbvserver_servicegroup_binding.local["cs:fgtera1:portgroup001:10407"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.local["fgtera1:portgroup001:10409"]
  to   = citrixadc_lbvserver_servicegroup_binding.local["cs:fgtera1:portgroup001:10409"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.local["fgtera1:portgroup002:10408"]
  to   = citrixadc_lbvserver_servicegroup_binding.local["cs:fgtera1:portgroup002:10408"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.local["fgtera2:portgroup001:10501"]
  to   = citrixadc_lbvserver_servicegroup_binding.local["cs:fgtera2:portgroup001:10501"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.local["fgtera2:portgroup001:10502"]
  to   = citrixadc_lbvserver_servicegroup_binding.local["cs:fgtera2:portgroup001:10502"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.local["fgtera2:portgroup001:10503"]
  to   = citrixadc_lbvserver_servicegroup_binding.local["cs:fgtera2:portgroup001:10503"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.local["fgtera2:portgroup001:10504"]
  to   = citrixadc_lbvserver_servicegroup_binding.local["cs:fgtera2:portgroup001:10504"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.local["fgtera2:portgroup001:10505"]
  to   = citrixadc_lbvserver_servicegroup_binding.local["cs:fgtera2:portgroup001:10505"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.local["fgtera2:portgroup001:10506"]
  to   = citrixadc_lbvserver_servicegroup_binding.local["cs:fgtera2:portgroup001:10506"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.local["fgtera2:portgroup001:10507"]
  to   = citrixadc_lbvserver_servicegroup_binding.local["cs:fgtera2:portgroup001:10507"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.local["fgtera2:portgroup001:10509"]
  to   = citrixadc_lbvserver_servicegroup_binding.local["cs:fgtera2:portgroup001:10509"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.local["fgtera2:portgroup002:10508"]
  to   = citrixadc_lbvserver_servicegroup_binding.local["cs:fgtera2:portgroup002:10508"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.remote["artera1:portgroup001:10301"]
  to   = citrixadc_lbvserver_servicegroup_binding.remote["cs:artera1:portgroup001:10301"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.remote["artera1:portgroup001:10302"]
  to   = citrixadc_lbvserver_servicegroup_binding.remote["cs:artera1:portgroup001:10302"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.remote["artera1:portgroup001:10303"]
  to   = citrixadc_lbvserver_servicegroup_binding.remote["cs:artera1:portgroup001:10303"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.remote["artera1:portgroup001:10304"]
  to   = citrixadc_lbvserver_servicegroup_binding.remote["cs:artera1:portgroup001:10304"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.remote["artera1:portgroup001:10305"]
  to   = citrixadc_lbvserver_servicegroup_binding.remote["cs:artera1:portgroup001:10305"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.remote["artera1:portgroup001:10306"]
  to   = citrixadc_lbvserver_servicegroup_binding.remote["cs:artera1:portgroup001:10306"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.remote["artera1:portgroup001:10307"]
  to   = citrixadc_lbvserver_servicegroup_binding.remote["cs:artera1:portgroup001:10307"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.remote["artera1:portgroup001:10309"]
  to   = citrixadc_lbvserver_servicegroup_binding.remote["cs:artera1:portgroup001:10309"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.remote["fgtera1:portgroup001:10401"]
  to   = citrixadc_lbvserver_servicegroup_binding.remote["cs:fgtera1:portgroup001:10401"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.remote["fgtera1:portgroup001:10402"]
  to   = citrixadc_lbvserver_servicegroup_binding.remote["cs:fgtera1:portgroup001:10402"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.remote["fgtera1:portgroup001:10403"]
  to   = citrixadc_lbvserver_servicegroup_binding.remote["cs:fgtera1:portgroup001:10403"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.remote["fgtera1:portgroup001:10404"]
  to   = citrixadc_lbvserver_servicegroup_binding.remote["cs:fgtera1:portgroup001:10404"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.remote["fgtera1:portgroup001:10405"]
  to   = citrixadc_lbvserver_servicegroup_binding.remote["cs:fgtera1:portgroup001:10405"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.remote["fgtera1:portgroup001:10406"]
  to   = citrixadc_lbvserver_servicegroup_binding.remote["cs:fgtera1:portgroup001:10406"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.remote["fgtera1:portgroup001:10407"]
  to   = citrixadc_lbvserver_servicegroup_binding.remote["cs:fgtera1:portgroup001:10407"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.remote["fgtera1:portgroup001:10409"]
  to   = citrixadc_lbvserver_servicegroup_binding.remote["cs:fgtera1:portgroup001:10409"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.remote["fgtera2:portgroup001:10501"]
  to   = citrixadc_lbvserver_servicegroup_binding.remote["cs:fgtera2:portgroup001:10501"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.remote["fgtera2:portgroup001:10502"]
  to   = citrixadc_lbvserver_servicegroup_binding.remote["cs:fgtera2:portgroup001:10502"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.remote["fgtera2:portgroup001:10503"]
  to   = citrixadc_lbvserver_servicegroup_binding.remote["cs:fgtera2:portgroup001:10503"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.remote["fgtera2:portgroup001:10504"]
  to   = citrixadc_lbvserver_servicegroup_binding.remote["cs:fgtera2:portgroup001:10504"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.remote["fgtera2:portgroup001:10505"]
  to   = citrixadc_lbvserver_servicegroup_binding.remote["cs:fgtera2:portgroup001:10505"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.remote["fgtera2:portgroup001:10506"]
  to   = citrixadc_lbvserver_servicegroup_binding.remote["cs:fgtera2:portgroup001:10506"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.remote["fgtera2:portgroup001:10507"]
  to   = citrixadc_lbvserver_servicegroup_binding.remote["cs:fgtera2:portgroup001:10507"]
}

moved {
  from = citrixadc_lbvserver_servicegroup_binding.remote["fgtera2:portgroup001:10509"]
  to   = citrixadc_lbvserver_servicegroup_binding.remote["cs:fgtera2:portgroup001:10509"]
}

moved {
  from = citrixadc_servicegroup.local["artera1:portgroup001:10301"]
  to   = citrixadc_servicegroup.local["cs:artera1:portgroup001:10301"]
}

moved {
  from = citrixadc_servicegroup.local["artera1:portgroup001:10302"]
  to   = citrixadc_servicegroup.local["cs:artera1:portgroup001:10302"]
}

moved {
  from = citrixadc_servicegroup.local["artera1:portgroup001:10303"]
  to   = citrixadc_servicegroup.local["cs:artera1:portgroup001:10303"]
}

moved {
  from = citrixadc_servicegroup.local["artera1:portgroup001:10304"]
  to   = citrixadc_servicegroup.local["cs:artera1:portgroup001:10304"]
}

moved {
  from = citrixadc_servicegroup.local["artera1:portgroup001:10305"]
  to   = citrixadc_servicegroup.local["cs:artera1:portgroup001:10305"]
}

moved {
  from = citrixadc_servicegroup.local["artera1:portgroup001:10306"]
  to   = citrixadc_servicegroup.local["cs:artera1:portgroup001:10306"]
}

moved {
  from = citrixadc_servicegroup.local["artera1:portgroup001:10307"]
  to   = citrixadc_servicegroup.local["cs:artera1:portgroup001:10307"]
}

moved {
  from = citrixadc_servicegroup.local["artera1:portgroup001:10309"]
  to   = citrixadc_servicegroup.local["cs:artera1:portgroup001:10309"]
}

moved {
  from = citrixadc_servicegroup.local["artera1:portgroup002:10308"]
  to   = citrixadc_servicegroup.local["cs:artera1:portgroup002:10308"]
}

moved {
  from = citrixadc_servicegroup.local["fgtera1:portgroup001:10401"]
  to   = citrixadc_servicegroup.local["cs:fgtera1:portgroup001:10401"]
}

moved {
  from = citrixadc_servicegroup.local["fgtera1:portgroup001:10402"]
  to   = citrixadc_servicegroup.local["cs:fgtera1:portgroup001:10402"]
}

moved {
  from = citrixadc_servicegroup.local["fgtera1:portgroup001:10403"]
  to   = citrixadc_servicegroup.local["cs:fgtera1:portgroup001:10403"]
}

moved {
  from = citrixadc_servicegroup.local["fgtera1:portgroup001:10404"]
  to   = citrixadc_servicegroup.local["cs:fgtera1:portgroup001:10404"]
}

moved {
  from = citrixadc_servicegroup.local["fgtera1:portgroup001:10405"]
  to   = citrixadc_servicegroup.local["cs:fgtera1:portgroup001:10405"]
}

moved {
  from = citrixadc_servicegroup.local["fgtera1:portgroup001:10406"]
  to   = citrixadc_servicegroup.local["cs:fgtera1:portgroup001:10406"]
}

moved {
  from = citrixadc_servicegroup.local["fgtera1:portgroup001:10407"]
  to   = citrixadc_servicegroup.local["cs:fgtera1:portgroup001:10407"]
}

moved {
  from = citrixadc_servicegroup.local["fgtera1:portgroup001:10409"]
  to   = citrixadc_servicegroup.local["cs:fgtera1:portgroup001:10409"]
}

moved {
  from = citrixadc_servicegroup.local["fgtera1:portgroup002:10408"]
  to   = citrixadc_servicegroup.local["cs:fgtera1:portgroup002:10408"]
}

moved {
  from = citrixadc_servicegroup.local["fgtera2:portgroup001:10501"]
  to   = citrixadc_servicegroup.local["cs:fgtera2:portgroup001:10501"]
}

moved {
  from = citrixadc_servicegroup.local["fgtera2:portgroup001:10502"]
  to   = citrixadc_servicegroup.local["cs:fgtera2:portgroup001:10502"]
}

moved {
  from = citrixadc_servicegroup.local["fgtera2:portgroup001:10503"]
  to   = citrixadc_servicegroup.local["cs:fgtera2:portgroup001:10503"]
}

moved {
  from = citrixadc_servicegroup.local["fgtera2:portgroup001:10504"]
  to   = citrixadc_servicegroup.local["cs:fgtera2:portgroup001:10504"]
}

moved {
  from = citrixadc_servicegroup.local["fgtera2:portgroup001:10505"]
  to   = citrixadc_servicegroup.local["cs:fgtera2:portgroup001:10505"]
}

moved {
  from = citrixadc_servicegroup.local["fgtera2:portgroup001:10506"]
  to   = citrixadc_servicegroup.local["cs:fgtera2:portgroup001:10506"]
}

moved {
  from = citrixadc_servicegroup.local["fgtera2:portgroup001:10507"]
  to   = citrixadc_servicegroup.local["cs:fgtera2:portgroup001:10507"]
}

moved {
  from = citrixadc_servicegroup.local["fgtera2:portgroup001:10509"]
  to   = citrixadc_servicegroup.local["cs:fgtera2:portgroup001:10509"]
}

moved {
  from = citrixadc_servicegroup.local["fgtera2:portgroup002:10508"]
  to   = citrixadc_servicegroup.local["cs:fgtera2:portgroup002:10508"]
}

moved {
  from = citrixadc_servicegroup.remote["artera1:portgroup001:10301"]
  to   = citrixadc_servicegroup.remote["cs:artera1:portgroup001:10301"]
}

moved {
  from = citrixadc_servicegroup.remote["artera1:portgroup001:10302"]
  to   = citrixadc_servicegroup.remote["cs:artera1:portgroup001:10302"]
}

moved {
  from = citrixadc_servicegroup.remote["artera1:portgroup001:10303"]
  to   = citrixadc_servicegroup.remote["cs:artera1:portgroup001:10303"]
}

moved {
  from = citrixadc_servicegroup.remote["artera1:portgroup001:10304"]
  to   = citrixadc_servicegroup.remote["cs:artera1:portgroup001:10304"]
}

moved {
  from = citrixadc_servicegroup.remote["artera1:portgroup001:10305"]
  to   = citrixadc_servicegroup.remote["cs:artera1:portgroup001:10305"]
}

moved {
  from = citrixadc_servicegroup.remote["artera1:portgroup001:10306"]
  to   = citrixadc_servicegroup.remote["cs:artera1:portgroup001:10306"]
}

moved {
  from = citrixadc_servicegroup.remote["artera1:portgroup001:10307"]
  to   = citrixadc_servicegroup.remote["cs:artera1:portgroup001:10307"]
}

moved {
  from = citrixadc_servicegroup.remote["artera1:portgroup001:10309"]
  to   = citrixadc_servicegroup.remote["cs:artera1:portgroup001:10309"]
}

moved {
  from = citrixadc_servicegroup.remote["fgtera1:portgroup001:10401"]
  to   = citrixadc_servicegroup.remote["cs:fgtera1:portgroup001:10401"]
}

moved {
  from = citrixadc_servicegroup.remote["fgtera1:portgroup001:10402"]
  to   = citrixadc_servicegroup.remote["cs:fgtera1:portgroup001:10402"]
}

moved {
  from = citrixadc_servicegroup.remote["fgtera1:portgroup001:10403"]
  to   = citrixadc_servicegroup.remote["cs:fgtera1:portgroup001:10403"]
}

moved {
  from = citrixadc_servicegroup.remote["fgtera1:portgroup001:10404"]
  to   = citrixadc_servicegroup.remote["cs:fgtera1:portgroup001:10404"]
}

moved {
  from = citrixadc_servicegroup.remote["fgtera1:portgroup001:10405"]
  to   = citrixadc_servicegroup.remote["cs:fgtera1:portgroup001:10405"]
}

moved {
  from = citrixadc_servicegroup.remote["fgtera1:portgroup001:10406"]
  to   = citrixadc_servicegroup.remote["cs:fgtera1:portgroup001:10406"]
}

moved {
  from = citrixadc_servicegroup.remote["fgtera1:portgroup001:10407"]
  to   = citrixadc_servicegroup.remote["cs:fgtera1:portgroup001:10407"]
}

moved {
  from = citrixadc_servicegroup.remote["fgtera1:portgroup001:10409"]
  to   = citrixadc_servicegroup.remote["cs:fgtera1:portgroup001:10409"]
}

moved {
  from = citrixadc_servicegroup.remote["fgtera2:portgroup001:10501"]
  to   = citrixadc_servicegroup.remote["cs:fgtera2:portgroup001:10501"]
}

moved {
  from = citrixadc_servicegroup.remote["fgtera2:portgroup001:10502"]
  to   = citrixadc_servicegroup.remote["cs:fgtera2:portgroup001:10502"]
}

moved {
  from = citrixadc_servicegroup.remote["fgtera2:portgroup001:10503"]
  to   = citrixadc_servicegroup.remote["cs:fgtera2:portgroup001:10503"]
}

moved {
  from = citrixadc_servicegroup.remote["fgtera2:portgroup001:10504"]
  to   = citrixadc_servicegroup.remote["cs:fgtera2:portgroup001:10504"]
}

moved {
  from = citrixadc_servicegroup.remote["fgtera2:portgroup001:10505"]
  to   = citrixadc_servicegroup.remote["cs:fgtera2:portgroup001:10505"]
}

moved {
  from = citrixadc_servicegroup.remote["fgtera2:portgroup001:10506"]
  to   = citrixadc_servicegroup.remote["cs:fgtera2:portgroup001:10506"]
}

moved {
  from = citrixadc_servicegroup.remote["fgtera2:portgroup001:10507"]
  to   = citrixadc_servicegroup.remote["cs:fgtera2:portgroup001:10507"]
}

moved {
  from = citrixadc_servicegroup.remote["fgtera2:portgroup001:10509"]
  to   = citrixadc_servicegroup.remote["cs:fgtera2:portgroup001:10509"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["artera1:portgroup001:10301:local:srv_jurzwiese2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:artera1:portgroup001:10301:local:srv_jurzwiese2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["artera1:portgroup001:10301:local:srv_jurzwiese2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:artera1:portgroup001:10301:local:srv_jurzwiese2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["artera1:portgroup001:10302:local:srv_jurzwiese2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:artera1:portgroup001:10302:local:srv_jurzwiese2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["artera1:portgroup001:10302:local:srv_jurzwiese2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:artera1:portgroup001:10302:local:srv_jurzwiese2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["artera1:portgroup001:10303:local:srv_jurzwiese2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:artera1:portgroup001:10303:local:srv_jurzwiese2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["artera1:portgroup001:10303:local:srv_jurzwiese2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:artera1:portgroup001:10303:local:srv_jurzwiese2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["artera1:portgroup001:10304:local:srv_jurzwiese2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:artera1:portgroup001:10304:local:srv_jurzwiese2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["artera1:portgroup001:10304:local:srv_jurzwiese2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:artera1:portgroup001:10304:local:srv_jurzwiese2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["artera1:portgroup001:10305:local:srv_jurzwiese2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:artera1:portgroup001:10305:local:srv_jurzwiese2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["artera1:portgroup001:10305:local:srv_jurzwiese2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:artera1:portgroup001:10305:local:srv_jurzwiese2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["artera1:portgroup001:10306:local:srv_jurzwiese2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:artera1:portgroup001:10306:local:srv_jurzwiese2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["artera1:portgroup001:10306:local:srv_jurzwiese2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:artera1:portgroup001:10306:local:srv_jurzwiese2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["artera1:portgroup001:10307:local:srv_jurzwiese2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:artera1:portgroup001:10307:local:srv_jurzwiese2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["artera1:portgroup001:10307:local:srv_jurzwiese2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:artera1:portgroup001:10307:local:srv_jurzwiese2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["artera1:portgroup001:10309:local:srv_jurzwiese2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:artera1:portgroup001:10309:local:srv_jurzwiese2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["artera1:portgroup001:10309:local:srv_jurzwiese2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:artera1:portgroup001:10309:local:srv_jurzwiese2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["artera1:portgroup002:10308:local:srv_jurzwieseap93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:artera1:portgroup002:10308:local:srv_jurzwieseap93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera1:portgroup001:10401:local:srv_jurzwiese2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera1:portgroup001:10401:local:srv_jurzwiese2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera1:portgroup001:10401:local:srv_jurzwiese2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera1:portgroup001:10401:local:srv_jurzwiese2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera1:portgroup001:10402:local:srv_jurzwiese2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera1:portgroup001:10402:local:srv_jurzwiese2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera1:portgroup001:10402:local:srv_jurzwiese2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera1:portgroup001:10402:local:srv_jurzwiese2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera1:portgroup001:10403:local:srv_jurzwiese2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera1:portgroup001:10403:local:srv_jurzwiese2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera1:portgroup001:10403:local:srv_jurzwiese2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera1:portgroup001:10403:local:srv_jurzwiese2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera1:portgroup001:10404:local:srv_jurzwiese2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera1:portgroup001:10404:local:srv_jurzwiese2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera1:portgroup001:10404:local:srv_jurzwiese2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera1:portgroup001:10404:local:srv_jurzwiese2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera1:portgroup001:10405:local:srv_jurzwiese2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera1:portgroup001:10405:local:srv_jurzwiese2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera1:portgroup001:10405:local:srv_jurzwiese2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera1:portgroup001:10405:local:srv_jurzwiese2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera1:portgroup001:10406:local:srv_jurzwiese2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera1:portgroup001:10406:local:srv_jurzwiese2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera1:portgroup001:10406:local:srv_jurzwiese2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera1:portgroup001:10406:local:srv_jurzwiese2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera1:portgroup001:10407:local:srv_jurzwiese2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera1:portgroup001:10407:local:srv_jurzwiese2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera1:portgroup001:10407:local:srv_jurzwiese2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera1:portgroup001:10407:local:srv_jurzwiese2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera1:portgroup001:10409:local:srv_jurzwiese2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera1:portgroup001:10409:local:srv_jurzwiese2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera1:portgroup001:10409:local:srv_jurzwiese2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera1:portgroup001:10409:local:srv_jurzwiese2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera1:portgroup002:10408:local:srv_jurzwieseap93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera1:portgroup002:10408:local:srv_jurzwieseap93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera2:portgroup001:10501:local:srv_jurzwiese2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera2:portgroup001:10501:local:srv_jurzwiese2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera2:portgroup001:10501:local:srv_jurzwiese2a95"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera2:portgroup001:10501:local:srv_jurzwiese2a95"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera2:portgroup001:10502:local:srv_jurzwiese2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera2:portgroup001:10502:local:srv_jurzwiese2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera2:portgroup001:10502:local:srv_jurzwiese2a95"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera2:portgroup001:10502:local:srv_jurzwiese2a95"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera2:portgroup001:10503:local:srv_jurzwiese2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera2:portgroup001:10503:local:srv_jurzwiese2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera2:portgroup001:10503:local:srv_jurzwiese2a95"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera2:portgroup001:10503:local:srv_jurzwiese2a95"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera2:portgroup001:10504:local:srv_jurzwiese2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera2:portgroup001:10504:local:srv_jurzwiese2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera2:portgroup001:10504:local:srv_jurzwiese2a95"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera2:portgroup001:10504:local:srv_jurzwiese2a95"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera2:portgroup001:10505:local:srv_jurzwiese2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera2:portgroup001:10505:local:srv_jurzwiese2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera2:portgroup001:10505:local:srv_jurzwiese2a95"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera2:portgroup001:10505:local:srv_jurzwiese2a95"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera2:portgroup001:10506:local:srv_jurzwiese2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera2:portgroup001:10506:local:srv_jurzwiese2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera2:portgroup001:10506:local:srv_jurzwiese2a95"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera2:portgroup001:10506:local:srv_jurzwiese2a95"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera2:portgroup001:10507:local:srv_jurzwiese2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera2:portgroup001:10507:local:srv_jurzwiese2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera2:portgroup001:10507:local:srv_jurzwiese2a95"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera2:portgroup001:10507:local:srv_jurzwiese2a95"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera2:portgroup001:10509:local:srv_jurzwiese2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera2:portgroup001:10509:local:srv_jurzwiese2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera2:portgroup001:10509:local:srv_jurzwiese2a95"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera2:portgroup001:10509:local:srv_jurzwiese2a95"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.local["fgtera2:portgroup002:10508:local:srv_jurzwieseap93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.local["cs:fgtera2:portgroup002:10508:local:srv_jurzwieseap93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["artera1:portgroup001:10301:remote:srv_jurzmazse2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:artera1:portgroup001:10301:remote:srv_jurzmazse2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["artera1:portgroup001:10301:remote:srv_jurzmazse2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:artera1:portgroup001:10301:remote:srv_jurzmazse2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["artera1:portgroup001:10302:remote:srv_jurzmazse2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:artera1:portgroup001:10302:remote:srv_jurzmazse2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["artera1:portgroup001:10302:remote:srv_jurzmazse2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:artera1:portgroup001:10302:remote:srv_jurzmazse2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["artera1:portgroup001:10303:remote:srv_jurzmazse2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:artera1:portgroup001:10303:remote:srv_jurzmazse2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["artera1:portgroup001:10303:remote:srv_jurzmazse2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:artera1:portgroup001:10303:remote:srv_jurzmazse2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["artera1:portgroup001:10304:remote:srv_jurzmazse2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:artera1:portgroup001:10304:remote:srv_jurzmazse2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["artera1:portgroup001:10304:remote:srv_jurzmazse2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:artera1:portgroup001:10304:remote:srv_jurzmazse2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["artera1:portgroup001:10305:remote:srv_jurzmazse2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:artera1:portgroup001:10305:remote:srv_jurzmazse2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["artera1:portgroup001:10305:remote:srv_jurzmazse2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:artera1:portgroup001:10305:remote:srv_jurzmazse2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["artera1:portgroup001:10306:remote:srv_jurzmazse2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:artera1:portgroup001:10306:remote:srv_jurzmazse2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["artera1:portgroup001:10306:remote:srv_jurzmazse2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:artera1:portgroup001:10306:remote:srv_jurzmazse2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["artera1:portgroup001:10307:remote:srv_jurzmazse2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:artera1:portgroup001:10307:remote:srv_jurzmazse2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["artera1:portgroup001:10307:remote:srv_jurzmazse2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:artera1:portgroup001:10307:remote:srv_jurzmazse2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["artera1:portgroup001:10309:remote:srv_jurzmazse2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:artera1:portgroup001:10309:remote:srv_jurzmazse2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["artera1:portgroup001:10309:remote:srv_jurzmazse2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:artera1:portgroup001:10309:remote:srv_jurzmazse2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera1:portgroup001:10401:remote:srv_jurzmazse2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera1:portgroup001:10401:remote:srv_jurzmazse2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera1:portgroup001:10401:remote:srv_jurzmazse2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera1:portgroup001:10401:remote:srv_jurzmazse2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera1:portgroup001:10402:remote:srv_jurzmazse2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera1:portgroup001:10402:remote:srv_jurzmazse2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera1:portgroup001:10402:remote:srv_jurzmazse2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera1:portgroup001:10402:remote:srv_jurzmazse2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera1:portgroup001:10403:remote:srv_jurzmazse2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera1:portgroup001:10403:remote:srv_jurzmazse2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera1:portgroup001:10403:remote:srv_jurzmazse2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera1:portgroup001:10403:remote:srv_jurzmazse2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera1:portgroup001:10404:remote:srv_jurzmazse2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera1:portgroup001:10404:remote:srv_jurzmazse2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera1:portgroup001:10404:remote:srv_jurzmazse2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera1:portgroup001:10404:remote:srv_jurzmazse2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera1:portgroup001:10405:remote:srv_jurzmazse2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera1:portgroup001:10405:remote:srv_jurzmazse2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera1:portgroup001:10405:remote:srv_jurzmazse2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera1:portgroup001:10405:remote:srv_jurzmazse2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera1:portgroup001:10406:remote:srv_jurzmazse2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera1:portgroup001:10406:remote:srv_jurzmazse2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera1:portgroup001:10406:remote:srv_jurzmazse2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera1:portgroup001:10406:remote:srv_jurzmazse2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera1:portgroup001:10407:remote:srv_jurzmazse2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera1:portgroup001:10407:remote:srv_jurzmazse2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera1:portgroup001:10407:remote:srv_jurzmazse2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera1:portgroup001:10407:remote:srv_jurzmazse2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera1:portgroup001:10409:remote:srv_jurzmazse2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera1:portgroup001:10409:remote:srv_jurzmazse2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera1:portgroup001:10409:remote:srv_jurzmazse2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera1:portgroup001:10409:remote:srv_jurzmazse2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera2:portgroup001:10501:remote:srv_jurzmazse2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera2:portgroup001:10501:remote:srv_jurzmazse2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera2:portgroup001:10501:remote:srv_jurzmazse2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera2:portgroup001:10501:remote:srv_jurzmazse2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera2:portgroup001:10502:remote:srv_jurzmazse2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera2:portgroup001:10502:remote:srv_jurzmazse2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera2:portgroup001:10502:remote:srv_jurzmazse2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera2:portgroup001:10502:remote:srv_jurzmazse2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera2:portgroup001:10503:remote:srv_jurzmazse2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera2:portgroup001:10503:remote:srv_jurzmazse2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera2:portgroup001:10503:remote:srv_jurzmazse2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera2:portgroup001:10503:remote:srv_jurzmazse2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera2:portgroup001:10504:remote:srv_jurzmazse2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera2:portgroup001:10504:remote:srv_jurzmazse2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera2:portgroup001:10504:remote:srv_jurzmazse2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera2:portgroup001:10504:remote:srv_jurzmazse2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera2:portgroup001:10505:remote:srv_jurzmazse2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera2:portgroup001:10505:remote:srv_jurzmazse2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera2:portgroup001:10505:remote:srv_jurzmazse2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera2:portgroup001:10505:remote:srv_jurzmazse2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera2:portgroup001:10506:remote:srv_jurzmazse2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera2:portgroup001:10506:remote:srv_jurzmazse2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera2:portgroup001:10506:remote:srv_jurzmazse2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera2:portgroup001:10506:remote:srv_jurzmazse2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera2:portgroup001:10507:remote:srv_jurzmazse2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera2:portgroup001:10507:remote:srv_jurzmazse2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera2:portgroup001:10507:remote:srv_jurzmazse2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera2:portgroup001:10507:remote:srv_jurzmazse2a94"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera2:portgroup001:10509:remote:srv_jurzmazse2a93"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera2:portgroup001:10509:remote:srv_jurzmazse2a93"]
}

moved {
  from = citrixadc_servicegroup_servicegroupmember_binding.remote["fgtera2:portgroup001:10509:remote:srv_jurzmazse2a94"]
  to   = citrixadc_servicegroup_servicegroupmember_binding.remote["cs:fgtera2:portgroup001:10509:remote:srv_jurzmazse2a94"]
}
