variable "resource_group" {
  default = "AzureContainerProject1-rg"
}

variable "location" {
  default = "westeurope"
}

variable "acr_name" {

}

variable "acr_login_server" {
 
}

variable "acr_username" {

}
variable "acr_password" {
    
}
variable "ssl_cert_password" {
  type        = string
  description = "Password used for the PFX file"
}



variable "custom_domain" {
  default = "azureapp.isaiahmichael.com"
}

variable "container_app_url" {
  default = "devops-demo-app--qqzrtaq.salmonocean-cb66bb50.westeurope.azurecontainerapps.io"
}
