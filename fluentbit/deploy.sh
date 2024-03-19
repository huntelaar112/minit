#!/bin/bash

conname=fluent-bit
image="mannk98/fluent-bit:test"

logpath="/tmp/log/"
configpath="./fluent-bit.conf"
datapreper='192.168.144.5'
datapreperPort='2021'

configContent="
[INPUT]
  name                  tail
  tag                   testlog
  refresh_interval      5
  DB                    /app.db
  path                  /var/log/app/*.log
  read_from_head        true

[INPUT]
  name                  tail
  tag                   testlog
  refresh_interval      5
  DB                    /database.db
  path                 /var/log/app/database/*.log
  read_from_head        true

# push to data-preper
[OUTPUT]
  Name http
  Match *
  Host ${datapreper}
  Port ${datapreperPort}
  URI /log/ingest
  Format json
"

echo "${configContent}" >./fluent-bit.conf

docker run -idt --name ${conname} --hostname ${conname} -e TZ=Asia/Ho_Chi_Minh --restart always \
    -p 2020:2020 -v ${logpath}:/var/log/app -v ${configpath}:/etc/fluent-bit/fluent-bit.conf \
    "${image}"
