#!/bin/bash

network_setup="
# interfaces(5) file used by ifup(8) and ifdown(8)
# Include files from /etc/network/interfaces.d:
source-directory /etc/network/interfaces.d
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet manual

auto eth1
iface eth1 inet manual

auto cloudbr0
iface cloudbr0 inet static
    bridge_ports eth0
    bridge_fd 0
    bridge_stp off
    bridge_maxwait 1
    address 172.172.0.201
    netmask 255.255.0.0
    gateway 172.172.0.1
    dns-nameservers 1.1.1.1 8.8.8.8 

auto cloudbr1
iface cloudbr1 inet static
    bridge_ports eth1
    bridge_fd 0
    bridge_stp off
    bridge_maxwait 1
    address 172.188.0.201
    netmask 255.255.0.0
    gateway 172.188.0.1
    dns-nameservers 1.1.1.1 8.8.8.8 
"

echo "${network_setup}" >/etc/network/interface

apt-get update &&
    apt-get -y install \
        bridge-utils \
        dmidecode \
        dnsmasq \
        ebtables \
        iproute2 \
        iptables \
        libvirt-clients \
        libvirt-daemon-system \
        ovmf \
        qemu-efi \
        qemu-kvm \
        tini sudo git \
        qemu-system libvirt-daemon-system virt-manager

echo "root:hanoi123" | chpasswd
#sed -i 's|[#]*PermitRootLogin no|PermitRootLogin yes|g' /etc/ssh/sshd_config
echo "PermitRootLogin yes" >>/etc/ssh/sshd_config
echo "PasswordAuthentication yes" >>/etc/ssh/sshd_config
#sed -i 's|[#]*PasswordAuthentication no|PasswordAuthentication yes|g' /etc/ssh/sshd_config

echo 'libvirtd_opts=\"-l\"' >>/etc/default/libvirtd

libvrdconf="
listen_tls = 0
listen_tcp = 0
tls_port = \"16514\"
tcp_port = \"16509\"
auth_tcp = \"none\"
mdns_adv = 0
"

echo "${libvrdconf}" >>/etc/libvirt/libvirtd.conf

#srvctl sshd restart
pkill sshd && /usr/sbin/sshd
srvctl libvirtd restart
srvctl networking restart
virtlogd -d

##########################################################
# run in host
mobprobe -r kvm-intel
modprobe -r kvm 
modprobe kvm
modprobe kvm-intel nested=1

# network docker useless when bridge it, but default work
docker network connect bridge nginx_name

# ssh -i ~/.ssh/id_rsa.cloud -p 3922 root@169.254.14.1