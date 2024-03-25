variable "env" {
  description = "The suffix of resource name or tag"
  type        = string
}

variable "project_name" {
  description = "project name"
  type        = string
}

variable "vpc_id" {
  description = "Vpc this database instance will be created in"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet ids of database"
  type        = list(string)
}

variable "from_subnet_cidr_blocks" {
  description = "The subnets of the service which needs connect to this database"
  type        = list(string)
}

variable "bastion_host_subnet_cidr_block" {
  description = "The subnet cidr block of bastion host"
  type        = string
}

variable "bastion_host_subnet_id" {
  description = "The subnet id of bastion host"
  type        = string
}