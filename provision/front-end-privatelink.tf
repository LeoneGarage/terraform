locals {
    subnets = {
        existing = data.aws_subnet.front_end_pl_subnets
        created = [aws_subnet.pl_subnet1, aws_subnet.pl_subnet2]
    }
    front_end_pl_subnets = local.subnets[length(data.aws_subnet.front_end_pl_subnets) > 0 ? "existing" : "created"]
    create_front_end_pl = length(local.subnets["existing"]) > 0 ? 1 : 0
    front_end_vpc_id = local.create_front_end_pl > 0 ? local.front_end_pl_subnets[split(",", var.front_end_pl_subnet_ids)[0]].vpc_id : ""
}

resource "aws_security_group" "front_end_pl" {
  count = local.create_front_end_pl
  name        = "${local.prefix}-front-end-pl-sg"
  description = "Security Group for Front End Workspace Private Link"
  vpc_id      = local.front_end_vpc_id

  ingress {
    description      = "Workspace HTTPS Traffic"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = concat([for s in local.front_end_pl_subnets : s.cidr_block], [for s in data.aws_subnet.front_end_pl_source_subnets : s.cidr_block])
  }

  egress {
    description      = "Workspace HTTPS Traffic"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = concat([for s in local.front_end_pl_subnets : s.cidr_block], [for s in data.aws_subnet.front_end_pl_source_subnets : s.cidr_block])
  }

  tags = merge({
    Name = "${local.prefix}-Front-End-PL-sg"
  },
  var.tags)
}

data "aws_subnet" "front_end_pl_source_subnets" {
    for_each = length(var.front_end_pl_source_subnet_ids) > 0 ? toset(split(",", var.front_end_pl_source_subnet_ids)) : []
    id = each.value
}

data "aws_subnet" "front_end_pl_subnets" {
    for_each = length(var.front_end_pl_subnet_ids) > 0 ? toset(split(",", var.front_end_pl_subnet_ids)) : []
    id = each.value
}

resource "aws_vpc_endpoint" "front_end_workspace" {
  count = local.create_front_end_pl
  tags = merge({
    Name = "${local.prefix}-db-front-end-workspace-vpc-endpoint"
  },
  var.tags)
  vpc_id              = local.front_end_vpc_id // This is VPC Id of trhe VPC the front end VPC Endpoint should be in
  service_name        = local.private_link.workspace_service
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [for s in aws_security_group.front_end_pl : s.id] // This is security group for the VPC Endpoint of front end VPC
  subnet_ids          = [for s in local.front_end_pl_subnets : s.id] // Subnets where the front end VPC Endpoint should be in
  private_dns_enabled = var.private_dns_enabled
  depends_on          = [
      // Any other resource dependencies
  ]
}

resource "databricks_mws_vpc_endpoint" "front_end_workspace" {
  count = local.create_front_end_pl
  provider            = databricks.mws
  account_id          = var.databricks_account_id
  aws_vpc_endpoint_id = aws_vpc_endpoint.front_end_workspace[0].id
  vpc_endpoint_name   = "Front End Workspace REST API for ${aws_vpc_endpoint.front_end_workspace[0].vpc_id}"
  region              = var.region
  depends_on          = [aws_vpc_endpoint.front_end_workspace[0]]
}