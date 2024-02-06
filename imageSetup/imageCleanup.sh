#!/bin/bash
set -e
source $(which buildconfig)
set -x

testEnable=${1}

buildDir="/build"

apt-get clean
#find ${buildDir} -not \( -name 'minit' -or -name 'buildconfig' -or -name 'cleanup.sh' \) -delete

[[ "${testEnable}" == "test" ]] && {
    rm -rf ${buildDir}
}

rm -rf /tmp/* /var/tmp/*
rm -rf /var/lib/apt/lists/*

# clean up python bytecode
find / -mount -name *.pyc -delete
find / -mount -name *__pycache__* -delete

rm -f /etc/ssh/ssh_host_*
