# ryodocx's Cross-Platform Dotfiles

Nix と chezmoi を組み合わせた、macOS、Windows (WSL)、Linux に対応するモダンな dotfiles 環境です。

## 特徴

1. **ハイブリッド設計**:
   - Nix: パッケージ管理（`flake.lock` によるバージョン完全固定）および macOS のシステム設定（nix-darwin）。
   - chezmoi: dotfiles テンプレート管理、マシン固有設定のローカル管理（Git非公開）。
2. **秘密情報のハードウェアバインド（TPM / Secure Enclave）**:
   - Touch ID や Windows Hello をセキュリティキーとした **FIDO2 SSH 鍵 (`ssh-keygen -t ecdsa-sk`)** を使用することで、秘密鍵が物理的にハードウェアの外へ出ない安全な運用を実現。
   - WSL 側から Windows 側の OpenSSH Agent へ自動でブリッジ（`npiperelay` ＋ `socat`）。
3. **日本語環境の最適化**:
   - 視認性の高いフォント **UDEV Gothic 35NF** を最優先とする Windows Terminal (Windows) および Ghostty/cmux (macOS) 構成。
   - macOS（英数/かなキー）と Windows（無変換/変換キー）の IME オン・オフ切り替え操作感の統一。

## 導入方法

### 事前準備 (Windows 固有)

Windows / WSL 環境で利用する場合、OpenSSH Authentication Agent サービスを自動起動させておく必要があります。
管理者権限で PowerShell を開き、以下のコマンドを実行してください：

```powershell
Set-Service ssh-agent -StartupType Automatic
Start-Service ssh-agent
```

### 1. ハードウェアバインド SSH 鍵の生成と登録

リポジトリを安全にクローン・操作するために、まず各マシンで個別に生体認証ハードウェア（Touch ID / Windows Hello）に紐づいた SSH 鍵を作成し、GitHub に登録します。

```bash
# macOS のターミナル、または Windows の PowerShell 上で実行（WSL内ではありません）
ssh-keygen -t ecdsa-sk -C "ryodocx@device"
```

生成された公開鍵（`~/.ssh/id_ecdsa_sk.pub`）のテキストをコピーし、[GitHub の SSH and GPG keys 設定](https://github.com/settings/keys) に登録してください。

### 2. リポジトリのクローン

登録した SSH 鍵を利用して、リポジトリをローカルにクローンします。

```bash
git clone git@github.com:ryodocx/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

### 3. セットアップスクリプトの実行

`install.sh` を実行します。Nix、Home Manager、nix-darwin、chezmoi、および必要なツールが自動的にセットアップされます。
また、OS ユーザー名に応じて `flake.nix` が自動的に書き換えられます。

```bash
./install.sh
```

非対話的に実行したい場合は、以下のオプションを使用して各設定値を渡すことができます。

```bash
# GITHUB_TOKENは対話プロンプトで入力するか、環境変数で指定してください
./install.sh \
  --os-user "your_os_username" \
  --git-user "Your Name" \
  --git-email "your-email@example.com"
```

指定されなかった項目は、スクリプト実行中にインタラクティブに入力が求められます。

## ツールチェーン & 設定の詳細

詳細な設計決定事項やモダン CLI 代替ツールのリストについては、以下を参照してください。

- [implementation_plan.md](docs/implementation_plan.md)
- [terminal_and_secrets_design.md](docs/terminal_and_secrets_design.md)

## 日常の運用・操作方法 (How to Use)

### 1. 設定ファイルの構成マップ (どこに何が設定されるか)

リポジトリ内のソースファイルと、ホームディレクトリ（`~`）に実際に配置される設定ファイルの対応表です。

| リポジトリ内のパス | 展開先のパス (ホームディレクトリ) | 用途・設定内容 |
| :--- | :--- | :--- |
| [home/dot_zshrc.tmpl](file:///C:/Users/ryotn/Documents/antigravity/gallant-shannon/home/dot_zshrc.tmpl) | `~/.zshrc` | Zsh の起動・シェル環境設定 (WSL SSH agent 含む) |
| [home/dot_zshenv](file:///C:/Users/ryotn/Documents/antigravity/gallant-shannon/home/dot_zshenv) | `~/.zshenv` | 環境変数（XDGベースディレクトリ、PATHなど） |
| [home/dot_config/git/config.tmpl](file:///C:/Users/ryotn/Documents/antigravity/gallant-shannon/home/dot_config/git/config.tmpl) | `~/.config/git/config` | Git の設定 (OSごとの資格情報ヘルパー設定含む) |
| [home/dot_config/git/ignore](file:///C:/Users/ryotn/Documents/antigravity/gallant-shannon/home/dot_config/git/ignore) | `~/.config/git/ignore` | Git のグローバル無視設定 |
| [home/dot_config/starship.toml](file:///C:/Users/ryotn/Documents/antigravity/gallant-shannon/home/dot_config/starship.toml) | `~/.config/starship.toml` | Starship プロンプトのデザイン設定 |
| [home/dot_config/ghostty/config](file:///C:/Users/ryotn/Documents/antigravity/gallant-shannon/home/dot_config/ghostty/config) | `~/.config/ghostty/config` | Ghostty (macOS用ターミナル) の設定 |
| [home/dot_config/zellij/config.kdl](file:///C:/Users/ryotn/Documents/antigravity/gallant-shannon/home/dot_config/zellij/config.kdl) | `~/.config/zellij/config.kdl` | Zellij (ターミナルマルチプレクサ) の設定 |
| [home/dot_config/bat/config](file:///C:/Users/ryotn/Documents/antigravity/gallant-shannon/home/dot_config/bat/config) | `~/.config/bat/config` | `bat` (cat代替ツール) のテーマ等の設定 |
| [home/dot_config/atuin/config.toml](file:///C:/Users/ryotn/Documents/antigravity/gallant-shannon/home/dot_config/atuin/config.toml) | `~/.config/atuin/config.toml` | Atuin (シェル履歴管理) の同期無効化等の設定 |
| [home/dot_config/sheldon/plugins.toml](file:///C:/Users/ryotn/Documents/antigravity/gallant-shannon/home/dot_config/sheldon/plugins.toml) | `~/.config/sheldon/plugins.toml` | Sheldon (Zshプラグインマネージャー) のプラグイン定義 |
| [home/dot_config/mise/config.toml](file:///C:/Users/ryotn/Documents/antigravity/gallant-shannon/home/dot_config/mise/config.toml) | `~/.config/mise/config.toml` | Mise (開発言語・ランタイムマネージャー) の設定 |

---

### 2. 新しい設定ファイルを追加する (chezmoi 管理下へ)

既存の設定ファイル（例: `~/.tmux.conf` や `~/.config/kitty/kitty.conf`）を新規に dotfiles リポジトリの管理下に置く手順です。

1. **chezmoi にファイルを追加する**:

   ```bash
   chezmoi add ~/.tmux.conf
   ```

   ※ これにより、ファイルが `chezmoi` のソースディレクトリ（`~/.local/share/chezmoi/`）にコピーされます。

2. **テンプレート化したい場合 (オプション)**:
   もし OS ごとの条件分岐などを入れるためにテンプレートファイル化したい場合は、追加時に `--template` を付与します。

   ```bash
   chezmoi add --template ~/.tmux.conf
   ```

---

### 3. 日常の編集と反映サイクル

設定を変更し、他の環境に同期するまでの一般的なサイクルです。

#### 1. 設定ファイルを編集する

設定ファイルを編集する場合は、ホームディレクトリの実ファイルを直接触るのではなく、以下のコマンドで編集します。

```bash
# 例: ~/.zshrc を編集する
chezmoi edit ~/.zshrc
```

※ 自動的にソースディレクトリ側のファイル（`dot_zshrc.tmpl`）がエディタで開き、保存して閉じるとホームディレクトリ側にも自動で適用されます。

もしリポジトリ側のファイルを直接エディタで開いて編集した場合は、以下のコマンドでホームディレクトリに反映させます。

```bash
chezmoi apply
```

#### 2. 変更をリポジトリへコミット & プッシュする

編集した設定ファイルを GitHub に保存します。chezmoi の管理ディレクトリに移動して Git 操作を行うか、chezmoi コマンド経由で実行します。

```bash
# chezmoi の管理ディレクトリ (リポジトリ) でシェルを開く
chezmoi cd

# あとは通常の Git 操作
git status
git add .
git commit -m "style: update zshrc aliases"
git push origin v2
```

#### 3. 他のマシンで最新の設定を取り込む (同期)

別のマシンで GitHub 上の最新設定を取り込み、適用します。

```bash
# 最新のリポジトリの変更を取得し、自動的に適用 (apply) する
chezmoi update
```

#### 4. 各種ソフトウェアのアップデート

本リポジトリに含まれる Nix、Homebrew、Mise、Sheldon などの各種ソフトウェアやプラグインを一括で最新版に更新するためのスクリプトが用意されています。Zsh 内で以下のエイリアスコマンドを実行してください。

```bash
dotfiles-update
```

または、直接以下のスクリプトを実行します。

```bash
~/.dotfiles/update.sh
```

このコマンドを実行すると、内部的に以下の処理が自動で行われます：

1. **リポジトリの pull**: `~/.dotfiles` 内で最新の変更を取得 (`git pull`)
2. **chezmoi の同期**: `chezmoi update` で最新の設定ファイルを再適用
3. **Nix の更新**: `nix flake update` を実行し、`nix-darwin` もしくは `home-manager` の最新状態を再構築・適用
4. **Homebrew の更新**: macOS (および Linuxbrew) の GUI アプリ・ツール群を更新 (`brew update && brew upgrade`)
5. **Sheldon の更新**: Zsh プラグインの最新ロックファイルを生成・更新 (`sheldon lock --update`)
6. **Mise の更新**: Mise 本体とインストール済みの言語ランタイムを更新 (`mise upgrade`)

> [!NOTE]
> `nix flake update` が走ると、ローカルリポジトリ内の `flake.lock` が書き換わります。適用が成功した後は、`flake.lock` の変更をコミットして GitHub にプッシュすることをお勧めします。

---

## 運用上の注意点 (Tips)

- **WSL 経由での Git 操作と生体認証**: FIDO2 (Touch ID / Windows Hello) キーを利用した `git push` 時、認証プロンプトが表示されます。WSL の場合、**Windows Hello のポップアップがターミナルの裏（バックグラウンド）で開いてしまい、ターミナルがフリーズしたように見える** ことがあります。応答がない場合は `Alt+Tab` 等でバックグラウンドに隠れた認証ウィンドウを探してください。
- **パッケージのアップデート**: Nix Flakes によってツールのバージョンは `flake.lock` で固定されています。定期的に `nix flake update` を実行し、環境を最新に保ってください。
- **chezmoi の編集**: 設定ファイルを編集する際は `chezmoi edit ~/.zshrc` のように操作し、その後 `chezmoi apply` で反映させてください。直接編集すると上書きされて消える可能性があります。
