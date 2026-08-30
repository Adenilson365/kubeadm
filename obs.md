# Kubernetes Stack de Observabilidade

Este Laboratório é uma extensão do laboratório de Kubernetes On-premises HA e contém a camada de observabilidade integrada ao laboratório. [Laboratório KubeADM](./README.md)

O objetivo é construir uma solução de observabilidade da infraestrutura, reproduzível e totalmente automatizada
capaz de fornecer:

- coleta de métricas de infraestrutura;
- métricas do Kubernetes e seus componentes;
- métricas do etcd;
- métricas do HAProxy;
- centralização de logs infra;
- visualização através do Grafana Dashboards;
- criação e roteamento de alertas.

Toda a infraestrutura e configuração do laboratório é gerenciada por
**Vagrant e Ansible**, evitando instalações e configurações manuais.

---

## Objetivos

A stack de observabilidade foi adicionada ao laboratório com os seguintes
objetivos:

- praticar conceitos de observabilidade em ambientes Kubernetes;
- centralizar métricas e logs da infraestrutura;
- observar componentes críticos do control plane;
- acompanhar a saúde do cluster etcd;
- monitorar os load balancers;
- automatizar o provisionamento da plataforma;
- manter dashboards e configurações versionados;
- criar uma base para estudos de troubleshooting e reliability.

O foco principal deste projeto é a integração entre os componentes de observabilidade e a infra, portanto, devido a limitações de recursos não há foco em HA nos componentes da stack de observabilidade.

## Arquitetura

![Diagrama arquitetura de observabilidade](./docs/assets/kubeadm-obs.jpg)

## Stack

1. Alloy - Colector de telemetria
2. Loki - Backend de logs
3. Prometheus - Backend de Métricas
4. Grafana - Dashboards
5. Alermanager - Alertas e Notificações
6. Kube-state-métrics - Metricas de objetos kubernetes
7. Ansible - Provisionamento

## Documentação

- [Ansible Collection Grafana](https://github.com/grafana/grafana-ansible-collection)
- [Ansible Role alloy](https://galaxy.ansible.com/ui/repo/published/grafana/grafana/content/role/alloy/)
- [Config alloy para prometheus](https://grafana.com/docs/alloy/latest/reference/components/prometheus/)
- [Alertmanager](https://prometheus.io/docs/alerting/latest/configuration/)
- [ETCD-Monitoring](https://etcd.io/docs/v3.4/op-guide/monitoring/)

## Componentes

### Alloy Collector

- Justiativa:
  - Usado como único collector de telemetria, logging, métricas, e possibilidade de traces.
  - Integrado/parte da stack grafana
  - Capaz de fazer scrape no formato prometheus, dessa forma é possível ter um único componente de coleta.
- Configuração e instalação:
  - Global: `role: alloy` instala em todas as máquinas o agent alloy, com configuração default.
    - Usei a ansible-role recomendada pela própria documentação, sem alterações.
  - Componetes: Cada host do ambiente configura o scrape do seu exporter alloy de acordo com o contexto, `task: configure_observability.yaml` em todas as roles.
    - Exemplo: Haproxy faz coleta de seus logs e seu endpoint específico, enquanto control-planes coletam métricas do etcd.
    - Sempre que um arquivo é alterado o alloy é restartado via handler
  - Todos os arquivos de configuração são via ansible-template.

### Prometheus

- Justificativa:
  - Usado como backend de métricas e alert-rules baseado em métricas.
  - Iniciei com endpoint write habilitado, pois o alloy será responsável pela coleta e envio de toda a telemetria.
- Instalaçao e configuração
  - Instalado via `role: obs_server`, sobe na stack docker compose, junto com demais componentes. `ansible/roles/obs_server/tasks/compose.yml`

### Loki

- Justificativa:
  - Usado como backend de logging e alert-rules baseado em padrão de logs.
  - Integrado ao grafana como datasource, e acessado via explorer.

### Prometheus Alertmanager

- Justificativa:
  - Roteador de alertas e notificações baseado em alertas recebidos do Prometheus ou loki.

### Grafana Dashboards

-

### Kube-state-metrics

- Para coleta de métricas de objetos do kubernetes.

### Logging

[Documentação k8s sobre Conceitos em logging](https://kubernetes.io/docs/concepts/cluster-administration/logging/)

- Habilitei coleta de logs do journald para coleta dos componentes que estão como serviços.
  - kubelet
  - containerd
- Habilitei coleta de arquivos de log personalizados como haproxy, auth, kernel
- A idéia é que caso necessário, basta adicionar ao conf.alloy uma nova fonte de logs.
-
