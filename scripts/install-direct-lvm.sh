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
volume=""
disk_size=""
DEBUG="-vvvv"

verbose=0

while getopts "d:p:u:" opt; do
    case "$opt" in
    d)  disk_size=$OPTARG
        ;;
    v)  volume=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))
[ "$1" = "--" ] && shift

verbose=1
echo "disk_size==$disk_size= ,volume=$volume ,Leftovers: $@"

if [ $disk_size == "0" ]; then
   echo "`date` No persistent disk here, exiting"
   exit 0
fi

echo "`date` Create a physical volume and a volume group called vg01DockerPool"
sudo pvcreate ${volume}
sudo vgcreate vg01DockerPool ${volume}

echo "`date` Create a logical volume called vg01DockerPool, and then convert it to a thin pool"
sudo lvcreate --wipesignatures y -n thinpool vg01DockerPool -l 95%VG
sudo lvcreate --wipesignatures y -n thinpoolmetadata vg01DockerPool -l 1%VG
sudo lvconvert -y --zero n -c 512K --thinpool vg01DockerPool/thinpool \
                               --poolmetadata vg01DockerPool/thinpoolmetadata 


echo "`date` Create a file called vg01DockerPoolThinpool.profile in /etc/lvm/profile/ for use as the new lvm profile"
sudo mkdir /etc/lvm/profile/
sudo tee /etc/lvm/profile/vg01DockerPoolThinpool.profile <<-EOF
activation {
thin_pool_autoextend_threshold=80
thin_pool_autoextend_percent=20
}
EOF

sudo lvchange --metadataprofile vg01DockerPoolThinpool vg01DockerPool/thinpool

# Tjis does not work, it overwrites not appends.
echo "`date` Make a file called docker.service. This version of docker.service configures Docker to make use of the thin pool"
sudo tee /etc/sysconfig/docker <<-EOF
--storage-opt=dm.fs=xfs \
--storage-opt=dm.thinpooldev=/dev/mapper/vg01DockerPool-thinpool \
--storage-opt=dm.use_deferred_removal=true \
--storage-opt=dm.use_deferred_deletion=true \
--storage-opt=dm.basesize=6G
EOF

echo "`date` Move the existing graph driver directory if the Docker daemon was previously started"
sudo service docker stop
sudo mkdir /var/lib/docker.bk 
sudo sh -c 'mv /var/lib/docker/* /var/lib/docker.bk'

echo "`date` Start Docker Service"
sudo service docker start


