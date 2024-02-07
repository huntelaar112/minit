#!/bin/bash

type=${1}
[[ ${type} == "-h" ]] && {
    echo "Use: ./buildImage [nivida-version]
example: nvidia525.105.17 or ./buildImage to build without nvidia driver."
    exit 0
}

docker build -t mannk98/zabbix-agent2:6.4ubuntu --build-arg nvidia_binary_version="${type}" -f ./../dockerfile-zabbixagent2 ..
echo "done build"
