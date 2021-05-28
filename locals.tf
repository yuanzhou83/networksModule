/*
    ---------------------------------------------------------------------------------------------
    locals.tf
    Description: Local variables are being created, separate them in to a 'locals.ft' file
    Original Authors: Yuan Zhou, yuan.zhou@hrsdc-rhdcc.gc.ca
    ---------------------------------------------------------------------------------------------
*/

# flatten ensures that this local value is a flat list of objects, rather
# than a list of lists of objects.
locals {
  network_subnets = flatten([
    for network_key, network in var.networks : [
      for subnet_key, subnet in network.subnets : {
        network_key       = network_key
        subnet_key        = subnet_key
        subnet_name       = subnet.subnet_name
        subnet_prefixes   = subnet.subnet_prefixes
      }
    ]
  ])
}