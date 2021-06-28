/*
    ---------------------------------------------------------------------------------------------
    variables.tf
    Description: All the variables in the child module
    Original Authors: Yuan Zhou, yuan.zhou@hrsdc-rhdcc.gc.ca
    ---------------------------------------------------------------------------------------------
*/

variable "rgname"{
    type = string
    description = "Name of Resource Group"
}

variable "location"{
    type = string
    description = "Azure location server environment"
}

variable "networks" {
    description = "Map of Network/Vnet objects with their subnets."
    type = map(object({
        vnet_name       = string
        address_space   = list(string)
        subnets         = map(object({
                subnet_name      = string
                subnet_prefixes  = list(string)
        }))
    }))    
}

variable "network_watcher_name" {
  type          = string
  description   = "Name of the network watcher."
}

variable "network_watcher_rg_name" {
  type          = string
  description   = "Resource group name of the network watcher."
}

variable "main_law" {
  description = "Main law object with it's id, location, workspace id."
  type = object({
    workspace_id = string
    location = string
    id = string
  })
}