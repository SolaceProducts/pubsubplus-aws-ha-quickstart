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


OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
config_file=""
ansible_dir=""
DEBUG="-vvvv"

verbose=0

while getopts "c:d:" opt; do
    case "$opt" in
    c)  config_file=$OPTARG
        ;;
    d)  ansible_dir=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))
[ "$1" = "--" ] && shift

murl_top=http://instance-data/latest/meta-data


thisInstance=$(curl -f $murl_top/instance-id 2> /dev/null)
if [ -z "$thisInstance" ] ; then
	thisInstance="unknown"
fi

thisRegion=$(curl -f $murl_top/placement/availability-zone 2> /dev/null)
if [ -z "$ThisRegion" ] ; then
	thisRegion="us-east-1"
else
	thisRegion="${ThisRegion%[a-z]}"
fi

PrimaryNetInt=`aws ec2 describe-network-interfaces --region ${thisRegion} \
                  --query "NetworkInterfaces[?"TagSet[?Value"=='MessageRouterPrimary']]"`

PrimaryPrivateIp=`echo ${PrimaryNetInt} | jq -r '.[0] | .PrivateIpAddress'`
PrimaryPublicIp=`echo ${PrimaryNetInt} | jq -r '.[0] | .Association.PublicIp'`
PrimaryNetworkInterfaceId=`echo ${PrimaryNetInt} | jq -r '.[0] | .NetworkInterfaceId'`

BackupNetInt=`aws ec2 describe-network-interfaces --region ${thisRegion} \
                  --query "NetworkInterfaces[?"TagSet[?Value"=='MessageRouterBackup']]"`

BackupPrivateIp=`echo ${BackupNetInt} | jq -r '.[0] | .PrivateIpAddress'`
BackupPublicIp=`echo ${BackupNetInt} | jq -r '.[0] | .Association.PublicIp'`
BackupNetworkInterfaceId=`echo ${BackupNetInt} | jq -r '.[0] | .NetworkInterfaceId'`


host_name=`hostname`
host_info=`grep ${host_name} ${config_file}`

local_role=`echo $host_info | grep -o -E 'Monitor|MessageRouterPrimary|MessageRouterBackup'`

ansible_config=${ansible_dir}/group_vars/LOCALHOST/localhost.yml

case $local_role in  
    Monitor ) 
        head -n 8 ${ansible_config} > /tmp/temp_file
        echo "PRIMARY_ROUTER:
   NAME: PRIMARY
   IP:   10.0.128.135
BACKUP_ROUTER:
   NAME: BACKUP
   IP:   10.0.129.135" >> /tmp/temp_file
        tail -n 3 ${ansible_config} >> /tmp/temp_file
    ;;
    MessageRouterPrimary ) 
        aws ec2 attach-network-interface --region ${thisRegion} \
                                 --network-interface-id ${PrimaryNetworkInterfaceId} \
                                 --instance-id ${thisInstance} --device-index 1
        head -n 6 ${ansible_config} > /tmp/temp_file
        echo "   NAME: PRIMARY
   ROLE: PRIMARY
PRIMARY_ROUTER:
   NAME: PRIMARY
   IP:   10.0.128.135
BACKUP_ROUTER:
   NAME: BACKUP
   IP:   10.0.129.135" >> /tmp/temp_file
        tail -n 3 ${ansible_config} >> /tmp/temp_file
        ;; 
    MessageRouterBackup ) 
        aws ec2 attach-network-interface --region ${thisRegion} \
                                 --network-interface-id ${BackupNetworkInterfaceId} \
                                 --instance-id ${thisInstance} --device-index 1
        head -n 6 ${ansible_config} > /tmp/temp_file
        echo "   NAME: BACKUP
   ROLE: BACKUP
PRIMARY_ROUTER:
   NAME: PRIMARY
   IP:   10.0.128.135
BACKUP_ROUTER:
   NAME: BACKUP
   IP:   10.0.129.135" >> /tmp/temp_file
        tail -n 3 ${ansible_config} >> /tmp/temp_file
        ;; 
esac

mv /tmp/temp_file ${ansible_config}