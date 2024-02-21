#!/bin/bash

conname=nfs-server
shareDir=/mnt/containerdata/nfs-server/share
image="mannk98/nfs-server:test"

docker run -idt --name ${conname} --hostname ${conname} -e TZ=Asia/Ho_Chi_Minh --restart always \
    --privileged -v ${shareDir}:/nfsshare -p 2049:2049 -e SHARED_DIRECTORY=/nfsshare \
    "${image}"
