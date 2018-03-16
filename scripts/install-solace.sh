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
logging_format=""
logging_group=""
logging_stream=""

verbose=0

while getopts "c:d:p:s:u:v:f:g:r:" opt; do
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
    f) logging_format=$OPTARG
        ;;
    g) logging_group=$OPTARG
        ;;
    r) logging_stream=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))
[ "$1" = "--" ] && shift

verbose=1
echo "config_file=$config_file , solace_directory=$solace_directory , admin_password_file=$admin_password_file , \
      solace_url=$solace_url , disk_size=$disk_size , volume=$volume , logging_format=$logging_format , \
      logging_group=$logging_group , logging_stream=$logging_stream , Leftovers: $@"

export admin_password=`cat ${admin_password_file}`
mkdir $solace_directory
cd $solace_directory
echo "`date` INFO: Configure VMRs Started"

echo "`date` INFO: check to make sure we have a complete load"
if [[ ${solace_url} == *"em.solace.com"* ]]; then
    # a redirect link provided by solace
    wget -O ${solace_directory}/solos.info -nv  https://products.solace.com/download/VMR_DOCKER_EVAL_MD5
else
    # an already-existing load (plus its md5 file) hosted somewhere else (e.g. in an s3 bucket)
    wget -O ${solace_directory}/solos.info -nv  ${solace_url}.md5
fi
IFS=' ' read -ra SOLOS_INFO <<< `cat ${solace_directory}/solos.info`
MD5_SUM=${SOLOS_INFO[0]}
SolOS_LOAD=${SOLOS_INFO[1]}
echo "`date` INFO: Reference md5sum is: ${MD5_SUM}"

wget -q -O solace-redirect ${solace_url}
if [[ ${solace_url} == *"em.solace.com"* ]]; then
    REAL_LINK=`egrep -o "https://[a-zA-Z0-9\.\/\_\?\=%]*" ${solace_directory}/solace-redirect`
else
    REAL_LINK=${solace_url}
fi
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

# Memory setup for when using smaller instance-types
echo "`date` INFO: Set up swap for < 6GB machines"
MEM_SIZE=`cat /proc/meminfo | grep MemTotal | tr -dc '0-9'`
if [ ${MEM_SIZE} -lt 6087960 ]; then
 echo "`date` WARN: Not enough memory: ${MEM_SIZE} Creating 2GB Swap space"
 mkdir /var/lib/solace
 dd if=/dev/zero of=/var/lib/solace/swap count=2048 bs=1MiB
 mkswap -f /var/lib/solace/swap
 chmod 0600 /var/lib/solace/swap
 swapon -f /var/lib/solace/swap
 grep -q 'solace\/swap' /etc/fstab || sudo sh -c 'echo "/var/lib/solace/swap none swap sw 0 0" >> /etc/fstab'
else
  echo "`date` INFO: Memory size is ${MEM_SIZE}"
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

echo "`date` INFO: Executing 'docker load'"
docker load -i ${solace_directory}/${SolOS_LOAD}

export VMR_VERSION=`docker images | grep solace | awk '{print $3}'`

cd ${solace_directory}

host_name=`hostname`
host_info=`grep ${host_name} ${config_file}`
local_role=`echo $host_info | grep -o -E 'Monitor|MessageRouterPrimary|MessageRouterBackup'`

primary_stack=`cat ${config_file} | grep MessageRouterPrimary | rev | cut -d "-" -f1 | rev | tr '[:upper:]' '[:lower:]'`
backup_stack=`cat ${config_file} | grep MessageRouterBackup | rev | cut -d "-" -f1 | rev | tr '[:upper:]' '[:lower:]'`
monitor_stack=`cat ${config_file} | grep Monitor | rev | cut -d "-" -f1 | rev | tr '[:upper:]' '[:lower:]'`

# Get the IP addressed for node
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
        ROUTER_NAME="monitor${monitor_stack}"
        REDUNDANCY_CFG=""
        ;;
    MessageRouterPrimary )
        NODE_TYPE="message_routing"
        ROUTER_NAME="primary${primary_stack}"
        REDUNDANCY_CFG="--env redundancy_matelink_connectvia=${BACKUP_IP} --env redundancy_activestandbyrole=primary --env configsync_enable=yes"
        is_primary="true"
        ;;
    MessageRouterBackup )
        NODE_TYPE="message_routing"
        ROUTER_NAME="backup${backup_stack}"
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

# Start up the SolOS docker instance with HA config keys
echo "`date` INFO: Executing 'docker create'"
docker create \
   --uts=host \
   --shm-size 2g \
   --ulimit core=-1 \
   --ulimit memlock=-1 \
   --ulimit nofile=2448:1048576 \
   --net=host \
   --restart=always \
   -v jail:/usr/sw/jail \
   -v var:/usr/sw/var \
   -v /mnt/vmr/secrets:/run/secrets \
   ${SPOOL_MOUNT} \
   --log-driver=awslogs \
   --log-opt awslogs-group=${logging_group} \
   --log-opt awslogs-stream=${logging_stream} \
   --env "logging_debug_output=all" \
   --env "logging_debug_format=${logging_format}" \
   --env "logging_command_output=all" \
   --env "logging_command_format=${logging_format}" \
   --env "logging_system_output=all" \
   --env "logging_system_format=${logging_format}" \
   --env "logging_event_output=all" \
   --env "logging_event_format=${logging_format}" \
   --env "logging_kernel_output=all" \
   --env "logging_kernel_format=${logging_format}" \
   --env "nodetype=${NODE_TYPE}" \
   --env "routername=${ROUTER_NAME}" \
   --env "username_admin_globalaccesslevel=admin" \
   --env "username_admin_passwordfilepath=$(basename ${admin_password_file})" \
   --env "service_ssh_port=2222" \
   ${REDUNDANCY_CFG} \
   --env "redundancy_group_passwordfilepath=$(basename ${admin_password_file})" \
   --env "redundancy_enable=yes" \
   --env "redundancy_group_node_primary${primary_stack}_nodetype=message_routing" \
   --env "redundancy_group_node_primary${primary_stack}_connectvia=${PRIMARY_IP}" \
   --env "redundancy_group_node_backup${backup_stack}_nodetype=message_routing" \
   --env "redundancy_group_node_backup${backup_stack}_connectvia=${BACKUP_IP}" \
   --env "redundancy_group_node_monitor${monitor_stack}_nodetype=monitoring" \
   --env "redundancy_group_node_monitor${monitor_stack}_connectvia=${MONITOR_IP}" \
   --name=solace ${VMR_VERSION}

# Start the solace service and enable it at system start up.
chkconfig --add solace-vmr
echo "`date` INFO: Starting Solace service"
service solace-vmr start

# Poll the VMR SEMP port until it is Up
loop_guard=30
pause=10
count=0
echo "`date` INFO: Wait for the VMR SEMP service to be enabled"
while [ ${count} -lt ${loop_guard} ]; do
  online_results=`/tmp/semp_query.sh -n admin -p ${admin_password} -u http://localhost:8080/SEMP \
    -q "<rpc semp-version='soltr/8_7VMR'><show><service/></show></rpc>" \
    -v "/rpc-reply/rpc/show/service/services/service[name='SEMP']/enabled[text()]"`
  is_vmr_up=`echo ${online_results} | jq '.valueSearchResult' -`
  echo "`date` INFO: SEMP service 'enabled' status is: ${is_vmr_up}"
  run_time=$((${count} * ${pause}))
  if [ "${is_vmr_up}" = "\"true\"" ]; then
      echo "`date` INFO: VMR SEMP service is up, after ${run_time} seconds"
      break
  fi
  ((count++))
  echo "`date` INFO: Waited ${run_time} seconds, VMR SEMP service not yet up"
  sleep ${pause}
done

# Remove all VMR Secrets from the host; at this point, the VMR should have come up
# and it won't be needing those files anymore
rm ${admin_password_file}

if [ ${count} -eq ${loop_guard} ]; then
  echo "`date` ERROR: Solace VMR SEMP service never came up" | tee /dev/stderr
  exit 1
fi

# Poll the redundancy status on the Primary VMR
loop_guard=30
pause=10
count=0
mate_active_check=""
if [ "${is_primary}" = "true" ]; then
  echo "`date` INFO: Wait for Primary to be 'Local Active' or 'Mate Active'"
  while [ ${count} -lt ${loop_guard} ]; do
    online_results=`/tmp/semp_query.sh -n admin -p ${admin_password} -u http://localhost:8080/SEMP \
         -q "<rpc semp-version='soltr/8_7VMR'><show><redundancy><detail/></redundancy></show></rpc>" \
         -v "/rpc-reply/rpc/show/redundancy/virtual-routers/primary/status/activity[text()]"`

    local_activity=`echo ${online_results} | jq '.valueSearchResult' -`
    echo "`date` INFO: Local activity state is: ${local_activity}"

    run_time=$((${count} * ${pause}))
    case "${local_activity}" in
      "\"Local Active\"")
        echo "`date` INFO: Redundancy is up locally, Primary Active, after ${run_time} seconds"
        mate_active_check="Standby"
        break
        ;;
      "\"Mate Active\"")
        echo "`date` INFO: Redundancy is up locally, Backup Active, after ${run_time} seconds"
        mate_active_check="Active"
        break
        ;;
    esac
    ((count++))
    echo "`date` INFO: Waited ${run_time} seconds, Redundancy not yet up"
    sleep ${pause}
  done

  if [ ${count} -eq ${loop_guard} ]; then
    echo "`date` ERROR: Solace redundancy group never came up" | tee /dev/stderr
    exit 1
  fi

  loop_guard=45
  pause=10
  count=0
  echo "`date` INFO: Wait for Backup to be 'Active' or 'Standby'"
  while [ ${count} -lt ${loop_guard} ]; do
    online_results=`/tmp/semp_query.sh -n admin -p ${admin_password} -u http://localhost:8080/SEMP \
         -q "<rpc semp-version='soltr/8_7VMR'><show><redundancy><detail/></redundancy></show></rpc>" \
         -v "/rpc-reply/rpc/show/redundancy/virtual-routers/primary/status/detail/priority-reported-by-mate/summary[text()]"`

    mate_activity=`echo ${online_results} | jq '.valueSearchResult' -`
    echo "`date` INFO: Mate activity state is: ${mate_activity}"

    run_time=$((${count} * ${pause}))
    case "${mate_activity}" in
      "\"Active\"")
        echo "`date` INFO: Redundancy is up end-to-end, Backup Active, after ${run_time} seconds"
        mate_active_check="Standby"
        break
        ;;
      "\"Standby\"")
        echo "`date` INFO: Redundancy is up end-to-end, Primary Active, after ${run_time} seconds"
        mate_active_check="Active"
        break
        ;;
    esac
    ((count++))
    echo "`date` INFO: Waited ${run_time} seconds, Redundancy not yet up"
    sleep ${pause}
  done

  if [ ${count} -eq ${loop_guard} ]; then
    echo "`date` ERROR: Solace redundancy group never came up" | tee /dev/stderr
    exit 1
  fi

  /tmp/semp_query.sh -n admin -p ${admin_password} -u http://localhost:8080/SEMP \
    -q "<rpc semp-version='soltr/8_7VMR'><admin><config-sync><assert-master><router/></assert-master></config-sync></admin></rpc>"
  /tmp/semp_query.sh -n admin -p ${admin_password} -u http://localhost:8080/SEMP \
    -q "<rpc semp-version='soltr/8_7VMR'><admin><config-sync><assert-master><vpn-name>default</vpn-name></assert-master></config-sync></admin></rpc>"
fi
