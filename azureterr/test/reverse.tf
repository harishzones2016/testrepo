variable "resource_ids" {
  type = list(string)
  default = [
    "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup/providers/Microsoft.Network/virtualNetworks/myVNet",
    "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup/providers/Microsoft.Network/subnets/mySubnet"
  ]
}

locals {
  resource_names = [for id in var.resource_ids : reverse(split("/", id))[0]]
}


output "resource_names" {
  value = local.resource_names
}
