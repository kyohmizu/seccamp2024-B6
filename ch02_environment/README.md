# 演習環境の紹介

- [演習環境の紹介](#演習環境の紹介)
- [構成情報](#構成情報)
  - [クライアント環境](#クライアント環境)
  - [Kubernetes サーバー環境](#kubernetes-サーバー環境)
- [サーバー環境詳細](#サーバー環境詳細)
  - [kind](#kind)
  - [Unguard](#unguard)
  - [Ingress-Nginx Controller](#ingress-nginx-controller)
  - [Cilium](#cilium)
  - [Hubble](#hubble)


本演習では、一つの EC2 上にクライアントとサーバー環境が混在しています。操作しているのがクライアント側なのか、サーバー側なのかを意識しておくと理解しやすいでしょう。

- Kubernetes 管理者のクライアント環境
- Kubernetes サーバー環境
- （攻撃者のサーバー環境）

# 構成情報

## クライアント環境

- [docker](https://docs.docker.com/engine/reference/commandline/cli/)
- [kubectl](https://kubernetes.io/docs/reference/kubectl/)
- [krew](https://github.com/kubernetes-sigs/krew)
- [helm](https://github.com/helm/helm)
- [helm-diff](https://github.com/databus23/helm-diff)
- [helmfile](https://github.com/helmfile/helmfile)
- [trivy](https://github.com/aquasecurity/trivy)

## Kubernetes サーバー環境

- Kubernetes クラスタ
  - kind
- ミドルウェア&アプリケーション
  - Ingress-Nginx Controller
  - Unguard
  - Cilium CNI
  - Hubble
- セキュリティ（後述）
  - Tetragon
  - Kubeclarity
  - Inspektor Gadget

# サーバー環境詳細

## kind

https://kind.sigs.k8s.io/

Docker コンテナをノードに見立て、ローカルのKubernetesクラスタを実行するためのツール。ローカルで開発環境を用意したり、Kubernetes 自体の検証をしたりするのに使用されます。

![kind](https://kind.sigs.k8s.io/docs/images/diagram.png)

演習環境の kind クラスタはコントロールプレーン1台、ワーカーノード2台で構成されています。
（[設定ファイル](../ch00_setup/k8s/kind/kind-config.yaml)）

仕組みとしては、kind はノードとなるコンテナ内で [kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/) というツールを利用してクラスタを構築します。

## Unguard

https://github.com/dynatrace-oss/unguard

マイクロサービスで構成された脆弱なデモアプリケーション。Twitter風のSNSサービスとしてユーザー登録/ログイン、投稿（テキスト、URL、画像）、ユーザーフォローの機能を備えています。

![unguard-timeline](https://github.com/dynatrace-oss/unguard/raw/main/docs/images/unguard-timeline.png)

以下の図のように、Unguard は異なる言語で書かれた8つのマイクロサービスで構成され、RESTを介して相互に通信する。

![unguard-arch](https://github.com/dynatrace-oss/unguard/raw/main/docs/images/unguard-architecture.svg)

本演習では一部の機能、脆弱性にしか着目しませんが、興味がありましたらご自身で色々と試してみてください。

## Ingress-Nginx Controller

https://github.com/kubernetes/ingress-nginx

NGINX をロードバランサとして使用する Ingress コントローラ。

## Cilium

https://github.com/cilium/cilium

Linux カーネルの eBPF 技術を利用したネットワークプラグインで、Kubernetes クラスタに高度なネットワークセキュリティ機能を提供します。Cilium を使用することで、ネットワークポリシーの実装、サービスメッシュのサポート、トラフィックの可視化などを実現できます。

演習環境では、kube-proxy の代わりに Clium を CNI として使用しています。

![cilium](https://github.com/cilium/cilium/raw/main/Documentation/images/cilium-overview.png)

## Hubble

https://github.com/cilium/hubble

Cilium と eBPF の上に構築される、分散型のネットワーキングおよびセキュリティ可観測性ツール。Hubble を使用することで、Kubernetes クラスタ内のネットワークトラフィックをリアルタイムで監視し、トラブルシューティングやセキュリティ監査を行うことができます。

![hubble-arch](https://github.com/cilium/hubble/raw/main/Documentation/images/hubble_arch.png)

演習環境には Hubble UI がデプロイされており、サービスの依存関係を視覚的に確認することができます。

![hubble-service-map](https://github.com/cilium/hubble/raw/main/Documentation/images/servicemap.png)

---

[演習2](./training.md)

[3章: Kubernetes 環境のへの攻撃](../ch03_attacking_k8s/README.md)
