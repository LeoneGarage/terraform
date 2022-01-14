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

  tags = {
    Name = "Databricks PL SG"
  }
}

resource "aws_vpc_endpoint" "workspace" {
  tags = {
    Name = "${local.prefix}-db-workspace-vpc-endpoint"
  }
  vpc_id             = module.vpc.vpc_id
  service_name       = local.private_link.workspace_service
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.pl.id]
  subnet_ids         = [aws_subnet.pl_subnet.id]
  depends_on         = [aws_subnet.pl_subnet, aws_security_group.pl]
  private_dns_enabled = var.private_dns_enabled
}

resource "aws_vpc_endpoint" "relay" {
  tags = {
    Name = "${local.prefix}-db-relay-vpc-endpoint"
  }
  vpc_id             = module.vpc.vpc_id
  service_name       = local.private_link.relay_service
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.pl.id]
  subnet_ids         = [aws_subnet.pl_subnet.id]
  depends_on         = [aws_subnet.pl_subnet, aws_security_group.pl]
  private_dns_enabled = var.private_dns_enabled
}

resource "aws_subnet" "pl_subnet" {
  vpc_id     = module.vpc.vpc_id
  cidr_block = cidrsubnet(var.cidr_block, 12, 0)
  tags = {
    Name = "${local.prefix}-pl-subnet"
  }
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
}
