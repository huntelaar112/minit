#!/bin/bash
repo=sonnt/cloudstackfull:latest
conname=cloudstackall
docker rm -f $conname
docker run --privileged -e VHOST=cloudstack.cloud.runsystem.work -e VPORT=8080 -p 8250:8250 \
   -p 8096:8096 -p 1798:1798 -p 16514:16514 \
   -p 2049:2049 -p 32767:32767 -p 32765:32765 -p 32766:32766 \
   --restart always -idt \
  --shm-size 200M  -v /mnt/containerdata/${conname}:/mnt/hosthome --network ocrnetwork --ip 172.172.0.201 \
  -v /lib/modules:/lib/modules --security-opt=apparmor=unconfined -v /sys/fs/cgroup:/sys/fs/cgroup \
   --name $conname -h $conname $repo

docker network connect monitoring ${conname} --ip 172.188.0.201
docker network connect  bridge ${conname}