#! /bin/bash

Host=`cat /etc/hosts | grep build_riak_1 | head -n1 | awk '{print $1}'`
echo $Host
echo "riak-admin cluster join \"riak@$Host\"" 
riak-admin cluster join riak@$Host  
sleep 9;















