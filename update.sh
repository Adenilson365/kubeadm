#### Comandos para atualizar kubeadm.sh ####

### Documentação oficial para atualização do kubeadm
### Patch Releases: https://v1-34.docs.kubernetes.io/releases/patch-releases/
### https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/
# Verificar repositórios atuais do kubeadm
KUBERNETES_VERSION=1.34
CRIO_VERSION=1.34
apt-cache madison kubeadm


# Adicioner repositório do Kubernetes
curl -fsSL https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION/deb/ /" |
    tee /etc/apt/sources.list.d/kubernetes.list

# Adicioner repositórios e instalar componentes

curl -fsSL https://download.opensuse.org/repositories/isv:/cri-o:/stable:/v$CRIO_VERSION/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://download.opensuse.org/repositories/isv:/cri-o:/stable:/v$CRIO_VERSION/deb/ /" |
    tee /etc/apt/sources.list.d/cri-o.list

apt-get update

apt-cache madison kubeadm

apt-mark unhold kubelet kubeadm kubectl

### Antes de atualizar os nós é necessário fazer o drain e o cordon.

#kubectl drain <nome-do-node> --ignore-daemonsets --delete-local-data
#kubectl cordon <nome-do-node>

#atualizar kubeadm, kubelet e kubectl
apt-get install -y kubelet=$KUBERNETES_VERSION.0-1.1 kubeadm=$KUBERNETES_VERSION.0-1.1 kubectl=$KUBERNETES_VERSION.0-1.1 cri-o=$CRIO_VERSION.0-1.1

apt-mark hold kubelet kubeadm kubectl

### Depois de atualizar os componentes via apt  é necessários fazer o upgrade do cluster que vai continuar na mesma versão.
### Versão precisa ser no formato vX.Y.Z - exemplo v1.34.0
kubeadm upgrade apply v$KUBERNETES_VERSION.0 -y

systemctl restart kubelet

# para workers apenas restartar o kubelet
systemctl restart kubelet