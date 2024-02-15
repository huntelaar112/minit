#!/bin/bash

set -e
set -x
source $(which buildconfig)

cp ${buildDirServices}/symlink/10_global_symlink.minit ${etcServicePreStartDir}