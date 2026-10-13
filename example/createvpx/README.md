# VPX provisionieren und optional HA konfigurieren

`terraform.tfvars` enthält die VPX-Instanzen und ein optionales HA-Paar.
`ha.nodes` enthält genau zwei Schlüssel aus `vpx_instances`, z. B.
`["adc123", "adc124"]`. Die ADC-Endpunkte werden aus ihren NSIPs abgeleitet.
Diese Konfiguration setzt neue VPX im selben Netz mit den Standard-HA-
Einstellungen (Synchronisation und Propagation aktiviert, INC deaktiviert) voraus.

## Benötigte Angaben

- Zwei VPX-Namen und deren unterschiedliche, gegenseitig erreichbare NSIPs.
- Gemeinsame VPX-Zugangsdaten aus dem SDX-Profil: `adc_username`, `adc_password`.
- Gemeinsames RPC-Passwort: `rpc_node_password`.
- TLS-Prüfung: `adc_insecure_skip_verify` bei Bedarf für selbstsignierte Zertifikate.
- Optional gemeinsame SNIP und Netzmaske in `ha.snip`; `null` erzeugt keine SNIP.
- Beide VPX müssen im selben Netz liegen und HA-Kommunikation zulassen.

## Ablauf

1. `ha.enabled = false` lassen, dann `terraform init` und `terraform apply`.
2. VPX-Erstellung abschließen.
3. VPX- und RPC-Passwort eintragen, die Nodes prüfen und `ha.enabled = true` setzen.
4. `terraform plan` und `terraform apply` ausführen.

Beim HA-Apply prüft `wait_for_nitro` beide VPX mit einer authentifizierten
Abfrage von `/nitro/v1/config/nsconfig`. Die Prüfung beginnt sofort und wird
alle 25 Sekunden wiederholt; nach maximal 10 Minuten bricht sie mit einem
Fehler ab. Erst nach erfolgreicher Prüfung beider Nodes startet die
HA-Konfiguration. Auf dem Terraform-Rechner muss Python 3 installiert sein.
Änderungen oder Neuerstellungen der VPX lösen die Prüfung erneut aus.
Nach Ergänzung des Null-Providers einmal `terraform init` ausführen.

`depends_on` ersetzt keine Bereitschaftsprüfung: ADC-Provider können schon beim
Plan auf ihre Endpunkte zugreifen. Deshalb erfolgt die Erstkonfiguration in zwei
Schritten. Es werden keine Änderungen auf den Appliances ohne `apply` ausgeführt.

Die gemeinsame SNIP wird über Node 1 verwaltet. Vor dem Apply muss Node 1 der
aktive Primary sein; nach einem Failover muss die Verwaltung synchronisierter
Ressourcen auf den dann aktiven Primary angepasst werden. Für INC/different-subnet
HA wäre eine separate Netzwerkkonfiguration pro Node nötig.

`rpcnodepassword` ist ein Create-Attribut; Passwortänderungen können den HA-Peer
ersetzen. Der sensitive Wert wird im Terraform-State gespeichert.

Quellen:

- [citrixadc_hanode](https://registry.terraform.io/providers/citrix/citrixadc/latest/docs/resources/hanode)
- [citrixadc_nsip (SNIP)](https://registry.terraform.io/providers/citrix/citrixadc/latest/docs/resources/nsip)
- [citrixadc-Provider](https://registry.terraform.io/providers/citrix/citrixadc/latest/docs)
