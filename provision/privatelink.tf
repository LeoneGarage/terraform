resource "aws_security_group" "pl" {
  name        = "${local.prefix}-pl-sg"
  description = "Security Group for Private Link"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "REST API Traffic"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    self             = true
  }
  ingress {
    description      = "REST API Traffic"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    security_groups = [module.vpc.default_security_group_id]
  }
  ingress {
    description      = "Relay Traffic"
    from_port        = 6666
    to_port          = 6666
    protocol         = "tcp"
    self             = true
  }
  ingress {
    description      = "Relay Traffic"
    from_port        = 6666
    to_port          = 6666
    protocol         = "tcp"
    security_groups = [module.vpc.default_security_group_id]
  }

  egress {
    description      = "REST API Traffic"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    self             = true
  }
  egress {
    description      = "REST API Traffic"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    security_groups = [module.vpc.default_security_group_id]
  }
  egress {
    description      = "Relay Traffic"
    from_port        = 6666
    to_port          = 6666
    protocol         = "tcp"
    self             = true
  }
  egress {
    description      = "Relay Traffic"
    from_port        = 6666
    to_port          = 6666
    protocol         = "tcp"
    security_groups = [module.vpc.default_security_group_id]
  }

  tags = merge({
    Name = "${local.prefix}-PL-sg"
  },
  var.tags)
}

resource "aws_vpc_endpoint" "workspace" {
  tags = merge({
    Name = "${local.prefix}-db-workspace-vpc-endpoint"
  },
  var.tags)
  vpc_id             = module.vpc.vpc_id
  service_name       = local.private_link.workspace_service
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.pl.id]
  subnet_ids         = [aws_subnet.pl_subnet1.id, aws_subnet.pl_subnet2.id]
  private_dns_enabled = var.private_dns_enabled
  depends_on         = [
    aws_subnet.pl_subnet1,
    aws_subnet.pl_subnet2,
    aws_route_table_association.pl_subnet1_route_table_assoc,
    aws_route_table_association.pl_subnet2_route_table_assoc,
    aws_security_group.pl
  ]
}

resource "aws_vpc_endpoint" "relay" {
  tags = merge({
    Name = "${local.prefix}-db-relay-vpc-endpoint"
  },
  var.tags)
  vpc_id             = module.vpc.vpc_id
  service_name       = local.private_link.relay_service
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.pl.id]
  subnet_ids         = [aws_subnet.pl_subnet1.id, aws_subnet.pl_subnet2.id]
  private_dns_enabled = var.private_dns_enabled
  depends_on         = [
    aws_subnet.pl_subnet1,
    aws_subnet.pl_subnet2,
    aws_route_table_association.pl_subnet1_route_table_assoc,
    aws_route_table_association.pl_subnet2_route_table_assoc,
    aws_security_group.pl
  ]
}

resource "aws_subnet" "pl_subnet1" {
  vpc_id     = module.vpc.vpc_id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block = local.small_subnet_cidrs[0]
  tags = merge({
    Name = "${local.prefix}-pl-subnet-${data.aws_availability_zones.available.names[0]}"
  },
  var.tags)
}

resource "aws_subnet" "pl_subnet2" {
  vpc_id     = module.vpc.vpc_id
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block = local.small_subnet_cidrs[1]
  tags = merge({
    Name = "${local.prefix}-pl-subnet-${data.aws_availability_zones.available.names[1]}"
  },
  var.tags)
}

resource "aws_route_table" "pl_subnet_route_table" {
  vpc_id = module.vpc.vpc_id

  tags = merge({
    Name = "${local.prefix}-pl-subnet-route-table"
  },
  var.tags)
}

resource "aws_route_table_association" "pl_subnet1_route_table_assoc" {
  subnet_id = aws_subnet.pl_subnet1.id
  route_table_id = aws_route_table.pl_subnet_route_table.id
}

resource "aws_route_table_association" "pl_subnet2_route_table_assoc" {
  subnet_id = aws_subnet.pl_subnet2.id
  route_table_id = aws_route_table.pl_subnet_route_table.id
}

resource "databricks_mws_vpc_endpoint" "workspace" {
  provider            = databricks.mws
  account_id          = var.databricks_account_id
  aws_vpc_endpoint_id = aws_vpc_endpoint.workspace.id
  vpc_endpoint_name   = "Workspace Relay for ${module.vpc.vpc_id}"
  region              = var.region
  depends_on          = [aws_vpc_endpoint.workspace]
}

resource "databricks_mws_vpc_endpoint" "relay" {
  provider            = databricks.mws
  account_id          = var.databricks_account_id
  aws_vpc_endpoint_id = aws_vpc_endpoint.relay.id
  vpc_endpoint_name   = "VPC Relay for ${module.vpc.vpc_id}"
  region              = var.region
  depends_on          = [aws_vpc_endpoint.relay]
}

resource "databricks_mws_private_access_settings" "pas" {
  provider                     = databricks.mws
  account_id                   = var.databricks_account_id
  private_access_settings_name = "Private Access Settings for ${local.prefix}"
  region                       = var.region
  public_access_enabled        = true
  private_access_level         = "ANY"
}
