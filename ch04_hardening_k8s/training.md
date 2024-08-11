# 演習 4-1

- [演習 4-1](#演習-4-1)
  - [監査ログの確認](#監査ログの確認)
  - [Security Context の設定](#security-context-の設定)
  - [seccomp の設定](#seccomp-の設定)
  - [環境のクリーンアップ](#環境のクリーンアップ)
- [演習 4-2](#演習-4-2)
  - [クラスタのセキュリティスキャン (Trivy)](#クラスタのセキュリティスキャン-trivy)
  - [脆弱性管理 (KubeClarity)](#脆弱性管理-kubeclarity)
  - [コンテナのプロセス監視 (Tetragon)](#コンテナのプロセス監視-tetragon)

Kubernetes のセキュリティベストプラクティスを体験してみましょう。

※ コマンドと出力結果を区別するため、実行コマンドには `$ ` をプレフィックスとして付与します。

[演習環境にアクセス](../ch00_setup/README.md)した後、事前準備として演習用のディレクトリを作成します。

```bash
$ pwd
/root

$ mkdir ch04
$ cd ch04

$ pwd
/root/ch04
```

## 監査ログの確認

大量に出力されるので注意。

```bash
$ docker exec kind-control-plane cat /var/log/kubernetes/kube-apiserver-audit.log
{"kind":"Event","apiVersion":"audit.k8s.io/v1","level":"Metadata","auditID":"4cf311a0-6a75-4364-9d15-5ff65ca99fc4","stage":"RequestReceived","requestURI":"/api/v1/namespaces/default/events","verb":"create","user":{"username":"system:node:kind-control-plane","groups":["system:nodes","system:authenticated"]},"sourceIPs":["172.18.0.2"],"userAgent":"kubelet/v1.30.0 (linux/amd64) kubernetes/7c48c2b","objectRef":{"resource":"events","namespace":"default","apiVersion":"v1"},"requestReceivedTimestamp":"2024-08-11T15:04:42.938588Z","stageTimestamp":"2024-08-11T15:04:42.938588Z"}
{"kind":"Event","apiVersion":"audit.k8s.io/v1","level":"Metadata","auditID":"21d49901-fda4-458f-973c-c582a59f8b6f","stage":"RequestReceived","requestURI":"/apis/storage.k8s.io/v1/csinodes/kind-control-plane?resourceVersion=0","verb":"get","user":{"username":"system:node:kind-control-plane","groups":["system:nodes","system:authenticated"]},"sourceIPs":["172.18.0.2"],"userAgent":"kubelet/v1.30.0 (linux/amd64) kubernetes/7c48c2b","objectRef":{"resource":"csinodes","name":"kind-control-plane","apiGroup":"storage.k8s.io","apiVersion":"v1"},"requestReceivedTimestamp":"2024-08-11T15:04:42.940142Z","stageTimestamp":"2024-08-11T15:04:42.940142Z"}
{"kind":"Event","apiVersion":"audit.k8s.io/v1","level":"Metadata","auditID":"21d49901-fda4-458f-973c-c582a59f8b6f","stage":"ResponseComplete","requestURI":"/apis/storage.k8s.io/v1/csinodes/kind-control-plane?resourceVersion=0","verb":"get","user":{"username":"system:node:kind-control-plane","groups":["system:nodes","system:authenticated"]},"sourceIPs":["172.18.0.2"],"userAgent":"kubelet/v1.30.0 (linux/amd64) kubernetes/7c48c2b","objectRef":{"resource":"csinodes","name":"kind-control-plane","apiGroup":"storage.k8s.io","apiVersion":"v1"},"responseStatus":{"metadata":{},"status":"Failure","message":"csinodes.storage.k8s.io \"kind-control-plane\" not found","reason":"NotFound","details":{"name":"kind-control-plane","group":"storage.k8s.io","kind":"csinodes"},"code":404},"requestReceivedTimestamp":"2024-08-11T15:04:42.940142Z","stageTimestamp":"2024-08-11T15:04:42.940847Z","annotations":{"authorization.k8s.io/decision":"allow","authorization.k8s.io/reason":""}}
...
```

## Security Context の設定

```bash
$ cat <<EOF > nginx-securit-context.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-securit-context
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    runAsNonRoot: true
  containers:
  - name: nginx
    image: nginx
    command: [ "sleep", "infinity" ]
    securityContext:
      readOnlyRootFilesystem: true
      allowPrivilegeEscalation: false
      capabilities:
        add: ["NET_ADMIN", "SYS_TIME"]
        drop: ["ALL"]
EOF
```

## seccomp の設定

```bash
$ cat <<EOF > nginx-seccomp.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-seccomp
spec:
  hostPID: true
  containers:
  - name: nginx
    image: nginx
    command: [ "sleep", "infinity" ]
    securityContext:
      seccompProfile:
        type: RuntimeDefault
EOF
```

## 環境のクリーンアップ

演習で作成したリソースを削除します。

（コピペしやすいように `$` は除いています）

```bash
kubectl delete -f nginx-securit-context.yaml
kubectl delete -f nginx-seccomp.yaml
```

# 演習 4-2

ツールを使用したセキュリティ運用を体験してみましょう。

## クラスタのセキュリティスキャン (Trivy)

```bash
trivy k8s --compliance=k8s-pss-baseline-0.1 --report all --timeout 30m --debug --tolerations node-role.kubernetes.io/control-plane=:NoSchedule -o trivy-result-pss.txt

trivy k8s --scanners misconfig --misconfig-scanners dockerfile,helm,kubernetes --report all --timeout 30m --debug --tolerations node-role.kubernetes.io/control-plane=:NoSchedule -o trivy-result-misconfig.txt
```

## 脆弱性管理 (KubeClarity)

KubeClarity は演習環境のクラスタにデプロイ済みで、Ingress を使ってクラスタ外に公開されています。

```bash
$ kubectl get ingress -n kubeclarity
NAME                      CLASS   HOSTS                     ADDRESS         PORTS   AGE
kubeclarity-kubeclarity   nginx   kubeclarity.seccamp.com   10.96.200.169   80      3d20h
```

KubeClarity の UI にアクセスするため、[セットアップ手順](../ch00_setup/README.md)の通りにローカル環境からポートフォワードを実行します。

ポートフォワードに成功すると、ローカル環境のブラウザから `kubeclarity.seccamp.com:8081` でアクセスできます。

## コンテナのプロセス監視 (Tetragon)

Tetragon は演習環境のクラスタにデプロイ済みです。まずは状態を確認してみましょう。

```bash
$ kubectl get all -n kube-system | grep tetragon
pod/tetragon-7pgpm                               2/2     Running   1 (3d20h ago)   3d20h
pod/tetragon-fxdcz                               2/2     Running   1 (3d20h ago)   3d20h
pod/tetragon-ltjjn                               2/2     Running   1 (3d20h ago)   3d20h
pod/tetragon-operator-84bb9bc55c-hrscz           1/1     Running   0               3d20h
service/tetragon                    ClusterIP   10.96.141.87    <none>        2112/TCP                 3d20h
service/tetragon-operator-metrics   ClusterIP   10.96.86.14     <none>        2113/TCP                 3d20h
daemonset.apps/tetragon   3         3         3       3            3           <none>                   3d20h
deployment.apps/tetragon-operator   1/1     1            1           3d20h
replicaset.apps/tetragon-operator-84bb9bc55c   1         1         1       3d20h
```
