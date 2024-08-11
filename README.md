# クラウドネイティブなシステムを保護するための実践的Kubernetesセキュリティ

[セキュリティ・キャンプ2024 全国大会](https://www.ipa.go.jp/jinzai/security-camp/2024/camp/zenkoku/index.html) B6の講義資料です。

※ 内容は今後アップデートされる可能性があります。

## 目的とゴール

- Kubernetes を好きになってもらう
- プロダクトセキュリティの考え方に触れる

## 学習シナリオ

あなたはサービスチームのセキュリティ担当者として、インフラ基盤となる Kubernetes クラスタのセキュリティ対策を任されることになりました。専任のセキュリティ担当者はあなたが初めてで、これまではクラスタ管理者やアプリ開発者がセキュリティも兼任していましたが、クラスタに対して特別なセキュリティ対策は実施してきませんでした。

一人目のセキュリティ担当者として、Kubernetes クラスタのセキュリティ対策にどのように取り組みますか？

## 対象範囲

本講義は Kubernetes クラスタ、コンテナの実行環境に焦点を当てた内容となっています。CI/CD やコンテナレジストリなどのセキュリティは対象外です。

また講義で紹介するツールはOSSがメインであり、有償ツールは取り扱いません。

## 目次

- [0章: セットアップ](./ch00_setup/README.md)
- [1章: Kubernetes 超入門](./ch01_k8s_intro/README.md)
  - [演習1](./ch01_k8s_intro/training.md)
- [2章: 演習環境の紹介](./ch02_environment/README.md)
  - [演習2](./ch02_environment/training.md)
- [3章: Kubernetes 環境への攻撃](./ch03_attacking_k8s/README.md)
  - [演習3](./ch03_attacking_k8s/training.md)
  - [攻撃シナリオ（デモ）](./ch03_attacking_k8s/attack_scenario.md)
- [4章: Kubernetes 環境のセキュリティ対策](./ch04_hardening_k8s/README.md)
  - [演習4](./ch04_hardening_k8s/training.md)
