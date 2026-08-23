- Necessário adicionar no list

```
    - --listen-metrics-urls=http://127.0.0.1:2381,https://192.168.56.12:2381

```

- Comando checar conf prometheus

```shell
 promtool check config
 # No container
 docker exec prometheus promtool check config /etc/prometheus/prometheus.yml
```

- Curl para teste endpoint metricas

```
curl --cacert /etc/kubernetes/pki/etcd/ca.crt      --cert /etc/kubernetes/pki/etcd/healthcheck-client.crt      --key /etc/kubernetes/pki/etcd/healthcheck-client.key      https://192.168.56.11:2381/metrics

```

- Comando stress wait

```
stress-ng --hdd 4 --hdd-bytes 5G --timeout 120s --metrics-brief
```

### HAproxy Instrumentation

[Documentation](https://www.haproxy.com/documentation/haproxy-configuration-tutorials/alerts-and-monitoring/prometheus/)
