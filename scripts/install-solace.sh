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

docker create \
   --uts=host \
   --shm-size 2g \
   --ulimit core=-1 \
   --ulimit memlock=-1 \
   --ulimit nofile=2448:38048 \
   --cap-add=IPC_LOCK \
   --cap-add=SYS_NICE \
   --net=host \
   --restart=always \
   -v jail:/usr/sw/jail \
   -v var:/usr/sw/var \
   -v internalSpool:/usr/sw/internalSpool \
   -v adbBackup:/usr/sw/adb \
   -v softAdb:/usr/sw/internalSpool/softAdb \
   --env "username_admin_globalaccesslevel=admin" \
   --env "username_admin_password=${admin_password}" \
   --env "SERVICE_SSH_PORT=2222" \
   --name=solace ${VMR_VERSION}



#Start the solace service and enable it at system start up.
chkconfig --add solace-vmr
service solace-vmr start

cd ${solace_directory}

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

host_name=`hostname`
host_info=`grep ${host_name} ${config_file}`

local_role=`echo $host_info | grep -o -E 'Monitor|MessageRouterPrimary|MessageRouterBackup'`

sed -i "s/SOLACE_LOCAL_NAME/${host_name}/g" group_vars/LOCALHOST/localhost.yml
# Set up the local host part of the ansible varialbes file

# Make sure Docker is actually up
ansible_exists=""
while [[ ! -f /usr/local/bin/ansible-playbook ]]; do 
    echo "ERROR: Ansible does not yet exists"
    sleep 10
done


case $local_role in  
    Monitor ) 
        sed -i "s/SOLACE_LOCAL_ROLE/MONITOR/g" group_vars/LOCALHOST/localhost.yml
        /usr/local/bin/ansible-playbook ${DEBUG} -i hosts ShowRedundancyDetailSEMPv1.yml --connection=local
        sleep 30
        /usr/local/bin/ansible-playbook ${DEBUG} -i hosts ConfigReloadToMonitorSEMPv1.yml --connection=local
        sleep 60
        /usr/local/bin/ansible-playbook ${DEBUG} -i hosts ConfigRedundancyGroupSEMPv1.yml --connection=local
        /usr/local/bin/ansible-playbook ${DEBUG} -i hosts ConfigRedundancyNoShutSEMPv1.yml --connection=local
        ;; 
    MessageRouterPrimary ) 
        export VMR_ROLE=primary
        export MATE_IP=${BACKUP_IP}
        sed -i "s/SOLACE_LOCAL_ROLE/PRIMARY/g" group_vars/LOCALHOST/localhost.yml
<<<<<<< HEAD
        /usr/local/bin/ansible-playbook ${DEBUG} -i hosts ShowRedundancyDetailSEMPv1.yml --connection=local
        sleep 30
        /usr/local/bin/ansible-playbook ${DEBUG} -i hosts ConfigShutMessageSpoolSEMPv1.yml --connection=local
        /usr/local/bin/ansible-playbook ${DEBUG} -i hosts ConfigRedundancyGroupSEMPv1.yml --connection=local
        /usr/local/bin/ansible-playbook ${DEBUG} -i hosts ConfigRedundancyMateSEMPv1.yml --connection=local
        /usr/local/bin/ansible-playbook ${DEBUG} -i hosts ConfigRedundancyNoShutSEMPv1.yml --connection=local
        /usr/local/bin/ansible-playbook ${DEBUG} -i hosts ConfigNoShutMessageSpoolSEMPv1.yml --connection=local
        /usr/local/bin/ansible-playbook ${DEBUG} -i hosts ConfigConfigsyncNoShutSEMPv1.yml --connection=local
=======
        ansible-playbook ${DEBUG} -i hosts ShowRedundancyDetailSEMPv1.yml --connection=local
        sleep 30
        ansible-playbook ${DEBUG} -i hosts ConfigShutMessageSpoolSEMPv1.yml --connection=local
        ansible-playbook ${DEBUG} -i hosts ConfigRedundancyGroupSEMPv1.yml --connection=local
        ansible-playbook ${DEBUG} -i hosts ConfigRedundancyMateSEMPv1.yml --connection=local
        ansible-playbook ${DEBUG} -i hosts ConfigRedundancyNoShutSEMPv1.yml --connection=local
        ansible-playbook ${DEBUG} -i hosts ConfigNoShutMessageSpoolSEMPv1.yml --connection=local
        ansible-playbook ${DEBUG} -i hosts ConfigConfigsyncNoShutSEMPv1.yml --connection=local
>>>>>>> master
        echo MessageRouterPrimary
        ;; 
    MessageRouterBackup ) 
        export VMR_ROLE=backup
        export MATE_IP=${PRIMARY_IP}
        sed -i "s/SOLACE_LOCAL_ROLE/BACKUP/g" group_vars/LOCALHOST/localhost.yml 
<<<<<<< HEAD
        /usr/local/bin/ansible-playbook ${DEBUG} -i hosts ShowRedundancyDetailSEMPv1.yml --connection=local
        sleep 30
        /usr/local/bin/ansible-playbook ${DEBUG} -i hosts ConfigShutMessageSpoolSEMPv1.yml --connection=local
        /usr/local/bin/ansible-playbook ${DEBUG} -i hosts ConfigRedundancyGroupSEMPv1.yml --connection=local
        /usr/local/bin/ansible-playbook ${DEBUG} -i hosts ConfigRedundancyMateSEMPv1.yml --connection=local
        /usr/local/bin/ansible-playbook ${DEBUG} -i hosts ConfigRedundancyNoShutSEMPv1.yml --connection=local
        /usr/local/bin/ansible-playbook ${DEBUG} -i hosts ConfigNoShutMessageSpoolSEMPv1.yml --connection=local
        /usr/local/bin/ansible-playbook ${DEBUG} -i hosts ConfigConfigsyncNoShutSEMPv1.yml --connection=local
=======
        ansible-playbook ${DEBUG} -i hosts ShowRedundancyDetailSEMPv1.yml --connection=local
        sleep 30
        ansible-playbook ${DEBUG} -i hosts ConfigShutMessageSpoolSEMPv1.yml --connection=local
        ansible-playbook ${DEBUG} -i hosts ConfigRedundancyGroupSEMPv1.yml --connection=local
        ansible-playbook ${DEBUG} -i hosts ConfigRedundancyMateSEMPv1.yml --connection=local
        ansible-playbook ${DEBUG} -i hosts ConfigRedundancyNoShutSEMPv1.yml --connection=local
        ansible-playbook ${DEBUG} -i hosts ConfigNoShutMessageSpoolSEMPv1.yml --connection=local
        ansible-playbook ${DEBUG} -i hosts ConfigConfigsyncNoShutSEMPv1.yml --connection=local
>>>>>>> master
        ;; 
esac