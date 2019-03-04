#!/bin/bash
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Generate the clusters hosts files for a AWS Cloudformation Stack.
# If no stack is given, we try to figure out out from tags of this
# instance.
#
# The assumption is that the Cloudformation Stack deploys 2 autoscaling groups.
#	MessageBroker	(/tmp/routers)
#	MonitorNodes	(/tmp/monitors)
#
# The complete list of hosts for this stack is saved
# to SOLACE_HOSTS_FILE (default is /tmp/solacehosts)


murl_top=http://169.254.169.254/latest/meta-data

SOLACE_HOSTS_FILE=${SOLACE_HOSTS_FILE:-/tmp/solacehosts}

ThisInstance=$(curl -f $murl_top/instance-id 2> /dev/null)
if [ -z "$ThisInstance" ] ; then
	ThisInstance="unknown"
fi

ThisRegion=$(curl -f $murl_top/placement/availability-zone 2> /dev/null)
if [ -z "$ThisRegion" ] ; then
	ThisRegion="us-east-1"
else
	ThisRegion="${ThisRegion%[a-z]}"
fi

if [ -z "${1}" ] ; then
	ThisStack=$(aws ec2 describe-instances --region $ThisRegion --output text --instance-ids $ThisInstance --query 'Reservations[].Instances[].Tags[?Key==`aws:cloudformation:stack-name`].Value ')
else
	ThisStack=$1
fi


if [ -z "$ThisStack" ] ; then
	echo "No AWS Cloudformation Stack specified; aborting script"
	exit 1
elif [ -z "$ThisRegion" ] ; then
	echo "Failed to determine AWS region; aborthing script"
	exit 1
fi

# List out cluster_hosts in time-based launch order (with no domain spec)
# This MAY correspond to AmiLaunchIndex order, so we do our best to keep
# that ordering aligned for the different cluster roles (remember that we
# may have multiple AutoScalingGroups comprising a single cluster).
#	NOTE: I don't think there's a way for two stacks with the same
#	name to be deployed in the same region with different keys 
#	(even with IAM users), but we could do the extra filtering
#	on KeyName if necessary. 
#

touch ${SOLACE_HOSTS_FILE}
total_nodes=$(cat ${SOLACE_HOSTS_FILE} | wc -l)
while [ ${total_nodes} -lt 3 ]; do
	aws ec2 describe-instances --output text --region $ThisRegion \
	--filters 'Name=instance-state-name,Values=running,stopped' \
	--query 'Reservations[].Instances[].[PrivateDnsName,InstanceId,LaunchTime,AmiLaunchIndex,KeyName,Tags[?Key== `HARole`] | [0].Value,Tags[?Key == `ParentStack`] | [0].Value,Tags[?Key == `aws:cloudformation:stack-name`] | [0].Value ] ' \
	| grep -w "$ThisStack" | sort -k 3,4 \
	| awk '{split ($1,fqdn,"."); print fqdn[1]" "$2" "$3" "$4" "$5" "$8}' \
	> ${SOLACE_HOSTS_FILE}

    total_nodes=$(cat ${SOLACE_HOSTS_FILE} | wc -l)
done

# We have two different Cloudformation models, one flat and one nested.
# The different models will have slightly different labels for the 
# nodes associated with each group ... but it's simple to handle both cases.
#pwd
grep -q -e "-MessageBroker.*Stack-" ${SOLACE_HOSTS_FILE}
if [ $? -eq 0 ] ; then
    grep -e "-MessageBroker.*Stack-" ${SOLACE_HOSTS_FILE} \
    | awk '{print $1" ROUTERNODE"NR-1" "$2" "$3" "$4}' > /tmp/routers
else
    cp ${SOLACE_HOSTS_FILE} /tmp/routers
fi

grep -q -e "-MonitorStack-" ${SOLACE_HOSTS_FILE}
if [ $? -eq 0 ] ; then
    grep -e "-MonitorStack-" ${SOLACE_HOSTS_FILE} \
    | awk '{print $1" MONITORNODE"NR-1" "$2" "$3" "$4}' > /tmp/monitors
fi