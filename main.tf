/**
*   # Description
*   This module creates a network that assists in creating a Protected-B complete networking solution. 
*   It sends VNET and NSG diagnostic logs to the specified log analytics workspace. 
*   This requires a log analytics workspace to be created before this module.
*   It is enabled Network security group flow logs in the Network Watcher.
*
*   Vnet Diagnostics:
*   VMProtectionAlerts
*   AllMetrics
*
*   NSG Diagnostics:
*   NetworkSecurityGroupEvent
*   NetworkSecurityGroupRuleCounter
*
*   ### Original Authors 
*   - Yuan Zhou
*
*/

terraform{
    required_providers{
        azurerm={
            source = "hashicorp/azurerm"
            version = "> 2.46.0"
        }
    }
}

#--------------create virtual network ----------------

resource "azurerm_virtual_network" "vnet" {
    for_each   =  var.networks

    name                = each.value.vnet_name
    location            = var.location
    resource_group_name = var.rgname
    address_space       = each.value.address_space
}

#--------------create subnet----------------
resource "azurerm_subnet" "subnet" {
    for_each              = {for subnet in local.network_subnets : "${subnet.network_key}.${subnet.subnet_key}" => subnet}
    
    name                  = each.value.subnet_name
    resource_group_name   = var.rgname
    address_prefixes      = each.value.subnet_prefixes
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

/*             NSG flow logs              */

#---------------------create storage account----------------

resource "azurerm_storage_account" "sa" {
  name                = "flowlogssaj8"
  resource_group_name = var.rgname
  location            = var.location

  account_tier              = "Standard"
  account_kind              = "StorageV2"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
}

#---------------------create network watcher flow log----------------
resource "azurerm_network_watcher_flow_log" "nsgflowlog" {
  for_each                  = azurerm_subnet.subnet

  network_watcher_name = var.network_watcher_name
  resource_group_name  = var.network_watcher_rg_name

  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
  storage_account_id        = azurerm_storage_account.sa.id
  enabled                   = true

  retention_policy {
    enabled = true
    days    = 7
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = var.main_law.workspace_id
    workspace_region      = var.main_law.location
    workspace_resource_id = var.main_law.id
    interval_in_minutes   = 10
  }
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
    log_analytics_workspace_id    = var.main_law.id

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
  log_analytics_workspace_id    = var.main_law.id

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