variable "node_count" {
  default = 1
}

variable "dns_prefix" {
  default = "aks-k8s-2022"
}

variable "cluster_name" {
  default = "aks-k8s-2022"
}

variable "kubernetes_version" {
  default = "1.21.2"
}

variable "acr_name" {
  type = string
  default = "acr42001"
}


variable "resource_group_name" {
  default = "aks-k8s-2020"
}

variable "location" {
  default = "eastus2"
}
