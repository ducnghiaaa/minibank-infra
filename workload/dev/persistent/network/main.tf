# NAT lives in the ephemeral stack (fck-nat); it adds 0.0.0.0/0 to the private route table

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.3"

  name = "minibank-dev"
  cidr = "10.0.0.0/16"
  azs  = ["ap-southeast-1a", "ap-southeast-1b"]

  public_subnets   = ["10.0.64.0/24", "10.0.65.0/24"]
  private_subnets  = ["10.0.0.0/19", "10.0.32.0/19"]
  database_subnets = ["10.0.66.0/26", "10.0.66.64/26"]

  # no NAT here, but single_nat_gateway = true makes one shared private route table
  enable_nat_gateway = false
  single_nat_gateway = true

  # own route table for db subnets: local route only, never the NAT route
  create_database_subnet_route_table = true
  create_database_subnet_group       = true

  enable_dns_support   = true
  enable_dns_hostnames = true

  # AWS Load Balancer Controller finds subnets by these tags
  public_subnet_tags  = { "kubernetes.io/role/elb" = "1" }
  private_subnet_tags = { "kubernetes.io/role/internal-elb" = "1" }
}

# S3 gateway endpoint (free): image layers and S3 reads skip the NAT
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.ap-southeast-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids

  tags = { Name = "minibank-dev-s3" }
}
