#! /bin/bash
export DOCKER_HOST="tcp://127.0.0.1:2375"
set -e

if env | grep -q "DOCKER_RIAK_DEBUG"; then
  set -x
fi

CLEAN_DOCKER_HOST=$(echo "${DOCKER_HOST}" | cut -d'/' -f3 | cut -d':' -f1)
RANDOM_CONTAINER_ID=$(sudo docker ps | egrep "docker.getzephyr.com/riak:2.1.1" | cut -d" " -f1 | perl -MList::Util=shuffle -e'print shuffle<>' | head -n1)
CONTAINER_HTTP_PORT=$(sudo docker port "${RANDOM_CONTAINER_ID}" 8098 | cut -d ":" -f2)

curl -s "http://${CLEAN_DOCKER_HOST}:${CONTAINER_HTTP_PORT}/stats" | python -mjson.tool
