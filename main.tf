terraform{
    required_providers{
        azurerm={
            source = "hashicorp/azurerm"
            version = "> 2.46.0"
        }
    }
}

#-------------------DDoS protection plan---------------------
resource "azurerm_network_ddos_protection_plan" "DDoSProtPlan" {
  name                = "DDoSProtectionPlan"
  location            = var.location
  resource_group_name = var.rgname
}


#--------------create virtual network ----------------

resource "azurerm_virtual_network" "vnet" {
    for_each   =  var.networks

    name                = each.value.vnet_name
    location            = var.location
    resource_group_name = var.rgname
    address_space       = each.value.address_space
   
    ddos_protection_plan {
        id     = azurerm_network_ddos_protection_plan.DDoSProtPlan.id
        enable = true
    }
}

# flatten ensures that this local value is a flat list of objects, rather
# than a list of lists of objects.
locals {
  network_subnets = flatten([
    for network_key, network in var.networks : [
      for subnet_key, subnet in network.subnets : {
        network_key       = network_key
        subnet_key        = subnet_key
        subnet_name       = subnet.subnet_name
        subnet_prefix     = subnet.subnet_prefix
      }
    ]
  ])
}

#--------------create subnet----------------

resource "azurerm_subnet" "subnet" {
    for_each              = {for subnet in local.network_subnets : "${subnet.network_key}.${subnet.subnet_key}" => subnet}
    
    name                  = each.value.subnet_name
    resource_group_name   = var.rgname
    address_prefixes      = each.value.subnet_prefix
    virtual_network_name  = azurerm_virtual_network.vnet[each.value.network_key].name
}

#------------------create nsg-----------------
resource "azurerm_network_security_group" "nsg" {
    for_each            = azurerm_subnet.subnet

    name                = "${each.value.name}Nsg"
    location            = var.location
    resource_group_name = var.rgname
}  

#---------------------Link Subnet to NSG---------------------

resource "azurerm_subnet_network_security_group_association" "sbnsgass" {
    for_each                  = azurerm_subnet.subnet

    subnet_id                 = azurerm_subnet.subnet[each.key].id
    network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}

#---------------------create route table--------------------

resource "azurerm_route_table" "rtable" {
    for_each            = azurerm_subnet.subnet

    name                = "${each.value.name}Rtable"
    resource_group_name = var.rgname
    location            = var.location   
}

#---------------Subnets Route Table Associations---------------------
resource "azurerm_subnet_route_table_association" "test" {
    for_each            = azurerm_subnet.subnet

    subnet_id           = azurerm_subnet.subnet[each.key].id
    route_table_id      = azurerm_route_table.rtable[each.key].id
}

#---------------------diagnostics--------------------
/* Network Security Group Diagnostic Settings */
resource "azurerm_monitor_diagnostic_setting" "vnets_subnets_nsgs_diagnostics" {
    for_each                      = azurerm_network_security_group.nsg
  
    name                          = "${each.value.name}Diagnostics"
    target_resource_id            = azurerm_network_security_group.nsg[each.key].id
    log_analytics_workspace_id    = var.main_law_id

    log {
        category = "NetworkSecurityGroupEvent"

        retention_policy {
            enabled = false
        }
    }

    log {
        category = "NetworkSecurityGroupRuleCounter"

        retention_policy {
            enabled = false
        }
    }
}

/* Virtual Networks Diagnostic Settings */
resource "azurerm_monitor_diagnostic_setting" "vnets_diagnostics" {
  for_each                      =  var.networks

  name                          = "${azurerm_virtual_network.vnet[each.key].name}Diagnostics"
  target_resource_id            = azurerm_virtual_network.vnet[each.key].id
  log_analytics_workspace_id    = var.main_law_id

  log {
    category = "VMProtectionAlerts"

    retention_policy {
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}