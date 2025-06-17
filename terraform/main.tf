terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}


resource "azurerm_resource_group" "main" {
  name     = var.resource_group
  location = var.location
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.resource_group}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
}

resource "azurerm_container_app_environment" "main" {
  name                       = "${var.resource_group}-env"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
}

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
  

  identity {
  type = "SystemAssigned"
}

  ingress {
    allow_insecure_connections = false
    external_enabled          = true
    target_port              = 5000
    transport                = "http"

    traffic_weight {
      latest_revision = true
      percentage     = 100
    }
  }

  registry {
    server               = var.acr_login_server
    username             = var.acr_username
    password_secret_name = "acr-password"
  }

  secret {
    name  = "acr-password"
    value = var.acr_password
  }
}
