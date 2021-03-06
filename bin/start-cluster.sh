#! /bin/bash

export DOCKER_HOST="tcp://127.0.0.1:2375"

set -e

if env | grep -q "DOCKER_RIAK_DEBUG"; then
  set -x
fi

if [ -z "${DOCKER_HOST}" ]; then
  echo ""
  echo "It looks like the environment variable DOCKER_HOST has not"
  echo "been set.  The Riak cluster cannot be started unless this has"
  echo "been set appropriately.  For example:"
  echo ""
  echo "  export DOCKER_HOST=\"tcp://127.0.0.1:2375\""
  echo ""

  
fi

CLEAN_DOCKER_HOST=$(echo "${DOCKER_HOST}" | cut -d'/' -f3 | cut -d':' -f1)
DOCKER_RIAK_CLUSTER_SIZE=${DOCKER_RIAK_CLUSTER_SIZE:-5}
DOCKER_RIAK_AUTOMATIC_CLUSTERING=${DOCKER_RIAK_AUTOMATIC_CLUSTERING:-1}

if sudo docker ps -a | grep "docker.getzephyr.com/riak" >/dev/null; then
  echo ""
  echo "It looks like you already have some Riak containers running."
  echo "Please take them down before attempting to bring up another"
  echo "cluster with the following command:"
  echo ""
  echo "  make stop-cluster"
  echo ""

  
fi

echo
echo "Bringing up cluster nodes:"
echo

# The default allows Docker to forward arbitrary ports on the VM for the Riak
# containers. Ports used by default are usually in the 49xx range.

publish_http_port="8098"
publish_pb_port="8087"

# If DOCKER_RIAK_BASE_HTTP_PORT is set, port number
# $DOCKER_RIAK_BASE_HTTP_PORT + $index gets forwarded to 8098 and
# $DOCKER_RIAK_BASE_HTTP_PORT + $index + $DOCKER_RIAK_PROTO_BUF_PORT_OFFSET
# gets forwarded to 8087. DOCKER_RIAK_PROTO_BUF_PORT_OFFSET is optional and
# defaults to 100.

DOCKER_RIAK_PROTO_BUF_PORT_OFFSET=${DOCKER_RIAK_PROTO_BUF_PORT_OFFSET:-100}

for index in $(seq -f "%02g" "1" "${DOCKER_RIAK_CLUSTER_SIZE}");
do
         sudo rm -f /connect/riak${index}/ring/*
  if [ ! -z $DOCKER_RIAK_BASE_HTTP_PORT ]; then
    final_http_port=$((DOCKER_RIAK_BASE_HTTP_PORT + index))
    final_pb_port=$((DOCKER_RIAK_BASE_HTTP_PORT + index + DOCKER_RIAK_PROTO_BUF_PORT_OFFSET))
    publish_http_port="${final_http_port}:8098"
    publish_pb_port="${final_pb_port}:8087"
  fi

  if [ "${index}" -gt "1" ] ; then
   sudo docker run -e "DOCKER_RIAK_CLUSTER_SIZE=${DOCKER_RIAK_CLUSTER_SIZE}" \
               -e "DOCKER_RIAK_AUTOMATIC_CLUSTERING=${DOCKER_RIAK_AUTOMATIC_CLUSTERING}" \
               -p 72${index}:$publish_http_port \
               -p 71${index}:$publish_pb_port \
			   -v /connect/riak${index}:/var/lib/riak \
			   -v /connect/riak${index}:/var/log/riak \
	             --link "riak01:seed" \
               --name "riak${index}" \
               -d docker.getzephyr.com/riak:2.1.1 > /dev/null 2>&1
  else
   sudo docker run -e "DOCKER_RIAK_CLUSTER_SIZE=${DOCKER_RIAK_CLUSTER_SIZE}" \
               -e "DOCKER_RIAK_AUTOMATIC_CLUSTERING=${DOCKER_RIAK_AUTOMATIC_CLUSTERING}" \
                -p 72${index}:$publish_http_port \
               -p 71${index}:$publish_pb_port \
			   -v /connect/riak${index}:/var/lib/riak \
			   -v /connect/riak${index}:/var/log/riak \
               --name "riak${index}" \
               -d docker.getzephyr.com/riak:2.1.1 > /dev/null 2>&1
  fi

  CONTAINER_ID=$(sudo docker ps | egrep "riak${index}[^/]" | cut -d" " -f1)
  CONTAINER_PORT=$(sudo docker port "${CONTAINER_ID}" 8098 | cut -d ":" -f2)

  until curl -s "http://${CLEAN_DOCKER_HOST}:${CONTAINER_PORT}/ping" | grep "OK" > /dev/null 2>&1;
  do
    sleep 3
  done

  echo "  Successfully brought up [riak${index}]"
done

echo
echo "Please wait approximately 30 seconds for the cluster to stabilize."
echo
