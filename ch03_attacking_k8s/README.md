# Kubernetes 環境への攻撃

- [Kubernetes 環境への攻撃](#kubernetes-環境への攻撃)
- [攻撃者から見る Kubernetes](#攻撃者から見る-kubernetes)
  - [豊富なマシンリソース](#豊富なマシンリソース)
  - [アタックサーフェスの多層化](#アタックサーフェスの多層化)
- [脅威事例](#脅威事例)
  - [TeamTNT: Cloud Attack Campaign](#teamtnt-cloud-attack-campaign)
  - [Kinsing Malware](#kinsing-malware)
- [MITRE ATT\&CK Matrix](#mitre-attck-matrix)
  - [Containers Matrix](#containers-matrix)
  - [Kubernetes Matrix](#kubernetes-matrix)
- [具体的な攻撃手法](#具体的な攻撃手法)
  - [クラスタコンポーネントへのアクセス](#クラスタコンポーネントへのアクセス)
    - [匿名アクセス](#匿名アクセス)
    - [正規の認証情報を利用した不正アクセス](#正規の認証情報を利用した不正アクセス)
  - [コンテナブレイクアウト](#コンテナブレイクアウト)
    - [privileged などの安全でない設定](#privileged-などの安全でない設定)
    - [脆弱性の悪用](#脆弱性の悪用)
  - [認証情報の窃取](#認証情報の窃取)
    - [サービスアカウントトークン](#サービスアカウントトークン)
    - [クラウドへの認証情報](#クラウドへの認証情報)
    - [Secret](#secret)
    - [クラスタコンポーネントの使用する認証情報](#クラスタコンポーネントの使用する認証情報)
  - [クラスタリソースの作成・更新](#クラスタリソースの作成更新)
    - [攻撃用コンテナのデプロイ](#攻撃用コンテナのデプロイ)
    - [CSR による認証情報の追加](#csr-による認証情報の追加)
    - [匿名ユーザーへの権限付与](#匿名ユーザーへの権限付与)
- [関連ツール](#関連ツール)
  - [kubesploit](#kubesploit)
  - [pirates](#pirates)
  - [Kubernetes Goat](#kubernetes-goat)
- [OWASP Kubernetes Top 10](#owasp-kubernetes-top-10)

# 攻撃者から見る Kubernetes

## 豊富なマシンリソース

Kubernetes はスケーラブルなアプリケーションを運用するのに利用されるため、攻撃者にとって豊富なマシンリソースが提供される環境と言えます。

クラスタ全体を制御することができれば、計算リソースを悪用して暗号通貨のマイニングや DDoS 攻撃などの不正活動を行うことが可能です。また、クラウド環境で運用されている Kubernetes クラスタでは、クラウドサービスもリソースとして利用できるため、攻撃者にとってより一層魅力的なターゲットとなります。

## アタックサーフェスの多層化

Kubernetes は複数のレイヤで構成されており、これが攻撃者にとって大きな利点となります。従来のアプリケーションやクラウドサービスに加え、コンテナや Kubernetes クラスタ自体が新たな攻撃対象となります。

たとえば、コンテナの脆弱性を突いた攻撃や、Kubernetes API サーバーの不正アクセスなど、さまざまなレイヤで攻撃が可能です。この多層化したアタックサーフェスにより、防御側が全ての層でセキュリティを確保するのが難しく、攻撃者にとって侵入のチャンスが増える結果となります。

# 脅威事例

## TeamTNT: Cloud Attack Campaign

https://blog.aquasec.com/teamtnt-reemerged-with-new-aggressive-cloud-campaign

Docker/Kubernetes を標的としたボットネット感染、情報窃取の攻撃キャンペーン。

## Kinsing Malware

https://techcommunity.microsoft.com/t5/microsoft-defender-for-cloud/initial-access-techniques-in-kubernetes-environments-used-by/ba-p/3697975

コンテナ環境を標的とするクリプトマイナー。

- PHPUnit や WordPress などの脆弱なコンテナイメージを主に悪用。
- また PostgreSQL コンテナの設定ミスを利用し、Kubernetes 環境への初期アクセスを獲得。

# MITRE ATT&CK Matrix

MITRE ATT&CK は、サイバー攻撃の戦術（Tactics）、手法・技術（Techniques）、手順（Procedures）を体系的にまとめたフレームワークです。セキュリティ専門家はこれを利用して攻撃パターンを理解し、防御策を講じます。

TTP は攻撃の具体的な方法を示し、攻撃シミュレーションやセキュリティギャップの特定に用いられる他、インシデント対応時にも有用です。

- **Initial Access（初期アクセス）**
  - 攻撃者が最初にKubernetes環境にアクセスする。
  - 例: 悪意のあるコンテナイメージの使用、公開APIの悪用。
- **Execution（実行）**
  - 攻撃者が悪意のあるコードを実行する。
  - 例: コンテナ内でのシェルアクセス。
- **Persistence（永続化）**
  - 攻撃者がシステムへの永続的なアクセスを確保する。
  - 例: CronJob の悪用。
- **Privilege Escalation（権限昇格）**
  - 攻撃者がより高い権限を取得する。
  - 例: 不正なサービスアカウントの使用。
- **Defense Evasion（防御回避）**
  - 攻撃者が検出を回避する。
  - 例: ログの削除、監視ツールの無効化。
- **Credential Access（認証情報アクセス）**
  - 攻撃者が認証情報を取得する。
  - 例: Secret の取得、コンテナやVM内の認証情報取得。
- **Discovery（探索）**
  - 攻撃者が環境内のリソースを特定する。
  - 例: API サーバーへのリクエスト、ネットワークスキャン。
- **Lateral Movement（横展開）**
  - 攻撃者がシステム内で影響範囲を拡大する。
  - 例: 他の Pod へのアクセス、ノード間移動。
- **Collection（収集）**
  - 攻撃者がデータを収集する。
  - 例: コンテナ内のデータ盗難。
- **Exfiltration（データ漏洩）**
  - 攻撃者が収集したデータを外部に送信する。
  - 例: 外部サーバーへのデータ送信。
- **Impact（影響）**
  - 攻撃者がシステムに与える影響。
  - 例: データの削除、サービスの停止。

## Containers Matrix

https://attack.mitre.org/matrices/enterprise/containers/

## Kubernetes Matrix

https://www.microsoft.com/en-us/security/blog/2020/04/02/attack-matrix-kubernetes/

![k8s-matrix](https://www.microsoft.com/en-us/security/blog/wp-content/uploads/2020/04/k8s-matrix.png)

# 具体的な攻撃手法

## クラスタコンポーネントへのアクセス

クラスタコンポーネントは、ユーザーからのリクエスト受信やコンポーネント間の通信のために特定ポートで外部公開されています。
コンポーネントの公開範囲や設定に不備があると、外部やクラスタ内からコンポーネントにアクセスできる可能性があります。

![hack-k8s-arch](https://cloud.hacktricks.xyz/~gitbook/image?url=https%3A%2F%2Fsickrov.github.io%2Fmedia%2FScreenshot-68.jpg&width=768&dpr=2&quality=100&sign=4902871c&sv=1)

- コントロールプレーン

| Protocol | Direction | Port Range | Purpose                    | Used By               |
|----------|-----------|------------|----------------------------|-----------------------|
| TCP      | Inbound   | 6443       | Kubernetes API server      | All                   |
| TCP      | Inbound   | 2379-2380  | etcd server client API      | kube-apiserver, etcd  |
| TCP      | Inbound   | 10250      | Kubelet API                | Self, Control plane   |
| TCP      | Inbound   | 10259      | kube-scheduler             | Self                  |
| TCP      | Inbound   | 10257      | kube-controller-manager    | Self                  |

- ワーカーノード

| Protocol | Direction | Port Range    | Purpose            | Used By               |
|----------|-----------|---------------|--------------------|-----------------------|
| TCP      | Inbound   | 10250         | Kubelet API        | Self, Control plane   |
| TCP      | Inbound   | 10256         | kube-proxy         | Self, Load balancers  |
| TCP      | Inbound   | 30000-32767   | NodePort Services | All                   |


https://kubernetes.io/docs/reference/networking/ports-and-protocols/

### 匿名アクセス

kube-apiserver や kubelet には認証なしのアクセスを許可するオプション (`--anonymous-auth`) があります。これが有効になっている場合、クラスタへの認証情報を持たない攻撃者がクラスタにアクセスできる可能性があります。
認証が設定されていない API サーバーは、攻撃者にとっての侵入口となり得ます。

匿名アクセスは `system:anonymous` ユーザーとなり、この匿名ユーザーに RoleBinding を設定している場合はクラスタリソースへのアクセスが可能になります。

kube-apiserver は公開範囲を制限することが望ましいですが、実際にはインターネットに公開されているサーバーが多数発見されます。

https://search.censys.io/search?resource=hosts&sort=RELEVANCE&per_page=25&virtual_hosts=EXCLUDE&q=services.service_name%3D%60KUBERNETES%60

### 正規の認証情報を利用した不正アクセス

攻撃者が正規のユーザーやサービスアカウントの認証情報を盗み取ることで、認証されたアクセスを装い、クラスタ内で不正な操作を行います。この手法では、攻撃者は通常のユーザーと同様にリソースへアクセスできるため、不正な活動が検出されにくくなります。

## コンテナブレイクアウト

コンテナ内に侵入した攻撃者は、権限昇格のためにコンテナプロセスからホストシステム（＝ノード）への脱出（コンテナブレイクアウト）を試みます。ホストの root 権限を取得できれば、ホスト上で実行されているすべてのコンテナにアクセスでき、ホスト上に配置されているさまざまなファイルを閲覧・更新できます。

### privileged などの安全でない設定

コンテナが「privileged」モードで実行されている、「hostPath」ボリュームが不適切に設定されているなど、コンテナや Pod に安全でない設定がされていると容易にコンテナブレイクアウトを達成できます。

### 脆弱性の悪用

コンテナランタイムや Linux の脆弱性を悪用して、コンテナからホストに脱出できる場合があります。コンテナブレイクアウトの脆弱性はこれまでに複数見つかっています。

- cgroup v1 の脆弱性 ([CVE-2022-0492](https://nvd.nist.gov/vuln/detail/CVE-2022-0492))
- CRI-O の脆弱性 ([CVE-2022-0811](https://nvd.nist.gov/vuln/detail/CVE-2022-0811))
- runc の脆弱性 ([CVE-2024-21626](https://nvd.nist.gov/vuln/detail/CVE-2024-21626))

## 認証情報の窃取

攻撃者は侵入したコンテナやノード、クラスタ内でさまざまな方法を使って認証情報を窃取します。

### サービスアカウントトークン

Kubernetes のサービスアカウントトークンを盗むことで、攻撃者はそのトークンを使用してリソースへの不正アクセスを行います。アクセス可能な範囲はサービスアカウントに紐づけられている権限に依存します。

### クラウドへの認証情報

クラウドサービスとの連携に使用される認証情報が窃取されると、攻撃者はクラウド環境への不正アクセスを試み、クラウドリソースの悪用や破壊を行います。

### Secret

Kubernetes の Secret リソースに格納されたパスワードやAPIキーなどの機密情報が盗まれると、攻撃者はこれらの情報を利用して、さらなるシステム侵入やデータの不正取得を試みます。

### クラスタコンポーネントの使用する認証情報

API サーバーなどのクラスタコンポーネントで使用される認証情報は、それぞれのノード上に配置されています。ノードに侵入した攻撃者は、この権限を使ってクラスタリソースの操作やコンポーネントへの不正アクセスを行います。

## クラスタリソースの作成・更新

### 攻撃用コンテナのデプロイ

攻撃者は、クラスタ内に探索ツールやクリプトマイナーやボットネットなどのコンテナをデプロイし、リソースを不正に利用します。このようなコンテナはクラスタの計算リソースを消費し、他のコンテナやアプリケーションのパフォーマンスを低下させる可能性があります。

### CSR による認証情報の追加

証明書署名リクエスト（CSR）から新しい認証情報を作成することで、クラスタへのアクセスを永続化させます。これにより攻撃者はクラスタ管理者の監視をすり抜けながら、不正アクセスを続けることが可能です。

### 匿名ユーザーへの権限付与

攻撃者は匿名ユーザー (`system:anonymous`) に対して権限を付与することで、クラスタへのアクセスを永続化させます。匿名ユーザーのアクセスにはクラスタコンポーネントのオプション設定 (`--anonymous-auth`) が必要です。

# 関連ツール

## kubesploit

https://github.com/cyberark/kubesploit

コンテナ化された環境、特に Kubernetes クラスタに特化したポストエクスプロイトツールです。kubesploit は Kubernetes 環境内でのリアルな攻撃シミュレーションを可能にし、特権昇格や脆弱性の悪用、ネットワークスキャンなど、さまざまなモジュールを提供します。特にRed Teamやペネトレーションテストにおいて、コンテナ化された環境のセキュリティを評価し、改善するために重要な役割を果たします

- **Kubernetes APIの脆弱性探索**: API サーバーに対する不正アクセスや脆弱性を探索し、クラスタ全体に影響を及ぼすリスクを評価します。
- **Podの権限昇格**: 特権を持たない Pod からの権限昇格をシミュレーションし、コンテナ間での攻撃の可能性を検証します。
- **ネットワークスキャン**: クラスタ内外のネットワークをスキャンし、公開されているサービスやポートのリスクを特定します。

## pirates

https://github.com/inguardians/peirates

Kubernetes クラスタに対する特権昇格や横展開を目的としたペネトレーションテストツールです。主に Kubernetes 環境内での攻撃者の動きをシミュレートするために使用されます。

- **特権昇格**: サービスアカウントトークンの取得やホストパスを利用したノードシェルの獲得を行います。
- **横展開**: 別の Pod への移動や、クラウドのIAM資格情報の取得を行います。

## Kubernetes Goat

https://github.com/madhuakula/kubernetes-goat

Kubernetes のやられ環境を構築し攻撃手法を学習するためのツールです。セキュリティの学習やトレーニングに特化した環境を提供し、Kubernetes に対する様々な攻撃手法を実際に体験することができます。

- **やられ環境の構築**: セキュリティのトレーニングや学習のために、意図的に脆弱性を持たせた Kubernetes 環境を構築します。
- **攻撃手法の学習**: 現実的なシナリオを通じて、Kubernetes に対する攻撃手法や防御策を実践的に学ぶことができます。
- **シナリオベースのトレーニング**: 実際のセキュリティインシデントを模したシナリオを使用し、実践的なスキルを磨くことが可能です。

![kubernetes-goat](https://github.com/madhuakula/kubernetes-goat/raw/master/kubernetes-goat-home.png)

# OWASP Kubernetes Top 10

https://owasp.org/www-project-kubernetes-top-ten/

Kubenretes 環境の主要なリスクをまとめたもの。

- K01: Insecure Workload Configurations（安全でないワークロードの設定）
- K02: Supply Chain Vulnerabilities（サプライチェーンにおける脆弱性）
- K03: Overly Permissive RBAC Configurations（過剰なRBACの権限設定）
- K04: Lack of Centralized Policy Enforcement（一元化されたポリシー適用の欠如）
- K05: Inadequate Logging and Monitoring（不十分なロギングと監視）
- K06: Broken Authentication Mechanisms（認証メカニズムの欠陥）
- K07: Missing Network Segmentation Controls（ネットワーク分離の欠如）
- K08: Secrets Management Failures（シークレット管理の失敗）
- K09: Misconfigured Cluster Components（クラスタコンポーネントの設定ミス）
- K10: Outdated and Vulnerable Kubernetes Components（古く脆弱なk8sコンポーネント）

---

[演習3](./training.md)

[攻撃シナリオ（デモ）](./attack_scenario.md)

[4章: Kubernetes 環境のセキュリティ対策](../ch04_hardening_k8s/README.md)

