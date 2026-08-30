#!/bin/bash
### Intalação Kubeadm no Ubuntu ###
### Dcumentação de referência: ###
# KubeAdm: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
# calico: https://docs.tigera.io/calico/latest/about/

KUBERNETES_VERSION=v1.33
CRIO_VERSION=v1.33
POD_CIDR="10.244.0.0/16"
SERVICE_CIDR="10.96.0.0/12"
GO_VERSION=1.25.6  
ETCD_VERSION=v3.4.37

mkdir -p /home/kubeadm
cd /home/kubeadm || exit 1

install_test() {
    if [ $? -eq 0 ]; then
        echo "$1 instalado com sucesso"
    else
        echo " Falha na instalação do $1 "
        exit 1
    fi
}

apt-get update
apt-get install -y software-properties-common curl

# Adicioner repositório do Kubernetes
curl -fsSL https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/ /" |
    tee /etc/apt/sources.list.d/kubernetes.list

# Adicioner repositórios e instalar componentes

curl -fsSL https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/ /" |
    tee /etc/apt/sources.list.d/cri-o.list

apt-get update
apt-get install -y cri-o kubelet kubeadm kubectl

# Impedir que os compoentes do Kubernetes sejam atualizados automaticamente
apt-mark hold kubelet kubeadm kubectl



mv /etc/cni/net.d/10-crio-bridge.conflist.disabled /etc/cni/net.d/10-crio-bridge.conflist

systemctl enable crio --now
systemctl enable kubelet --now

systemctl start crio.service    

#desabilitar swap
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab   


modprobe br_netfilter
echo "br_netfilter" > /etc/modules-load.d/modules.conf

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

### Kubeadm init ###
# https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/

# --apiserver-advertise-address: Endereço IP onde o master do servidor API irá escutar
# --pod-network-cidr: Faixa de IPs para o pod network (necessário para alguns plugins de rede, como o Calico)
# Esse valor deve ser compatível com o plugin de rede que será utilizado, por exemplo, o Calico utiliza 
# --service-cidr: Faixa de IPs para os serviços do cluster

case "$(hostname)" in
  cp1|cp2|cp3)
    echo "Executando configuração de control-plane em $(hostname)"

    NODE_IP=$(ip -4 -o addr show dev enp0s8 | awk '{print $4}' | cut -d/ -f1)

    sudo tee /etc/default/kubelet >/dev/null <<EOF
KUBELET_EXTRA_ARGS=--node-ip=${NODE_IP}
EOF

    sudo systemctl daemon-reload
    sudo systemctl restart kubelet
    ;;

  wk1|wk2)
    echo "Executando configuração de worker em $(hostname)"

    NODE_IP=$(ip -4 -o addr show dev enp0s8 | awk '{print $4}' | cut -d/ -f1)

    sudo tee /etc/default/kubelet >/dev/null <<EOF
KUBELET_EXTRA_ARGS=--node-ip=${NODE_IP}
EOF

    sudo systemctl daemon-reload
    sudo systemctl restart kubelet
    ;;

  *)
    echo "Hostname não reconhecido: $(hostname)"
    exit 1
    ;;
esac

if [ "$(hostname)" = "cp1" ]; then
  echo "Inicializando cluster HA no cp1"

  kubeadm init \
    --apiserver-advertise-address="$NODE_IP" \
    --control-plane-endpoint="192.168.200.31:6443" \
    --apiserver-cert-extra-sans="192.168.200.31,192.168.200.11,192.168.200.12,192.168.200.13" \
    --upload-certs \
    --pod-network-cidr="$POD_CIDR" \
    --service-cidr="$SERVICE_CIDR"

  mkdir -p "$HOME/.kube"
  cp -f /etc/kubernetes/admin.conf "$HOME/.kube/config"
  chown "$(id -u)":"$(id -g)" "$HOME/.kube/config"

  kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.3/manifests/calico.yaml
fi