/*
    ---------------------------------------------------------------------------------------------
    outputs.tf
    Description: The variables which will be displayed in the result
    Original Authors: Yuan Zhou, yuan.zhou@hrsdc-rhdcc.gc.ca
    ---------------------------------------------------------------------------------------------
*/

output "vnet_ids" {
    description = "IDs of the list of virtual networks"    
    value = values(azurerm_virtual_network.vnet).*.id
}

output "nsg_ids" {
    description = "IDs of the list of network security groups"    
    value = values(azurerm_network_security_group.nsg).*.id
}

output "route_table_ids" {  
    description = "IDs of the list of route tables"    
    value = values(azurerm_route_table.rtable).*.id
}
