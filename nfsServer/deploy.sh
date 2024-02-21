#!/bin/bash

conname=nfs-server
shareDir=/mnt/containerdata/nfs-server/share
image=""

docker run -d --name ${conname} --privileged -v ${shareDir}:/nfsshare -e SHARED_DIRECTORY=/nfsshare "${image}"