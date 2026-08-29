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

### Alloy

- Global: componente instala o exporter alloy, com uma configuração padrão pela `role: alloy`
- Componente: Cada componente do ambiente configura o scrape do seu exporter alloy de acordo com o contexto, `task: configure_observability.yaml`

### Prometheus

### Loki

### Prometheus Alertmanager

### Grafana Dashboards

### Kube-state-metrics
