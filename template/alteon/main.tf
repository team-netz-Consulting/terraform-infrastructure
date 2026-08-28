/*
###############################################################################
# Datei      : main.tf
# Zweck      : Definition der Alteon-ADC-Ressourcen
#
# Hinweis:
# Nach jeder Aenderung den Zeitstempel in terraform_data.always_run anpassen.
###############################################################################
*/

resource "terraform_data" "always_run" {
  input = "202606111153"
}

# Schreibt die vorbereiteten Aenderungen auf das Alteon-System und speichert
# die Konfiguration bei jedem gepflegten Change erneut.
resource "alteon_apply" "apply" {
  depends_on = [terraform_data.always_run]

  lifecycle {
    replace_triggered_by = [terraform_data.always_run]
  }
}
