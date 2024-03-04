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

$minimal_apt_get_install apt-utils procps

## Install HTTWPS support for APT.
$minimal_apt_get_install apt-transport-https ca-certificates

## Install add-apt-repository
$minimal_apt_get_install software-properties-common

## Upgrade all packages.
apt-get dist-upgrade -y --no-install-recommends -o Dpkg::Options::="--force-confold"

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

##########################################################################################################
##########################################################################################################
### prepare services
mkdir -p /etc/minit
mkdir -p /etc/minit_prestart
#mkdir -p /etc/my_init.pre_shutdown.d
#mkdir -p /etc/my_init.post_shutdown.d
mkdir -p /etc/container_environment
chmod 700 /etc/container_environment
touch /etc/container_environment.sh
touch /etc/container_environment.json

groupadd -g 8377 docker_env
chown :docker_env /etc/container_environment.sh /etc/container_environment.json
chmod 640 /etc/container_environment.sh /etc/container_environment.json
ln -s /etc/container_environment.sh /etc/profile.d/

## Install runit.
#$minimal_apt_get_install runit

## Install a syslog daemon and logrotate.
[ "$DISABLE_SYSLOG" -eq 0 ] && "${buildDir}"/minitBaseSetup/services/syslog-ng/syslog-ng.sh || true

## Install the SSH server.
[ "$DISABLE_SSH" -eq 0 ] && "${buildDir}"/minitBaseSetup/services/sshd/sshd.sh || true

## Install cron daemon.
[ "$DISABLE_CRON" -eq 0 ] && "${buildDir}"/minitBaseSetup/services/cron/cron.sh || true

# install runit

## Often used tools.
apt-get install -y curl less vim-tiny psmisc gpg-agent dirmngr nano htop iputils-ping jq kmod wget resolvconf
ln -s /usr/bin/vim.tiny /usr/bin/vim

## This tool runs a command as another user and sets $HOME.
#cp /bd_build/bin/setuser /sbin/setuser
## This tool allows installation of apt packages with automatic cache cleanup.
chmod +x "${buildDir}"/minitBaseSetup/image-utils
cp "${buildDir}"/minitBaseSetup/image-utils /bin && echo "source $(which image-utils)" >> ~/.bashrc 
cat "${buildDir}"/minitBaseSetup/bashrc-utils >> ~/.bashrc 
