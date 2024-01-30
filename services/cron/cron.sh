#!/bin/bash
set -e
source /imageBuild/buildconfig
set -x

$minimal_apt_get_install cron
mkdir /etc/minit.d/cron
chmod 600 /etc/crontab
cp /imageBuild/services/cron/cron.minit /etc/minit
# Fix cron issues in 0.9.19, see also #345: https://github.com/phusion/baseimage-docker/issues/345
sed -i 's/^\s*session\s\+required\s\+pam_loginuid.so/# &/' /etc/pam.d/cron

## Remove useless cron entries.
# Checks for lost+found and scans for mtab.
rm -f /etc/cron.daily/standard
rm -f /etc/cron.daily/upstart
rm -f /etc/cron.daily/dpkg
rm -f /etc/cron.daily/password
rm -f /etc/cron.weekly/fstrim
rm -f /etc/cron.d/e2scrub_all
