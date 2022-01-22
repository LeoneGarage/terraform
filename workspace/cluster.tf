data "databricks_node_type" "smallest" {
  local_disk = true
}

data "databricks_spark_version" "latest_lts" {
  long_term_support = true
}

resource "databricks_cluster" "test" {
  cluster_name            = "Test"
  spark_version           = data.databricks_spark_version.latest_lts.id
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
      "PYSPARK_PYTHON" : "/databricks/python3/bin/python3"
      "AWS_REGION"     : "${local.region}"
  }
  aws_attributes {
    instance_profile_arn           = databricks_instance_profile.initial.instance_profile_arn
  }
}