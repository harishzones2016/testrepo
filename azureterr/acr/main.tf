locals {
  identity_name = "example_worker"
  resource_group_name = "tutorial"
  location = "eastus2"
  namespace = "default"
  service_account_name = "test-service-account"
}

resource "azurerm_resource_group" "example" {
  name     = local.resource_group_name
  location = "eastus2"
}

resource "azurerm_kubernetes_cluster" "example" {
  name                = "aks1"
  location            = local.location
  resource_group_name = local.resource_group_name
  dns_prefix          = "aks1"
  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
    os_disk_size_gb = 30
  }
  identity {
    type = "SystemAssigned"
  }
  tags = {
    Environment = "Production"
  }

  // These two are required!
  oidc_issuer_enabled       = true
  workload_identity_enabled = true
 depends_on = [azurerm_resource_group.example]

}
/*
resource "azurerm_storage_account" "aks" {
  name                     = "chutanku"
  resource_group_name      = local.resource_group_name
  location                 = local.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "production"
  }
 depends_on = [azurerm_resource_group.example]
}

resource "azurerm_storage_share" "example" {
  name                 = "myshare"
  storage_account_name = azurerm_storage_account.aks.name
  quota                = 1
}
######kubelet-identity##
data "azurerm_user_assigned_identity" "test" {
  name                = "${azurerm_kubernetes_cluster.example.name}-agentpool"
  resource_group_name = azurerm_kubernetes_cluster.example.node_resource_group
  depends_on = [azurerm_resource_group.example,azurerm_kubernetes_cluster.example]
}


resource "azurerm_container_registry" "acr" {
  name                     = "acr42001"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  sku                      = "Standard"
  admin_enabled            = false
  depends_on = [azurerm_resource_group.example]
}
resource "azurerm_role_assignment" "acrpull_role" {
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = data.azurerm_user_assigned_identity.test.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "acrpush_role" {
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPush"
  principal_id                     = data.azurerm_user_assigned_identity.test.principal_id
  skip_service_principal_aad_check = true
}



resource "azurerm_role_assignment" "acrpull_role" {
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_user_assigned_identity.example_worker.principal_id
  skip_service_principal_aad_check = true
}

*/

#############################
resource "azurerm_user_assigned_identity" "example_worker" {
  name                = local.identity_name
  resource_group_name = local.resource_group_name
  location            = local.location
 depends_on = [azurerm_resource_group.example]
}

// Allow our identity to be assumed by a Pod in the cluster
resource "azurerm_federated_identity_credential" "example_worker" {
  name                = local.identity_name
  resource_group_name = local.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
#  issuer              = "${output.kubernetes_oidc_issuer_url}" // Use the output from above or if in the same file
  issuer              = azurerm_kubernetes_cluster.example.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.example_worker.id
  subject             = "system:serviceaccount:${local.namespace}:${local.service_account_name}"
depends_on = [azurerm_resource_group.example,azurerm_kubernetes_cluster.example]

}

output "managed_user_client_id" {
  value = azurerm_user_assigned_identity.example_worker.client_id
}

output "kubernetes_oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.example.oidc_issuer_url
}

