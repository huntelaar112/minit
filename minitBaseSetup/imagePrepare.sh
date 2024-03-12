#!/bin/bash
set -e
source $(which buildconfig)
set -x

## Prevent initramfs updates from trying to run grub and lilo.
## https://journal.paul.querna.org/articles/2013/10/15/docker-ubuntu-on-rackspace/
## http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=594189
export INITRD=no
mkdir -p /etc/container_environment
echo -n no >/etc/container_environment/INITRD

# maybe update sourcelist before.
apt update

## Fix some issues with APT packages.
## See https://github.com/dotcloud/docker/issues/1024
dpkg-divert --local --rename --add /sbin/initctl
ln -sf /bin/true /sbin/initctl

## Replace the 'ischroot' tool to make it always return true.
## Prevent initscripts updates from breaking /dev/shm.
## https://journal.paul.querna.org/articles/2013/10/15/docker-ubuntu-on-rackspace/
## https://bugs.launchpad.net/launchpad/+bug/974584

#dpkg-divert --local --rename --add /usr/bin/ischroot
#ln -sf /bin/true /usr/bin/ischroot

## Apt utils
apt-get install -y apt-utils procps  apt-transport-https ca-certificates software-properties-common
## Often used tools.
apt-get install -y curl less vim-tiny psmisc gpg-agent dirmngr nano htop iputils-ping jq kmod wget iproute2 dnsutils
ln -s /usr/bin/vim.tiny /usr/bin/vim
## Upgrade all packages.
#apt-get dist-upgrade -y --no-install-recommends -o Dpkg::Options::="--force-confold"
## Fix locale.
case $(lsb_release -is) in
Ubuntu)
  $minimal_apt_get_install language-pack-en
  ;;
Debian)
  $minimal_apt_get_install locales locales-all
  ;;
*) ;;
esac
locale-gen en_US
update-locale LANG=en_US.UTF-8 LC_CTYPE=en_US.UTF-8
echo -n en_US.UTF-8 >/etc/container_environment/LANG
echo -n en_US.UTF-8 >/etc/container_environment/LC_CTYPE

##################################################################################################################
##################################################################################################################
### prepare services
mkdir -p /etc/minit
mkdir -p /etc/minit_prestart
#mkdir -p /etc/my_init.pre_shutdown.d
#mkdir -p /etc/my_init.post_shutdown.d

## Install a syslog daemon and logrotate.
[ "$DISABLE_SYSLOG" -eq 0 ] && "${buildDir}"/minitBaseSetup/services/syslog-ng/syslog-ng.sh || true

## Install the SSH server.
[ "$DISABLE_SSH" -eq 0 ] && "${buildDir}"/minitBaseSetup/services/sshd/sshd.sh || true

## Install cron daemon.
[ "$DISABLE_CRON" -eq 0 ] && "${buildDir}"/minitBaseSetup/services/cron/cron.sh || true

mkdir -p /bin/utils
chmod +x "${buildDir}"/minitBaseSetup/utils/*
chmod +x "${buildDir}"/minitBaseSetup/utils/scripts/*

cp "${buildDir}"/minitBaseSetup/utils/scripts/* /bin

bashrcSource='export PATH="$PATH:/bin/utils"
listSourceFiles=($(ls /bin/utils))
for file in "${listSourceFiles[@]}"; do
        source $(which ${file})
done'

find "${buildDir}"/minitBaseSetup/utils/ -maxdepth 1 -type f -exec cp {} /bin/utils \;
echo "${bashrcSource}" >> ~/.bashrc