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


sudo yum update -y

OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
solace_tarball=""
verbose=0

while getopts "f:d:" opt; do
    case "$opt" in
    f)  solace_tarball=$OPTARG
        ;;
    d)  solace_directory=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

echo "solace_tarball=$solace_tarball ,solace_directory=$solace_directory ,Leftovers: $@"  

cd $solace_directory
tar zxf $solace_tarball

retry=30
while [ ${retry} -gt 0 ]
do
    if [ -f /usr/local/bin/ansible ] ; then
       retry=0
    fi
    echo "${retry} more attempts to install ansible"
    ((retry=retry-1))
    easy_install --upgrade pip
    echo `/usr/local/bin/pip2.7 install ansible`
    sleep 10
done
