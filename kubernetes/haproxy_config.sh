#!/usr/bin/env bash
set -euo pipefail

cat > /etc/kubernetes/kubeadm-config.yaml <<'EOF'
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
kubernetesVersion: v1.33.11
controlPlaneEndpoint: "192.168.56.31:6443"
apiServer:
  certSANs:
    - "192.168.56.31"
    - "192.168.56.11"
EOF

cd /etc/kubernetes/pki


rm -f apiserver.crt apiserver.key

kubeadm init phase certs apiserver --config /etc/kubernetes/kubeadm-config.yaml

systemctl restart kubelet

openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -text | grep -A2 "Subject Alternative Name"