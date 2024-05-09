locals {
  vpc_cidr_block             = "10.0.0.0/16"
  private_subnet_cidr_blocks = ["10.0.0.0/24", "10.0.2.0/24"]
  public_subnet_cidr_blocks  = ["10.0.1.0/24", "10.0.3.0/24"]
  availability_zones         = ["us-east-1a", "us-east-1b"]

  api_container_binding_port = 5000
  app_container_binding_port = 8080

  subdomain   = "augmed"
  domain_name = "dhep.org"
}
