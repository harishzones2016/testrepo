variable "node_count" {
  default = 1
}

variable "dns_prefix" {
  default = "aks-k8s-2022"
}

variable "cluster_name" {
 }


variable "acr_name" {
  type = string
 
}

variable "resource_group_name" {
  }

variable "location" {
  default = "westus"
}
