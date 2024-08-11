# 演習 1

- [演習 1](#演習-1)
  - [Pod](#pod)
  - [Deployment](#deployment)
  - [Service](#service)
  - [Ingress](#ingress)
  - [環境のクリーンアップ](#環境のクリーンアップ)

Kubernetes の基本的なリソースについて理解しましょう。

※ コマンドと出力結果を区別するため、実行コマンドには `$ ` をプレフィックスとして付与します。

[演習環境にアクセス](../ch00_setup/README.md)した後、事前準備として演習用のディレクトリを作成します。

```bash
$ pwd
/root

$ mkdir ch01
$ cd ch01

$ pwd
/root/ch01
```

## Pod

以下のコマンドで Pod のマニフェストファイルを作成します。

```bash
$ cat <<EOF > nginx-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.14.2
    ports:
    - containerPort: 80
EOF

$ ls
nginx-pod.yaml
```

次にマニフェストファイルから Pod を作成します。

```bash
$ kubectl apply -f nginx-pod.yaml
pod/nginx created
```

Pod が正常に作成・起動しているか確認してみます。

```bash
$ kubectl get po
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          72s
```

（コマンド末尾の `po` は `pod` の省略表記です）

出力結果から、nginx という名前の Pod が1つ実行されていることが確認できました。

Pod の状態を見るには `kubectl describe po nginx`、Pod の構成情報を見るには `kubectl get po nginx -o yaml` を実行します。それぞれ出力結果を確認してみてください。

続いて nginx コンテナにアクセスしてみます。このコンテナは現状、クラスタ内からのみアクセス可能な状態になっています。クラスタ外からアクセスするために、今回は `kubectl port-forward` を利用します。

```bash
$ kubectl port-forward pods/nginx 8080:80 &
[1] 2498146
Forwarding from 127.0.0.1:8080 -> 80
```

これで localhost 宛のリクエストをコンテナにフォワーディングすることができるようになりました。`curl` を実行すると nginx からレスポンスが返ってきます。

```bash
$ curl localhost:8080
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

確認が終わったら `kill %1` でフォワーディングプロセスを停止してください。

コンテナのログを見るには `kubectl logs` コマンドを実行します。以下のコマンドを実行すると、先ほど curl を実行した時のログが出力されます。

```bash
$ kubectl logs nginx
127.0.0.1 - - [10/Aug/2024:18:56:35 +0000] "GET / HTTP/1.1" 200 612 "-" "curl/7.81.0" "-"
```

今度はコンテナ内でコマンドを実行してみましょう。これには `kubectl exec` を利用します。

```bash
$ kubectl exec -it nginx -- bash

$ cat /etc/hostname
nginx
```

ホスト名が `nginx` となっており、コンテナ内でコマンドを実行できていることがわかります。
`kubectl exec` はデバック等で重宝する機能ですが、注意点としてコンテナ内に存在しないコマンドは実行できません。

```bash
$ ps
bash: ps: command not found

$ exit
```

最近ではデバッグ用のコマンド `kubectl debug` を利用することもできるので、デバッグ対象のコンテナに機能が足りない場合はこちらを利用すると良いです。

```bash
$ kubectl debug nginx -it --image=busybox
Defaulting debug container name to debugger-t74t4.
If you don't see a command prompt, try pressing enter.

$ cat /etc/hostname
nginx

$ ps
PID   USER     TIME  COMMAND
    1 root      0:00 sh
   14 root      0:00 ps

$ exit
```

## Deployment

Deployment は、Pod の管理を簡単にするための Kubernetes リソースです。Deployment を使用することで、指定した数の Pod が常に動作していることを保証し、Pod の更新やロールバックも容易に行えます。

```bash
$ cat <<EOF > nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
EOF

$ kubectl apply -f nginx-deployment.yaml
deployment.apps/nginx-deployment created

$ kubectl get deploy
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   3/3     3            3           105s

$ kubectl get po,rs -l app=nginx
NAME                                    READY   STATUS    RESTARTS   AGE
pod/nginx-deployment-77d8468669-4ts7w   1/1     Running   0          102s
pod/nginx-deployment-77d8468669-hf9mx   1/1     Running   0          102s
pod/nginx-deployment-77d8468669-wrcgq   1/1     Running   0          102s

NAME                                          DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-deployment-77d8468669   3         3         3       102s
```

`kubectl get` の出力結果の通り、Deployment から1つの ReplicaSet と3つの Pod が作成されています。Deployment は ReplicaSet のバージョンを管理し、ReplicaSet は指定された数の Pod を作成します。

次に Deployment の更新を試みます。nginx コンテナのイメージを `nginx:1.16.1` にアップデートしてみましょう。

```bash
$ kubectl set image deployment.v1.apps/nginx-deployment nginx=nginx:1.16.1

$ kubectl get deploy
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   3/3     3            3           13m

$ kubectl get po,rs -l app=nginx
NAME                                    READY   STATUS    RESTARTS   AGE
pod/nginx-deployment-595dff4fdb-84d4d   1/1     Running   0          15s
pod/nginx-deployment-595dff4fdb-cbzwr   1/1     Running   0          22s
pod/nginx-deployment-595dff4fdb-r5d77   1/1     Running   0          8s

NAME                                          DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-deployment-595dff4fdb   3         3         3       22s
replicaset.apps/nginx-deployment-77d8468669   0         0         0       11m
```

新しい ReplicaSet が作成され、Pod がすべて入れ替わりました。古い方の ReplicaSet は Pod 数が0になっています。

Deployment の状態を確認してみます。

```bash
$ kubectl describe deploy nginx-deployment
Name:                   nginx-deployment
Namespace:              default
CreationTimestamp:      Sat, 10 Aug 2024 19:34:31 +0000
Labels:                 <none>
Annotations:            deployment.kubernetes.io/revision: 2
Selector:               app=nginx
Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=nginx
  Containers:
   nginx:
    Image:         nginx:1.16.1
    Port:          80/TCP
    Host Port:     0/TCP
    Environment:   <none>
    Mounts:        <none>
  Volumes:         <none>
  Node-Selectors:  <none>
  Tolerations:     <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  nginx-deployment-77d8468669 (0/0 replicas created)
NewReplicaSet:   nginx-deployment-595dff4fdb (3/3 replicas created)
Events:
  Type    Reason             Age    From                   Message
  ----    ------             ----   ----                   -------
  Normal  ScalingReplicaSet  15m    deployment-controller  Scaled up replica set nginx-deployment-77d8468669 to 3
  Normal  ScalingReplicaSet  4m47s  deployment-controller  Scaled up replica set nginx-deployment-595dff4fdb to 1
  Normal  ScalingReplicaSet  4m40s  deployment-controller  Scaled down replica set nginx-deployment-77d8468669 to 2 from 3
  Normal  ScalingReplicaSet  4m40s  deployment-controller  Scaled up replica set nginx-deployment-595dff4fdb to 2 from 1
  Normal  ScalingReplicaSet  4m33s  deployment-controller  Scaled down replica set nginx-deployment-77d8468669 to 1 from 2
  Normal  ScalingReplicaSet  4m33s  deployment-controller  Scaled up replica set nginx-deployment-595dff4fdb to 3 from 2
  Normal  ScalingReplicaSet  4m31s  deployment-controller  Scaled down replica set nginx-deployment-77d8468669 to 0 from 1
```

末尾のイベントログを見ると、Pod が1つずつ順番に再作成されていることがわかります。これは `StrategyType` が `RollingUpdate` となっているためです。一度に更新できる Pod 数は `RollingUpdateStrategy` の値により決定されます。

最後に、実行したアップデートを元に戻してみます。

```bash
$ kubectl rollout undo deployment nginx-deployment
deployment.apps/nginx-deployment rolled back

$ kubectl get po,rs -l app=nginx
NAME                                    READY   STATUS    RESTARTS   AGE
pod/nginx-deployment-77d8468669-d2wxh   1/1     Running   0          64s
pod/nginx-deployment-77d8468669-g5gng   1/1     Running   0          62s
pod/nginx-deployment-77d8468669-zxr8s   1/1     Running   0          65s

NAME                                          DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-deployment-595dff4fdb   0         0         0       12m
replicaset.apps/nginx-deployment-77d8468669   3         3         3       23m
```

古い方の ReplicaSet の Pod 数が3つ、新しい方が0に更新されています。

## Service

Service は、Kubernetes クラスタ内で動作する Pod に対するネットワークアクセスを提供するリソースです。Service を使用すると、Pod が再作成された場合でも、安定した IP アドレスを維持できます。

```bash
$ cat <<EOF > nginx-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
EOF

$ kubectl apply -f nginx-service.yaml
service/nginx-service created

$ kubectl get svc
NAME            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
kubernetes      ClusterIP   10.96.0.1      <none>        443/TCP   3d23h
nginx-service   ClusterIP   10.96.101.36   <none>        80/TCP    13s
```

nginx Pod にアクセスするための Service が作成されました。Service はクラスタ内で動作している Pod に安定したアクセスを提供し、負荷分散機能も提供します。外部からアクセスする場合は、`NodePort` または `LoadBalancer` タイプの Service を使用することもできます（デフォルトは `ClusterIP`）。

マニフェストファイルを編集し、`NodePort` タイプの Service を作成してみます。

```bash
$ cat <<EOF > nginx-service-nodeport.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 30007
EOF

$ kubectl apply -f nginx-service-nodeport.yaml
service/nginx-service configured

$ kubectl get svc
NAME            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
kubernetes      ClusterIP   10.96.0.1      <none>        443/TCP        3d23h
nginx-service   NodePort    10.96.101.36   <none>        80:30007/TCP   6m33s
```

Service タイプが `NodePort` になりました。これによりノードのIPアドレス宛のリクエストが Pod に届くようになります。

```bash
$ kubectl get no -o wide
NAME                 STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION   CONTAINER-RUNTIME
kind-control-plane   Ready    control-plane   4d    v1.30.0   172.18.0.2    <none>        Debian GNU/Linux 12 (bookworm)   6.5.0-1020-aws   containerd://1.7.15
kind-worker          Ready    <none>          4d    v1.30.0   172.18.0.3    <none>        Debian GNU/Linux 12 (bookworm)   6.5.0-1020-aws   containerd://1.7.15
kind-worker2         Ready    <none>          4d    v1.30.0   172.18.0.4    <none>        Debian GNU/Linux 12 (bookworm)   6.5.0-1020-aws   containerd://1.7.15
```

ノード情報を見ればノードのIPアドレスがわかるので、このIPアドレス宛にリクエストを送ってみます。

```bash
$ curl 172.18.0.3:30007
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

nginx からレスポンスが返ってきました。3台のノードすべてのIPアドレス宛にリクエストが成功します。

## Ingress

Ingress は、HTTP および HTTPS のリクエストをクラスタ内の Service にルーティングするためのリソースです。Ingress を使用することで、外部からのリクエストを特定の Service に振り分けることができます。

```bash
$ cat <<EOF > nginx-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
spec:
  rules:
  - host: nginx.seccamp.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-service
            port:
              number: 80
EOF

$ kubectl apply -f nginx-ingress.yaml
ingress.networking.k8s.io/nginx-ingress created

$ kubectl get ingress
NAME            CLASS   HOSTS               ADDRESS   PORTS   AGE
nginx-ingress   nginx   nginx.seccamp.com             80      15s
```

Ingress の作成後、`nginx.seccamp.com` にアクセスすると nginx-service にリクエストがルーティングされるようになります。実際にアクセスするには DNS 設定や Ingress コントローラーの設定が必要ですが、演習環境ではどちらも設定済みです。

```bash
$ curl nginx.seccamp.com
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

## 環境のクリーンアップ

演習で作成したリソースを削除します。

（コピペしやすいように `$` は除いています）

```bash
kubectl delete po nginx
kubectl delete deploy nginx-deployment
kubectl delete svc nginx-service
kubectl delete ingress nginx-ingress
```

ここでは取り扱わなかったリソースが多くありますが、Namespace や DaemonSet などのリソースは2章の演習で取り扱います。
