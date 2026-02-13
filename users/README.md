### Criar usuários

> Criar usuários e exportar seu kubeconfig par acesso ao cluster via RBAC

- Gere as chaves com opnssl

```shell
  USERNAME=outro
  GROUP=cluster-wide-viewer
  CLUSTER_IP_ADDRESS=https://192.168.56.11:6443
  CLUSTER_CONTEXT=outro
  CLUSTER_NAME=outro

  echo $USERNAME
  echo $GROUP
  echo $CLUSTER_IP_ADDRESS
  echo $CLUSTER_CONTEXT
  echo $CLUSTER_NAME

  openssl genrsa -out $USERNAME.pem
  openssl req -new -key $USERNAME.pem -out $USERNAME.csr -subj "/CN=$USERNAME /O=$GROUP"
  BASE64_CSR=$(cat $USERNAME.csr | base64 | tr -d "\n")
```

- Crie a SigningRequest

```shell
cat > cert-sign-request.yaml <<'EOF'
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: <user>-csr
spec:
  request: <cert-base64>
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages:
  - digital signature
  - key encipherment
  - client auth
EOF

sed -i "s/<user>/${USERNAME}/g" cert-sign-request.yaml
sed -i "s/<cert-base64>/${BASE64_CSR}/g" cert-sign-request.yaml
```

- após criado aprove a request

```shell
kubectl apply -f cert-sign-request.yaml
kubectl certificate approve $USERNAME-csr
```

- Extraia o certificado aprovado para criar o kubeconfig

```shell
kubectl get csr/$USERNAME-csr -o jsonpath="{.status.certificate}" | base64 -d > $USERNAME.crt
```

- Cria o kubeconfig para o usuário

```shell
kubectl --kubeconfig ~/.kube/config-$USERNAME config set-cluster $CLUSTER_NAME --insecure-skip-tls-verify=true --server=${CLUSTER_IP_ADDRESS}
kubectl --kubeconfig ~/.kube/config-$USERNAME config set-credentials $USERNAME --client-certificate=${USERNAME}.crt --client-key=${USERNAME}.pem --embed-certs=true
kubectl --kubeconfig ~/.kube/config-$USERNAME config set-context $CLUSTER_CONTEXT --cluster=${CLUSTER_NAME} --user=${USERNAME}
kubectl --kubeconfig ~/.kube/config-$USERNAME config use-context $CLUSTER_CONTEXT
kubectl --kubeconfig ~/.kube/config-$USERNAME get pods
```
