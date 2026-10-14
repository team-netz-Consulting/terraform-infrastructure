# VPX provisionieren und optional HA konfigurieren

`terraform.tfvars` enthält die VPX-Instanzen und ein optionales HA-Paar.
`ha.nodes` enthält genau zwei Schlüssel aus `vpx_instances`, z. B.
`["adc123", "adc124"]`. Die ADC-Endpunkte werden aus ihren NSIPs abgeleitet.
Diese Konfiguration setzt neue VPX im selben Netz mit den Standard-HA-
Einstellungen (Synchronisation und Propagation aktiviert, INC deaktiviert) voraus.

## Anzahl der VPX und Ziel-SDX

Jeder Eintrag in `vpx_instances` erstellt eine VPX. Das Attribut `sdx` wählt
`"sdx1"` (Standard) oder `"sdx2"`. Die VPX-Einstellungen werden über dasselbe
Modul auf der gewählten SDX provisioniert.

- **Eine VPX:** Nur den gewünschten Eintrag in `vpx_instances` behalten und
  `ha.enabled = false` setzen. Alternativ den gesamten `ha`-Block weglassen.
- **Zwei VPX auf einer SDX:** Beide Einträge mit `sdx = "sdx1"` konfigurieren.
- **Zwei VPX auf unterschiedlichen SDX:** Einen Eintrag auf `"sdx1"`, den
  anderen auf `"sdx2"` setzen und die zweite SDX konfigurieren:

```hcl
sdx2 = {
  host                 = "https://<SDX-2-IP>"
  username             = "nsroot"
  password             = "<SDX-2-Passwort>"
  insecure_skip_verify = false
}
```

SDX 1 verwendet weiterhin `netscaler_host`, `netscaler_username`,
`netscaler_password` und `netscaler_insecure_skip_verify`. Für eine VPX nur auf
SDX 2 bleibt SDX 1 ohne Ressourcen. Image, Profil und Interfaces müssen auf der
jeweiligen Ziel-SDX existieren. Ohne HA werden keine ADC-Ressourcen und keine
NITRO-Bereitschaftsprüfung angelegt. Bei aktiviertem HA müssen beide in
`ha.nodes` genannten VPX vorhanden sein.

Nach dem Umbau `terraform init` ausführen, um das lokale Modul einzulesen.
Der `moved`-Block übernimmt bisherige VPX-State-Adressen automatisch in das
SDX-1-Modul. Eine bereits existierende VPX sollte dabei zunächst `sdx = "sdx1"`
behalten. Das Umstellen auf `"sdx2"` verschiebt keine laufende VM zwischen den
Appliances: Terraform plant dann den Abbau auf SDX 1 und die Erstellung auf
SDX 2. Vor einem Apply den Plan prüfen.

## Benötigte Angaben für HA

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
Änderungen an der VPX-Konfiguration oder ihren Ressourcen-IDs lösen die Prüfung erneut aus.
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
