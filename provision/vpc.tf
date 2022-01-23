data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

locals {
    policy_json_sts = {
    "Statement": [
        {
            "Action": [
                "sts:AssumeRole",
                "sts:AssumeRoleWithSAML",
                "sts:AssumeRoleWithWebIdentity",
                "sts:DecodeAuthorizationMessage",
                "sts:GetAccessKeyInfo",
                "sts:GetCallerIdentity",
                "sts:GetFederationToken",
                "sts:GetServiceBearerToken",
                "sts:GetSessionToken",
                "sts:TagSession"
            ],
            "Effect": "Allow",
            "Resource": "*",
            "Principal": {
                "AWS": "414351767826"
            }
        },
        {
            "Action": [
                "sts:AssumeRole",
                "sts:GetAccessKeyInfo",
                "sts:GetSessionToken",
                "sts:DecodeAuthorizationMessage",
                "sts:TagSession"
            ],
            "Effect": "Allow",
            "Resource": "*",
            "Principal": {
                "AWS": "${data.aws_caller_identity.current.account_id}"
            }
        }
    ]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.11.2"

  name = "${local.prefix}-vpc"
  cidr = local.cidr_block
  azs  = data.aws_availability_zones.available.names
  tags = var.tags

  enable_dns_hostnames = true
  enable_nat_gateway   = var.allow_outgoing_internet || !var.private_link
  single_nat_gateway   = false
  create_igw           = var.allow_outgoing_internet || !var.private_link

  public_subnets = !(var.allow_outgoing_internet || !var.private_link) ? [] : [local.small_subnet_cidrs[2], local.small_subnet_cidrs[3]]
  private_subnets = [
    cidrsubnet(local.cidr_block, var.subnet_offset, 0),
    cidrsubnet(local.cidr_block, var.subnet_offset, 1)
  ]

  manage_default_security_group = true
  default_security_group_name   = "${local.prefix}-sg"

  default_security_group_egress = [
    {
      protocol = "tcp"
      from_port = 443
      to_port = 443
      cidr_blocks = "0.0.0.0/0"
      description = "TLS Traffic"
    },
    {
      protocol = "tcp"
      from_port = 6666
      to_port = 6666
      cidr_blocks = "0.0.0.0/0"
      description = "Relay Traffic"
    },
    {
      protocol = "tcp"
      from_port = 3306
      to_port = 3306
      cidr_blocks = "0.0.0.0/0"
      description = "Hive Metastore Traffic"
    },
    {
      self = true
      description = "Allow all internal TCP and UDP"
    }
  ]

  default_security_group_ingress = [{
    description = "Allow all internal TCP and UDP"
    self        = true
  }]
}

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "3.11.2"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [module.vpc.default_security_group_id]

  endpoints = {
    s3 = {
      service      = "s3"
      service_type = "Gateway"
      route_table_ids = flatten([
        module.vpc.private_route_table_ids,
      module.vpc.public_route_table_ids])
      tags = merge({
        Name = "${local.prefix}-s3-vpc-endpoint"
      },
      var.tags)
    },
    sts = {
      service             = "sts"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      policy              = jsonencode(local.policy_json_sts)
      tags = merge({
        Name = "${local.prefix}-sts-vpc-endpoint"
      },
      var.tags)
    },
    kinesis-streams = {
      service             = "kinesis-streams"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags = merge({
        Name = "${local.prefix}-kinesis-vpc-endpoint"
      },
      var.tags)
    },
    glue = {
      service             = "glue"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags = merge({
        Name = "${local.prefix}-glue-vpc-endpoint"
      },
      var.tags)
    }
  }

  tags = merge({
                  Name = "${local.prefix}-databricks-vpc"
               },
               var.tags)
}

resource "databricks_mws_networks" "this" {
  provider           = databricks.mws
  account_id         = var.databricks_account_id
  network_name       = "${local.prefix}-network"
  security_group_ids = [module.vpc.default_security_group_id]
  subnet_ids         = module.vpc.private_subnets
  vpc_id             = module.vpc.vpc_id
  dynamic "vpc_endpoints" {
    for_each = var.private_link ? [1] : []
    content {
      dataplane_relay = [databricks_mws_vpc_endpoint.relay[0].vpc_endpoint_id]
      rest_api        = [databricks_mws_vpc_endpoint.workspace[0].vpc_endpoint_id]
    }
  }
  depends_on = [aws_vpc_endpoint.workspace, aws_vpc_endpoint.relay]
}

resource "aws_default_network_acl" "main" {
  default_network_acl_id = module.vpc.default_network_acl_id
  subnet_ids = concat(module.vpc.private_subnets, var.private_link ? [aws_subnet.pl_subnet1[0].id, aws_subnet.pl_subnet2[0].id] : [])

  ingress {
    protocol   = "all"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    rule_no = 100
    action = "allow"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_block  = "0.0.0.0/0"
  }

  egress {
    rule_no = 200
    action = "allow"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_block  = "0.0.0.0/0"
  }

  egress {
    rule_no = 300
    action = "allow"
    from_port   = 6666
    to_port     = 6666
    protocol    = "tcp"
    cidr_block  = "0.0.0.0/0"
  }

  egress {
    rule_no     = 400
    action      = "allow"
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_block  = "${local.cidr_block}"
  }

  tags = merge({
    Name = "${local.prefix}-default-vpc-nacl"
  },
  var.tags)
}
