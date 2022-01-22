locals {
  cidr_blocks = concat([cidrsubnet(local.cidr_block, var.subnet_offset, 0),
     cidrsubnet(local.cidr_block, var.subnet_offset, 1)],
     var.private_link ? [aws_subnet.pl_subnet1[0].cidr_block,
     aws_subnet.pl_subnet2[0].cidr_block] : [])
}

resource "aws_security_group" "pl" {
  count = var.private_link ? 1 : 0
  name        = "${local.prefix}-pl-sg"
  description = "Security Group for Private Link"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "REST API Traffic"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = concat(local.cidr_blocks, local.front_source_subnet_cidrs)
  }
  ingress {
    description      = "Relay Traffic"
    from_port        = 6666
    to_port          = 6666
    protocol         = "tcp"
    cidr_blocks      = local.cidr_blocks
  }

  egress {
    description      = "REST API Traffic"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = concat(local.cidr_blocks, local.front_source_subnet_cidrs)
  }
  egress {
    description      = "Relay Traffic"
    from_port        = 6666
    to_port          = 6666
    protocol         = "tcp"
    cidr_blocks      = local.cidr_blocks
  }

  tags = merge({
    Name = "${local.prefix}-PL-sg"
  },
  var.tags)
}

resource "aws_vpc_endpoint" "workspace" {
  count = var.private_link ? 1 : 0
  tags = merge({
    Name = "${local.prefix}-db-workspace-vpc-endpoint"
  },
  var.tags)
  vpc_id             = module.vpc.vpc_id
  service_name       = local.private_link.workspace_service
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.pl[0].id]
  subnet_ids         = [aws_subnet.pl_subnet1[0].id, aws_subnet.pl_subnet2[0].id]
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
  count = var.private_link ? 1 : 0
  tags = merge({
    Name = "${local.prefix}-db-relay-vpc-endpoint"
  },
  var.tags)
  vpc_id             = module.vpc.vpc_id
  service_name       = local.private_link.relay_service
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.pl[0].id]
  subnet_ids         = [aws_subnet.pl_subnet1[0].id, aws_subnet.pl_subnet2[0].id]
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
  count = var.private_link ? 1 : 0
  vpc_id     = module.vpc.vpc_id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block = local.small_subnet_cidrs[0]
  tags = merge({
    Name = "${local.prefix}-pl-subnet-${data.aws_availability_zones.available.names[0]}"
  },
  var.tags)
}

resource "aws_subnet" "pl_subnet2" {
  count = var.private_link ? 1 : 0
  vpc_id     = module.vpc.vpc_id
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block = local.small_subnet_cidrs[1]
  tags = merge({
    Name = "${local.prefix}-pl-subnet-${data.aws_availability_zones.available.names[1]}"
  },
  var.tags)
}

resource "aws_route_table" "pl_subnet_route_table" {
  count = var.private_link ? 1 : 0
  vpc_id = module.vpc.vpc_id

  tags = merge({
    Name = "${local.prefix}-pl-subnet-route-table"
  },
  var.tags)
}

resource "aws_route_table_association" "pl_subnet1_route_table_assoc" {
  count = var.private_link ? 1 : 0
  subnet_id = aws_subnet.pl_subnet1[0].id
  route_table_id = aws_route_table.pl_subnet_route_table[0].id
}

resource "aws_route_table_association" "pl_subnet2_route_table_assoc" {
  count = var.private_link ? 1 : 0
  subnet_id = aws_subnet.pl_subnet2[0].id
  route_table_id = aws_route_table.pl_subnet_route_table[0].id
}

resource "databricks_mws_vpc_endpoint" "workspace" {
  count = var.private_link ? 1 : 0
  provider            = databricks.mws
  account_id          = var.databricks_account_id
  aws_vpc_endpoint_id = aws_vpc_endpoint.workspace[0].id
  vpc_endpoint_name   = "Workspace Relay for ${module.vpc.vpc_id}"
  region              = var.region
  depends_on          = [aws_vpc_endpoint.workspace]
}

resource "databricks_mws_vpc_endpoint" "relay" {
  count = var.private_link ? 1 : 0
  provider            = databricks.mws
  account_id          = var.databricks_account_id
  aws_vpc_endpoint_id = aws_vpc_endpoint.relay[0].id
  vpc_endpoint_name   = "VPC Relay for ${module.vpc.vpc_id}"
  region              = var.region
  depends_on          = [aws_vpc_endpoint.relay]
}

resource "databricks_mws_private_access_settings" "pas" {
  count = var.private_link ? 1 : 0
  provider                     = databricks.mws
  account_id                   = var.databricks_account_id
  private_access_settings_name = "Private Access Settings for ${local.prefix}"
  region                       = var.region
  public_access_enabled        = var.front_end_access == "private" ? false : true
  private_access_level         = (var.front_end_access == "private" && length(databricks_mws_vpc_endpoint.front_end_workspace) > 0) ? "ENDPOINT" : "ACCOUNT"
  allowed_vpc_endpoint_ids     = (var.front_end_access == "private" && length(databricks_mws_vpc_endpoint.front_end_workspace) > 0) ? concat([
    for v in databricks_mws_vpc_endpoint.front_end_workspace: v.vpc_endpoint_id
  ],
    [databricks_mws_vpc_endpoint.workspace[0].vpc_endpoint_id, databricks_mws_vpc_endpoint.relay[0].vpc_endpoint_id]
  ) : []
}
