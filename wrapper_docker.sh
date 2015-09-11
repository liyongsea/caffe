#!/bin/bash

FOO=`nvidia-smi`
if [ "$?" == "0" ]; then
        echo "Linking GPU version of caffe"
        ln -s /opt/caffe/distribute_gpu /opt/caffe/distribute
        export CPU_ONLY=0
else
        echo "Linking CPU version of caffe"
        ln -s /opt/caffe/distribute_cpu /opt/caffe/distribute
        export CPU_ONLY=1
fi

exec "$@"


