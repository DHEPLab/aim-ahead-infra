variable "suffix" {
  description = "The suffix of resource name or tag"
  type        = string
}

variable "vpc_id" {
  description = "Vpc this database instance will be created in"
  type        = string
}

variable "subnet_id" {
  description = "Subnet id of database"
  type        = string
}

variable "from_subnet_cidr" {
  description = "The subnet of the service which needs connect to this database"
  type        = string
}