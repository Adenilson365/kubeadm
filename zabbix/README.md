### Monitoria ETCD

![alt text](./assets/image.png)
![alt text](./assets/image-1.png)

- Quando há muitas eleições indicando instabilidade no ambiente
  > Comando usado para gerar instabilidade `stress-ng --hdd 4 --hdd-bytes 5G --timeout 220s --metrics-brief &`
- ![alt text](./assets/too_many_leader_zabbix.png)
- Nesse caso tivemos 10 eleições em poucos minutos
  ![alt text](./assets/too_many_leader_etcdctl.png)
