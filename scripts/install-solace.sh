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

verbose=0

while getopts "c:d:u:" opt; do
    case "$opt" in
    c)  config_file=$OPTARG
        ;;
    d)  solace_directory=$OPTARG
        ;;
    u)  solace_url=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

echo "config_file=$config_file ,solace_directory=$solace_directory ,solace_url=$solace_url ,Leftovers: $@"

cd $solace_directory
echo "`date` Configure VMRs Started"

#Set up the cluster part of the ansible variables file
for role in Monitor MessageRouterPrimary MessageRouterBackup
do 
    role_info=`grep ${role} ${config_file}`
    role_name=${role%% *}
    role_ip=`echo ${role_name} | cut -c 4- | tr "-" .`
    case $role in  
        ?Monitor* )
            sed -i "s/SOLACE_MONITOR_NAME/${role_name}/g" group_vars_LOCALHOST/localhost.yml
            sed -i "s/SOLACE_MONITOR_IP/${role_ip}/g" group_vars_LOCALHOST/localhost.yml
            ;; 
        ?MessageRouterPrimary* ) 
            sed -i "s/SOLACE_PRIMARY_NAME/${role_name}/g" group_vars_LOCALHOST/localhost.yml
            sed -i "s/SOLACE_PRIMARY_IP/${role_ip}/g" group_vars_LOCALHOST/localhost.yml
            PRIMARY_IP=${role_ip}
            ;; 
        ?MessageRouterBackup* ) 
            sed -i "s/SOLACE_BACKUP_NAME/${role_name}/g" group_vars_LOCALHOST/localhost.yml
            sed -i "s/SOLACE_BACKUP_IP/${role_ip}/g" group_vars_LOCALHOST/localhost.yml
            BACKUP_IP=${role_ip}
            ;; 
    esac
done

host_name=`hostname`
host_info=`grep ${host_name} ${config_file}`

sed -i "s/SOLACE_LOCAL_NAME/${host_name}/g" group_vars_LOCALHOST/localhost.yml
local_role=`echo $host_info | grep -o -e "-M.*Stack-"`

# Set up the local host part of the ansible varialbes file
case $local_role in  
    ?Monitor* ) 
        sed -i "s/SOLACE_LOCAL_ROLE/MONITOR/g" group_vars_LOCALHOST/localhost.yml 
        ansible-playbook ${DEBUG} -i hosts ConfigReloadToMonitorSEMPv1.yml --connection=local
        ansible-playbook ${DEBUG} -i hosts ConfigRedundancyGroupSEMPv1.yml --connection=local
        ;; 
    ?MessageRouterPrimary* ) 
        export VMR_ROLE=primary
        export MATE_IP=${BACKUP_IP}
        sed -i "s/SOLACE_LOCAL_ROLE/PRIMARY/g" group_vars_LOCALHOST/localhost.yml 
        ansible-playbook ${DEBUG} -i hosts ConfigShutMessageSpoolSEMPv1.yml --connection=local
        ansible-playbook ${DEBUG} -i hosts ConfigRedundancyGroupSEMPv1.yml --connection=local
        ansible-playbook ${DEBUG} -i hosts ConfigRedundancyMateSEMPv1.yml --connection=local
        ansible-playbook ${DEBUG} -i hosts ConfigNoShutMessageSpoolSEMPv1.yml --connection=local
        ;; 
    ?MessageRouterBackup* ) 
        export VMR_ROLE=backup
        export MATE_IP=${PRIMARY_IP}
        sed -i "s/SOLACE_LOCAL_ROLE/BACKUP/g" group_vars_LOCALHOST/localhost.yml 
        ansible-playbook ${DEBUG} -i hosts ConfigShutMessageSpoolSEMPv1.yml --connection=local
        ansible-playbook ${DEBUG} -i hosts ConfigRedundancyGroupSEMPv1.yml --connection=local
        ansible-playbook ${DEBUG} -i hosts ConfigRedundancyMateSEMPv1.yml --connection=local
        ansible-playbook ${DEBUG} -i hosts ConfigNoShutMessageSpoolSEMPv1.yml --connection=local
        ;; 
esac
