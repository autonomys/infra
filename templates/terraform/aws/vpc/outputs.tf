locals {
    redshift_route_table_ids = aws_route_table.redshift[*].id
    public_route_table_ids   = aws_route_table.public[*].id
    private_route_table_ids  = aws_route_table.private[*].id
  }

  ######################################
  # VPC
  ######################################

  output "vpc_id" {
    description = "The ID of the VPC"
    value       = try(aws_vpc.this[0].id, null)
  }

  output "vpc_arn" {
    description = "The ARN of the VPC"
    value       = try(aws_vpc.this[0].arn, null)
  }

  output "vpc_cidr_block" {
    description = "The CIDR block of the VPC"
    value       = try(aws_vpc.this[0].cidr_block, null)
  }

  output "default_security_group_id" {
    description = "The ID of the security group created by default on VPC creation"
    value       = try(aws_vpc.this[0].default_security_group_id, null)
  }

  output "default_network_acl_id" {
    description = "The ID of the default network ACL"
    value       = try(aws_vpc.this[0].default_network_acl_id, null)
  }

  output "default_route_table_id" {
    description = "The ID of the default route table"
    value       = try(aws_vpc.this[0].default_route_table_id, null)
  }

  output "vpc_instance_tenancy" {
    description = "Tenancy of instances spin up within VPC"
    value       = try(aws_vpc.this[0].instance_tenancy, null)
  }

  output "vpc_enable_dns_support" {
    description = "Whether or not the VPC has DNS support"
    value       = try(aws_vpc.this[0].enable_dns_support, null)
  }

  output "vpc_enable_dns_hostnames" {
    description = "Whether or not the VPC has DNS hostname support"
    value       = try(aws_vpc.this[0].enable_dns_hostnames, null)
  }

  output "vpc_main_route_table_id" {
    description = "The ID of the main route table associated with this VPC"
    value       = try(aws_vpc.this[0].main_route_table_id, null)
  }

  output "vpc_ipv6_association_id" {
    description = "The association ID for the IPv6 CIDR block"
    value       = try(aws_vpc.this[0].ipv6_association_id, null)
  }

  output "vpc_ipv6_cidr_block" {
    description = "The IPv6 CIDR block"
    value       = try(aws_vpc.this[0].ipv6_cidr_block, null)
  }

  output "vpc_secondary_cidr_blocks" {
    description = "List of secondary CIDR blocks of the VPC"
    value       = compact(aws_vpc_ipv4_cidr_block_association.this[*].cidr_block)
  }

  output "vpc_owner_id" {
    description = "The ID of the AWS account that owns the VPC"
    value       = try(aws_vpc.this[0].owner_id, null)
  }

  ######################################
  # DHCP Options Set
  ######################################

  output "dhcp_options_id" {
    description = "The ID of the DHCP options"
    value       = try(aws_vpc_dhcp_options.this[0].id, null)
  }

  ######################################
  # Internet Gateway
  ######################################

  output "igw_id" {
    description = "The ID of the Internet Gateway"
    value       = try(aws_internet_gateway.this[0].id, null)
  }

  output "igw_arn" {
    description = "The ARN of the Internet Gateway"
    value       = try(aws_internet_gateway.this[0].arn, null)
  }

  ######################################
  # Public Subnets
  ######################################

  output "public_subnets" {
    description = "List of IDs of public subnets"
    value       = aws_subnet.public[*].id
  }

  output "public_subnet_arns" {
    description = "List of ARNs of public subnets"
    value       = aws_subnet.public[*].arn
  }

  output "public_subnets_cidr_blocks" {
    description = "List of cidr_blocks of public subnets"
    value       = compact(aws_subnet.public[*].cidr_block)
  }

  output "public_subnets_ipv6_cidr_blocks" {
    description = "List of IPv6 cidr_blocks of public subnets in an IPv6 enabled VPC"
    value       = compact(aws_subnet.public[*].ipv6_cidr_block)
  }

  output "public_route_table_ids" {
    description = "List of IDs of public route tables"
    value       = local.public_route_table_ids
  }

  output "public_internet_gateway_route_id" {
    description = "ID of the internet gateway route"
    value       = try(aws_route.public_internet_gateway[0].id, null)
  }

  output "public_internet_gateway_ipv6_route_id" {
    description = "ID of the IPv6 internet gateway route"
    value       = try(aws_route.public_internet_gateway_ipv6[0].id, null)
  }

  output "public_route_table_association_ids" {
    description = "List of IDs of the public route table association"
    value       = aws_route_table_association.public[*].id
  }

  output "public_network_acl_id" {
    description = "ID of the public network ACL"
    value       = try(aws_network_acl.public[0].id, null)
  }

  output "public_network_acl_arn" {
    description = "ARN of the public network ACL"
    value       = try(aws_network_acl.public[0].arn, null)
  }

  ######################################
  # Private Subnets
  ######################################

  output "private_subnets" {
    description = "List of IDs of private subnets"
    value       = aws_subnet.private[*].id
  }

  output "private_subnet_arns" {
    description = "List of ARNs of private subnets"
    value       = aws_subnet.private[*].arn
  }

  output "private_subnets_cidr_blocks" {
    description = "List of cidr_blocks of private subnets"
    value       = compact(aws_subnet.private[*].cidr_block)
  }

  output "private_subnets_ipv6_cidr_blocks" {
    description = "List of IPv6 cidr_blocks of private subnets in an IPv6 enabled VPC"
    value       = compact(aws_subnet.private[*].ipv6_cidr_block)
  }

  output "private_route_table_ids" {
    description = "List of IDs of private route tables"
    value       = local.private_route_table_ids
  }

  output "private_nat_gateway_route_ids" {
    description = "List of IDs of the private nat gateway route"
    value       = aws_route.private_nat_gateway[*].id
  }

  output "private_ipv6_egress_route_ids" {
    description = "List of IDs of the ipv6 egress route"
    value       = aws_route.private_ipv6_egress[*].id
  }

  output "private_route_table_association_ids" {
    description = "List of IDs of the private route table association"
    value       = aws_route_table_association.private[*].id
  }

  output "private_network_acl_id" {
    description = "ID of the private network ACL"
    value       = try(aws_network_acl.private[0].id, null)
  }

  output "private_network_acl_arn" {
    description = "ARN of the private network ACL"
    value       = try(aws_network_acl.private[0].arn, null)
  }

  ######################################
  # NAT Gateway
  ######################################

  output "nat_ids" {
    description = "List of allocation ID of Elastic IPs created for AWS NAT Gateway"
    value       = aws_eip.nat[*].id
  }

  output "nat_public_ips" {
    description = "List of public Elastic IPs created for AWS NAT Gateway"
    value       = var.reuse_nat_ips ? var.external_nat_ips : aws_eip.nat[*].public_ip
  }

  output "natgw_ids" {
    description = "List of NAT Gateway IDs"
    value       = aws_nat_gateway.this[*].id
  }

  output "natgw_interface_ids" {
    description = "List of Network Interface IDs assigned to NAT Gateways"
    value       = aws_nat_gateway.this[*].network_interface_id
  }

  ######################################
  # Egress Only Gateway
  ######################################

  output "egress_only_internet_gateway_id" {
    description = "The ID of the egress only Internet Gateway"
    value       = try(aws_egress_only_internet_gateway.this[0].id, null)
  }

  ######################################
  # Default VPC
  ######################################

  output "default_vpc_id" {
    description = "The ID of the Default VPC"
    value       = try(aws_default_vpc.this[0].id, null)
  }

  output "default_vpc_arn" {
    description = "The ARN of the Default VPC"
    value       = try(aws_default_vpc.this[0].arn, null)
  }

  output "default_vpc_cidr_block" {
    description = "The CIDR block of the Default VPC"
    value       = try(aws_default_vpc.this[0].cidr_block, null)
  }

  output "default_vpc_default_security_group_id" {
    description = "The ID of the security group created by default on Default VPC creation"
    value       = try(aws_default_vpc.this[0].default_security_group_id, null)
  }

  output "default_vpc_default_network_acl_id" {
    description = "The ID of the default network ACL of the Default VPC"
    value       = try(aws_default_vpc.this[0].default_network_acl_id, null)
  }

  output "default_vpc_default_route_table_id" {
    description = "The ID of the default route table of the Default VPC"
    value       = try(aws_default_vpc.this[0].default_route_table_id, null)
  }

  output "default_vpc_instance_tenancy" {
    description = "Tenancy of instances spin up within Default VPC"
    value       = try(aws_default_vpc.this[0].instance_tenancy, null)
  }

  output "default_vpc_enable_dns_support" {
    description = "Whether or not the Default VPC has DNS support"
    value       = try(aws_default_vpc.this[0].enable_dns_support, null)
  }

  output "default_vpc_enable_dns_hostnames" {
    description = "Whether or not the Default VPC has DNS hostname support"
    value       = try(aws_default_vpc.this[0].enable_dns_hostnames, null)
  }

  output "default_vpc_main_route_table_id" {
    description = "The ID of the main route table associated with the Default VPC"
    value       = try(aws_default_vpc.this[0].main_route_table_id, null)
  }

  ######################################
  # Static values
  ######################################

  output "azs" {
    description = "A list of availability zones specified as argument to this module"
    value       = var.azs
  }

  output "name" {
    description = "The name of the VPC specified as argument to this module"
    value       = var.name
  }
