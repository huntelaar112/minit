#!/bin/bash
set -e
exitval=0

namescrpit=${0:2}

function help() {
  echo "Usage: ${namescrpit} <container-name> [network] [static-ip]
  Note: This script need sudo permission to execute.
        Should use network and static IP."
  exit ${exitval}
}

conname=$1
network=$2
staticip=$3

numberArgs="1"
[[ ${1} = "-h" || -z ${1} || "$#" -lt ${numberArgs} ]] && {
  echo "Missing arguments."
  help
}

imagebase=minit:test
connname=${conname}
CDATA=/mnt/containerdata # save data of container
HOSTHOME=/mnt/containerdata/minit

#docker pull ${imagebase}
echo "remove ""${connname}"".old container" || :
docker rm -f "${connname}".old || :
#docker rename ${connname} ${connname}.old || :
echo "rename ""${connname}"" to ""${connname}"".old" || :
docker rename "${connname}"{,.old} &>/dev/null || :
docker stop "${connname}".old || :

[[ -n ${network} && -n ${staticip} ]] && {
  docker run -idt --network "${network}" --ip "${staticip}" \
    -p 4443:443 -p 8080:80 -p 222:22\
    --restart always \
    -e HOSTHOME=/mnt/hosthome \
    -v ${HOSTHOME}:/mnt/hosthome -e TZ=Asia/Ho_Chi_Minh \
    -v ${CDATA}:${CDATA} \
    --name "${connname}" --hostname "${connname}" -itd ${imagebase}

  docker network connect bridge "${connname}"
  echo "Run ${connname} on docker network: ${network} with IP:${staticip}"
} || {
  echo "Use default bridge network."
  docker run -idt --network bridge --ip "${staticip}" \
    -p 4443:443 -p 8080:80 -p 222:22\
    --restart always -e TZ=Asia/Ho_Chi_Minh \
    -e HOSTHOME=/mnt/hosthome \
    -v ${HOSTHOME}:/mnt/hosthome \
    -v ${CDATA}:${CDATA} \
    --name "${connname}" --hostname "${connname}" -itd ${imagebase}
}

#docker network connect ocrnet ${connname}
#docker network connect toyota-dkx_sail  ${connname}
docker exec -it "${connname}" bash

#    --cap-add SYS_ADMIN --device /dev/fuse --security-opt "apparmor:unconfined" \
#    --cap-add SYS_PTRACE \
#    --ipc host --privileged -v /var/run/docker.sock:/var/run/docker.sock
