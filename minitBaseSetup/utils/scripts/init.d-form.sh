#!/bin/bash
# chkconfig: 2345 20 80
# description: Description comes here....

# Source function library.
source "/etc/init.d/functions"

start() {
   echo ""
   # code to start app comes here
   # example: daemon program_name &
}

stop() {
   echo ""
   # code to stop app comes here
   # example: killproc program_name
}

case "$1" in
start)
   start
   ;;
stop)
   stop
   ;;
restart)
   stop
   start
   ;;
status)
   # code to check status of app comes here
   # example: status program_name
   ;;
*)
   echo "Usage: $0 {start|stop|status|restart}"
   ;;
esac

exit 0

# srvctl, sysctl
# 50-01-symlinks-env.shenv load all .shenv in /$USERNAME/workspace/.config/
# 50-00-env.shenv --> export TZ, publicuser, root name env and its home, load JAVA ENV if java exist .shenv in ${USERHOME}/workspace/.config/
# 60-00-nginxgen.shenv get nginxshell env, use inside script start.