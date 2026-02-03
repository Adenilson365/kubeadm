### Intalação Kubeadm no Ubuntu ###
### Dcumentação de referência: ###
# KubeAdm: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
# calico: https://docs.tigera.io/calico/latest/about/

#!/bin/bash
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
        echo "\n\n$1 instalado com sucesso\n\n"
    else
        echo "\n\nFalha na instalação do $1 \n\n"
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
sysctl -w net.ipv4.ip_forward=1

### Kubeadm init ###
# https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/

# --apiserver-advertise-address: Endereço IP onde o master do servidor API irá escutar
# --pod-network-cidr: Faixa de IPs para o pod network (necessário para alguns plugins de rede, como o Calico)
# Esse valor deve ser compatível com o plugin de rede que será utilizado, por exemplo, o Calico utiliza 
# --service-cidr: Faixa de IPs para os serviços do cluster


if [ "$(hostname)" = "cp1" ]; then
    echo "Iniciando o nó master cp1"
    NODE_IP=$(ip -4 -o addr show dev enp0s8 | awk '{print $4}' | cut -d/ -f1) 
    kubeadm init --apiserver-advertise-address="$NODE_IP" \
      --pod-network-cidr=$POD_CIDR \
      --service-cidr=$SERVICE_CIDR


    ## Corrigir ip do kubelet
    sudo tee /etc/default/kubelet >/dev/null <<EOF
KUBELET_EXTRA_ARGS=--node-ip=${NODE_IP}
EOF

    sudo systemctl daemon-reload
    sudo systemctl restart kubelet

    # Configurar kubectl para o usuário vagrant
    mkdir -p "$HOME/.kube"
    sudo cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
    sudo chown "$(id -u)":"$(id -g)" "$HOME/.kube/config"

   kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.3/manifests/calico.yaml
   kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.3/manifests/tigera-operator.yaml

    echo "\n\n########---Instalando Go---#########\n\n"
    wget https://go.dev/dl/go$GO_VERSION.linux-amd64.tar.gz
    rm -rf /usr/local/go && tar -C /usr/local -xzf go$GO_VERSION.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    go version 
    install_test "Go"

    echo "\n\n########---Instalando etcdctl---#########\n\n"
    git clone -b $ETCD_VERSION https://github.com/etcd-io/etcd.git
    cd etcd
    ./build
    export PATH=$PATH:/home/kubeadm/etcd/bin
    etcdctl version
    install_test "etcdctl"


else
echo "executando nó worker ${HOSTNAME}"

NODE_IP=$(ip -4 -o addr show dev enp0s8 | awk '{print $4}' | cut -d/ -f1) 

sudo tee /etc/default/kubelet >/dev/null <<EOF
KUBELET_EXTRA_ARGS=--node-ip=${NODE_IP}
EOF
    sudo systemctl daemon-reload
    sudo systemctl restart kubelet
fi









