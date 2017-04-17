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
# Specifically, this script is intended SOLELY to support the Confluent
# Quick Start offering in Amazon Web Services. It is not recommended
# for use in any other production environment.
#
#
#
#
# Simple script to wait for a Cloudformation resource identified as 
# part of a Cloudformation::Stack chain (using logical resource names).
#
#
# usage:
#	$0 ParentStack ChildStack ResourceName
#
# If the ChildStack or the leaf Resource does not exist, this returns immediately.
#

murl_top=http://instance-data/latest/meta-data

ThisInstance=$(curl -f $murl_top/instance-id 2> /dev/null)
if [ -z "$ThisInstance" ] ; then
	ThisInstance="unknown"
fi

ThisRegion=$(curl -f $murl_top/placement/availability-zone 2> /dev/null)
if [ -z "$ThisRegion" ] ; then
	ThisRegion="us-west-2"
else
	ThisRegion="${ThisRegion%[a-z]}"
fi

ParentStack=${1:-}
ChildStack=${2:-}
TargetResource=${3:-}

if [ -z "$ParentStack" -o -z "${ChildStack}" ] ; then
	echo "No AWS Cloudformation Stacks specified; aborting script"
	exit 1
elif [ -z "$TargetResource" ] ; then
	echo "No Resource specified; aborting script"
elif [ -z "$ThisRegion" ] ; then
	echo "Failed to determine AWS region; aborthing script"
	exit 1
fi

# We need the physical resource id for the ChildStack in order to track the 
# leaf Resource, so we're use the following query to retrieve it.
ChildStackId=$(aws cloudformation describe-stack-resources \
	--output json \
	--region $ThisRegion \
	--stack-name $ParentStack \
	--query "StackResources[?LogicalResourceId=='${ChildStack}']" \
	| jq -r '.[0] | .PhysicalResourceId')

# echo "ChildStackId=$ChildStackId"

if [ -z "${ChildStackId}"  -o  "${ChildStackId}" = "null" ] ; then
	echo "$ChildStack does not exist as a resource in $ParentStack"
	exit 0
fi

# Wait for all nodes to come on-line within a group
#
resourceStatus=$(aws cloudformation describe-stack-resources \
	--output text \
	--region $ThisRegion \
	--stack-name $ChildStackId \
	--logical-resource-id $TargetResource \
	--query StackResources[].ResourceStatus)

if [ -z "$resourceStatus" ] ; then
	echo "$TargetResource has does not exist in $ParentStack/$ChildStack"
	exit 0
fi

## TBD ... add timeout (optional, since CFT will enforce timeout)
#
while [ $resourceStatus != "CREATE_COMPLETE" ]
do
    sleep 30
    resourceStatus=$(aws cloudformation describe-stack-resources \
	--output text \
	--region $ThisRegion \
	--stack-name $ChildStackId \
	--logical-resource-id $TargetResource \
	--query StackResources[].ResourceStatus)
done

echo "$ChildStack/$TargetResource has status $resourceStatus"

