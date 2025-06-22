terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

# Create the main resource group to contain all resources
resource "azurerm_resource_group" "main" {
  name     = var.resource_group
  location = var.location
}

# Log Analytics workspace for Container App monitoring and diagnostics
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.resource_group}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
}

# Container App Environment - shared infrastructure for container apps
resource "azurerm_container_app_environment" "main" {
  name                       = "${var.resource_group}-env"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
}

# Main Container App hosting our Flask application
resource "azurerm_container_app" "main" {
  name                         = "devops-demo-app"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  template {
    container {
      name   = "devops-demo-app"
      image  = "${var.acr_login_server}/devops-demo-app:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  # Ingress configuration - exposes the app externally on port 5000
  ingress {
    allow_insecure_connections = false
    external_enabled          = true
    target_port              = 5000    # Flask app runs on port 5000
    transport                = "http"

    traffic_weight {
      latest_revision = true
      percentage     = 100
    }
  }

  # ACR authentication using managed secrets
  registry {
    server               = var.acr_login_server
    username             = var.acr_username
    password_secret_name = "acr-password"
  }

  # Store ACR password as a secure secret
  secret {
    name  = "acr-password"
    value = var.acr_password
  }
}

# Static public IP for Application Gateway
resource "azurerm_public_ip" "appgw_ip" {
  name                = "${var.resource_group}-agw-pip"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Virtual Network with dedicated subnet for Application Gateway
resource "azurerm_virtual_network" "main" {
  name                = "${var.resource_group}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  subnet {
    name           = "appgw-subnet"
    address_prefix = "10.0.1.0/24"
  }
}

# Application Gateway - provides SSL termination and load balancing
resource "azurerm_application_gateway" "main" {
  name                = "${var.resource_group}-agw"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  # Standard_v2 SKU for production workloads with autoscaling
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  # Gateway configuration linking to dedicated subnet
  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_virtual_network.main.subnet.*.id[0]
  }

  # HTTPS frontend port configuration
  frontend_port {
    name = "https-port"
    port = 443
  }

  # Public IP configuration for external access
  frontend_ip_configuration {
    name                 = "appgw-frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw_ip.id
  }

  # SSL certificate for HTTPS termination
  ssl_certificate {
    name     = "cf-cert"
    data     = filebase64("cloudflare-origin.pfx")
    password = var.ssl_cert_password
  }

  # Backend pool pointing to Container App FQDN
  backend_address_pool {
    name = "appgw-backend-pool"
    fqdns = [azurerm_container_app.main.latest_revision_fqdn]
  }

  # Backend settings - HTTPS connection to Container App ingress
  backend_http_settings {
    name                                = "appgw-backend-http-settings"
    cookie_based_affinity               = "Disabled"
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = 60
    pick_host_name_from_backend_address = false
    host_name                           = azurerm_container_app.main.latest_revision_fqdn
  }

  # HTTPS listener with SSL certificate
  http_listener {
    name                           = "appgw-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "https-port"
    protocol                       = "Https"
    ssl_certificate_name           = "cf-cert"
  }

  # Routing rule connecting listener to backend
  request_routing_rule {
    name                       = "appgw-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "appgw-listener"
    backend_address_pool_name  = "appgw-backend-pool"
    backend_http_settings_name = "appgw-backend-http-settings"
    priority                   = 100
  }
}



