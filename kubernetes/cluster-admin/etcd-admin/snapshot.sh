#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'


# ===== Config =====
export ETCDCTL_API=3

ETCDCTL_BIN="${ETCDCTL_BIN:-/home/kubeadm/etcd/bin/etcdctl}"

SNAPSHOT_DIR="${SNAPSHOT_DIR:-/home/etcd/snapshot}"
LOG_DIR="${LOG_DIR:-/home/etcd/logs}"
SNAPSHOT_LOG="${SNAPSHOT_LOG:-$LOG_DIR/snapshot.log}"
LOCK_FILE="${LOCK_FILE:-/var/lock/etcd-snapshot.lock}"

ENDPOINT="${ENDPOINT:-https://192.168.56.11:2379}"
CACERT="${CACERT:-/etc/kubernetes/pki/etcd/ca.crt}"
CERT="${CERT:-/etc/kubernetes/pki/etcd/server.crt}"
KEY="${KEY:-/etc/kubernetes/pki/etcd/server.key}"

TS="$(date +'%Y_%m_%d_%H-%M-%S')"
SNAPSHOT_NAME="etcd_snapshot_${TS}"
SNAPSHOT_PATH="${SNAPSHOT_DIR}/${SNAPSHOT_NAME}.db"

# ===== End-Config =====

# ===== Helpers =====
# Escreve mensagens de log mo arquivo e no console.
log() {
  local level="$1"; shift
  local msg="$*"
  local line="[$(date +'%F %T%z')] [$level] $msg"
  echo "$line" | tee -a "$SNAPSHOT_LOG" >&2
}

# Sai do script com uma mensagem de erro e exit code 1
die() {
  log "ERROR" "$*"
  exit 1
}

#Captura erros não tratados/previstos e loga a linha do erro e o exit code
on_err() {
  local exit_code=$?
  log "ERROR" "Falha inesperada (linha ${BASH_LINENO[0]}). Exit code: ${exit_code}"
  exit "$exit_code"
}

# trap captura erros não tratados (sinais) e chama a função on_err
trap on_err ERR

#Verifica se o arquivo existe, caso contrário sai do script com erro
require_file() {
  [[ -f "$1" ]] || die "Arquivo não encontrado: $1"
}

# ===== End-Helpers =====
log "INFO" "Iniciando snapshot do etcd"

# === Validations ===
log "INFO" "Iniciando validação script de snapshot do etcd"
require_file "$ETCDCTL_BIN"
require_file "$CACERT"
require_file "$CERT"
require_file "$KEY"

# Lock para evitar concorrência
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  die "Já existe um backup rodando (lock: $LOCK_FILE)"
fi


# ===== Script =====

log "INFO" "Criando snapshot do etcd: $SNAPSHOT_NAME"

sleep 10 # Simula um processo demorado para teste de concorrência

$ETCDCTL_BIN --endpoints=$ENDPOINT --cacert=$CACERT --cert=$CERT --key=$KEY snapshot save $SNAPSHOT_PATH

status=$($ETCDCTL_BIN snapshot status $SNAPSHOT_PATH -w json 2>/dev/null || true)
if [[ -n "$status" ]]; then

        log "INFO" "Snapshot criado com sucesso: $SNAPSHOT_PATH"
else
        log "INFO" "Falha ao criar snapshot do etcd: $SNAPSHOT_PATH"
fi

log "INFO" "Finalizando snapshot do etcd"


