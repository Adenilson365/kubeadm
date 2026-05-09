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

### AnsibleVault

```shell
ansible-vault encrypt ./ansible/roles/haproxy/vars/vault.yaml
```

- Execute a play:
  ```shell
  ansible-playbook -l ha-proxy-1 main.yaml --ask-vault-pass
  ```
