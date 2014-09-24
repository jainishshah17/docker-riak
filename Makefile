.PHONY: all build riak-container start-cluster test-cluster stop-cluster

all: stop-cluster riak-container start-cluster

build riak-container:
	sudo  docker build -t "docker.getzephyr.com/riak" .

start-cluster:
	./bin/start-cluster.sh

test-cluster:
	./bin/test-cluster.sh

stop-cluster:
	./bin/stop-cluster.sh
