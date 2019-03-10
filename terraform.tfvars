# GLOBAL CONFIG :
#################
# usage:
# terraform apply -var-file="../../terraform.tfvars"

default_resource_group_location = "northeurope"

# network config
network_resource_group_name = "remote-network"

network_vnet_name = "remote-network"

# ip configs
network_vnet_address_space = ["10.0.0.0/24"]

# add up to 4 subnets
network_subnet_cidrs = {
  default  = "10.0.0.0/26"
  gateway  = "10.0.0.64/26"
  clusters = "10.0.0.128/26"
  consul   = "10.0.0.192/26"
}

# loadbalancer config
lb_resource_group_name = "remote-loadbalancers"

internal_lb_name = "remote-internal-lb"

internal_lb_ip = "10.0.0.198"
