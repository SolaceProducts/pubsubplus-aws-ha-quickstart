[![Actions Status](https://github.com/SolaceProducts/pubsubplus-aws-ha-quickstart/workflows/build/badge.svg?branch=master)](https://github.com/SolaceProducts/pubsubplus-aws-ha-quickstart/actions?query=workflow%3Abuild+branch%3Amaster)

# Install and Configure Solace PubSub+ Software Event Broker in an HA Tuple using AWS Cloud Formation

This project is a best practice template intended for development and demo purposes. The tested and recommended Solace PubSub+ Software Event Broker version is 9.13.
It is important to note that for earlier versions of Solace PubSub+ Software Event Broker, it is recommended that you use v3.1.0 of the quickstart. 

This document provides a quick getting started guide to install a Solace PubSub+ software event broker deployment in Amazon Web Services cloud computing platform.

![alt text](/images/Solace-AWS-HA-Prod-3AZ.png "Production Environment for Solace PubSub+")

This Quick Start template installs Solace PubSub+ Software Event Broker in fault tolerant high-availability (HA) redundancy groups. HA redundancy provides 1:1 event broker redundancy to increase overall service availability. If one of the event brokers fails, or is taken out of service, the other one automatically takes over and provides service to the clients that were previously served by the now out-of-service event broker.  To increase availability, the event brokers are deployed across 3 availability zones.

To learn more about event broker redundancy see the [Redundancy Documentation](https://docs.solace.com/Features/SW-Broker-Redundancy-and-Fault-Tolerance.htm ).  If you are not familiar with Solace PubSub+ or high-availability configurations it is recommended that you review this document. 

Alternatively this Quick Start can create event brokers in an environment suitable for Proof-of-Concept testing where loss of an AWS Availability Zone will not cause loss of access to mission critical data.

![alt text](/images/Solace-AWS-HA-PoC-2AZ.png "Proof of Concept Environment for Solace PubSub+ Software Event Broker")

There is another option where the Solace PubSub+ Software Event Broker is deployed in private VPC with internal facing network load balancer (LB). 
This options ensures the broker services are not exposed externally and only accessible in the private VPC selected during deployment.

![alt text](/images/Solace-AWS-HA-Prod-Private-VPC-3AZ.png "Proof of Concept Environment for Solace PubSub+ Software Event Broker with Internally Facing Broker Services")


# Minimum Resource Requirements

Below is the list of AWS resources that will be deployed by the Quick Start. Please consult the [Amazon VPC Limits](https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Appendix_Limits.html ) page and ensure that your AWS region is within the limit range per resource before launching:

| Resource                   | Deploy |
|----------------------------|--------|
| VPCs                       |   1    |
| subnets                    |   6    |
| Elastic IPs                |   5    |
| Internet Gateways          |   1    |
| NAT Gateways               |   3    |
| Running Instances          |   5    |
| Route Tables               |   5    |
| Network ACLs               |   1    |
| Endpoints                  |   1    |
| Security Groups            |   6    |

## Required IAM roles

Look for `AWS::IAM::Role` in the templates source for the list of required IAM roles to create the stacks. 

# How to Deploy PubSub+ Software Event Broker in an HA Group

This is a two step process:

**Step 1**: Obtain a reference to the Docker image of the event broker to be deployed

First, decide which [Solace PubSub+ Software Event Broker](https://docs.solace.com/Solace-SW-Broker-Set-Up/Setting-Up-SW-Brokers.htm ) edition and version is suitable to your use case.

The Docker image reference can be:

*	A public or accessible private Docker registry repository name with an optional tag. This is the recommended option if using PubSub+ Software Event Broker Standard. The default is to use the latest event broker image [available from Docker Hub](https://hub.docker.com/r/solace/solace-pubsub-standard/ ) as `solace/solace-pubsub-standard:latest`, or use a specific version [tag](https://hub.docker.com/r/solace/solace-pubsub-standard/tags/ ).

*	A Docker image download URL
     * If using Solace PubSub+ Software Event Broker Enterprise Evaluation Edition, go to the Solace Downloads page. For the image reference, copy and use the download URL in the Solace PubSub+ Software Event Broker Enterprise Evaluation Edition Docker Images section.

         | PubSub+ Software Event Broker Enterprise Evaluation Edition<br/>Docker Image
         | :---: |
         | 90-day trial version of PubSub+ Enterprise |
         | [Get URL of Evaluation Docker Image](http://dev.solace.com/downloads#eval ) |

     * If you have purchased a Docker image of Solace PubSub+ Enterprise, Solace will give you information for how to download the compressed tar archive package from a secure Solace server. Contact Solace Support at support@solace.com if you require assistance. Then you can host this tar archive together with its MD5 on a file server and use the download URL as the image reference.

**Step 2**: Go to the AWS Cloud Formation service and launch the template. The following links are for your convenience and take you directly to the event broker templates.

**Note:** Using `Launch Quick Start (for new VPC)` launches the AWS infrastructure stacks needed with the event broker stack on top (recommended)[-see Launch Option 1 in the next section of this document](#launch-option-1-parameters-for-deploying-into-a-new-vpc). However, if you have already have a VPC or previously launched this Quick Start within your target region and would like to re-deploy just the event broker stack on top of the existing AWS infrastructure stacks, you can use `Launch Quick Start (for existing VPC)`. 
This approach of deployment of the PubSub+ Event Broker is associated with Launch [Option 2](#launch-option-2-parameters-for-deploying-into-an-existing-vpc-with-publicly-accessible-broker-services) and [3](#launch-option-3-parameters-for-deploying-into-an-existing-vpc-with-broker-services-accessible-internally-within-vpc-only).

<a href="https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=Solace-HA&templateURL=https://s3.amazonaws.com/solace-products/pubsubplus-aws-ha-quickstart/latest/templates/solace-master.template" target="_blank">
    <img src="/images/launch-button-new.png"/>
</a>

<a href="https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=Solace-HA&templateURL=https://s3.amazonaws.com/solace-products/pubsubplus-aws-ha-quickstart/latest/templates/solace.template" target="_blank">
    <img src="/images/launch-button-existing.png"/>
</a>

* If you want to take a look under the hood, you can view the AWS CloudFormation template that automates the deployment. You can customize the template during launch or download and extend it for other projects. For that, copy your extended version of `scripts`, `submodules` and `templates` directories in a  folder in an S3 bucket and make them public.

<a href="https://raw.githubusercontent.com/SolaceProducts/pubsubplus-aws-ha-quickstart/master/templates/solace-master.template" target="_blank">
    <img src="/images/view-template-new.png"/>
</a>

<a href="https://raw.githubusercontent.com/SolaceProducts/pubsubplus-aws-ha-quickstart/master/templates/solace.template" target="_blank">
    <img src="/images/view-template-existing.png"/>
</a>

# Filling In the Templates

Selecting the 'Launch Quick Start' button shown above will take you to the AWS "Select Template" tab with the Solace template. You can change the deployment region using the drop-down menu in the top right corner. Hit the next button in the bottom right corner once you are done.

![alt text](/images/Select-Template.png "Select Template")

<br/><br/>

The next screen will allow you to fill in the details for the selected launch option.

![alt text](/images/specify-details.png "Specify Details")

<br/><br/>

### Launch option 1: Parameters for deploying into a new VPC

| Parameter label (name)     | Default   | Description                                                        |
|----------------------------|-----------|--------------------------------------------------------------------|
| Stack name                 | Solace-HA | Any globally unique name                                           |
| **PubSub+ Event Broker Configuration**      |           |                                                                    |
| PubSub+ Docker image reference (SolaceDockerImage) | solace/solace-pubsub-standard:latest | A reference to the Solace PubSub+ event broker Docker image, from step 1. Either the image name with optional tag in an accessible Docker registry or a download URL. The download URL can be obtained from http://dev.solace.com/downloads/ or it can be a URL to a remotely hosted image version, e.g. on S3 |
| Password to access PubSub+ admin console and SEMP (AdminPassword) | _Requires_ _input_ | Password to allow PubSub+ admin access to configure the event broker instances |
| Maximum Number of Client Connections (MaxClientConnections)| 100   | Broker system scaling: the maximum supported number of client connections |
| Maximum Number of Queue Messages (MaxQueueMessages)     | 100   | Broker system scaling: the maximum number of queue messages, in millions |
| Instance Type (WorkerNodeInstanceType) | m4.large | The EC2 instance type for the PubSub+ event broker primary and backup instances in Availability Zones 1 and 2. The m series are recommended for production use. <br/> Ensure adequate CPU and Memory resources are available to support the selected broker system scaling parameters. For requirements, check the [Solace documentation](//docs.solace.com/Configuring-and-Managing/SW-Broker-Specific-Config/System-Scaling-Parameters.htm). |
| Persistent Storage (WorkerNodeStorage) | 0 | Amazon event broker storage allocated for each block device, in GiBs. The Quick Start supports up to 640 GiB per device. For sizing requirements, check the [Solace documentation](//docs.solace.com/Configuring-and-Managing/SW-Broker-Specific-Config/System-Scaling-Parameters.htm). The default value of 0 (zero) indicates ephemeral storage only. A non-zero value will cause a new disk to be created for message-spool. This disk will not be deleted on stack termination. |
| Persistent Storage Type (WorkerNodeStorageType) | gp2 | Storage volume type provided by Amazon EBS if non-zero Persistent Storage has been specified. "io1" is recommended for Production environments (better performance, more expensive) and is required for large storage size |
| Instance Type (MonitorNodeInstanceType) | t2.small | The EC2 instance type for the PubSub+ event broker monitor instance in Availability Zone 3 (or Availability Zone 2, if you’re using only two zones). |
| Container logging format (ContainerLoggingFormat) | graylog | The format of the logs sent by the event broker to the CloudWatch service (see [documentation](https://docs.solace.com/Configuring-and-Managing/SW-Broker-Specific-Config/Docker-Tasks/Configuring-VMR-Container-Logging.htm?Highlight=logging#Config-Out-Form ) for details) |
| **Network Configuration**  |           |                                                                    |
| Number of Availability Zones (NumberOfAZs) | 3 | The number of Availability Zones (2 may be used for Proof-of-Concept testing or 3 for Production) you want to use in your deployment. This count must match the number of selections in the Availability Zones parameter; otherwise, your deployment will fail with an AWS CloudFormation template validation error. (Note that some regions provide only one or two Availability Zones.) |
| Availability Zones (AvailabilityZones) | _Requires_ _input_ | Choose two or three Availability Zones from this list, which shows the available zones within your selected region. The logical order of your selections is preserved in your deployment. After you make your selections, make sure that the value of the Number of Availability Zones parameter matches the number of selections. |
| Create production ready environment (CreatePrivateSubnets) | true | Whether to create and use Private subnets and accompanying public ELB with health-check, which is recommended for production deployment. In this case SSH access to the PubSub+ event broker nodes is only possible through the bastion hosts. |
| Permitted IP range for SSH Access (SSHAccessCIDR) | _Requires_ _input_ | The CIDR IP range that is permitted to access the event broker nodes via SSH for management purposes. We recommend that you set this value to a trusted IP range. You can use 0.0.0.0/0 for unrestricted access - not recommended for non-production use. |
| Allowed External Access CIDR (RemoteAccessCIDR) | _Requires_ _input_ | The CIDR IP range that is permitted to access the event broker nodes. We recommend that you set this value to a trusted IP range. For example, you might want to grant only your corporate network  access to the software. You can use 0.0.0.0/0 for unrestricted access - not recommended for non-production use. |
| **Common Amazon EC2 Configuration** | |                                                                     |
| Key Pair Name (KeyPairName) | _Requires_ _input_ | A new or an existing public/private key pair within the AWS Region, which allows you to connect securely to your instances after launch. |
| Boot Disk Capacity (BootDiskSize) | 24 | Amazon event broker storage allocated for the boot disk, in GiBs. The Quick Start supports 8-128 GiB. |
| **AWS Quick Start Configuration** | |                                                                     |
| Quick Start S3 Bucket Name (QSS3BucketName) | solace-products | S3 bucket where the Quick Start templates and scripts are installed. Change this parameter to specify the S3 bucket name you’ve created for your copy of Quick Start assets, if you decide to customize or extend the Quick Start for your own use. |
| Quick Start S3 bucket region (QSS3BucketRegion) | us-east-1 | The AWS Region where the Quick Start S3 bucket (QSS3BucketName) is hosted. When using your own bucket, you must specify this value. |
| Quick Start S3 Key Prefix (QSS3KeyPrefix) | pubsubplus-aws-ha-quickstart/latest/ | Specifies the S3 folder for your copy of Quick Start assets. Change this parameter if you decide to customize or extend the Quick Start for your own use. |

### Launch option 2: Parameters for deploying into an existing VPC with publicly accessible broker services.

If you are deploying into an existing VPC, most of the parameters are the same as for the new VPC option with the following additions:

| Parameter label (name)                                            | Default            | Description                                                                                                                                                                                                                                                                                                                                                |
|-------------------------------------------------------------------|--------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Network Configuration**                                         |                    |                                                                                                                                                                                                                                                                                                                                                            |
| VPC ID (VPCID)                                                    | _Requires_ _input_ | Choose the ID of your existing VPC stack - for a value, refer to the `VPCID` in the "VPCStack"'s `Outputs` tab in the AWS CloudFormation view (e.g., vpc-0343606e). This VPC must exist with the proper configuration for PubSub+ cluster access.                                                                                                          |
| VPC CIDR (VPC CIDR)                                               | _0.0.0.0/0_        | Choose the VPC CIDR of your existing VPC stack - for a value, refer to the `VPCCIDR` in the "VPCStack"'s `Outputs` tab in the AWS CloudFormation view (e.g., 10.0.0.0/16). This VPC CIDR must match with the `VPCID` parameter for proper configuration for PubSub+ cluster access.                                                                        |
| Public Subnet IDs (Public SubnetIDs)                              | _Requires_ _input_ | Choose public subnet IDs in your existing VPC from this list (e.g., subnet-4b8d329f,subnet-bd73afc8,subnet-a01106c2), matching your deployment architecture.                                                                                                                                                                                               |
| Private Subnet IDs (PrivateSubnetIDs)                             | _Requires_ _input_ | Choose private subnet IDs in your existing VPC from this list (e.g., subnet-4b8d329f,subnet-bd73afc8,subnet-a01106c2), matching your deployment architecture. Note: This parameter is ignored if you set the Use private subnets parameter to false, however you must still provide at least one item from the list (any) to satisfy parameter validation. |
| Security group allowed to access console SSH (SSHSecurityGroupID) | _Requires_ _input_ | The ID of the security group in your existing VPC that is allowed to access the console via SSH  - for a value, refer to the `BastionSecurityGroupID` in the "BastionStack"'s `Outputs` tab in the AWS CloudFormation view (e.g., sg-7f16e910). Note: This parameter is ignored if you set the Use private subnets parameter to false.                     |

### Launch option 3: Parameters for deploying into an existing VPC with broker services accessible internally within VPC only.

If you are deploying into an existing private VPC, then you will need the third deployment option. This allows broker nodes and services to only be accessed from within the private VPC. If both "VPC internal access only" and "Use private subnets" are set to `true`. It uses most of the parameters from the first two options.

| Parameter label (name)                                            | Default            | Description                                                                                                                                                                                                                                                                                                                                                |
|-------------------------------------------------------------------|--------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Network Configuration**                                         |                    |                                                                                                                                                                                                                                                                                                                                                            |
| VPC Internal access only (VPCAccessOnly)                          | false              | Whether broker nodes and services are only exposed internally to the VPC. Only applicable if private subnets used.                                                                                                                                                                                                                                         |
| Use private subnets (UsePrivateSubnets)                           | true               | Whether to deploy broker nodes into Private Subnets. Note: When this parameter and `VPCAccessOnly` are set to `true` it will ensure broker nodes are only accessible inside the VPC `VPCID`                                                                                                                                                                |


<br/><br/>

Select [next] after completing the parameters form to get to the "Options" screen.

Select [next] on the "Options" screen unless you want to add tags, use specific IAM roles, or blend in custom stacks.

Acknowledge that resources will be created and select [Create] in bottom right corner.

![alt text](/images/capabilities.png "Create Stack")

# Stack structure

The Quick Start will create the nested VPC, Bastion, and Solace stacks using their respective templates. The SolaceStack further creates sub-stacks for the deployment of the primary, backup and monitor event brokers. You’ll see all these listed in the AWS CloudFormation console, as illustrated below. Following the links in the Resources tab provides detailed information about the underlying resources.
 
![alt text](/images/stacks-after-deploy-success.png "Created stacks after deployment")

For external access to the deployment (explained in the next sections), the resources of interest are the
*	the Elastic Load Balancer (ELB), and
*	the EC2 instances for the primary, backup, and monitoring event brokers.

For messaging and management access to the active event broker, you will need to note the information about the ELB’s DNS host name, which can be obtained from the `SolaceStack > Resources > ELB, or the EC2 Dashboard > Load Balancing > Load Balancers` section:
 
![alt text](/images/elb-details.png "ELB details")

For direct SSH access to the individual event brokers, the public DNS host names (elastic IPs) of the EC2 instances of the Bastion Hosts and the private DNS host names of the primary, backup, and monitoring event brokers are required. This can be obtained from the `EC2 Dashboard > Instances > Instances` section: 
 
![alt text](/images/ec2-instance-details.png "EC2 instances details")


# Gaining admin access to the Solace PubSub+ Software Event Broker

## Using SSH connection to the individual event brokers

For persons used to working with event broker console access, this is still available with the AWS EC2 instance:

* Copy the Key Pair file used during deployment (KeyPairName) to the Linux Bastion Host. The key must not be publicly viewable.
```
chmod 400 <key.pem>
scp -i <key.pem> <key.pem> ec2-user@<bastion-elastic-ip>:/home/ec2-user
```
* Log in to the Linux Bastion Host
```
ssh -i <key.pem> ec2-user@<bastion-elastic-ip>
```
* From the Linux Bastion Host, SSH to your desired EC2 host that is running the event broker.
```
ssh -i <key.pem> ec2-user@<ec2-host>
```
* From the host, log into the PubSub+ CLI
```
sudo docker exec -it solace /usr/sw/loads/currentload/bin/cli -A
```

## Management tools access through the ELB

Non-CLI [management tools](https://docs.solace.com/Management-Tools.htm ) can access the event broker cluster through the ELB’s public DNS host name at port 8080. Use the user `admin` and the password you set for the "AdminPassword".

# Event Broker Logs

Both host and container logs get logged to [Amazon CloudWatch](https://aws.amazon.com/cloudwatch/ ) on the region where the deployment occurred. The event broker logs can be found under the `*/solace.log` log stream. The `ContainerLoggingFormat` field can be used to control the log output format.

![alt text](/images/CloudWatch_logging.png "CloudWatch Logging")

# About Quick Starts

Quick Starts are automated reference deployments for key workloads on the AWS Cloud. Each Quick Start launches, configures, and runs the AWS compute, network, storage, and other services required to deploy a specific workload on AWS using AWS best practices for security and availability.

# Testing data access to the HA cluster

To test data traffic though the newly created event broker instances, [visit the Solace developer portal and select your preferred API or protocol](//dev.solace.com/get-started/send-receive-messages/) to send and receive messages. Under each language there is a Publish/Subscribe tutorial that will help you get started.

For data, the event broker cluster can be accessed through the ELB’s public DNS host name and the API or protocol specific port. 

![alt text](/images/solace_tutorial.png "getting started publish/subscribe")

# Updating or Upgrading the HA cluster

It is important to note that, AWS HA quickstart will not be used to modify an existing deployment. That is, you can not update, one deployment  configuration to another with the quickstart.
You can not for instance migrate PubSub+ broker HA nodes in public VPC to a private VPC by running the AWS HA quickstart. You can also, not upgrade or downgrade docker images or other configurations after installation. 
It is strictly for installation and has no update workflow.



## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

See the list of [contributors](../../graphs/contributors) who participated in this project.

## License

This project is licensed under the Apache License, Version 2.0. - See the [LICENSE](LICENSE) file for details.

## Resources

For more information about Solace PubSub+ technology in general please visit these resources:

- The Solace Developer Portal website at: [solace.dev](//solace.dev/)
- Understanding [Solace technology](//solace.com/products/platform/)
- Ask the [Solace community](//dev.solace.com/community/).
