resource "azurerm_resource_group" "rg" {
  name     = "maa"
  location = "East US2"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "myakscluster"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
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
 depends_on = [azurerm_resource_group.rg]

}
/*

resource "azurerm_role_assignment" "aks_contributor" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
 #principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  principal_id   = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  depends_on = [azurerm_resource_group.rg,azurerm_kubernetes_cluster.aks]
}
*/

output "aks_client_id" {
  value = azurerm_kubernetes_cluster.aks.kubelet_identity[0].client_id
}

output "aks_object_id" {
  value = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}


resource "azurerm_container_registry" "acr" {
  name                = "acr47"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  admin_enabled       = true # false
 depends_on = [azurerm_resource_group.rg,azurerm_kubernetes_cluster.aks]

}

resource "azurerm_role_assignment" "role_acrpull" {
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "role_acrpush" {
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPush"
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}




