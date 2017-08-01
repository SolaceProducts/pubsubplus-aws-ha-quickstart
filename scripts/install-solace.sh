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
DEBUG="-vvvv"

verbose=0

while getopts "c:d:p:u:" opt; do
    case "$opt" in
    c)  config_file=$OPTARG
        ;;
    d)  solace_directory=$OPTARG
        ;;
    p)  admin_password_file=$OPTARG
        ;;
    u)  solace_url=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))
[ "$1" = "--" ] && shift

verbose=1
echo "config_file=$config_file ,solace_directory=$solace_directory ,admin_password_file=admin_password_file, solace_url=$solace_url ,Leftovers: $@"

export admin_password=`cat ${admin_password_file}`
rm ${admin_password_file}
mkdir $solace_directory
cd $solace_directory
echo "`date` Configure VMRs Started"

wget -q -O solace-redirect ${solace_url}
REAL_LINK=`egrep -o "https://[a-zA-Z0-9\.\/\_\?\=]*" ${solace_directory}/solace-redirect`
wget -q -O soltr-docker.tar.gz ${REAL_LINK}

# Make sure Docker is actually up
docker_running=""
while [[ ${docker_running} != "running" ]]; do 
    echo "ERROR: Tried to launch Solace but Docker was not up"
    sleep 10
    docker_running=`service docker status | grep -o running`
done

docker load -i ${solace_directory}/soltr-docker.tar.gz

export VMR_VERSION=`docker images | grep solace | awk '{print $3}'`

cd ${solace_directory}

host_name=`hostname`
host_info=`grep ${host_name} ${config_file}`
local_role=`echo $host_info | grep -o -E 'Monitor|MessageRouterPrimary|MessageRouterBackup'`
sed -i "s/SOLACE_LOCAL_NAME/${host_name}/g" group_vars/LOCALHOST/localhost.yml

#Set up the cluster part of the ansible variables file
for role in Monitor MessageRouterPrimary MessageRouterBackup
do 
    role_info=`grep ${role} ${config_file}`
    role_name=${role_info%% *}
    role_ip=`echo ${role_name} | cut -c 4- | tr "-" .`
    case $role in  
        Monitor )
            sed -i "s/SOLACE_MONITOR_NAME/${role_name}/g" group_vars/LOCALHOST/localhost.yml
            sed -i "s/SOLACE_MONITOR_IP/${role_ip}/g" group_vars/LOCALHOST/localhost.yml
            MONITOR_IP=${role_ip}
            ;; 
        MessageRouterPrimary ) 
            sed -i "s/SOLACE_PRIMARY_NAME/${role_name}/g" group_vars/LOCALHOST/localhost.yml
            sed -i "s/SOLACE_PRIMARY_IP/${role_ip}/g" group_vars/LOCALHOST/localhost.yml
            PRIMARY_IP=${role_ip}
            ;; 
        MessageRouterBackup ) 
            sed -i "s/SOLACE_BACKUP_NAME/${role_name}/g" group_vars/LOCALHOST/localhost.yml
            sed -i "s/SOLACE_BACKUP_IP/${role_ip}/g" group_vars/LOCALHOST/localhost.yml
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
        ;; 
    MessageRouterBackup ) 
        NODE_TYPE="message_routing"
        ROUTER_NAME="backup"
        REDUNDANCY_CFG="--env redundancy_matelink_connectvia=${PRIMARY_IP} --env redundancy_activestandbyrole=backup --env configsync_enable=yes"
        ;; 
esac

# Set up the local host part of the ansible varialbes file

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
   -v internalSpool:/usr/sw/internalSpool \
   -v adbBackup:/usr/sw/adb \
   -v softAdb:/usr/sw/internalSpool/softAdb \
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