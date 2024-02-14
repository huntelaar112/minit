#!/bin/bash

source $(which buildconfig)

cp ${buildDirServices}/symlink/10_symlink.minit ${etcServicePreStartDir}