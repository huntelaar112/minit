#!/bin/bash

[[ ${1} == "no-cache" ]] && {
	docker build --no-cache -t minit:test -f ./dockerfile .
	echo "Build image no-cache done"
} || {
	docker build -t minit:test -f ./dockerfile .
	echo "Build image (with cache) done"
}
