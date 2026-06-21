# 秘密情報管理と日本語ターミナル環境の統合設計書

本ドキュメントは、macOS、Windows (WSL)、Linux のクロスプラットフォーム環境において、**SaaS 非依存で秘密情報を物理的に外部へ持ち出し不可能な状態**を保ちつつ、**日本語環境においてストレスのない開発環境**を構築するための詳細な技術選定と設計をまとめたものです。

### 想定ターゲット環境 (Target Hardware Premises)

本環境の設計・チューニングにおける基準となる想定ハードウェアスペックは以下の通りです。
- **macOS**: **MacBook Air M5 (Apple Silicon), メモリ 32GB**
  - **32GB 大容量メモリ**: 複数の Docker コンテナ、ローカル Kubernetes クラスタ（k3d等）、AI エージェント（Claude Code, Aider 等）、Pueue によるビルドキューの同時稼働を想定し、スワップの発生を極力抑える設計としています。
  - **ファンレス設計（MacBook Air）の考慮**: 長時間のコンパイルや高負荷な並列処理においてサーマルスロットリング（熱による性能低下）が懸念されるため、CPU効率が極めて高い Rust/Go 製ツールを積極的に採用し、無駄なプロセス負荷と発熱を最小化する構成に最適化しています。また、生体認証（Touch ID / Secure Enclave）をフル活用して物理デバイスに強固に紐づいた秘密鍵管理を行います。
- **Windows / WSL**: ホスト PC の TPM / Windows Hello にバインドされた OpenSSH Agent および WSL ブリッジ環境。

---

## 1. 秘密情報管理・認証の設計 (Secrets & Auth)

マシンの外部へ秘密情報（秘密鍵・APIキー）を持ち出す経路を遮断し、各マシンのハードウェアセキュア領域（Windows: TPM, macOS: Secure Enclave）にバインドされた安全な認証管理を行います。

### 1.1 SSH 鍵のハードウェアバインド（OpenSSH FIDO2 セキュリティキー）

秘密鍵そのものをファイルとしてディスク上にプレーンテキストで置く（あるいはマシンの間で共有する）運用を廃止し、**各マシンの内蔵生体認証（Touch ID / Windows Hello）にバインドされた FIDO2 セキュリティキー型鍵**を作成します。

- **仕組み**: `ssh-keygen -t ecdsa-sk` (または `-t ed25519-sk`) で鍵を生成します。
  - 生成される秘密鍵ファイル（`id_ecdsa_sk` 等）は、単なる「セキュアチップへの参照情報（アタッチメント）」に過ぎず、実体は TPM や Secure Enclave 内で保護されます。
  - 悪意ある者がこのファイルだけを外部に持ち出しても、元のマシンのハードウェアと指紋（Touch ID / Windows Hello）がなければ一切署名できません。
  - これにより、SSH 鍵は「原理的に外部に持ち出せない状態」になります。

#### macOS での設定
- Apple 純正の SSH クライアントは FIDO2 (`ecdsa-sk` 等) をネイティブサポートしています。
- 鍵生成時に macOS の Touch ID をセキュリティキーとして利用可能です。

#### Windows (WSL) での設定
WSL2 は独立した Linux 仮想マシンのため、Windows 側の物理 TPM (Windows Hello) に直接アクセスできません。これを **`npiperelay`** と **`socat`** を用いて Windows の OpenSSH Agent が管理する SSH 鍵にブリッジします。

```
[ WSL2 (Linux) ]                        [ Windows ホスト ]
┌──────────────────┐                    ┌────────────────────────────┐
│ $ ssh git@github │                    │  Windows Hello (TPM)       │
└────────┬─────────┘                    │  による署名検証（生体認証） │
         │ (SSH_AUTH_SOCK)              └────────────┬───────────────┘
         ▼                                           │ (OpenSSH 互換)
┌──────────────────┐    (stdout/stdin)  ┌────────────▼───────────────┐
│ socat (Unix Dom) ├───────────────────►│ npiperelay.exe             │
└──────────────────┘                    │ (\\.\pipe\openssh-ssh-agent)
                                        └────────────────────────────┘
```

**具体的な設定手順**:

1. **Windows 側サービス起動**:
   Windows の管理者権限 PowerShell で以下を実行し、Windows 標準の OpenSSH Agent を自動起動にします。
   ```powershell
   Set-Service ssh-agent -StartupType Automatic
   Start-Service ssh-agent
   ```
2. **WSL (zsh) 側でのソケットブリッジ設定** (`.zshrc` / chezmoi で配置):
   ```bash
   # SSHエージェントソケットのパスを定義
   export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"

   # すでにソケットが接続されていない場合のみブリッジを起動
   if ! ss -a | grep -q "$SSH_AUTH_SOCK"; then
       rm -f "$SSH_AUTH_SOCK"
       # Windows側の npiperelay.exe のパス (Windowsユーザー名 ryodocx)
       local npiperelay_path="/mnt/c/Users/ryodocx/bin/npiperelay.exe"
       
       if [ -f "$npiperelay_path" ]; then
           (setsid socat UNIX-LISTEN:"$SSH_AUTH_SOCK",fork EXEC:"$npiperelay_path -ei -s //./pipe/openssh-ssh-agent",nofork &) >/dev/null 2>&1
       fi
   fi
   ```
   * ※ `socat` は Nix パッケージ（`nix/home/packages.nix`）に含めることで、OS を問わず自動インストールされます。

---

### 1.2 API キー等のマシン個別ローカル管理

共有データベース（KeePassXC の DB 等）をクラウドや他マシンと同期する運用は、データベースファイルの流出リスクが生じるため行いません。API キーやアクセストークンは、マシンごとに個別発行し、ローカルマシン外に一切出さない運用を徹底します。

#### chezmoi のローカルテンプレート変数の活用
`chezmoi init` 実行時に、対話型プロンプトで API キーの入力を求めます。

- **仕組み**: 入力された秘密情報は、Git リポジトリにはコミットされず、ローカルマシンの `~/.config/chezmoi/chezmoi.toml` にのみ変数として保存されます。
- **保護**: 生成されるローカル設定ファイルは権限 `600` (所有者のみ読み書き可能) で保護されます。
- **暗号化**: 必要であれば `chezmoi` の `age` 統合を利用し、ローカルの SSH 公開鍵でローカル設定ファイル自体を暗号化して保管することも可能です。

これにより、クラウドSaaSや共有ファイルを使うことなく、各マシンのローカルストレージ内に閉じた安全な秘密情報管理を実現します。

---

## 2. 日本語ターミナル環境の設計 (Windows Terminal / Ghostty / cmux)

Windows 環境では Microsoft Store から入手可能な **Windows Terminal** を採用し、macOS 環境では高速かつ AI 開発に特化した **Ghostty** / **cmux** を採用します。

### 2.1 採用ツールとメリット

#### Windows Terminal (Windows)
- **標準搭載と高い親和性**: Windows 11 等に標準搭載（または Store から入手可能）されており、動作が軽量で WSL への接続プロファイルが自動生成されます。
- **設定の簡便さ**: UI または `settings.json` でフォントやカラースキームを直感的に設定できます。

#### Ghostty / cmux (macOS)
- **特徴**: Ghostty (libghostty) エンジンをベースに構築された高速なターミナルエミュレータ。cmux はその派生で、AI エージェント用の専用機能（サイドバーや通知リング等）を備えています。
- **設定の共有**: Ghostty の設定ファイル（`~/.config/ghostty/config`）は cmux にもそのまま読み込まれます。このため、dotfiles で Ghostty の設定ファイルを配置しておけば、両エディタでシームレスに共通の設定を利用できます。

---

### 2.2 UDEV Gothic ＋ システムフォントフォールバック設定

英数字には Starship プロンプトやモダン CLI が多用するアイコンが崩れないよう、**UDEV Gothic 35NF** (Nerd Font 対応版) を最優先に指定し、各 OS 固有の高品質な UD 和文フォントへフォールバックさせます。

#### Windows Terminal でのフォント設定例 (`settings.json`):
```json
"profiles": {
    "defaults": {
        "font": {
            "face": "UDEV Gothic 35NF",
            "size": 12
        }
    }
}
```

#### Ghostty / cmux でのフォント設定例 (`ghostty/config`):
```
# フォント設定
font-family = UDEV Gothic 35NF
font-size = 12

# Ghosttyは自動的にOS標準のフォントフォールバック（Hiragino / BIZ UDゴシック等）を処理します
# 必要に応じてフォント調整や IME 設定
adjust-cursor-thickness = 1
```

---

## 3. 日本語入力 (IME) キーバインドの統一

macOS と Windows を行き来する開発者向けに、日本語入力（IME）のオン/オフ切り替えを「macOS スタイル（英数キーで OFF / かなキーで ON）」に統一します。

```
macOS 配列 (JIS)   :  [英数] (スペースの左) ──► IME OFF  /  [かな] (スペースの右) ──► IME ON
Windows 配列 (JIS) :  [無変換] (スペースの左) ─► IME OFF  /  [変換] (スペースの右) ──► IME ON
```

### 3.1 Windows (Host) 側での統一設定
Windows 標準の IME 設定（MS-IME や Google 日本語入力）を変更して、`無変換`キーに「IMEを無効化」、`変換`キーに「IMEを有効化」を割り当てます。

- **MS-IME の場合**:
  `設定 > 時刻と言語 > 言語と地域 > 日本語 (オプション) > キーとタッチのカスタマイズ` にて：
  - **無変換キー**: `IME-オフ`
  - **変換キー**: `IME-オン`

### 3.2 macOS 側でのシステムキーマップ管理
macOS では、`nix-darwin` を使って CapsLock を Control にマップする等のカスタマイズをコード管理します。

```nix
# nix/darwin/default.nix
system.keyboard = {
  enableKeyMapping = true;
  remapCapsLockToControl = true;
};
```

---

## 4. 環境構築時における「摩擦」の回避と詳細設計

マルチOS環境において、実際に構築を始めた段階で発生しやすい技術的な問題（摩擦）を回避するための詳細設計です。

### 4.1 npiperelay.exe の自動取得・セットアップ
WSL 側から Windows Hello 連携された SSH Agent を呼び出すための `npiperelay.exe` は、手動での配置ではなく chezmoi の**ブートストラップ用自動実行スクリプト（`run_once_`）**で自動取得します。

- **処理フロー**:
  1. WSL 側で chezmoi が起動した際、ホスト（Windows）のユーザーディレクトリ下（例: `/mnt/c/Users/ryodocx/bin/npiperelay.exe`）にファイルが存在するかチェック。
  2. 存在しない場合、GitHub リリース（`jstarks/npiperelay`）から最新の zip を `curl` で WSL 側に取得し、Windows 側の該当パスに展開・配置する。
  3. 配置後、パーミッションを確認する。
  これにより、新マシンセットアップ時の完全自動化を担保します。

### 4.2 改行コード問題 (CRLF) の完全防止 (.gitattributes)
Windows 側で dotfiles リポジトリをチェックアウトした際、Git の `core.autocrlf` 設定によってシェルスクリプトや設定テンプレートの改行コードが自動で `CRLF` に変換され、WSL 側で実行時に構文エラー（`\r` が原因）を引き起こすことがあります。

- **解決策**: リポジトリのルートに以下の `.gitattributes` を配置し、Git に改行コードの制御を明示的に強制します。
  ```gitattributes
  # デフォルトのテキストファイル判定
  * text=auto

  # シェル・スクリプト、Nix、Lua、設定テンプレートなどはLFに固定
  *.sh text eol=lf
  *.nix text eol=lf
  *.lua text eol=lf
  *.toml text eol=lf
  *.tmpl text eol=lf
  *.kdl text eol=lf
  *.config text eol=lf
  .chezmoiignore text eol=lf
  ```

### 4.3 Nix/Home Manager と sheldon (zshプラグイン) の競合回避
Nix (Home Manager) がインストールされている環境では、zshプラグイン（zsh-autosuggestions等）が Nix によって自動でインストールおよび `.zshrc` へ展開されます。Nix がない環境での Fallback として `sheldon` も dotfiles に含めるハイブリッド構成を取るため、プラグインの二重ロードによるシェルの起動遅延や挙動異常を防ぎます。

- **解決策**: chezmoi で生成する `.zshrc`（または `dot_zshrc.tmpl`）内に、以下のような Nix環境の有無を判定する条件分岐を記述します。
  ```zsh
  # Nix もしくは nix-darwin/Home-Manager の環境変数が存在するかチェック
  if [ -d "/nix" ] || [ -n "$NIX_PROFILES" ]; then
      # Nix 環境: プラグインロードは Nix に任せ、sheldon はスキップ
      # (Nixによって ~/.zshrc に自動ロード設定が挿入される、またはHome Managerのモジュールが処理)
  else
      # 非 Nix 環境: chezmoi + sheldon が有効であればプラグインをロード
      if command -v sheldon >/dev/null 2>&1; then
          eval "$(sheldon source)"
      fi
  fi
  ```

### 4.4 Windows ネイティブ側（PowerShell）のプロファイル要否
Windows 側は WSL や Windows Terminal、KeePassXC などを動かす「ホストOS」として機能しますが、Windows の PowerShell (pwsh) 自体でも作業（CLI操作）を行うかによって、PowerShell プロファイル（`Microsoft.PowerShell_profile.ps1`）の dotfiles 管理が必要になります。

- **設計指針**:
  - **PowerShell を利用する場合**: `home/Documents/PowerShell/Microsoft.PowerShell_profile.ps1`（OS別マッピング）を chezmoi に含め、PowerShell 側でも `starship` や `zoxide` が自動インテグレートされるように構成します。
  - **PowerShell を利用しない場合（開発は100% WSL）**: PowerShell 側の設定は管理対象外とし、Windows Terminal のプロファイル設定でデフォルト起動シェルを直接 WSL (`wsl.exe`) に向けることで、構成をシンプルに保ちます。
