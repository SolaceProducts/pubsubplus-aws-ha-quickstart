
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


host_name=`hostname`
host_info=`grep ${host_name} ${config_file}`

local_role=`echo $host_info | grep -o -E 'Monitor|MessageRouterPrimary|MessageRouterBackup'`

cd ${ansible_dir}
# Set up the local host part of the ansible varialbes file
case $local_role in  
    Monitor ) 
        sed -i "s/SOLACE_LOCAL_ROLE/MONITOR/g" group_vars/LOCALHOST/localhost.yml
        ansible-playbook ${DEBUG} -i hosts ShowRedundancyDetailSEMPv1.yml --connection=local
        sleep 30
        ansible-playbook ${DEBUG} -i hosts ConfigReloadToMonitorSEMPv1.yml --connection=local
        sleep 60
        ansible-playbook ${DEBUG} -i hosts ConfigRedundancyGroupSEMPv1.yml --connection=local
        ansible-playbook ${DEBUG} -i hosts ConfigRedundancyNoShutSEMPv1.yml --connection=local
        ;; 
    MessageRouterPrimary ) 
        export VMR_ROLE=primary
        export MATE_IP=${BACKUP_IP}
        sed -i "s/SOLACE_LOCAL_ROLE/PRIMARY/g" group_vars/LOCALHOST/localhost.yml
        ansible-playbook ${DEBUG} -i hosts ConfigShutMessageSpoolSEMPv1.yml --connection=local
        ansible-playbook ${DEBUG} -i hosts ConfigRedundancyGroupSEMPv1.yml --connection=local
        ansible-playbook ${DEBUG} -i hosts ConfigRedundancyMateSEMPv1.yml --connection=local
        ansible-playbook ${DEBUG} -i hosts ConfigRedundancyNoShutSEMPv1.yml --connection=local
        ansible-playbook ${DEBUG} -i hosts ConfigNoShutMessageSpoolSEMPv1.yml --connection=local
        ansible-playbook ${DEBUG} -i hosts ConfigConfigsyncNoShutSEMPv1.yml --connection=local
        echo MessageRouterPrimary
        ;; 
    MessageRouterBackup ) 
        export VMR_ROLE=backup
        export MATE_IP=${PRIMARY_IP}
        sed -i "s/SOLACE_LOCAL_ROLE/BACKUP/g" group_vars/LOCALHOST/localhost.yml 
        ansible-playbook ${DEBUG} -i hosts ConfigShutMessageSpoolSEMPv1.yml --connection=local
        ansible-playbook ${DEBUG} -i hosts ConfigRedundancyGroupSEMPv1.yml --connection=local
        ansible-playbook ${DEBUG} -i hosts ConfigRedundancyMateSEMPv1.yml --connection=local
        ansible-playbook ${DEBUG} -i hosts ConfigRedundancyNoShutSEMPv1.yml --connection=local
        ansible-playbook ${DEBUG} -i hosts ConfigNoShutMessageSpoolSEMPv1.yml --connection=local
        ansible-playbook ${DEBUG} -i hosts ConfigConfigsyncNoShutSEMPv1.yml --connection=local
        ;; 
esac
