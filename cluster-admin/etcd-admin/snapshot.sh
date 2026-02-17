#!/bin/bash
set -u

export PATH=$PATH:/home/kubeadm/etcd/bin
export ETCDCTL_API=3
SNAPSHOT_DIR=/home/etcd/snapshot
SNAPSHOT_NAME=etcd_snapshot_$(date +"%Y_%m_%d_%H-%M-%S")
SNAPSHOT_PATH=$SNAPSHOT_DIR/$SNAPSHOT_NAME
SNAPSHOT_LOG=/home/etcd/logs/snapshot.log
ENDPOINT=https://192.168.56.11:2379
CACERT=/etc/kubernetes/pki/etcd/ca.crt
CERT=/etc/kubernetes/pki/etcd/server.crt
KEY=/etc/kubernetes/pki/etcd/server.key

etcdctl --endpoints=$ENDPOINT --cacert=$CACERT --cert=$CERT --key=$KEY snapshot save $SNAPSHOT_PATH

if [ $? -eq 0 ]; then
        echo "###-Snapshot: $SNAPSHOT_NAME realizado com sucesso-###" 
        echo "Sucesso - Data: $(date +"%Y_%m_%d_%H-%M-%S") - Snapshot: $SNAPSHOT_NAME - Status: $( etcdctl snapshot status $SNAPSHOT_PATH -w json 2>/dev/null || echo '{"status":"Indisponivel"}')" >> $SNAPSHOT_LOG
else
        echo "Falha - Data: $(date +'%Y_%m_%d_%H-%M-%S')" >> $SNAPSHOT_LOG
fi
