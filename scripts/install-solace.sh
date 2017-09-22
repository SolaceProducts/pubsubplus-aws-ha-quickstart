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
solace_directory=""
solace_url=""
admin_password_file=""
disk_size=""
volume=""
DEBUG="-vvvv"
is_primary="false"

verbose=0

while getopts "c:d:p:s:u:v:" opt; do
    case "$opt" in
    c)  config_file=$OPTARG
        ;;
    d)  solace_directory=$OPTARG
        ;;
    p)  admin_password_file=$OPTARG
        ;;
    s)  disk_size=$OPTARG
        ;;
    u)  solace_url=$OPTARG
        ;;
    v)  volume=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))
[ "$1" = "--" ] && shift

verbose=1
echo "config_file=$config_file ,solace_directory=$solace_directory ,admin_password_file=$admin_password_file, \
      solace_url=$solace_url ,disk_size=$disk_size , volume=$volume ,Leftovers: $@"

export admin_password=`cat ${admin_password_file}`
rm ${admin_password_file}
mkdir $solace_directory
cd $solace_directory
echo "`date` INFO: Configure VMRs Started"

echo "`date` INFO: check to make sure we have a complete load"
wget -O ${solace_directory}/solos.info -nv  https://products.solace.com/download/VMR_DOCKER_EVAL_MD5
IFS=' ' read -ra SOLOS_INFO <<< `cat ${solace_directory}/solos.info`
MD5_SUM=${SOLOS_INFO[0]}
SolOS_LOAD=${SOLOS_INFO[1]}
echo "`date` INFO: Reference md5sum is: ${MD5_SUM}"

wget -q -O solace-redirect ${solace_url}
REAL_LINK=`egrep -o "https://[a-zA-Z0-9\.\/\_\?\=]*" ${solace_directory}/solace-redirect`
wget -q -O  ${solace_directory}/${SolOS_LOAD} ${REAL_LINK}
cd ${solace_directory}
LOCAL_OS_INFO=`md5sum ${SolOS_LOAD}`
IFS=' ' read -ra SOLOS_INFO <<< ${LOCAL_OS_INFO}
LOCAL_MD5_SUM=${SOLOS_INFO[0]}
if [ ${LOCAL_MD5_SUM} != ${MD5_SUM} ]; then
    echo "`date` WARN: Possible corrupt SolOS load, md5sum do not match"
else
    echo "`date` INFO: Successfully downloaded ${SolOS_LOAD}"
fi


# Make sure Docker is actually up
docker_running=""
loop_guard=6
loop_count=0
while [ ${loop_count} != ${loop_guard} ]; do 
    sleep 10
    docker_running=`service docker status | grep -o running`
    if [ ${docker_running} != "running" ]; then
        ((loop_count++))
        echo "`date` WARN: Tried to launch Solace but Docker in state ${docker_running}"
    else
        echo "`date` INFO: Docker in state ${docker_running}"
        break
    fi
done

docker load -i ${solace_directory}/${SolOS_LOAD}

export VMR_VERSION=`docker images | grep solace | awk '{print $3}'`

cd ${solace_directory}

host_name=`hostname`
host_info=`grep ${host_name} ${config_file}`
local_role=`echo $host_info | grep -o -E 'Monitor|MessageRouterPrimary|MessageRouterBackup'`

#Get the IP addressed for node
for role in Monitor MessageRouterPrimary MessageRouterBackup
do 
    role_info=`grep ${role} ${config_file}`
    role_name=${role_info%% *}
    role_ip=`echo ${role_name} | cut -c 4- | tr "-" .`
    case $role in  
        Monitor )
            MONITOR_IP=${role_ip}
            ;; 
        MessageRouterPrimary ) 
            PRIMARY_IP=${role_ip}
            ;; 
        MessageRouterBackup ) 
            BACKUP_IP=${role_ip}
            ;; 
    esac
done

case $local_role in  
    Monitor )
        NODE_TYPE="monitoring"
        ROUTER_NAME="monitor"
        REDUNDANCY_CFG=""
        ;; 
    MessageRouterPrimary ) 
        NODE_TYPE="message_routing"
        ROUTER_NAME="primary"
        REDUNDANCY_CFG="--env redundancy_matelink_connectvia=${BACKUP_IP} --env redundancy_activestandbyrole=primary --env configsync_enable=yes"
        is_primary="true"
        ;; 
    MessageRouterBackup ) 
        NODE_TYPE="message_routing"
        ROUTER_NAME="backup"
        REDUNDANCY_CFG="--env redundancy_matelink_connectvia=${PRIMARY_IP} --env redundancy_activestandbyrole=backup --env configsync_enable=yes"
        ;; 
esac

if [ $disk_size == "0" ]; then
   SPOOL_MOUNT="-v internalSpool:/usr/sw/internalSpool -v adbBackup:/usr/sw/adb -v softAdb:/usr/sw/internalSpool/softAdb"
else
    echo "`date` Create primary partition on new disk"
    (
    echo n # Add a new partition
    echo p # Primary partition
    echo 1  # Partition number
    echo   # First sector (Accept default: 1)
    echo   # Last sector (Accept default: varies)
    echo w # Write changes
    ) | sudo fdisk $volume

    mkfs.xfs  ${volume}1 -m crc=0
    UUID=`blkid -s UUID -o value ${volume}1`
    echo "UUID=${UUID} /opt/vmr xfs defaults 0 0" >> /etc/fstab
    mkdir /opt/vmr
    mount -a
    SPOOL_MOUNT="-v /opt/vmr:/usr/sw/internalSpool -v /opt/vmr:/usr/sw/adb -v /opt/vmr:/usr/sw/internalSpool/softAdb"
fi

# Start up the SolOS docer instance with HA config keys
docker create \
   --uts=host \
   --shm-size 2g \
   --ulimit core=-1 \
   --ulimit memlock=-1 \
   --ulimit nofile=2448:1048576 \
   --cap-add=IPC_LOCK \
   --cap-add=SYS_NICE \
   --net=host \
   --restart=always \
   -v jail:/usr/sw/jail \
   -v var:/usr/sw/var \
   ${SPOOL_MOUNT} \
   --env "nodetype=${NODE_TYPE}" \
   --env "routername=${ROUTER_NAME}" \
   --env "username_admin_globalaccesslevel=admin" \
   --env "username_admin_password=${admin_password}" \
   --env "service_ssh_port=2222" \
   ${REDUNDANCY_CFG} \
   --env "redundancy_group_password=${admin_password}" \
   --env "redundancy_enable=yes" \
   --env "redundancy_group_node_primary_nodetype=message_routing" \
   --env "redundancy_group_node_primary_connectvia=${PRIMARY_IP}" \
   --env "redundancy_group_node_backup_nodetype=message_routing" \
   --env "redundancy_group_node_backup_connectvia=${BACKUP_IP}" \
   --env "redundancy_group_node_monitor_nodetype=monitoring" \
   --env "redundancy_group_node_monitor_connectvia=${MONITOR_IP}" \
   --name=solace ${VMR_VERSION}


#Start the solace service and enable it at system start up.
chkconfig --add solace-vmr
service solace-vmr start

loop_guard=30
pause=10
count=0
if [ "${is_primary}" = "true" ]; then
  while [ ${count} -lt ${loop_guard} ]; do 
    online_results=`/tmp/semp_query.sh -n admin -p ${admin_password} -u http://localhost:8080/SEMP \
         -q "<rpc semp-version='soltr/8_5VMR'><show><redundancy><group/></redundancy></show></rpc>" \
         -c '/rpc-reply/rpc/show/redundancy/group-node/status[text()="Online"]'`

    online_count=`echo ${online_results} | jq '.countSearchResult' -`

    run_time=$((${count} * ${pause}))
    if [ ${online_count} -eq 3 ]; then
        echo "`date` INFO: Redundancy is up after ${run_time} seconds"
        break
    fi
    ((count++))
    echo "`date` INFO: Waited ${run_time} seconds, Redundancy not yet up"
    sleep ${pause}
  done

  if [ ${count} -eq ${loop_guard} ]; then
    echo "`date` ERROR: Solace redundancy group never came up" | tee /dev/stderr
    exit 1 
  fi

 /tmp/semp_query.sh -n admin -p ${admin_password} -u http://localhost:8080/SEMP \
         -q "<rpc semp-version='soltr/8_5VMR'><admin><config-sync><assert-master><router/></assert-master></config-sync></admin></rpc>"
 /tmp/semp_query.sh -n admin -p ${admin_password} -u http://localhost:8080/SEMP \
         -q "<rpc semp-version='soltr/8_5VMR'><admin><config-sync><assert-master><vpn-name>default</vpn-name></assert-master></config-sync></admin></rpc>"
fi