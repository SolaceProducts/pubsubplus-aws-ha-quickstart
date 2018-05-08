[![Build Status](https://travis-ci.org/SolaceProducts/solace-aws-ha-quickstart.svg?branch=master)](https://travis-ci.org/SolaceProducts/solace-aws-ha-quickstart)

# Install and Configure Solace PubSub+ Software Message Brokers in an HA Tuple using AWS Cloud Formation

![alt text](/images/Solace-AWS-HA-Prod-3AZ.png "Production Environment for Solace PubSub+ Software Message Brokers")

This Quick Start template installs Solace PubSub+ software message brokers in fault tolerant high-availability (HA) redundancy groups. HA redundancy provides 1:1 message broker sparing to increase overall service availability. If one of the message brokers fails, or is taken out of service, the other one automatically takes over and provides service to the clients that were previously served by the now out-of-service message broker.  To increase availability, the message brokers are deployed across 3 availability zones.

To learn more about message broker redundancy see the [Redundancy Documentation](http://docs.solace.com/Features/SW-Broker-Redundancy-and-Fault-Tolerance.htm).  If you are not familiar with Solace PubSub+ or high-availability configurations it is recommended that you review this document. 

![alt text](/images/Solace-AWS-HA-PoC-2AZ.png "Proof of Concept Environment for Solace PubSub+ Software Message Brokers")

Alternatively this Quick Start can create message brokers in an environment suitable for Proof-of-Concept testing where loss of an AWS Availability Zone will not cause loss of access to mission critical data.

To learn more about connectivity to the HA redundancy group see the AWS [VPC Gateway Documentation](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Internet_Gateway.html).

# Minimum Resource Requirements

Below is the list of AWS resources that will be deployed by the Quick Start. Please consult the [Amazon VPC Limits](https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Appendix_Limits.html) page and ensure that your AWS region is within the limit range per resource before launching:

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

Look for `AWS::IAM::Role` in the source for the list of required IAM roles to create the stacks.

# How to Deploy a Message Broker in an HA Group

This is a two step process:

**Step 1**: Go to the Solace Developer Portal and request a Solace PubSub+ software message broker. This process will return an email with a Download link. To get going, right click "Copy Hyperlink" on the "Download the Solace PubSub+ Software Message Broker for Docker" hyperlink. This will be needed in the following section.

You can use this quick start with either PubSub+ `Standard` or PubSub+ `Enterprise Evaluation Edition`.

| PubSub+ Standard | PubSub+ Enterprise Evaluation Edition
| :---: | :---: |
| Free, up to 1k simultaneous connections,<br/>up to 100k messages per second | 90-day trial version, unlimited |
| <a href="http://dev.solace.com/downloads/download_vmr-ce-docker" target="_blank"><img src="images/register.png"/></a> | <a href="http://dev.solace.com/downloads/download-vmr-evaluation-edition-docker/" target="_blank"><img src="images/register.png"/></a> |

**Step 2**: Go to the AWS Cloud Formation service and launch the template. The following links are for your convenience and take you directly to the message broker templates.

**Note:** Using `Launch Quick Start (for new VPC)` launches the AWS infrastructure stacks needed with the message broker stack on top (recommended). However, if you have previously launched this Quick Start within your target region and would like to re-deploy just the message broker stack on top of the existing AWS infrastructure stacks, you can use `Launch Quick Start (for existing VPC)`.

<a href="https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=Solace-HA&templateURL=https://s3.amazonaws.com/solace-products/solace-aws-ha-quickstart/latest/templates/solace-master.template" target="_blank">
    <img src="/images/launch-button-new.png"/>
</a>

<a href="https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=Solace-HA&templateURL=https://s3.amazonaws.com/solace-products/solace-aws-ha-quickstart/latest/templates/solace.template" target="_blank">
    <img src="/images/launch-button-existing.png"/>
</a>

* If you want to take a look under the hood, you can view the AWS CloudFormation template that automates the deployment. You can customize the template during launch or download and extend it for other projects.

<a href="https://raw.githubusercontent.com/SolaceProducts/solace-aws-ha-quickstart/master/templates/solace-master.template" target="_blank">
    <img src="/images/view-template-new.png"/>
</a>

<a href="https://raw.githubusercontent.com/SolaceProducts/solace-aws-ha-quickstart/master/templates/solace.template" target="_blank">
    <img src="/images/view-template-existing.png"/>
</a>

# Filling In the Templates

Selecting the 'Launch Quick Start (for new VPC)' above will take you to the AWS "Select Template" tab with the Solace template referenced in region `us-east-1`. You can change the deployment region using the drop-down menu in the top right corner. Hit the next button in the bottom right corner once you are done.

![alt text](/images/Select-Template.png "Select Template")

The next screen will allow you to fill in the details of the root AWS stack for this solution:

| Field                      | Value                                                                          |
|----------------------------|--------------------------------------------------------------------------------|
| Stack name                 | Default is Solace-HA, any unique name will suffice |
| **Solace Parameters**      |  |
| SolaceDockerURL            | URL from the registration email. Can also use load versions hosted remotely (if so, a .md5 file needs to be created in the same remote directory) |
| AdminPassword              | Password to allow Solace admin access to configure the message broker instances |
| ContainerLoggingFormat     | The format of the logs sent by the message broker to the CloudWatch service (see [documentation](https://docs.solace.com/Configuring-and-Managing/SW-Broker-Specific-Config/Docker-Tasks/Configuring-VMR-Container-Logging.htm?Highlight=log%20output#Config-Out-Form) for details) |
| **Network Parameters**     |  |
| NumberOfAZs                | Default is 3. Depends on number of `AvailibilityZones` selected |
| AvailabilityZones          | Pick 3 AZs from the drop-down menu, alternatively pick 2 for PoC or limited Region. Must equal `NumberOfAZs` |
| ProductionEnv              | True will create Private subnets and accompanying public ELB with health-check if production deployment |
| RemoteAccessCIDR           | IP range that can send/receive messages, use 0.0.0.0/0 if unsure |
| SSHAccessCIDR              | IP range that can configure message broker, use 0.0.0.0/0 if unsure |
| **EC2 Parameters**         |  |
| KeyPairName                | Pick from your existing key pairs, create new AWSW key pair if required |
| BootDiskSize               | Default is 24GB minimum is 20GB |
| MessageRouterNodeInstance  | Default is t2.large which is the minimum |
| MessageRouterNodeStorage   | Default is 0 which means ephemeral, non-zero will cause new io1 disk creation for message-spool which will not delete on stack termination |
| MonitorNodeInstance        | Default is t2.large which is the minimum | 
| **AWS Quick Start Config**  |  |   
| QSS3BucketName             | Leave at default. References the S3 bucket where the templates are hosted |
| QSS3KeyPrefix              | Leave at default. References the path to the Quick Start resources within the S3 bucket |

![alt text](/images/specify-details.png "Specify Details")

Select [next] on the "Options" screen unless you want to add tags, use specific IAM roles, or blend in custom stacks.

Acknowledge that resources will be created and select [Create] in bottom right corner.

![alt text](/images/capabilities.png "Create Stack")

# Stack structure

The Quick Start will create the nested VPC, Bastion, and Solace stacks using their respective templates. The SolaceStack further creates sub-stacks for the deployment of the primary, backup and monitor message brokers. You’ll see all these listed in the AWS CloudFormation console, as illustrated in below. Following the links in the Resources tab provides detailed information about the underlying resources.
 
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

Both host and container logs get logged to [Amazon CloudWatch](https://aws.amazon.com/cloudwatch/) on the region where the deployment occurred. The message broker logs can be found under the `*/solace.log` log stream. The `ContainerLoggingFormat` field can be used to control the log output format.

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