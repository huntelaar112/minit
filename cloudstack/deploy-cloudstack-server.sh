#!/bin/bash

./deploy-mariadb.sh mariadb.env

docker run -idt --name cloudstack-manager --hostname cloudstack-manager -e TZ=Asia/Ho_Chi_Minh --network ocrnetwork \
    --cap-add SYS_ADMIN --device /dev/fuse --security-opt "apparmor:unconfined" \
    --cap-add SYS_PTRACE \
    --ipc host --privileged --entrypoint /bin/bash cloudstack:server