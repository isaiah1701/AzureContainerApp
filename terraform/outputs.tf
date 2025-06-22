output "container_app_url" {
  value = azurerm_container_app.main.latest_revision_fqdn
}
output "application_gateway_ip" {
  value = azurerm_public_ip.appgw_ip.ip_address
}
##out put values 