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

variable "main_law_id" {
  type          = string
  description   = "ID of the workspace to send diagnostics to"
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
