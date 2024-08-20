

variable "subscription_id" {
  description = "The subscription ID where the resources will be created"
  default = "abb41ac5-f2f6-496b-ac03-bec3fd27a105"
}

variable "resource_group_name" {
  description = "The name of the resource group"
  default = "example-rg"
}

variable "location" {
  description = "The location where the resources will be created"
  default     = "eastus"
}

variable "user_assigned_identity_name" {
  description = "The name of the user-assigned managed identity"
  default     = "example-identity"
}


resource "azurerm_resource_group" "example" {
  name     = "example-rg"
  location = "eastus"
}


resource "azurerm_user_assigned_identity" "example" {
  name                = "example-identity"
  resource_group_name = "example-rg"
  location            = "eastus"
  depends_on = [
    azurerm_resource_group.example
  ]

}

resource "azurerm_role_assignment" "example" {
  principal_id   = azurerm_user_assigned_identity.example.principal_id
  role_definition_name = "Contributor"
  scope          = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"

depends_on = [
    azurerm_user_assigned_identity.example
  ]
}

resource "azurerm_federated_identity_credential" "example" {
  name                   = "github-credential"
  parent_id              = azurerm_user_assigned_identity.example.id
  resource_group_name    = azurerm_resource_group.example.name
  audience               = ["api://AzureADTokenExchange"]
  issuer                 = "https://token.actions.githubusercontent.com"
  subject                = "repo:harishzones2016/testrepo:ref:refs/heads/main"
}
