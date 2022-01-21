# terraform
### Databricks Terraform for provisioning Databricks E2 AWS PL Workspaces

This repo contains terraform templates and scripts for provisioning a E2 Databricks Workspace on AWS with PrivateLink. It includes all the AWS VPC infrastructure provisioning.

Running the templates will do the following:
* Provision AWS VPC in ap-southeast-2 region with 2 subnets in different AZs for the Workspace and 2 subnets in different AZs for PL (for redundancy)
  - By default VPC CIDR is 10.0.0.0/16 and subnets 10.0.0.0/19. This gives you over 8000 IP addresses per subnet/AZ, so over 4000 cluster nodes. If you want to adjust these ranges you can modify *cidr_block_prefix* and *subnet_offset* variables in *provision/variables.tf* file before running the template. Keep in mind that subnet netmask must be between /17 and /26 and you need to fit at least 2 Workspace subnets in different AZs. In addition, you need smaller subnets for PL and NAT, if choosing that option. This means *subnet_offset* should not be less than 2 (so 2 bits for space for 4 subnets).
* Provision Databricks PL for REST API and Relay integration and S3, STS, Kinesis, Glue PL for AWS
* Provision E2 Databricks Workspace objects through Account API
* Provision initial IAM Role with access to Glue Catalog
* Create a Test cluster with access to Glue Catalog and a Test Notebook to test the setup

Note, at this stage public access is on for Front End Workspace UI access, only the Back End Dataplane to Control Plane is configured with PL access.
Support for private access for Front End will be added to this template at a later stage.

#### Content
There are 2 subdirectories, *provision* and *workspace*. Each contains individual terraform templates.
*provision* will provision AWS VPC infrastructure and configure Databricks Workspace with Account API. After this template is run succesfully, the Workspace should be accessible through its url.
*workspace* will use PAT created by *provision* step to configure a Cluster and a Notebook in the newly created Workspace.
The whole thing is executed by running ./configure.sh script from root directory.

### Steps to execute the templates

1. Install Terraform. For Mac, this is described in https://learn.hashicorp.com/tutorials/terraform/install-cli.
2. Clone this repo to your machine.
3. Make sure you've configured your AWS CLI credentials with the AWS Account you want to deploy to.
4. In *provision* create a file called *secrets.tfvars*. This file should have the following variables:
> databricks_account_id       = "\<databricks account id>"<br>
> databricks_account_username = "\<databricks account owner username>"<br>
> databricks_account_password = "\<databricks account owner password>"<br>

These are your Databricks Account Id that you can get from Databricks Account Console, Your Databricks Account Owner User Name and Databricks Account Owner Password. If you don't have Databricks Account Id you can sign up for a 14 free trial in https://databricks.com/try-databricks to get it.
Be careful with password as secrets in Terraform are stored in plain text. This is why *secrets.tfvars* file is in .gitignore

4. Once you created *secrets.tfvars* file in *provision* subdirectory, back in root directory there is a script called *configure.sh*. Run this script and pass to it *-w <your workspace name>* parameter. So for example, if I want to create a Databricks Workspace called **demo**, I would run *./configure.sh -w demo* on command line.
5. The script will apply the template in *provision* subdirectory and then run the teamplate in *workspace* subdirectory.
6. If the script runs successfully it will output the url of the newly created workspace that you can access. The Workspace will have a Test cluster and a Test Notebook, created by the templates. You can run Test Notebook on Test cluster to verify that everything is working as it should.

### Usage
**./configure.sh [-igw] [-w \<workspace name\>]**<br>
| Argument              | Description    |
| ---                   | ---            |
|\-igw                  |- optional, if specified will still deploy with PL but also with NAT and IGW. Default is to deploy without NAT and IGW.<br> |
|\-w \<workspace name\> |- optional, deployment artefacts will have specified \<workspace name\> prefix and the Workspace will be named \<workspace name\>. If not specified <workspace name> will default to **terratest-\<random string\>**<br> |

### Steps to tear down deployment
To tear down deployment after you've run *configure.sh* script, there is a *destroy.sh* script.
Running *destroy.sh* does not require any arguments. Terraform maintains state of deployment in a state file as deployment steps are executed and it simply reverses the steps that were executed when deploying and cleanly deletes all the resources that were previosly deployed.

### NOTE
* If you are creating a PL Databricks Workspace the S3 VPC Gateway prevents access to global S3 url. Access to regional one only is allowed. For PL Workspaces with newly created S3 buckets sometimes it may take a bit of time to gain access to regional root S3 bucket, bypassing S3 global url. It may happen that running Test Notebook hangs due to trying to resolve S3 root bucket for DBFS mounts. In that case leaving the Workspace for an hour or so resolves the issue eventually.
Alternatively you can run with configure.sh with additional **-igw** flag. This will still deploy PrivateLink but also deploy NAT and IGW to allow outbound Internet access for any IPs not going via PrivateLink. In this case global S3 url is resolvable and everything works as expected.
* Feel free to use these templates as you see fit. If you wish to alter them to suit your needs please fork this repo and add your changes there.


