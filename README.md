# terraform
### Databricks Terraform for provisioning AWS PL Workspaces

This repo contains terraform templates and scripts for provisioning a Databricks Workspace on AWS with PrivateLink. It includes all the AWS VPC infrastructure provisioning.

Running the templates will do the following:
* Provision AWS VPC in ap-southeast-2 regionn with 2 subnets in different AZs for the Workspace and 2 subnets in different AZs for PL (for redundancy)
* Provision Databricks PL for REST API and Relay integration and S3, STS, Kinesis, Glue PL for AWS
* Provision E2 Databricks Workspace objects through Account API
* Provision initial IAM Role with access to Glue Catalog
* Create a Test cluster with access to Glue Catalog and a Test Notebook to test the setup

Note, at this stage public access is on for Front End Workspace UI access, only the Back End Dataplane to Control Plane is configured with PL access.
Support for provate access for Front End will be added to this template at a later stage.

#### Content
There are 2 subdirectories, *provision* and *workspace*. Each contains individual terraform templates.
*provision* will provision AWS VPC infrastructure and configure Databricks Workspace with Account API. After this template is run succesfully, the Workspace should be accessible through it's url.
*workspace* will use PAT created by *provision* step to configure a Cluster and a Notebook in the newly created Workspace.
The whole thing is executed by running ./configure.sh script from root directory.

### Steps to execute the templates

1. Install Terraform. For Mac, this is described in https://learn.hashicorp.com/tutorials/terraform/install-cli.
2. Clone this repo to your machine. 
3. In *provision* create a file called *secrets.tfvars*. This file should have the following variables:
> databricks_account_id = "\<databricks account id\>"
>
> databricks_account_username = "\<databricks account owner username\>"
>
> databricks_account_password = "\<databricks account owner password\>"



