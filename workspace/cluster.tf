data "databricks_node_type" "smallest" {
  local_disk = true
}

data "databricks_spark_version" "latest_lts" {
  long_term_support = true
}

resource "databricks_cluster" "test" {
  cluster_name            = "Test"
  # There seems to be an issue with DBR 10.4 in PL only Workspaces where clusters don't start up immediately after Workspace deployment.
  # This gets resolved some time later, but it does make Terraform template fail.
  # Instead we use DBR 9.1, which doesn't exhibit this problem on cluster startup.
  # The suspicion is this is due some DNS issue accessing global S3 endpoints, which is required by DBFS daemon
  # It seems on DBR 9.1 the daemon was connecting lazily after the cluster started.
  # But on DBR 10.4 it seems to be doing it eagerly which causes the driver to fail to bootsrap Spark.
  spark_version           = !local.allow_outgoing_internet ? "9.1.x-scala2.12" : data.databricks_spark_version.latest_lts.id
  node_type_id            = data.databricks_node_type.smallest.id
  autotermination_minutes = 10
  autoscale {
    min_workers = 2
    max_workers = 8
  }
  spark_conf = {
    "spark.databricks.hive.metastore.glueCatalog.enabled" : true
  }
  spark_env_vars = {
      "AWS_REGION"     : "${local.region}"
  }
  custom_tags = var.tags

  aws_attributes {
    instance_profile_arn           = databricks_instance_profile.initial.instance_profile_arn
    zone_id                        = "auto"
  }
  data_security_mode = "USER_ISOLATION"
}