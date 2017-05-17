# Install and configure Solace message routers in an HA tuple using AWS Cloud Formation

![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-aws-ha-quickstart/master/images/Solace-AWS-HA-3AZ.png "Production enviroment for Solace VMR")

This QuickStart template installs Solace Virtual Message Routers (VMRs) in high-availability (HA) redundancy groups for fault tolerance. HA redundancy provides 1:1 router sparing to increase overall service availability. If one of the routers fails or is taken out of service, the other router automatically takes over and provides service to the clients that were previously served by the now-out-of-service router.  To increase availability the meassage routers are deployed across 3 availability zones.

To learn more about VMR redundancy see the [Redundancy Documentation](http://docs.solace.com/Features/VMR-Redundancy.htm).  If you are not familiar with Solace or the high-available configurations it is recommended that you review this document. 

![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-aws-ha-quickstart/master/images/Solace-AWS-HA-2AZ.png "Proof of Concept enviroment for Solace VMR")

Alternatively this quickstart can create Soalce VMRs into an enviroment sutible for Proof Of Concept testing where loss of an AWS Availability Zone will not cause loss of access to mision critical data.

To learn more about connectivity to the HA redundancy group see the AWS [VPC Gateway Documentation](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Internet_Gateway.html).

# How to Deploy a VMR HA 
This is a two step process:

* Go to the Solace Developer portal and request a Solace Comunity edition VMR. This process will return an email with a Download link. Do a right click "Copy Hyperlink" on the "Download the VMR Community Edition for Docker" hyperlink.  This will be needed in the following section.

<a href="http://dev.solace.com/downloads/download-vmr-evaluation-edition-docker" target="_blank">
    <img src="https://raw.githubusercontent.com/SolaceLabs/solace-aws-ha-quickstart/master/images/register.png"/>
</a>

* Go to AWS Cloud Formation service and launch template.  The following links are for your convenience and take you directly to the templates for Solace Mesage Routers.

<a href="https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=Solace-HA&templateURL=https://s3.amazonaws.com/solace-aws-ha-quickstart/latest/templates/solace-aws-master.template" target="_blank">
    <img src="https://raw.githubusercontent.com/SolaceLabs/solace-aws-ha-quickstart/master/images/launch-button-new.png"/>
</a>

<a href="https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=Solace-HA&templateURL=https://s3.amazonaws.com/solace-aws-ha-quickstart/latest/templates/solace-aws.template" target="_blank">
    <img src="https://raw.githubusercontent.com/SolaceLabs/solace-aws-ha-quickstart/master/images/launch-button-existing.png"/>
</a>

* If you want to take a look under the covers, you can view the AWS CloudFormation template that automates the deployment. You can customize the template during launch, or download and extend it for other projects.

<a href="https://raw.githubusercontent.com/SolaceLabs/solace-aws-ha-quickstart/master/templates/solace-aws-master.template" target="_blank">
    <img src="https://raw.githubusercontent.com/SolaceLabs/solace-aws-ha-quickstart/master/images/view-template-new.png"/>
</a>

<a href="https://raw.githubusercontent.com/SolaceLabs/solace-aws-ha-quickstart/master/templates/solace-aws.template" target="_blank">
    <img src="https://raw.githubusercontent.com/SolaceLabs/solace-aws-ha-quickstart/master/images/view-template-existing.png"/>
</a>

# Filling the templates
Select the Launch Quick Start (for new VPC) above will take you to the AWS "Select Template" tab with the Solace template references, hit the next button in the bottom right corner.

![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-aws-ha-quickstart/master/images/Select-Template.png "Select Template")

The next screen will allow you to fill in the details of the root AWS stack for this solution:

| Field                      | Value                                                                          |
|----------------------------|--------------------------------------------------------------------------------|
| Stack name                 | Default is Solace-HA, any unique name will suffice |
| SolaceDockerURL            | URL to Evaluation or Enterprise Solace VMR Docker image |
| AdminPassword              | Password to allow SolOS access to configure the Solace Message Router instances |
| AvailabilityZones          | Pick 3 AZs from the drop down menue, alternativey pick 2 for PoC or limited Region |
| NumberOfAZs                | Default is 3 unless only 2 AZs are selected above |
| VPCCIDR                    | Unless specific requirement for internal addressing leave at default, must encapsulate all the above Subnets |
| PublicSubnet1CIDR          | Unless specific requirement for internal addressing leave at default |
| PublicSubnet2CIDR          | Unless specific requirement for internal addressing leave at default |
| PublicSubnet3CIDR          | Unless specific requirement for internal addressing leave at default |
| RemoteAccessCIDR           | IP range that can send/recieve messages, use 0.0.0.0/0 if unsure |
| SSHAccessCIDR              | IP range that can configure VMR, use 0.0.0.0/0 if unsure |
| KeyPairName                | Pick from your exisitng key pairs, create new AWSW key pair if required |
| LinuxOSAMI                 | Default is Amazon-Linux-HVM, recommended stay with this selection |
| BootDiskSize               | Default is 24GB minimum is 20GB |
| MessageRouterNodeInstance  | Default is t2.large which is the minimum |
| MessageRouterNodeSpotPrice | Default is 0.00 which means not to use spot price |
| MessageRouterNodeStorage   | Default is 0 which means ephemeral |
| MonitorNodeInstance        | Default is t2.large which is the minimum | 
| MonitorNodeeSpotPrice      | Default is 0.00 which means not to use spot price |
| MonitorNodeStorage         | Default is 0 which means ephemeral |
| QSS3BucketName             | Leave at default |
| QSS3KeyPrefix              | Leave at default |

![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-aws-ha-quickstart/master/images/specify-details.png "Specify Details")

Select [next] on the "Options" screen unless you want to add tags, use specific IAM roles, or blend in custom stacks.

Acknoledge that resources will be created and select [Create] in bottom right corner.

![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-aws-ha-quickstart/master/images/capabilities.png "Create Stack")

# About Quick Starts

Quick Starts are automated reference deployments for key workloads on the AWS Cloud. Each Quick Start launches, configures, and runs the AWS compute, network, storage, and other services required to deploy a specific workload on AWS, using AWS best practices for security and availability.

# Testing data access to the ha cluster

To test data traffic though the newly created VMR instances, visit the Solace developer portal and and select your prefered programming langauge to [send and receive messages](http://dev.solace.com/get-started/send-receive-messages/). Under each language there is a Publish/Subscribe tutorial that will help you get started.

![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-aws-ha-quickstart/master/images/solace_tutorial.png "getting started publish/subscribe")

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

See the list of [contributors](https://github.com/SolaceLabs/solace-aws-ha-quickstart/graphs/contributors) who participated in this project.

## License

This project is licensed under the Apache License, Version 2.0. - See the [LICENSE](LICENSE) file for details.

## Resources

For more information about Solace technology in general please visit these resources:

- The Solace Developer Portal website at: http://dev.solace.com
- Understanding [Solace technology.](http://dev.solace.com/tech/)
- Ask the [Solace community](http://dev.solace.com/community/).
