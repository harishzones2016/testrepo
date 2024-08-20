
locals {
  env                 = "dev"
  location              = "eastus2"
  resource_group_name = "example-rg"
  eks_name            = "demo"
  eks_version         = "1.27"
}


resource "azurerm_user_assigned_identity" "dev_test" {
  name                = "workload-test"
  location            = local.location
  resource_group_name = local.resource_group_name
}


resource "azurerm_role_assignment" "dev_test_role" {
  scope              = data.azurerm_subscription.primary.id
  role_definition_name = "Contributor"
  principal_id       = azurerm_user_assigned_identity.dev_test.principal_id
}

# Data source to get the subscription ID
data "azurerm_subscription" "primary" {
  # Optional: Specify a subscription_id if different from the default
  # subscription_id = "your-subscription-id"
}

resource "azurerm_federated_identity_credential" "dev_test" {
  name                = "workload-test-fed"
  resource_group_name = local.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
#  issuer              = "https://vstoken.dev.azure.com/27f1ee44-b8be-4a43-a438-41a870cd0125"
  issuer   =           "https://token.actions.githubusercontent.com"
  parent_id           = azurerm_user_assigned_identity.dev_test.id
  #subject             = "sc://chutankumatarani2024/matarani/workload1"
  subject             = "repo:harishzones2016/testrepo:ref:refs/heads/main"
}

# Output the client_id of the managed identity
output "managed_identity_client_id" {
  value = azurerm_user_assigned_identity.dev_test.client_id
}

# Output the object_id of the managed identity
output "managed_identity_object_id" {
  value = azurerm_user_assigned_identity.dev_test.principal_id
}
output "managed_identity_tenant_id" {
  value = azurerm_user_assigned_identity.dev_test.tenant_id
}

