# minit
A lightweight init system for docker container.
- build with sshd (ssh with key /etc/ssh/ssh_host_ed25519_key) - gen different each time running new container.
- build with crontab.

## build minit base iamge
./buildminitbase

## build zabbix use minit base image
./build-zabbix/buildImage.sh [nvidia-driver-version]
example: ./build-zabbix/buildImage.sh 470.182.03