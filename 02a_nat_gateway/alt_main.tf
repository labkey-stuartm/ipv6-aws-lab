provider "aws" {
  region = var.region
  # profile = var.aws_profile_name
}

# Import the VPC resources
data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "../01_vpc/terraform.tfstate"
  }
}

# Allocate one EIP for NAT gateway (in AZ "A" — assumed to be index 0)
resource "aws_eip" "nat" {
  # vpc = true (deprecated unless you're in EC2-Classic, which you're not)

  tags = {
    Name        = format("v6LabNATGatewayIP-%s%s", data.terraform_remote_state.vpc.outputs.region, data.terraform_remote_state.vpc.outputs.availability_zones[0])
    Environment = "v6Lab"
  }
}

# Create a single NAT gateway in the first public subnet (AZ "A")
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat.id
  subnet_id     = data.terraform_remote_state.vpc.outputs.public_subnets[0].id

  tags = {
    Name        = format("v6LabNATGateway-%s%s", data.terraform_remote_state.vpc.outputs.region, data.terraform_remote_state.vpc.outputs.availability_zones[0])
    Environment = "v6Lab"
  }
}

# Add default IPv4 route to each private route table using the single NAT gateway
resource "aws_route" "private_default_gw" {
  count = length(data.terraform_remote_state.vpc.outputs.private_route_tables)

  route_table_id         = data.terraform_remote_state.vpc.outputs.private_route_tables[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}

# IPv6 NAT64 for private subnets
resource "aws_route" "private_nat64_default_gw" {
  count = length(data.terraform_remote_state.vpc.outputs.private_route_tables)

  route_table_id              = data.terraform_remote_state.vpc.outputs.private_route_tables[count.index].id
  destination_ipv6_cidr_block = "64:ff9b::/96"
  nat_gateway_id              = aws_nat_gateway.nat_gateway.id
}

# IPv6 NAT64 for public subnets (if any are IPv6-only and need NAT64, usually rare)
resource "aws_route" "public_nat64_default_gw" {
  count = length(data.terraform_remote_state.vpc.outputs.public_route_tables)

  route_table_id              = data.terraform_remote_state.vpc.outputs.public_route_tables[count.index].id
  destination_ipv6_cidr_block = "64:ff9b::/96"
  nat_gateway_id              = aws_nat_gateway.nat_gateway.id
}
