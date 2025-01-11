terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.40.0"
    }
    random = {
      version = ">=3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.34.0"
    }
  }

}

provider "azurerm" {
subscription_id = "a6903443-961a-487c-a135-ded1b11e2541" 
  features {}
}

