#!/bin/bash

set -e
set -x
source $(which buildconfig)

cp ${buildDirServices}/symlink/10_symlink.minit ${etcServicePreStartDir}