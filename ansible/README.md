### Ansible Provisioning

#

### Role Groups

- Kubernetes
  - All Kubernetes nodes Bootstrap
  - Control-Plane + ETCD
    - KubeADM
    - Kubelet
    - Kubectl
    - ETCD
    - Go
    - CP1
      - Execute KubeADM Init
    - Other CP
      - Execute KubeADM control-plane join
  - Workers
    - KubeADM
    - Kubelet
    - All Workers
      - Execute KubeADM join
- Load Balancer
  - HAproxy L4
  - HAproxy L7
-
