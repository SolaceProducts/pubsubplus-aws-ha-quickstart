[![Build Status](https://travis-ci.org/SolaceDev/solace-aws-ha-quickstart.svg?branch=master)](https://travis-ci.org/SolaceDev/solace-aws-ha-quickstart)

# Install and configure Solace message routers in an HA tuple using AWS Cloud Formation

![alt text](/images/Solace-AWS-HA-Prod-3AZ.png "Production enviroment for Solace VMR")

This QuickStart template installs Solace Virtual Message Routers (VMRs) in high-availability (HA) redundancy groups for fault tolerance. HA redundancy provides 1:1 router sparing to increase overall service availability. If one of the routers fails or is taken out of service, the other router automatically takes over and provides service to the clients that were previously served by the now-out-of-service router.  To increase availability the message routers are deployed across 3 availability zones.

To learn more about VMR redundancy see the [Redundancy Documentation](http://docs.solace.com/Features/VMR-Redundancy.htm).  If you are not familiar with Solace or the high-available configurations it is recommended that you review this document. 

![alt text](/images/Solace-AWS-HA-PoC-2AZ.png "Proof of Concept enviroment for Solace VMR")

Alternatively this quickstart can create Solace VMRs in an environment suitable for Proof Of Concept testing where loss of an AWS Availability Zone will not cause loss of access to mission critical data.

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

# How to Deploy a VMR HA

This is a two step process:

**Step 1**: Go to the Solace Developer portal and request a Solace Evaluation edition VMR. This process will return an email with a Download link. Do a right click "Copy Hyperlink" on the "Download the VMR Evaluation Edition for Docker" hyperlink.  This will be needed in the following section.

<a href="http://dev.solace.com/downloads/download-vmr-evaluation-edition-docker" target="_blank">
    <img src="/images/register.png"/>
</a>

**Step 2**: Go to AWS Cloud Formation service and launch template.  The following links are for your convenience and take you directly to the templates for Solace Message Routers.

**Note:** Using `Launch Quick Start (for new VPC)` launches the AWS infrastructure stacks needed, with the Solace VMR stack on top (recommended). If however you have previously launched this Quick Start within your target region, and, would like to re-deploy just the Solace VMR stack on top of the already-existing AWS infrastructure stacks; then you can use `Launch Quick Start (for existing VPC)` instead.

<a href="https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=Solace-HA&templateURL=https://s3.amazonaws.com/solace-products/solace-aws-ha-quickstart/latest/templates/solace-vmr-master.template" target="_blank">
    <img src="/images/launch-button-new.png"/>
</a>

<a href="https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=Solace-HA&templateURL=https://s3.amazonaws.com/solace-products/solace-aws-ha-quickstart/latest/templates/solace-vmr.template" target="_blank">
    <img src="/images/launch-button-existing.png"/>
</a>

* If you want to take a look under the covers, you can view the AWS CloudFormation template that automates the deployment. You can customize the template during launch, or download and extend it for other projects.

<a href="https://raw.githubusercontent.com/SolaceProducts/solace-aws-ha-quickstart/master/templates/solace-vmr-master.template" target="_blank">
    <img src="/images/view-template-new.png"/>
</a>

<a href="https://raw.githubusercontent.com/SolaceProducts/solace-aws-ha-quickstart/master/templates/solace-vmr.template" target="_blank">
    <img src="/images/view-template-existing.png"/>
</a>

# Filling the templates

Selecting the Launch Quick Start (for new VPC) above will take you to the AWS "Select Template" tab with the Solace template referenced in region `us-east-1`. You can change the deployment region using the drop down menu in the top right corner. Hit the next button in the bottom right corner once you are done.

![alt text](/images/Select-Template.png "Select Template")

The next screen will allow you to fill in the details of the root AWS stack for this solution:

| Field                      | Value                                                                          |
|----------------------------|--------------------------------------------------------------------------------|
| Stack name                 | Default is Solace-HA, any unique name will suffice |
| **Solace Parameters**      |  |
| SolaceDockerURL            | URL from the registration email. Can also use SolOS versions hosted remotely (if so, a .md5 file needs to be created in the same remote directory) |
| AdminPassword              | Password to allow SolOS access to configure the Solace Message Router instances |
| ContainerLoggingFormat     | The format of the logs sent by the VMR to the CloudWatch service (see [documentation](https://docs.solace.com/Solace-VMR-Set-Up/Docker-Containers/Configuring-VMR-Container-Logging.htm#configuring-the-vmr-container-log-output-format) for details) |
| **Network Parameters**     |  |
| NumberOfAZs                | Default is 3. Depends on number of `AvailibilityZones` selected |
| AvailabilityZones          | Pick 3 AZs from the drop down menu, alternativey pick 2 for PoC or limited Region. Must equal `NumberOfAZs` |
| ProductionEnv              | True will create Private subnets and accompanying public ELB with health-check if prod deployment |
| RemoteAccessCIDR           | IP range that can send/recieve messages, use 0.0.0.0/0 if unsure |
| SSHAccessCIDR              | IP range that can configure VMR, use 0.0.0.0/0 if unsure |
| **EC2 Parameters**         |  |
| KeyPairName                | Pick from your exisitng key pairs, create new AWSW key pair if required |
| BootDiskSize               | Default is 24GB minimum is 20GB |
| MessageRouterNodeInstance  | Default is t2.large which is the minimum |
| MessageRouterNodeStorage   | Default is 0 which means ephemeral, non-zero will cause new io1 disk creation for message-spool which will not delete on stack termination |
| MonitorNodeInstance        | Default is t2.large which is the minimum | 
| **AWS QuickStart Config**  |  |
| QSS3BucketName             | Leave at default. References the S3 bucket where the templates are hosted |
| QSS3KeyPrefix              | Leave at default. References the path to the Quick Start resources within the S3 bucket |

![alt text](/images/specify-details.png "Specify Details")

Select [next] on the "Options" screen unless you want to add tags, use specific IAM roles, or blend in custom stacks.

Acknowledge that resources will be created and select [Create] in bottom right corner.

![alt text](/images/capabilities.png "Create Stack")

# Stack structure

The Quick Start will create the nested VPC, Bastion, and Solace stacks using their respective templates. The SolaceStack further creates sub-stacks for the deployment of the primary, backup and monitor Solace VMRs. You’ll see all these listed in the AWS CloudFormation console, as illustrated in below. Following the links in the Resources tab provides detailed information about the underlying resources.
 
![alt text](/images/stacks-after-deploy-success.png "Created stacks after deployment")

For external access to the deployment (explained in the next sections), the resources of interest are the
*	the Elastic Load Balancer (ELB), and
*	the EC2 instances for the message router primary, backup, and monitor VMRs.

For messaging and management access to the active VMR, you will need to note the information about the ELB’s DNS host name, which can be obtained from the `SolaceStack > Resources > ELB, or the EC2 Dashboard > Load Balancing > Load Balancers` section:
 
![alt text](/images/elb-details.png "ELB details")

For direct SSH access to the individual VMRs, the public DNS host names (elastic IPs) of the EC2 instances of the Bastion Hosts and the private DNS host names of the primary, backup, and the monitor Solace VMRs are required. This can be obtained from the `EC2 Dashboard > Instances > Instances` section: 
 
![alt text](/images/ec2-instance-details.png "EC2 instances details")


# Gaining admin access to the VMR

## Using SSH connection to the individual VMRs

For persons used to working with Solace message router console access, this is still available with the AWS EC2 instance:

* Copy the Key Pair file used during deployment (KeyPairName) to the Linux Bastion Host. The key must not be publicaly viewable.
```
chmod 400 <key.pem>
scp -i <key.pem> <key.pem> ec2-user@<bastion-elastic-ip>:/home/ec2-user
```
* Log in to the Linux Bastion Host
```
ssh -i <key.pem> ec2-user@<bastion-elastic-ip>
```
* From the Linux Bastion Host, SSH to your desired EC2 host that is running the Solace VMR.
```
ssh -i <key.pem> ec2-user@<ec2-host>
```
* From the host, log in to the SolOS CLI
```
sudo docker exec -it solace /usr/sw/loads/currentload/bin/cli -A
```

## Management tools access through the ELB

Non-CLI [management tools](https://docs.solace.com/Management-Tools.htm ) can access the Solace VMR cluster through the ELB’s public DNS host name at port 8080. Use the user `admin` and the password you set for the SolOS "AdminPassword".

# Solace VMR Logs

Both host and container logs get logged to [Amazon CloudWatch](https://aws.amazon.com/cloudwatch/) on the region where the deployment occurred. The Solace VMR logs can be found under the `*/solace-vmr.log` log stream. The `ContainerLoggingFormat` field can be used to control the log output format.

![alt text](/images/CloudWatch_logging.png "CloudWatch Logging")

# About Quick Starts

Quick Starts are automated reference deployments for key workloads on the AWS Cloud. Each Quick Start launches, configures, and runs the AWS compute, network, storage, and other services required to deploy a specific workload on AWS, using AWS best practices for security and availability.

# Testing data access to the HA cluster

To test data traffic though the newly created VMR instances, visit the Solace developer portal and select your preferred API or protocol to [send and receive messages](http://dev.solace.com/get-started/send-receive-messages/). Under each language there is a Publish/Subscribe tutorial that will help you get started.

For data, the Solace VMR cluster can be accessed through the ELB’s public DNS host name and the API or protocol specific port. 

![alt text](/images/solace_tutorial.png "getting started publish/subscribe")

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

See the list of [contributors](../../graphs/contributors) who participated in this project.

## License

This project is licensed under the Apache License, Version 2.0. - See the [LICENSE](LICENSE) file for details.

## Resources

For more information about Solace technology in general please visit these resources:

- The Solace Developer Portal website at: http://dev.solace.com
- Understanding [Solace technology.](http://dev.solace.com/tech/)
- Ask the [Solace community](http://dev.solace.com/community/).
