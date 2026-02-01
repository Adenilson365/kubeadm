### Intalação Kubeadm no Ubuntu ###
### Dcumentação de referência: ###
# KubeAdm: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
# calico: https://docs.tigera.io/calico/latest/about/

#!/bin/bash
KUBERNETES_VERSION=v1.33
CRIO_VERSION=v1.33

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


kubeadm init --apiserver-advertise-address="192.168.56.11" --pod-network-cidr="10.244.0.0/16" --service-cidr="10.96.0.0/12"

## Corrigir ip do kubelet
sudo tee /etc/default/kubelet >/dev/null <<'EOF'
KUBELET_EXTRA_ARGS=--node-ip=192.168.56.11
EOF

sudo systemctl daemon-reload
sudo systemctl restart kubelet

## Por estar no virtualBox, o kubelet anuncia o ip nat, e ao tentar conectar aos workoloads não consigo.


# CNI - Calico e Tigera
# https://docs.tigera.io/calico/latest/getting-started/kubernetes/quick

# IMPORTANTE: CoreDNS não funciona enquanto não for aplicado um plugin de rede CNI

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.3/manifests/calico.yaml
kubectl create -f kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.3/manifests/tigera-operator.yaml






