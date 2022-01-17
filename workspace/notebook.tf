data "databricks_current_user" "me" {
}

resource "databricks_notebook" "test" {
  content_base64 = base64encode(<<-EOT
# Databricks notebook source
# MAGIC %sql
# MAGIC 
# MAGIC SHOW DATABASES

# COMMAND ----------

df = spark.range(0, 100000).selectExpr("id as a", "id*100 as b")

df.write.format('delta').mode('overwrite').saveAsTable('my_test_table')
EOT
  )
  path     = "${data.databricks_current_user.me.home}/Test"
  language = "PYTHON"
}