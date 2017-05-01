# Install and configure Solace message routers in an HA tuple using AWS Cloud Formation

![alt text](https://raw.githubusercontent.com/KenBarr/solace-aws-ha-quickstart/master/images/Solace-AWS-HA.png "getting started publish/subscribe")

The ...

# How to Deploy a VMR
This is a ... step process:

* Go to the Solace Developer portal and request a Solace Comunity edition VMR. This process will return an email with a Download link. Do a right click "Copy Hyperlink" on the "Download the VMR Community Edition for Docker" hyperlink.  This will be needed in the following section.

<a href="http://dev.solace.com/downloads/download_vmr-ce-docker" target="_blank">
    <img src="https://raw.githubusercontent.com/KenBarr/solace-aws-ha-quickstart/master/images/register.png"/>
</a>

* Go to ...


The following links are for your convenience. Before you launch the Quick Start, please review the architecture, configuration, network security, and other considerations discussed in this guide.

* If you have an AWS account and you’re already familiar with AWS services and Solace message router HA, you can launch the Quick Start to deploy Solace into a new virtual private cloud (VPC) in your AWS account. The deployment takes approximately 30 minutes. If you’re new to AWS or Solace Message Router, please review the implementation details and follow the step-by-step instructions.[TODO]

<a href="https://console.aws.amazon.com/cloudformation/home?region=us-east-1-2#/stacks/new?stackName=Solace-HA&templateURL=https://raw.githubusercontent.com/KenBarr/solace-aws-ha-quickstart/master/templates/solace-master.template" target="_blank">
    <img src="https://raw.githubusercontent.com/KenBarr/solace-aws-ha-quickstart/master/images/launch-button-new.png"/>
</a>

<a href="https://console.aws.amazon.com/cloudformation/home?region=us-east-1-2#/stacks/new?stackName=Solace-HA&templateURL=https://raw.githubusercontent.com/KenBarr/solace-aws-ha-quickstart/master/templates/solace.template" target="_blank">
    <img src="https://raw.githubusercontent.com/KenBarr/solace-aws-ha-quickstart/master/images/launch-button-existing.png"/>
</a>

* If you want to take a look under the covers, you can view the AWS CloudFormation template that automates the deployment. You can customize the template during launch, or download and extend it for other projects.

<a href="https://raw.githubusercontent.com/KenBarr/solace-aws-ha-quickstart/master/templates/solace-master.template" target="_blank">
    <img src="https://raw.githubusercontent.com/KenBarr/solace-aws-ha-quickstart/master/images/view-template-new.png"/>
</a>

<a href="https://raw.githubusercontent.com/KenBarr/solace-aws-ha-quickstart/master/templates/solace.template" target="_blank">
    <img src="https://raw.githubusercontent.com/KenBarr/solace-aws-ha-quickstart/master/images/view-template-existing.png"/>
</a>

# About Quick Starts

Quick Starts are automated reference deployments for key workloads on the AWS Cloud. Each Quick Start launches, configures, and runs the AWS compute, network, storage, and other services required to deploy a specific workload on AWS, using AWS best practices for security and availability.

# Testing data access to the ha cluster

To test data traffic though the newly created VMR instances, visit the Solace developer portal and and select your prefered programming langauge to [send and receive messages](http://dev.solace.com/get-started/send-receive-messages/). Under each language there is a Publish/Subscribe tutorial that will help you get started.

![alt text](https://raw.githubusercontent.com/KenBarr/solace-aws-ha-quickstart/master/images/solace_tutorial.png "getting started publish/subscribe")

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

See the list of [contributors](https://github.com/KenBarr/solace-aws-ha-quickstart/graphs/contributors) who participated in this project.

## License

This project is licensed under the Apache License, Version 2.0. - See the [LICENSE](LICENSE) file for details.

## Resources

For more information about Solace technology in general please visit these resources:

- The Solace Developer Portal website at: http://dev.solace.com
- Understanding [Solace technology.](http://dev.solace.com/tech/)
- Ask the [Solace community](http://dev.solace.com/community/).