### Como criar e restaurar cluster usando etcd

- Acesse o control-plane
- Para snapshot comando:

```shell
ETCDCTL_API=3 etcdctl --endpoints=https://192.168.56.11:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt  --key=/etc/kubernetes/pki/etcd/server.key snapshot save /home/etcd/snapshot-etcd-$(date "+%Y-%m-%d_%H-%M-%S")
```

- exporte a variável: ETCDCTL_API=3
- As flags estão como argumentos do command no pod do etcd em /etc/kubernetes/manifests
- Para o serviço do etcd antes do restore, faça isso movendo o etcd.yaml para outra pasta e após execução retorne o etcd.yaml.
- Para restore comando:

```shell
ETCDCTL_API=3 etcdctl --data-dir=/var/lib/etcd snapshot restore

```

- --data-dir -> é o diretório novo que o etcd vai ler e armazenar dados. O diretório não pode existir.
- Se alterar precisa substituir a configuração de volume do pod do etcd para novo path e o argumento --data-dir do command.
