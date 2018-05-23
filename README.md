[![Build Status](https://travis-ci.org/SolaceProducts/solace-aws-ha-quickstart.svg?branch=master)](https://travis-ci.org/SolaceProducts/solace-aws-ha-quickstart)

# Install and Configure Solace PubSub+ Software Message Brokers in an HA Tuple using AWS Cloud Formation

![alt text](/images/Solace-AWS-HA-Prod-3AZ.png "Production Environment for Solace PubSub+ Software Message Brokers")

This Quick Start template installs Solace PubSub+ software message brokers in fault tolerant high-availability (HA) redundancy groups. HA redundancy provides 1:1 message broker redundancy to increase overall service availability. If one of the message brokers fails, or is taken out of service, the other one automatically takes over and provides service to the clients that were previously served by the now out-of-service message broker.  To increase availability, the message brokers are deployed across 3 availability zones.

To learn more about message broker redundancy see the [Redundancy Documentation](https://docs.solace.com/Features/SW-Broker-Redundancy-and-Fault-Tolerance.htm ).  If you are not familiar with Solace PubSub+ or high-availability configurations it is recommended that you review this document. 

![alt text](/images/Solace-AWS-HA-PoC-2AZ.png "Proof of Concept Environment for Solace PubSub+ Software Message Brokers")

Alternatively this Quick Start can create message brokers in an environment suitable for Proof-of-Concept testing where loss of an AWS Availability Zone will not cause loss of access to mission critical data.

To learn more about connectivity to the HA redundancy group see the AWS [VPC Gateway Documentation](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Internet_Gateway.html ).

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

# How to Deploy a Message Broker in an HA Group

This is a two step process:

**Step 1**: Go to the Solace Developer Portal and copy the download URL of the Solace PubSub+ software message broker **Docker** image. 

You can use this quick start template with either PubSub+ `Standard` or PubSub+ `Enterprise Evaluation Edition`.

| PubSub+ Standard<br/>Docker Image | PubSub+ Enterprise Evaluation Edition<br/>Docker Image
| :---: | :---: |
| Free, up to 1k simultaneous connections,<br/>up to 10k messages per second | 90-day trial version of PubSub+ Enterprise |
| [Get URL of Standard Docker Image](http://dev.solace.com/downloads/) | [Get URL of Evaluation Docker Image](http://dev.solace.com/downloads#eval ) |

**Step 2**: Go to the AWS Cloud Formation service and launch the template. The following links are for your convenience and take you directly to the message broker templates.

**Note:** Using `Launch Quick Start (for new VPC)` launches the AWS infrastructure stacks needed with the message broker stack on top (recommended). However, if you have previously launched this Quick Start within your target region and would like to re-deploy just the message broker stack on top of the existing AWS infrastructure stacks, you can use `Launch Quick Start (for existing VPC)`.

<a href="https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=Solace-HA&templateURL=https://s3.amazonaws.com/solace-products/solace-aws-ha-quickstart/latest/templates/solace-master.template" target="_blank">
    <img src="/images/launch-button-new.png"/>
</a>

<a href="https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=Solace-HA&templateURL=https://s3.amazonaws.com/solace-products/solace-aws-ha-quickstart/latest/templates/solace.template" target="_blank">
    <img src="/images/launch-button-existing.png"/>
</a>

* If you want to take a look under the hood, you can view the AWS CloudFormation template that automates the deployment. You can customize the template during launch or download and extend it for other projects. For that, copy your extended version of `scripts`, `submodules` and `templates` directories in a  folder in an S3 bucket and make them public.

<a href="https://raw.githubusercontent.com/SolaceProducts/solace-aws-ha-quickstart/master/templates/solace-master.template" target="_blank">
    <img src="/images/view-template-new.png"/>
</a>

<a href="https://raw.githubusercontent.com/SolaceProducts/solace-aws-ha-quickstart/master/templates/solace.template" target="_blank">
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
| **Solace Parameters**      |           |                                                                    |
| Solace Docker URL (SolaceDockerURL) | _Requires_ _input_ | Solace PubSub+ software message broker Docker image download URL from Step 1. Can also use load versions hosted remotely (if so, a .md5 file needs to be created in the same remote directory) |
| Password to access Solace admin console and SEMP (AdminPassword) | _Requires_ _input_ | Password to allow Solace admin access to configure the message broker instances |
| Container logging format (ContainerLoggingFormat) | graylog | The format of the logs sent by the message broker to the CloudWatch service (see [documentation](https://docs.solace.com/Configuring-and-Managing/SW-Broker-Specific-Config/Docker-Tasks/Configuring-VMR-Container-Logging.htm?Highlight=logging#Config-Out-Form ) for details) |
| **Network Configuration**  |           |                                                                    |
| Number of Availability Zones (NumberOfAZs) | 3 | The number of Availability Zones (2 may be used for Proof-of-Concept testing or 3 for Production) you want to use in your deployment. This count must match the number of selections in the Availability Zones parameter; otherwise, your deployment will fail with an AWS CloudFormation template validation error. (Note that some regions provide only one or two Availability Zones.) |
| Availability Zones (AvailabilityZones) | _Requires_ _input_ | Choose two or three Availability Zones from this list, which shows the available zones within your selected region. The logical order of your selections is preserved in your deployment. After you make your selections, make sure that the value of the Number of Availability Zones parameter matches the number of selections. |
| Create production ready environment (CreatePrivateSubnets) | true | Whether to create and use Private subnets and accompanying public ELB with health-check, which is recommended for production deployment. In this case SSH access to the Solace message broker nodes is only possible through the bastion hosts. |
| Permitted IP range for SSH Access (SSHAccessCIDR) | _Requires_ _input_ | The CIDR IP range that is permitted to access the message broker nodes via SSH for management purposes. We recommend that you set this value to a trusted IP range. You can use 0.0.0.0/0 for unrestricted access - not recommended for non-production use. |
| Allowed External Access CIDR (RemoteAccessCIDR) | _Requires_ _input_ | The CIDR IP range that is permitted to access the message broker nodes. We recommend that you set this value to a trusted IP range. For example, you might want to grant only your corporate network  access to the software. You can use 0.0.0.0/0 for unrestricted access - not recommended for non-production use. |
| **Common Amazon EC2 Configuration** | |                                                                     |
| Key Pair Name (KeyPairName) | _Requires_ _input_ | A new or an existing public/private key pair within the AWS Region, which allows you to connect securely to your instances after launch. |
| Boot Disk Capacity (BootDiskSize) | 24 | Amazon EBS storage allocated for the boot disk, in GiBs. The Quick Start supports 8-128 GiB. |
| **MessageRouterInstance Configuration** | |                                                                     |
| Instance Type (MessageRouterNode InstanceType) | m4.large | The EC2 instance type for the Solace message broker primary and backup instances in Availability Zones 1 and 2. The m series are recommended for production use. <br/> The available CPU and memory of the selected machine type will limit the maximum connection scaling tier for the Solace message broker. For requirements, refer to the [Solace documentation](https://docs.solace.com/Solace-SW-Broker-Set-Up/Setting-Up-SW-Brokers.htm#Compare) |
| Persistent Storage (MessageRouterNode Storage) | 0 | Amazon EBS storage allocated for each block device, in GiBs. The Quick Start supports up to 640 GiB per device. The default value of 0 (zero) indicates emphemeral storage only. A non-zero value will cause a new Provisioned IOPS SSD (io1) disk to be created for message-spool. This disk will not be deleted on stack termination. |
| **MonitorInstance Configuration** | |                                                                     |
| Instance Type (MonitorNodeInstanceType) | t2.micro | The EC2 instance type for the Solace message broker monitor instance in Availability Zone 3 (or Availability Zone 2, if you’re using only two zones). |
| **AWS Quick Start Configuration** | |                                                                     |
| Quick Start S3 Bucket Name (QSS3BucketName) | solace-products | S3 bucket where the Quick Start templates and scripts are installed. Change this parameter to specify the S3 bucket name you’ve created for your copy of Quick Start assets, if you decide to customize or extend the Quick Start for your own use. |
| Quick Start S3 Key Prefix (QSS3KeyPrefix) | solace-aws-ha-quickstart/latest/ | Specifies the S3 folder for your copy of Quick Start assets. Change this parameter if you decide to customize or extend the Quick Start for your own use. |

### Launch option 2: Parameters for deploying into an existing VPC

If you are deploying into an existing VPC, most of the parameters are the same as for the new VPC option with the following additions:

| Parameter label (name)     | Default   | Description                                                        |
|----------------------------|-----------|--------------------------------------------------------------------|
| **Network Configuration**  |           |                                                                    |
| VPC ID (VPCID)             | _Requires_ _input_ | Choose the ID of your existing VPC stack - for a value, refer to the `VPCID` in the "VPCStack"'s `Outputs` tab in the AWS CloudFormation view (e.g., vpc-0343606e). This VPC must exist with the proper configuration for Solace cluster access. |
| Public Subnet IDs (Public SubnetIDs) | _Requires_ _input_ | Choose public subnet IDs in your existing VPC from this list (e.g., subnet-4b8d329f,subnet-bd73afc8,subnet-a01106c2), matching your deployment architecture. |
| Private Subnet IDs (PrivateSubnetIDs) | _Requires_ _input_ | Choose private subnet IDs in your existing VPC from this list (e.g., subnet-4b8d329f,subnet-bd73afc8,subnet-a01106c2), matching your deployment architecture. Note: This parameter is ignored if you set the Use private subnets parameter to false, however you must still provide at least one item from the list (any) to satisfy parameter validation. |
| Security group allowed to access console ssh (SSHSecurityGroupID) | _Requires_ _input_ | The ID of the security group in your existing VPC that is allowed to access the console via SSH  - for a value, refer to the `BastionSecurityGroupID` in the "BastionStack"'s `Outputs` tab in the AWS CloudFormation view (e.g., sg-7f16e910). Note: This parameter is ignored if you set the Use private subnets parameter to false. |

<br/><br/>

Select [next] after completing the parameters form to get to the "Options" screen.

Select [next] on the "Options" screen unless you want to add tags, use specific IAM roles, or blend in custom stacks.

Acknowledge that resources will be created and select [Create] in bottom right corner.

![alt text](/images/capabilities.png "Create Stack")

# Stack structure

The Quick Start will create the nested VPC, Bastion, and Solace stacks using their respective templates. The SolaceStack further creates sub-stacks for the deployment of the primary, backup and monitor message brokers. You’ll see all these listed in the AWS CloudFormation console, as illustrated below. Following the links in the Resources tab provides detailed information about the underlying resources.
 
![alt text](/images/stacks-after-deploy-success.png "Created stacks after deployment")

For external access to the deployment (explained in the next sections), the resources of interest are the
*	the Elastic Load Balancer (ELB), and
*	the EC2 instances for the primary, backup, and monitoring message brokers.

For messaging and management access to the active message broker, you will need to note the information about the ELB’s DNS host name, which can be obtained from the `SolaceStack > Resources > ELB, or the EC2 Dashboard > Load Balancing > Load Balancers` section:
 
![alt text](/images/elb-details.png "ELB details")

For direct SSH access to the individual message brokers, the public DNS host names (elastic IPs) of the EC2 instances of the Bastion Hosts and the private DNS host names of the primary, backup, and monitoring message brokers are required. This can be obtained from the `EC2 Dashboard > Instances > Instances` section: 
 
![alt text](/images/ec2-instance-details.png "EC2 instances details")


# Gaining admin access to the message broker

## Using SSH connection to the individual message brokers

For persons used to working with Solace PubSub+ message broker console access, this is still available with the AWS EC2 instance:

* Copy the Key Pair file used during deployment (KeyPairName) to the Linux Bastion Host. The key must not be publicly viewable.
```
chmod 400 <key.pem>
scp -i <key.pem> <key.pem> ec2-user@<bastion-elastic-ip>:/home/ec2-user
```
* Log in to the Linux Bastion Host
```
ssh -i <key.pem> ec2-user@<bastion-elastic-ip>
```
* From the Linux Bastion Host, SSH to your desired EC2 host that is running the message broker.
```
ssh -i <key.pem> ec2-user@<ec2-host>
```
* From the host, log into the Solace CLI
```
sudo docker exec -it solace /usr/sw/loads/currentload/bin/cli -A
```

## Management tools access through the ELB

Non-CLI [management tools](https://docs.solace.com/Management-Tools.htm ) can access the message broker cluster through the ELB’s public DNS host name at port 8080. Use the user `admin` and the password you set for the "AdminPassword".

# Message Broker Logs

Both host and container logs get logged to [Amazon CloudWatch](https://aws.amazon.com/cloudwatch/ ) on the region where the deployment occurred. The message broker logs can be found under the `*/solace.log` log stream. The `ContainerLoggingFormat` field can be used to control the log output format.

![alt text](/images/CloudWatch_logging.png "CloudWatch Logging")

# About Quick Starts

Quick Starts are automated reference deployments for key workloads on the AWS Cloud. Each Quick Start launches, configures, and runs the AWS compute, network, storage, and other services required to deploy a specific workload on AWS using AWS best practices for security and availability.

# Testing data access to the HA cluster

To test data traffic though the newly created message broker instances, visit the Solace developer portal and select your preferred API or protocol to [send and receive messages](http://dev.solace.com/get-started/send-receive-messages/). Under each language there is a Publish/Subscribe tutorial that will help you get started.

For data, the message broker cluster can be accessed through the ELB’s public DNS host name and the API or protocol specific port. 

![alt text](/images/solace_tutorial.png "getting started publish/subscribe")

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

See the list of [contributors](../../graphs/contributors) who participated in this project.

## License

This project is licensed under the Apache License, Version 2.0. - See the [LICENSE](LICENSE) file for details.

## Resources

For more information about Solace PubSub+ technology in general please visit these resources:

- The Solace Developer Portal website at: http://dev.solace.com
- Understanding [Solace technology.](http://dev.solace.com/tech/)
- Ask the [Solace community](http://dev.solace.com/community/).
