#!/bin/bash

nvidiaVersion=${1}
[[ ${nvidiaVersion} == "-h" ]] && {
    echo "Use: ./buildImage [nvidiaVersion]
example: 525.105.17 or ./buildImage to build without nvidia driver."
    exit 0
}

[[ -n ${nvidiaVersion} ]] && {
    nvidiaVersionTag="-nvidia${1}"
} || {
    nvidiaVersionTag=""
}

#470.182.03 prod
#525.105.17
#535.154.05 ssd

docker build -t mannk98/zabbix-agent2:6.4ubuntu"${nvidiaVersionTag}" --build-arg nvidia_version="${nvidiaVersion}" -f dockerfile-zabbixagent2 ..
echo "done build"
