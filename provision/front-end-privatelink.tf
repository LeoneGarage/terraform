resource "aws_vpc_endpoint" "front_end_workspace" {
  count = 0
  tags = merge({
    Name = "${local.prefix}-db-front-end-workspace-vpc-endpoint"
  },
  var.tags)
  vpc_id              = "" // This is VPC Id of trhe VPC the front end VPC Endpoint should be in
  service_name        = local.private_link.workspace_service
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [] // This is security group for the VPC Endpoint of front end VPC
  subnet_ids          = [] // Subnets where the front end VPC Endpoint should be in
  private_dns_enabled = var.private_dns_enabled
  depends_on          = [
      // Any other resource dependencies
  ]
}

resource "databricks_mws_vpc_endpoint" "front_end_workspace" {
  count = 0
  provider            = databricks.mws
  account_id          = var.databricks_account_id
  aws_vpc_endpoint_id = aws_vpc_endpoint.front_end_workspace[0].id
  vpc_endpoint_name   = "Front End Workspace REST API for ${aws_vpc_endpoint.front_end_workspace[0].vpc_id}"
  region              = var.region
  depends_on          = [aws_vpc_endpoint.front_end_workspace[0]]
}