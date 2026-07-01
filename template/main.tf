/*
###############################################################################
# Datei      : main.tf
# Zweck      : Definition der ADC-Ressourcen
#
# Änderungen
# -----------------------------------------------------------------------------
# Datum       CH-Nummer     Bearbeiter        Beschreibung
# -----------------------------------------------------------------------------
# 2026-06-11  CHM-001234     M. Schwenke       Initiale Erstellung
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
# freigegebenen Änderung (CH-Nummer).
###############################################################################
*/

resource "terraform_data" "always_run" {

  input = "202606111153"

  # Alternativ:
  # input = timestamp()
}





# Der Apply-Bereich schreibt die vorbereiteten Aenderungen auf das Alteon-
# System. Durch die Abhaengigkeit auf terraform_data.always_run wird dieser
# Schritt bei jedem gepflegten Change erneut angestossen, damit Apply und Save
# den freigegebenen Konfigurationsstand uebernehmen.

resource "alteon_apply" "apply" {
  depends_on = [
    terraform_data.always_run
  ]

  lifecycle {
    replace_triggered_by = [
      terraform_data.always_run
    ]
  }
}
