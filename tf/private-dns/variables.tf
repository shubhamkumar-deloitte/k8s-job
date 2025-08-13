###############
# variables.tf
###############

# meta
variable "tags" {
  type        = map(string)
  description = "Map of tags to put on the resource"
  default     = {}
}

variable "hosted_zone" {}
variable "resolver_endpoint_name" {}

# network
variable "vpc_id" {}
variable "subnets" {
  type = list
}
variable "ingress_security_groups" {
  type    = list
  default = []
}
variable "ingress_cidr_blocks" {
  type    = list
  default = []
}