locals {
   backend_address_pool_name      = "${var.vnet_name}-beap"
   frontend_port_name             = "${var.vnet_name}-feport"
   frontend_ip_configuration_name = "${var.vnet_name}-feip"
   http_setting_name              = "${var.vnet_name}-be-htst"
   listener_name                  = "${var.vnet_name}-httplstn"
   request_routing_rule_name      = "${var.vnet_name}-rqrt"
   app_gateway_subnet_name        = azurerm_subnet.appgwsubnet.name
 }

resource "azurerm_resource_group" "rg" {
   name     = var.resource_group_name
   location = var.resource_group_location
 }

resource "azurerm_virtual_network" "test" {
  name                = "test"
  location            =  var.resource_group_location
  resource_group_name =  azurerm_resource_group.rg.name
  address_space       = ["192.168.0.0/16"]

  tags = var.tags
}


resource "azurerm_subnet" "appgwsubnet" {
  name                 = "appgwsubnet"
  address_prefixes     = ["192.168.1.0/24"]
  virtual_network_name = azurerm_virtual_network.test.name
  resource_group_name  =  azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "akssubnet" {
   name = "akssubnet"
   address_prefixes     = ["192.168.2.0/24"]
  virtual_network_name = azurerm_virtual_network.test.name
  resource_group_name  =  azurerm_resource_group.rg.name
}

resource "azurerm_public_ip" "test" {
   name                = "publicIp1"
   location            = azurerm_resource_group.rg.location
   resource_group_name = azurerm_resource_group.rg.name
   allocation_method   = "Static"
   sku                 = "Standard"
   tags = var.tags
 }

 resource "azurerm_application_gateway" "network" {
   name                = var.app_gateway_name
   resource_group_name = azurerm_resource_group.rg.name
   location            = azurerm_resource_group.rg.location

   sku {
     name     = var.app_gateway_sku
     tier     = "Standard_v2"
     capacity = 2
   }


   gateway_ip_configuration {
     name      = "appGatewayIpConfig"
     subnet_id = azurerm_subnet.appgwsubnet.id
   }

   frontend_port {
     name = local.frontend_port_name
     port = 80
   }

   frontend_port {
     name = "httpsPort"
     port = 443
   }

   frontend_ip_configuration {
     name                 = local.frontend_ip_configuration_name
     public_ip_address_id = azurerm_public_ip.test.id
   }


backend_address_pool {
     name = local.backend_address_pool_name
   }

   backend_http_settings {
     name                  = local.http_setting_name
     cookie_based_affinity = "Disabled"
     port                  = 80
     protocol              = "Http"
     request_timeout       = 1
   }

   http_listener {
     name                           = local.listener_name
     frontend_ip_configuration_name = local.frontend_ip_configuration_name
     frontend_port_name             = local.frontend_port_name
     protocol                       = "Http"
   }

   request_routing_rule {
     name                       = local.request_routing_rule_name
     rule_type                  = "Basic"
     http_listener_name         = local.listener_name
     backend_address_pool_name  = local.backend_address_pool_name
     backend_http_settings_name = local.http_setting_name
     priority                   = 100
   }

   tags = var.tags

   depends_on = [azurerm_public_ip.test]

   lifecycle {
     ignore_changes = [
       backend_address_pool,
       backend_http_settings,
       request_routing_rule,
       http_listener,
       probe,
       #tags,
       frontend_port
     ]
   }
 }

############################################################################################################################


resource "azurerm_kubernetes_cluster" "aks" {
   name                                = var.cluster_name
   kubernetes_version                  = "1.27"
   location                            = var.location
   resource_group_name                 = azurerm_resource_group.rg.name
   dns_prefix                          = var.cluster_name
 #  private_cluster_enabled             = true
   http_application_routing_enabled    = false
   azure_policy_enabled                = true

   default_node_pool {
     name                = var.node_pool_name
     node_count          = var.system_node_count
     vm_size             = var.vm_size
     type                = var.aks_node_pool_type
     enable_auto_scaling = var.enable_auto_scaling
  #   os_disk_size_gb     = var.os_disk_size_gb
     vnet_subnet_id      = azurerm_subnet.akssubnet.id
   }

   ingress_application_gateway {
     gateway_id = azurerm_application_gateway.network.id
   }

#   azure_active_directory_role_based_access_control {
#     managed            = true
#     azure_rbac_enabled = true
#   }

   identity {
     type = var.identity_type
   }

   network_profile {
     network_plugin    = var.network_plugin
     load_balancer_sku = var.loadbalancer_sku
     network_policy    = var.network_policy
   }
   depends_on = [
     azurerm_application_gateway.network
   ]
 }



resource "azurerm_role_assignment" "Network_Contributor_subnet" {
   scope                = azurerm_subnet.appgwsubnet.id
   role_definition_name = "Network Contributor"
   principal_id         = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
 }

 resource "azurerm_role_assignment" "rg_reader" {
   scope                = azurerm_resource_group.rg.id
   role_definition_name = "Reader"
   principal_id         = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
 }

 resource "azurerm_role_assignment" "app-gw-contributor" {
   scope                = azurerm_application_gateway.network.id
   role_definition_name = "Contributor"
   principal_id         = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
 }
