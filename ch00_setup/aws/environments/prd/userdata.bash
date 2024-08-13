#!/bin/bash

#-----------------------------
# settings
#-----------------------------

# https://kind.sigs.k8s.io/docs/user/known-issues/#pod-errors-due-to-too-many-open-files
cat << EOF | tee /etc/sysctl.conf >/dev/null
fs.inotify.max_user_watches = 1048576
fs.inotify.max_user_instances = 1024
EOF
sysctl -p

export HOME=/root
export KUBECONFIG=/root/.kube/config

mkdir -p /root/logs
mkdir -p /root/attack

cat << EOF | sudo tee -a /etc/hosts >/dev/null
127.0.0.1 unguard.kube
127.0.0.1 nginx.seccamp.com
127.0.0.1 hubble.seccamp.com
127.0.0.1 kubeclarity.seccamp.com
EOF

#-----------------------------
# components
#-----------------------------

apt update
apt upgrade -y

# docker
# https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
apt install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# kubectl
# https://medium.com/@saeidlaalkaei/installing-kubectl-on-amazon-linux-2-machine-fc82a3e6b7c8
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# kind
# https://kind.sigs.k8s.io/docs/user/quick-start/
# For AMD64 / x86_64
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
# For ARM64
[ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-arm64
chmod +x ./kind
mv ./kind /usr/local/bin/kind

# helm
# https://ap-northeast-1.console.aws.amazon.com/systems-manager/session-manager/i-066a4abd1ab950454?region=ap-northeast-1#:
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# helm-diff
helm plugin install https://github.com/databus23/helm-diff

# helmfile
HELMFILE_VERSION="0.156.0"
wget "https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_$(echo ${HELMFILE_VERSION})_linux_amd64.tar.gz"
tar -zxvf "helmfile_$(echo ${HELMFILE_VERSION})_linux_amd64.tar.gz"
mv helmfile /usr/local/bin/helmfile
rm "helmfile_$(echo ${HELMFILE_VERSION})_linux_amd64.tar.gz"

# trivy
# https://aquasecurity.github.io/trivy/v0.54/getting-started/installation/
apt install -y apt-transport-https gnupg
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | tee -a /etc/apt/sources.list.d/trivy.list
apt update
apt install -y trivy

# krew
# https://krew.sigs.k8s.io/docs/user-guide/setup/install/
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

kubectl krew install neat
kubectl krew install view-secret
kubectl krew install who-can
kubectl krew install gadget

# curlshell
curl https://raw.githubusercontent.com/irsl/curlshell/main/curlshell.py > /root/attack/curlshell.py
chmod +x /root/attack/curlshell.py

#-----------------------------
# bashrc
#-----------------------------

# https://kubernetes.io/docs/reference/kubectl/generated/kubectl_completion/
echo 'source <(kubectl completion bash)' >> /root/.bashrc
echo 'alias k=kubectl' >> /root/.bashrc

echo 'complete -o default -F __start_kubectl k' >> /root/.bashrc

echo 'source <(kind completion bash)' >> /root/.bashrc

echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> /root/.bashrc

#-----------------------------
# kind config
#-----------------------------

mkdir -p /root/kind

# kind-config.yaml
cat <<EOF > /root/kind/kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  - |
    kind: ClusterConfiguration
    apiServer:
        # enable auditing flags on the API server
        extraArgs:
          audit-log-path: /var/log/kubernetes/kube-apiserver-audit.log
          audit-policy-file: /etc/kubernetes/policies/audit-policy.yaml
        # mount new files / directories on the control plane
        extraVolumes:
          - name: audit-policies
            hostPath: /etc/kubernetes/policies
            mountPath: /etc/kubernetes/policies
            readOnly: true
            pathType: "DirectoryOrCreate"
          - name: "audit-logs"
            hostPath: "/var/log/kubernetes"
            mountPath: "/var/log/kubernetes"
            readOnly: false
            pathType: DirectoryOrCreate
  extraMounts:
  - hostPath: /proc
    containerPath: /procHost
  - hostPath: /root/kind/audit-policy.yaml
    containerPath: /etc/kubernetes/policies/audit-policy.yaml
    readOnly: true
  extraPortMappings:
  # ingress port for nginx
  - containerPort: 30080
    hostPort: 80
    listenAddress: "0.0.0.0"
    protocol: TCP
  - containerPort: 30443
    hostPort: 443
    listenAddress: "0.0.0.0"
    protocol: TCP
- role: worker
  extraMounts:
  - hostPath: /proc
    containerPath: /procHost
- role: worker
  extraMounts:
  - hostPath: /proc
    containerPath: /procHost
networking:
  disableDefaultCNI: true
  kubeProxyMode: none
EOF

cat <<EOF > /root/kind/audit-policy.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
EOF

#-----------------------------
# helm releases
#-----------------------------

mkdir -p /root/helm/values
cat <<EOF > /root/helm/helmfile.yaml
repositories:
- name: cilium
  url: https://helm.cilium.io
- name: ingress-nginx
  url: https://kubernetes.github.io/ingress-nginx
- name: bitnami
  url: https://charts.bitnami.com/bitnami
- name: kubeclarity
  url: https://openclarity.github.io/kubeclarity

releases:
- name: cilium
  namespace: kube-system
  chart: cilium/cilium
  version: 1.15.4
  values:
  - values/cilium.values.yaml
- name: ingress-nginx
  namespace: ingress-nginx
  createNamespace: true
  chart: ingress-nginx/ingress-nginx
  version: 4.10.1
  values:
  - values/ingress-nginx.values.yaml
  needs:
  - kube-system/cilium
- name: unguard-mariadb
  namespace: unguard
  createNamespace: true
  chart: bitnami/mariadb
  version: 11.5.7
  values:
  - values/unguard-mariadb.values.yaml
  needs:
  - kube-system/cilium
- name: unguard
  namespace: unguard
  createNamespace: true
  chart: oci://ghcr.io/dynatrace-oss/unguard/chart/unguard
  version: 0.9.3
  values:
  - values/unguard.values.yaml
  needs:
  - kube-system/cilium
  - unguard/unguard-mariadb
  - ingress-nginx/ingress-nginx
- name: tetragon
  namespace: kube-system
  chart: cilium/tetragon
  version: 1.1.2
  values:
  - values/tetragon.values.yaml
  needs:
  - kube-system/cilium
- name: kubeclarity
  namespace: kubeclarity
  createNamespace: true
  chart: kubeclarity/kubeclarity
  version: 2.23.3
  values:
  - values/kubeclarity.values.yaml
  needs:
  - kube-system/cilium
EOF

cat <<EOF > /root/helm/values/cilium.values.yaml
# see: https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/#kubernetes-without-kube-proxy
kubeProxyReplacement: true
k8sServiceHost: kind-control-plane
k8sServicePort: 6443
# ensure pods roll when configmap updates
rollOutCiliumPods: true
# see: https://docs.cilium.io/en/latest/observability/visibility/#layer-7-protocol-visibility
endpointStatus:
  enabled: true
  status: policy
gatewayAPI:
  enabled: false
ingressController:
  enabled: false
operator:
  # ensure pods roll when configmap updates
  rollOutPods: true
  prometheus:
    enabled: true
prometheus:
  enabled: true
hubble:
  enabled: true
  relay:
    enabled: true
  ui:
    enabled: true
    # Visualization of l7 protocols
    podAnnotations:
      policy.cilium.io/proxy-visibility: "<Ingress/8081/TCP/HTTP>"
  metrics:
    enableOpenMetrics: true
    enabled:
    - dns
    - drop
    - tcp
    - flow
    - port-distribution
    - icmp
    - httpV2:exemplars=true;labelsContext=source_ip,source_namespace,source_workload,destination_ip,destination_namespace,destination_workload,traffic_direction
socketLB:
  hostNamespaceOnly: true
cni:
  exclusive: false
EOF

cat <<EOF > /root/helm/values/ingress-nginx.values.yaml
controller:
  metrics:
    enabled: true
  nodeSelector:
    kubernetes.io/hostname: kind-control-plane
  tolerations:
  - effect: NoSchedule
    key: node-role.kubernetes.io/control-plane
    operator: Exists
  ingressClassResource:
    default: true
  admissionWebhooks:
    enabled: false
  service:
    type: NodePort
    ports:
      http: 80
      https: 443
    nodePorts:
      http: 30080
      https: 30443
    targetPorts:
      http: http
      https: https
EOF

cat <<EOF > /root/helm/values/unguard-mariadb.values.yaml
primary:
  persistence:
    enabled: false
# https://github.com/bitnami/charts/issues/15093
auth:
  rootPassword: mysuperpass
  password: mysuperpass
EOF

cat <<EOF > /root/helm/values/unguard.values.yaml
userSimulator:
  cronJob:
    schedule: "*/30 * * * *"
    jobTemplate:
      restartPolicy: Never
EOF

cat <<EOF > /root/helm/values/tetragon.values.yaml
tetragon:
  hostProcPath: "/procHost"
EOF

cat <<EOF > /root/helm/values/kubeclarity.values.yaml
kubeclarity:
  ingress:
    enabled: true
    hosts:
      - host: kubeclarity.seccamp.com
EOF

#-----------------------------
# manifests
#-----------------------------

mkdir -p /root/app
cat <<EOF > /root/app/hubble-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hubble-ingress
  namespace: kube-system
spec:
  rules:
  - host: hubble.seccamp.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: hubble-ui
            port:
              number: 80
EOF

#-----------------------------
# exec
#-----------------------------

kind create cluster --config /root/kind/kind-config.yaml > /root/logs/kind-create.log 2>&1
mkdir -p /root/.kube
kind get kubeconfig > /root/.kube/config
chmod 600 /root/.kube/config

helmfile sync -f /root/helm/helmfile.yaml > /root/logs/helmfile-sync.log 2>&1

kubectl apply -f /root/app/hubble-ingress.yaml > /root/logs/hubble-ingress.log 2>&1

kubectl gadget deploy > /root/logs/gadget-deploy.log 2>&1

touch /root/logs/finished
