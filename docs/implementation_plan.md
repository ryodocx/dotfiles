# クロスプラットフォーム dotfiles 環境構築 — 実装計画

> [!TIP]
> ユーザーフィードバックを反映した改訂版。ハイブリッド構成（Nix + chezmoi）で**実用しながら比較・段階移行**する方針。
> 秘密情報は、マシンの外部へ持ち出し不可能な **TPM / Secure Enclave ハードウェアバインド**（FIDO2 セキュリティキー）および **chezmoi ローカル変数**で管理する設計。

---

## ユーザー情報

| 項目 | 値 |
|------|-----|
| GitHub | **ryodocx** |
| Git 名前 | **ryodocx** |
| Git メール | **your-email@example.com** |
| OS | macOS, Linux, Windows (WSL) |
| 秘密情報管理 | **TPM / Secure Enclave バインド**（SaaS非依存・外部持出不可） |

---

## 採用プラン: ハイブリッド（Nix パッケージ + chezmoi コンフィグ）

> **「迷っているなら両方使いながら比較する」** という方針を採用。
> 実用しながら Nix の世界を体験し、将来の完全移行を判断できる構成。

### 設計思想と責務の厳格な分離 (Separation of Concerns)

ハイブリッド構成の最大の罠である「Nix と chezmoi で設定ファイルが競合する問題」を防ぐため、両者の責務を以下のように厳格に分離します。

```text
┌─────────────────────────────────────────────────────────┐
│                    Git リポジトリ                         │
│                                                         │
│  ┌─ Nix (パッケージ層) ─────────────────────────────┐  │
│  │  flake.nix + nix/ (darwin.nix, home.nix)         │  │
│  │  • パッケージのインストール（バージョン完全固定）    │  │
│  │  • nix-darwin による macOS システムレベルの設定    │  │
│  │  • [!] programs.* による設定ファイル生成は原則禁止 │  │
│  └──────────────────────────────────────────────────┘  │
│                         ↕                               │
│  ┌─ chezmoi (コンフィグ層) ─────────────────────────┐  │
│  │  home/ (dot_config/, private_dot_zshrc.tmpl, etc.)       │  │
│  │  • 設定ファイルの配置とテンプレート処理（OS分岐等）│  │
│  │  • マシン固有秘密情報のローカル管理（持出不可）    │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### メリット

- 🟢 **今すぐ使い始められる**: chezmoi の設定ファイルは素の TOML/zshrc なので直感的
- 🟢 **Nix のバージョン固定**: `flake.lock` で全マシン同一パッケージ。chezmoi 自体も Nix でインストール
- 🟢 **競合の排除**: Nix は「入れるだけ」、chezmoi が「設定するだけ」と役割分担を明確化
- 🟢 **nix-darwin**: macOS システム設定（Dock, Finder等）を宣言的に管理
- 🟢 **ハードウェアバインド**: TPM や Secure Enclave に紐づいた SSH 鍵により、秘密鍵を物理的に外部へ持ち出し不可能に

---

## 具体的な使い方のイメージ (Workflow Examples)

この「ハイブリッド構成」において、日々の運用がどのようになるかの具体例です。Nix（インストール）と chezmoi（設定）の役割分担が明確になります。

### ケース1: 新しいCLIツール（例: `gh` コマンド）を追加したい場合

1. **ツールのインストール (Nix)**
   `nix/home.nix` を開き、インストールリストに `gh` を追記します。
   ```nix
   home.packages = with pkgs; [
     # ...既存のパッケージ...
     gh  # <- これを追記
   ];
   ```
2. **システムへの反映**
   ```bash
   # macOSの場合
   darwin-rebuild switch --flake .#darwin
   
   # WSL/Linuxの場合
   home-manager switch --flake .#linux
   ```
   > [!NOTE]
   > この時点では、`gh` コマンドは使えるようになりますが、設定ファイルは一切作成されません。Home Manager の `programs.gh.enable = true` 等のNix側での設定生成は使いません。

### ケース2: ツールの設定ファイル（例: `~/.config/gh/config.yml`）をカスタマイズしたい場合

1. **設定の作成・反映 (chezmoi)**
   chezmoi を使って、ローカルのホームディレクトリにある設定ファイルを dotfiles リポジトリの管理下に加えます。
   ```bash
   chezmoi add ~/.config/gh/config.yml
   ```
2. **設定の編集**
   ```bash
   chezmoi edit ~/.config/gh/config.yml
   ```
   編集を保存すると、元のファイルも自動的に更新されます。
3. **コミットして他マシンへ共有**
   ```bash
   chezmoi cd
   git add home/dot_config/gh/config.yml
   git commit -m "Add gh config"
   git push
   ```

### ケース3: マシン固有の秘密情報（APIキー等）を使いたい場合

設定ファイルでAPIキーを使いたいが、Gitには絶対にコミットしたくない場合の運用です。

1. **chezmoi変数の設定**
   各マシンのローカル（Git管理外）にある `~/.config/chezmoi/chezmoi.toml` に変数を定義します。
   ```toml
   [data]
   openai_api_key = "sk-xxxxxxxx"
   ```
2. **テンプレートでの利用**
   `chezmoi edit ~/.zshrc` でテンプレートを開き、変数として参照します。
   ```zsh
   export OPENAI_API_KEY="{{ .openai_api_key }}"
   ```
3. **反映**
   ```bash
   chezmoi apply
   ```
   > [!IMPORTANT]
   > 生成された実際の `~/.zshrc` にはキーが直接書き込まれますが、Gitリポジトリ（`private_dot_zshrc.tmpl`）側には `{{ .openai_api_key }}` という文字列しか存在しないため、リポジトリが公開されていても安全です。

---
## 採用ツール一覧

本 dotfiles 環境において導入・管理する最新のツール群です。

| 分類 | ツール名 | 用途・特徴 |
|---|---|---|
| **環境・構成管理** | **Nix (Flakes)** | パッケージ宣言、依存関係の完全再現（バージョン固定） |
| | **Home Manager** | ユーザー環境のパッケージ・構成管理 |
| | **nix-darwin** | macOS システム環境設定の宣言的管理（IaC） |
| | **chezmoi** | dotfiles テンプレート管理、マシン固有のローカル設定 |
| | **age** | 秘密情報のローカル暗号化用ツール |
| **ターミナル** | **Windows Terminal** | Windows 標準のモダンなターミナル。Store経由で入手 |
| | **Ghostty / cmux** (macOS) | libghosttyベースの高速かつ macOS ネイティブなターミナル |
| | **Zellij** | Rust製のモダンなターミナルマルチプレクサ（tmux代替） |
| **シェル & プロンプト**| **zsh** | メインシェル |
| | **sheldon** | zsh プラグインマネージャ（Nix未使用時のFallback用） |
| | **Starship** | 高速でモダンなクロスシェルプロンプト |
| **検索・履歴・移動** | **Atuin** | 暗号化されたシェル履歴の保存・検索 |
| | **fzf** | コマンドラインのあいまい検索（Fuzzy Finder） |
| | **zoxide** | コマンドライン用のスマートディレクトリ移動（cd代替） |
| | **yazi** | Rust製。超高速ターミナルファイルマネージャ |
| **モダン CLI 代替** | **eza** | アイコン・Gitステータス対応のディレクトリ一覧（ls代替） |
| | **bat** | シンタックスハイライト対応のテキスト閲覧（cat代替） |
| | **fd** | シンプルかつ高速なファイル検索（find代替） |
| | **ripgrep (rg)** | 高速な文字列検索（grep代替） |
| | **git-delta** | シンタックスハイライト対応の差分表示（git diff代替） |
| | **dust** | ディスク使用量のグラフィカル表示（du代替） |
| | **btop** | 美しいリソース・プロセスの監視（top代替） |
| **開発環境マネージャ** | **mise** | 各種プログラミング言語のランタイム・ツール管理（asdf/fnm代替） |
| | **lazygit** | Git 操作を爆速にするターミナル用 UI |
| **秘密情報・ブリッジ** | **OpenSSH (FIDO2)** | TPM/Secure Enclave と連携したハードウェアバインド鍵の生成 |
| | **socat** / **npiperelay**| WSL から Windows 側の OpenSSH Agent (Windows Hello) へのブリッジ |

---

## フォント選定: UDEV Gothic

日本語環境に最適化されたプログラミングフォントを比較し、**UDEV Gothic** を推奨：

| フォント | 欧文ベース | 和文ベース | 特徴 |
|---------|-----------|-----------|------|
| **UDEV Gothic** ⭐ | JetBrains Mono | BIZ UDゴシック | **UD（ユニバーサルデザイン）で視認性最高**。リガチャ対応版あり |
| HackGen | Hack | 源柔ゴシック | Ricty 後継の定番。安定感とバランス |
| PlemolJP | IBM Plex Mono | IBM Plex Sans JP | IBM Plex 統一でモダン。ウェイト豊富 |
| Moralerspace | Monaspace (GitHub) | IBM Plex Sans JP | 最新。5スタイル選択可能 |

> [!TIP]
> **UDEV Gothic を推奨する理由**:
> - JetBrains Mono ベース = Starship 推奨の JetBrainsMono Nerd Font と同じ欧文デザイン
> - **BIZ UDゴシック** = 経済産業省が推進する UD フォント。長時間作業の視認性に優れる
> - Nerd Font 対応版（`UDEV Gothic NF`）が用意されている

---

## 秘密情報管理: TPM / Secure Enclave ハードウェアバインド

SaaS に依存せず、秘密情報を「原理的に外部に持ち出せない状態」で管理する設計です。

### 1. SSH 鍵のハードウェアバインド (FIDO2 / Security Key 方式)
- macOS (Secure Enclave) や Windows (TPM / Windows Hello) は、OS レベルで FIDO2 / WebAuthn プロバイダとして動作するため、外付け物理 YubiKey なしで**内蔵の生体認証（Touch ID / Windows Hello）をセキュリティキーとして指定可能**です。
- `ssh-keygen -t ecdsa-sk` (または `-t ed25519-sk`) で鍵を生成します。
  - 生成される秘密鍵ファイルには「ハードウェア（TPM / Secure Enclave）への参照トークン」のみが書き込まれ、実体はセキュア領域に暗号化されて格納されます。
  - このファイルを他のマシンにコピーしても、元のハードウェアと生体認証がなければ一切署名できません。これにより「秘密情報を外部に持ち出せない状態」を担保します。
- **WSL での利用**:
  - Windows の OpenSSH Agent サービス（Windows Hello 連携）に、`npiperelay` + `socat` ブリッジ経由で接続することで、WSL 内の `git` や `ssh` も Windows Hello / TPM を通じて透過的に認証できます。

### 2. API キー等のマシン個別ローカル管理
- 秘密情報（API キーやアクセストークンなど）は、マシンをまたいで同期せず、各マシンで再発行・個別登録します。
- chezmoi の **ローカルテンプレート変数** を採用します。
  - `chezmoi init` 実行時に、対話プロンプトで API キーの入力を求めます。
  - 入力値はローカルの `~/.config/chezmoi/chezmoi.toml` にのみ変数として保存され、Git リポジトリには絶対にコミットされません。
  - 生成されるローカル設定ファイルは権限 `600` で保護され、外部に同期もされないため、機密情報をローカルマシン内に完全に閉じ込めることができます。

---

## Proposed Changes

### Nix 基盤 (マルチホスト構成へ最適化)

将来的に複数マシン（macOS, WSL, Linuxサーバーなど）を管理しやすくするため、`nix/` ディレクトリで構成をフラットに整理し、以下の Flake 構成を採用します。

#### [NEW] [flake.nix](../flake.nix)
Nix Flake エントリポイント。nixpkgs, home-manager, nix-darwin の入力定義。

#### [NEW] [nix/darwin.nix](../nix/darwin.nix)
macOS ホスト向けエントリポイント。nix-darwin の設定（Dock, Finder, キーボード, Touch ID sudo, Homebrew Cask）および Home Manager の呼び出し。

#### [NEW] [nix/home.nix](../nix/home.nix)
Home Manager のメインモジュールおよびパッケージ宣言（全OS共通）。

---

### chezmoi コンフィグ

#### [NEW] [home/.chezmoi.toml.tmpl](../home/.chezmoi.toml.tmpl)
chezmoi 設定。KeePassXC DB パス、ユーザー変数。

#### [NEW] [home/.chezmoiignore](../home/.chezmoiignore)
OS 別除外ルール。

#### [NEW] [home/private_dot_zshrc.tmpl](../home/private_dot_zshrc.tmpl)
zsh メイン設定。sheldon, Starship, Atuin, fzf, zoxide, エイリアス統合。WSL での `socat` + `npiperelay` による SSH Agent ブリッジも自動起動。

#### [NEW] [home/dot_zshenv](../home/dot_zshenv)
XDG ベースディレクトリ、PATH 設定。

#### [NEW] [home/dot_config/starship.toml](../home/dot_config/starship.toml)
Starship プロンプト設定。

#### [NEW] [home/dot_config/atuin/config.toml](../home/dot_config/atuin/config.toml)
Atuin シェル履歴設定。

#### [NEW] [home/dot_config/git/config.tmpl](../home/dot_config/git/config.tmpl)
Git 設定（OS 分岐: credential helper, autocrlf）。

#### [NEW] [home/dot_config/git/ignore](../home/dot_config/git/ignore)
グローバル gitignore。

#### [NEW] [home/dot_config/git/attributes](../home/dot_config/git/attributes)
グローバル gitattributes。

#### [NEW] [home/dot_config/sheldon/plugins.toml](../home/dot_config/sheldon/plugins.toml)
zsh プラグイン定義。

#### [NEW] [home/dot_config/zellij/config.kdl](../home/dot_config/zellij/config.kdl)
zellij 設定。

#### [NEW] [home/dot_config/bat/config](../home/dot_config/bat/config)
bat 設定。

#### [NEW] [home/dot_config/mise/config.toml](../home/dot_config/mise/config.toml)
mise グローバル設定。


#### [NEW] [home/dot_config/ghostty/config](../home/dot_config/ghostty/config)
Ghostty 設定ファイル（macOS 上の cmux が共通で読み込む設定）。UDEV Gothic フォントの設定や基本テーマを定義。

---

### ブートストラップ & ドキュメント

#### [NEW] [install.sh](../install.sh)
安全かつ確実な依存解決のためのブートストラップスクリプト。以下の順序で実行される：
1. **Nix のインストール** (Determinate Systems のインストーラを推奨)
2. **Nix Flake の適用** (`nix run nix-darwin` または `home-manager switch`)
   -> *ここで chezmoi, zsh, git などのベースツール群がインストールされる*
3. **chezmoi の適用** (`chezmoi init --apply`)
   -> *Nix で入った最新の chezmoi を使い、ホームディレクトリに設定を展開*

#### [NEW] [README.md](../README.md)
セットアップ手順、ツール一覧、移行ガイド。

#### [NEW] [docs/recommended_tools.md](recommended_tools.md)
将来的に採用を検討すべき拡張ツール提案ドキュメント。

---

## Verification Plan

### 自動検証
- `nix flake check` — Flake の構文・型チェック
- `chezmoi doctor` — chezmoi の設定検証
- `chezmoi diff` — 差分の事前確認

### 手動検証（ユーザーに依頼）
- WSL 環境で `install.sh` を実行してテスト
- macOS 環境で nix-darwin + chezmoi をテスト
