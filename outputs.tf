output "vnets" {
    description = "Name of the list of virtual networks"
    value = values(azurerm_virtual_network.vnet).*.name
}

output "nsgs" {
    description = "Name of the list of network security groups"
    value = values(azurerm_network_security_group.nsg).*.name
}

output "route_tables" {
    description = "Name of the list of route tables"
    value = values(azurerm_route_table.rtable).*.name
}