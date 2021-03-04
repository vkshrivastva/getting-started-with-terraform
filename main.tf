terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "1.21.0"
    }
  }
}

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = "us-south"
}



#### Variable that need to update according to individual user  ####
/**
Need to replace the IBM API Key
*/
variable "ibmcloud_api_key" {
  default = "EnteryourIBMAPIKey"
}
/**
Need to replace the IBM ssh key name
*/
variable "ssh_key" {
  default = "vks-mac-key"
}
/**
Need to replace the IBM Resource Group ID
*/
variable "resource_group_id" {
  default = "aadb17b59af948699a4b2bc66c1cda5c"
}
/**
Need to replace the IBM Image ID
*/
variable "image" {
  default = "r006-78fafd7c-4fc6-4373-a58a-637ba6dc3ee8"
}

#### Variable that need to update according to individual user  ####





variable "profile" {
  default = "cx2-2x4"
}

locals {
  PREFIX = "training-tf"
  ZONE   = "us-south-1"
}

resource "ibm_is_vpc" "vpc" {
  name           = "${local.PREFIX}-vpc"
  resource_group = var.resource_group_id
}

resource "ibm_is_security_group" "sg" {
  name           = "${local.PREFIX}-sg"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = var.resource_group_id
}

resource "ibm_is_security_group_rule" "ingress_ssh_all" {
  group     = ibm_is_security_group.sg.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "web_80" {
  group     = ibm_is_security_group.sg.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_subnet" "subnet" {
  name                     = "${local.PREFIX}-subnet"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = local.ZONE
  total_ipv4_address_count = 8
  resource_group           = var.resource_group_id
}


data "ibm_is_ssh_key" "ssh_key_id" {
  name = var.ssh_key
}


resource "ibm_is_instance" "vsi" {
  name           = "${local.PREFIX}-vsi"
  vpc            = ibm_is_vpc.vpc.id
  zone           = local.ZONE
  keys           = [data.ibm_is_ssh_key.ssh_key_id.id]
  resource_group = var.resource_group_id
  image          = var.image
  profile        = var.profile

  primary_network_interface {
    subnet          = ibm_is_subnet.subnet.id
    security_groups = [ibm_is_security_group.sg.id]
  }
}

resource "ibm_is_floating_ip" "fip" {
  name           = "${local.PREFIX}-fip"
  target         = ibm_is_instance.vsi.primary_network_interface[0].id
  resource_group = var.resource_group_id
}

output "IP" {
  value = ibm_is_floating_ip.fip.address
}
