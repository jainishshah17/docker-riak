#! /bin/bash

set -e

if env | grep -q "DOCKER_RIAK_DEBUG"; then
  set -x
fi

sudo docker ps | egrep "docker.getzephyr.com/riak:2.1.1" | cut -d" " -f1 | xargs -I{} sudo docker rm -f {} > /dev/null 2>&1

echo "Stopped the cluster and cleared all of the running containers."
