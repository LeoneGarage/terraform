# terraform
### Databricks Terraform for provisioning Databricks E2 AWS PL Workspaces

This repo contains terraform templates and scripts for provisioning a E2 Databricks Workspace on AWS with PrivateLink. It includes all the AWS VPC infrastructure provisioning.

Running the templates will do the following:
* Provision AWS VPC in ap-southeast-2 region with 2 subnets in different AZs for the Workspace and 2 subnets in different AZs for PL (for redundancy)
  - By default VPC CIDR is 10.0.0.0/16 and subnets 10.0.0.0/19. This gives you over 8000 IP addresses per subnet/AZ, so over 4000 cluster nodes. If you want to adjust these ranges you can modify *cidr_block_prefix* and *subnet_offset* variables in *provision/variables.tf* file before running the template. Keep in mind that subnet netmask must be between /17 and /26 and you need to fit at least 2 Workspace subnets in different AZs. In addition, you need smaller subnets for PL and NAT, if choosing that option. This means *subnet_offset* should not be less than 2 (so 2 bits for space for 4 subnets).
* Provision Databricks PL for REST API and Relay integration and S3, STS, Kinesis, Glue PL for AWS
* By default the templates will create and configure Customer Managed Keys for encryption of managed services (i.e. Notebooks, Metastore in Control Plane etc) and root S3 bucket storage. These can be individually turned off using script arguments described in Usage section below.
* Provision E2 Databricks Workspace objects through Account API
* Provision initial IAM Role with access to Glue Catalog
* Create a Test cluster with access to Glue Catalog and a Test Notebook to test the setup

Note, by default, the templates provision Back End Data Plane to Control Plane VPC Endpoints and allow public access for the Workspace UI.
If you wish to also configure Front End VPC Endpoint you can pass *--front_end_pl_subnet_ids* and *--front_end_pl_source_subnet_ids* arguments to *configure.sh* script. Each of these arguments takes a comma separated list of AWS Subnet ids for existing subnets. If you are reusing the same VPC as Data Plane Workspace VPC for Front End VPC Endpoint don't pass *--front_end_pl_subnet_ids*, it will use the one it will create for Back End Workspace VPC. More details in Usage section below.
You may also want to disable public access to the Workspace. You can do this by passing *--front_end_access private* argument to *configure.sh* script.
Beware, if you do turn off public access, Workspace configuration template in *workspace* subdirectory would then need to be run from a VPN or VM that can reach the Workspace, since with public access off the Workspace APIs will be unreachable except where network routing to Front End VPC Endpoint is possible.
In that scenario you may choose to run *provision.sh* script to only provision Databricks Workspace and run *workspace.sh* separately. These are described below.

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
./configure.sh [**-igw**]  [**-nocmk** all | managed | storage]  [**-w** \<workspace name\>]  [**--front_end_access** private|public]  [**--front_end_pl_subnet_ids** \<subnet_id1\>,\<subnet_id2\>]  [**--front_end_pl_source_subnet_ids** \<subnet_id1\>,\<subnet_id2\>]<br>
| Argument              | Description    |
| ---                   | ---            |
|**-igw**                  |- optional, if specified will still deploy with PL but also with NAT and IGW. Default is to deploy without NAT and IGW.<br> |
|**-w** \<workspace name\> |- optional, deployment artefacts will have specified \<workspace name\> prefix and the Workspace will be named \<workspace name\>. If not specified <workspace name> will default to **terratest-\<random string\>**<br> |
|**&#8209;nocmk**&#160;all&#160;\|&#160;managed&#160;\|&#160;storage |- optional, Customer Managed Keys are created and configured for both managed services and root S3 bucket storage. This can be turned off. If you specify all, no CMK keys will be configured at all and default encryption in Control Plane will be used. If you specify managed, no managed services CMK encryption will be provisioned and default Control Plane encryption will be used instead. If you specify storage, no storage root S3 bucket CMK enncryption will be provisioned and default Control Plane encryption will be used instead |
  |**&#8209;&#8209;front_end_pl_subnet_ids**&#160;<subnet_id1>,<subnet_id2> |- optional, Specify AWS Subnet ids, 1 or more, where Front End Databricks Workspace VPC Endpoint will be provisioned. If the subnets are the same as the Workspace subnets omit this argument|
|<nobr>**&#8209;&#8209;front_end_pl_source_subnet_ids**&#160;<subnet_id1>,<subnet_id2></nobr> |- optional, Specify AWS Subnet ids, 1 or more, which will route Databricks Front End Workspace traffic to the Front End VPC Endpoint. This could be your Direct Connect Transit VPC Subnet. If this is the same as the subnets used for --front_end_pl_subnet_ids above, omit this argument. Note if these subnets are inn a different VPC to where you deploying Front End VPC Endpoint i.e. subnets in --front_end_pl_subnet_ids argument above, the traffic must be routable from this VPC to the Front End VPC |
|**--front_end_access** private\|public | - optional, Specify whether you still wish to allow public Internet access to your Workspace URL or not. If you deny public access and you are running these templates from a VM that is not routable to Front End VPC Endpoint subnets specified in --front_end_pl_subnet_ids, the *workspace* templates will not be able to access the Workspace APIs |

#### Example
Let's assume you want to deploy a workspace called 'my_workspace' and you don't want to provision Customer Managed Keys for encryption of Managed Services objects and Root S3 Storage, and you want to deploy Front End Workspace VPC Endpoint into a VPC Subnet separate from the Workspace VPC which will be created by the template, let's assume the AWS Subnet Id in this VPC Endpoint is 'subnet-0c00ac0320cba6d93' and you want to route traffic to this subnet from another subnet in a different VPC, let's assume that subnets AWS Subnet Id is 'subnet-ad00ac0320cba6e00'. The the command line to configure the Workspace would be:

**./configure.sh**&#160;**&#8209;w**&#160;*my_workspace*&#160;**&#8209;nocmk**&#160;*all*&#160;**&#8209;&#8209;front_end_pl_subnet_ids**&#160;*subnet&#8209;0c00ac0320cba6d93* \\ **&#8209;&#8209;front_end_pl_source_subnet_ids**&#160;*subnet&#8209;ad00ac0320cba6e00*

You may also run *provision* script independendently from *workspace* script.
There is *provision.sh* script which is also called from *configure.sh* script that you can run which will only provision the Workspace. The arguments to *provision.sh* script are the same as *configure.sh* script described above.
Subsequently, *workspace.sh* script can be run separately to configure the created Databrticks Workspace. *workspace.sh* script does not take any arguments, but needs access to terraform state that was created as part of runing *provision.sh*.

### Steps to tear down deployment
To tear down deployment after you've run *configure.sh* script, there is a *destroy.sh* script.
Running *destroy.sh* does not require any arguments. Terraform maintains state of deployment in a state file as deployment steps are executed and it simply reverses the steps that were executed when deploying and cleanly deletes all the resources that were previosly deployed.

### NOTE
* If you are creating a PL Databricks Workspace the S3 VPC Gateway prevents access to global S3 url. Access to regional one only is allowed. For PL Workspaces with newly created S3 buckets sometimes it may take a bit of time to gain access to regional root S3 bucket, bypassing S3 global url. It may happen that running Test Notebook hangs due to trying to resolve S3 root bucket for DBFS mounts. In that case leaving the Workspace for an hour or so resolves the issue eventually.
Alternatively you can run with configure.sh with additional **-igw** flag. This will still deploy PrivateLink but also deploy NAT and IGW to allow outbound Internet access for any IPs not going via PrivateLink. In this case global S3 url is resolvable and everything works as expected.
* Feel free to use these templates as you see fit. If you wish to alter them to suit your needs please fork this repo and add your changes there.


