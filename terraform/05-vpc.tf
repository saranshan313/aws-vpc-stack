#VPC
resource "aws_vpc" "ecs_vpc" {
  cidr_block = local.settings.vpc_cidr_range

  enable_dns_support   = local.settings.enable_dns_support
  enable_dns_hostnames = local.settings.enable_dns_hostnames

  tags = merge(
    local.tags,
    {
      Name = "vpc-${local.settings.env}-${local.settings.region}-${local.settings.vpc_name}"
  })
}

#Internet Gateway and Attachment
resource "aws_internet_gateway" "ecs_igw" {
  vpc_id = aws_vpc.ecs_vpc.id

  tags = merge(
    local.tags,
    {
      Name = "igw-${local.settings.env}-${local.settings.region}-${local.settings.vpc_name}"
  })
}

#Public Subnets
resource "aws_subnet" "ecs_public_subnets" {
  for_each                = local.settings.public_subnets
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = each.value["cidr"]
  availability_zone       = each.value["availability_zone"]
  map_public_ip_on_launch = each.value["map_public_ip_on_launch"]

  tags = merge(
    local.tags,
    {
      Name = "subnet-${local.settings.env}-${local.settings.region}-${each.value["name"]}"
  })
}

#Application Subnets
resource "aws_subnet" "ecs_application_subnets" {
  for_each                = local.settings.application_subnets
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = each.value["cidr"]
  availability_zone       = each.value["availability_zone"]
  map_public_ip_on_launch = each.value["map_public_ip_on_launch"]

  tags = merge(
    local.tags,
    {
      Name = "subnet-${local.settings.env}-${local.settings.region}-${each.value["name"]}"
  })
}

#Database Subnets
resource "aws_subnet" "ecs_database_subnets" {
  for_each                = local.settings.database_subnets
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = each.value["cidr"]
  availability_zone       = each.value["availability_zone"]
  map_public_ip_on_launch = each.value["map_public_ip_on_launch"]

  tags = merge(
    local.tags,
    {
      Name = "subnet-${local.settings.env}-${local.settings.region}-${each.value["name"]}"
  })
}


# Elastic IPs and NAT Gateways
resource "aws_eip" "ecs_eip" {
  for_each = local.settings.public_subnets
  domain   = "vpc"

  tags = merge(
    local.tags,
    {
      Name = "eip-${local.settings.env}-${local.settings.region}-${each.value["name"]}"
  })
}

resource "aws_nat_gateway" "ecs_natgw" {
  for_each      = local.settings.public_subnets
  allocation_id = aws_eip.ecs_eip[each.key].id
  subnet_id     = aws_subnet.ecs_public_subnets[each.key].id

  tags = merge(
    local.tags,
    {
      Name = "natgw-${local.settings.env}-${local.settings.region}-${each.value["name"]}"
  })
}

# Public Subnets Route Tables, Routes and Associations
resource "aws_route_table" "ecs_public" {
  for_each = local.settings.public_subnets
  vpc_id   = aws_vpc.ecs_vpc.id

  tags = merge(
    local.tags,
    {
      Name = "rtb-${local.settings.env}-${local.settings.region}-${each.value["name"]}"
  })
}

resource "aws_route_table_association" "ecs_public" {
  for_each       = local.settings.public_subnets
  subnet_id      = aws_subnet.ecs_public_subnets[each.key].id
  route_table_id = aws_route_table.ecs_public[each.key].id
}

resource "aws_route" "ecs_public" {
  for_each               = local.settings.public_subnets
  route_table_id         = aws_route_table.ecs_public[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ecs_igw.id
}

# Application Subnets Route Tables, Routes and Associations
resource "aws_route_table" "ecs_application" {
  for_each = local.settings.application_subnets
  vpc_id   = aws_vpc.ecs_vpc.id

  tags = merge(
    local.tags,
    {
      Name = "rtb-${local.settings.env}-${local.settings.region}-${each.value["name"]}"
  })
}

resource "aws_route_table_association" "ecs_application" {
  for_each       = local.settings.application_subnets
  subnet_id      = aws_subnet.ecs_application_subnets[each.key].id
  route_table_id = aws_route_table.ecs_application[each.key].id
}

resource "aws_route" "ecs_application" {
  for_each               = local.settings.application_subnets
  route_table_id         = aws_route_table.ecs_application[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ecs_natgw["public_${each.value["nat_gateway"]}"].id
}

# database Subnets Route Tables, Routes and Associations
resource "aws_route_table" "ecs_database" {
  for_each = local.settings.database_subnets
  vpc_id   = aws_vpc.ecs_vpc.id

  tags = merge(
    local.tags,
    {
      Name = "rtb-${local.settings.env}-${local.settings.region}-${each.value["name"]}"
  })
}

resource "aws_route_table_association" "ecs_database" {
  for_each       = local.settings.database_subnets
  subnet_id      = aws_subnet.ecs_database_subnets[each.key].id
  route_table_id = aws_route_table.ecs_database[each.key].id
}

resource "aws_route" "ecs_database" {
  for_each               = local.settings.database_subnets
  route_table_id         = aws_route_table.ecs_database[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ecs_natgw["public_${each.value["nat_gateway"]}"].id
}

# Public Network ACL, associations and Rules
resource "aws_network_acl" "ecs_public_nacl" {
  vpc_id = aws_vpc.ecs_vpc.id

  tags = merge(
    local.tags,
    {
      Name = "nacl-${local.settings.env}-${local.settings.region}-public-ecs-01"
  })
}

resource "aws_network_acl_association" "ecs_public_nacl" {
  for_each       = local.settings.public_subnets
  network_acl_id = aws_network_acl.ecs_public_nacl.id
  subnet_id      = aws_subnet.ecs_public_subnets[each.key].id
}

resource "aws_network_acl_rule" "ecs_public_nacl" {
  for_each       = local.settings.public_nacl_rules
  network_acl_id = aws_network_acl.ecs_public_nacl.id
  rule_number    = each.value["number"]
  egress         = each.value["egress"]
  protocol       = each.value["protocol"]
  rule_action    = each.value["action"]
  cidr_block     = each.value["cidr"]
  from_port      = each.value["from"]
  to_port        = each.value["to"]
}

# Application Network ACL, associations and Rules
resource "aws_network_acl" "ecs_application_nacl" {
  vpc_id = aws_vpc.ecs_vpc.id

  tags = merge(
    local.tags,
    {
      Name = "nacl-${local.settings.env}-${local.settings.region}-application-ecs-01"
  })
}

resource "aws_network_acl_association" "ecs_application_nacl" {
  for_each       = local.settings.application_subnets
  network_acl_id = aws_network_acl.ecs_application_nacl.id
  subnet_id      = aws_subnet.ecs_application_subnets[each.key].id
}

resource "aws_network_acl_rule" "ecs_application_nacl" {
  for_each       = local.settings.application_nacl_rules
  network_acl_id = aws_network_acl.ecs_application_nacl.id
  rule_number    = each.value["number"]
  egress         = each.value["egress"]
  protocol       = each.value["protocol"]
  rule_action    = each.value["action"]
  cidr_block     = each.value["cidr"]
  from_port      = each.value["from"]
  to_port        = each.value["to"]
}

# Database Network ACL, associations and Rules
resource "aws_network_acl" "ecs_database_nacl" {
  vpc_id = aws_vpc.ecs_vpc.id

  tags = merge(
    local.tags,
    {
      Name = "nacl-${local.settings.env}-${local.settings.region}-database-ecs-01"
  })
}

resource "aws_network_acl_association" "ecs_database_nacl" {
  for_each       = local.settings.database_subnets
  network_acl_id = aws_network_acl.ecs_database_nacl.id
  subnet_id      = aws_subnet.ecs_database_subnets[each.key].id
}

resource "aws_network_acl_rule" "ecs_database_nacl" {
  for_each       = local.settings.database_nacl_rules
  network_acl_id = aws_network_acl.ecs_database_nacl.id
  rule_number    = each.value["number"]
  egress         = each.value["egress"]
  protocol       = each.value["protocol"]
  rule_action    = each.value["action"]
  cidr_block     = each.value["cidr"]
  from_port      = each.value["from"]
  to_port        = each.value["to"]
}
