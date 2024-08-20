locals {
  env                 = "dev"
  region              = "eastus2"
  resource_group_name = "tutorial"
  eks_name            = "demo"
  eks_version         = "1.27"
}

resource "azurerm_resource_group" "aks" {
  name     = local.resource_group_name
  location = local.region
}

resource "azurerm_storage_account" "aks" {
  name                     = "chutanku"
  resource_group_name      = azurerm_resource_group.aks.name
  location                 = azurerm_resource_group.aks.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "production"
  }
}

resource "azurerm_storage_share" "example" {
  name                 = "myshare"
  storage_account_name = azurerm_storage_account.aks.name
  quota                = 1
}


resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "aks"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = "aksdns"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2s_v3"
  }
 
   key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  identity {
    type = "SystemAssigned"
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true
 
  network_profile {
    network_plugin = "azure"
  }

}




resource "azurerm_user_assigned_identity" "dev_test" {
  name                = "dev-test"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
}

resource "azurerm_federated_identity_credential" "dev_test" {
  name                = "dev-test"
  resource_group_name = local.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks_cluster.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.dev_test.id
  subject             = "system:serviceaccount:default:my-account"

  depends_on = [azurerm_kubernetes_cluster.aks_cluster]
}

resource "azurerm_federated_identity_credential" "dev_test1" {
  name                = "dev-test1"
  resource_group_name = local.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks_cluster.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.dev_test.id
  subject             = "system:serviceaccount:external-dns:my-account"
  depends_on = [azurerm_kubernetes_cluster.aks_cluster]
}



resource "azurerm_federated_identity_credential" "dev_test2" {
  name                = "dev-test2"
  resource_group_name = local.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks_cluster.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.dev_test.id
  subject             = "system:serviceaccount:external-dns:external-dns"
  depends_on = [azurerm_kubernetes_cluster.aks_cluster]
}




data "azurerm_user_assigned_identity" "test" {
  name                = "${azurerm_kubernetes_cluster.aks_cluster.name}-agentpool"
  resource_group_name = azurerm_kubernetes_cluster.aks_cluster.node_resource_group
  depends_on = [azurerm_kubernetes_cluster.aks_cluster]

}



output "kube_config" {
  value = azurerm_kubernetes_cluster.aks_cluster.kube_config[0]
 sensitive =true
}

output "kubelet_identity_client_id" {
  value = data.azurerm_user_assigned_identity.test.client_id

}

output "kubelet_identity_object_id" {
  value = data.azurerm_user_assigned_identity.test.principal_id

}

output "aks_host" {
  value = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.host
  sensitive = true
}

output "aks_client_key" {
  value = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_key
 sensitive = true
}

output "aks_client_certificate" {
  value = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_certificate
   sensitive = true
}

output "aks_cluster_ca_certificate" {
  value = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.cluster_ca_certificate
  sensitive = true
}

output "kubernetes_oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.aks_cluster.oidc_issuer_url
}
###############################################################
/*

resource "azurerm_resource_group" "zone" {
  name     = "zone"
  location = "eastus2"
}

resource "azurerm_dns_zone" "harish_local" {
  name                = "harish.local"
  resource_group_name = azurerm_resource_group.zone.name
}


resource "azurerm_role_assignment" "reader" {
  scope                            = azurerm_resource_group.zone.id
  role_definition_name             =  "Reader"
  principal_id                     = data.azurerm_user_assigned_identity.test.principal_id
  skip_service_principal_aad_check = true
  depends_on = [azurerm_resource_group.zone]
}

resource "azurerm_role_assignment" "dnszone" {
  scope                            = azurerm_dns_zone.harish_local.id
  role_definition_name             =  "DNS Zone Contributor"
  principal_id                     = data.azurerm_user_assigned_identity.test.principal_id
  skip_service_principal_aad_check = true
  depends_on = [azurerm_resource_group.zone]
}



##############################################################################################
resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
#  version    = "1.41.3"
  create_namespace = true
  depends_on = [azurerm_kubernetes_cluster.aks_cluster]
}

resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"
#  version    = "5.3.3"  # Specify the version of the ExternalDNS chart
  create_namespace = true
  namespace  = "external-dns"  # Optional: Change the namespace as needed
 values = [file("values.yaml")]

}

*/
################################################################################################

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "example" {
  name                        = "maavault420"
  location                    = azurerm_resource_group.aks.location
  resource_group_name         = azurerm_resource_group.aks.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = true
  soft_delete_retention_days  = 7
  enable_rbac_authorization   = true
  enabled_for_disk_encryption = false
  enabled_for_deployment      = true
  enabled_for_template_deployment = true


}


resource "azurerm_role_assignment" "key2" {
  scope                            = azurerm_key_vault.example.id
  role_definition_name             =  "Key Vault Secrets Officer"
  principal_id                     = data.azurerm_client_config.current.object_id
  skip_service_principal_aad_check = true
 depends_on = [azurerm_key_vault.example]
}

resource "azurerm_role_assignment" "key3" {
  scope                            = azurerm_key_vault.example.id
  role_definition_name             =  "Key Vault Secrets User"
  principal_id                     = data.azurerm_client_config.current.object_id
  skip_service_principal_aad_check = true
 depends_on = [azurerm_key_vault.example]
}


resource "azurerm_role_assignment" "key4" {
  scope                            = azurerm_key_vault.example.id
  role_definition_name             =  "Key Vault Secrets Officer"
  principal_id                     = data.azurerm_user_assigned_identity.test.principal_id
  skip_service_principal_aad_check = true
 depends_on = [azurerm_key_vault.example]
}

resource "azurerm_role_assignment" "key5" {
  scope                            = azurerm_key_vault.example.id
  role_definition_name             =  "Key Vault Secrets User"
  principal_id                     = data.azurerm_user_assigned_identity.test.principal_id
  skip_service_principal_aad_check = true
 depends_on = [azurerm_key_vault.example]
}

resource "azurerm_role_assignment" "key6" {
  scope                            = azurerm_key_vault.example.id
  role_definition_name             =  "Key Vault Secrets Officer"
  principal_id                     = azurerm_user_assigned_identity.dev_test.principal_id
  skip_service_principal_aad_check = true
 depends_on = [azurerm_key_vault.example]
}

resource "azurerm_role_assignment" "key7" {
  scope                            = azurerm_key_vault.example.id
  role_definition_name             =  "Key Vault Secrets User"
  principal_id                     = azurerm_user_assigned_identity.dev_test.principal_id
  skip_service_principal_aad_check = true
 depends_on = [azurerm_key_vault.example]
}




