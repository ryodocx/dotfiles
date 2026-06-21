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
   - 視認性の高いフォント **UDEV Gothic 35NF** を最優先とし、OS 固有の高品質 UD フォントへフォールバックする WezTerm および Ghostty/cmux 構成。
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

```bash
./install.sh
```

## ツールチェーン & 設定の詳細
詳細な設計決定事項やモダン CLI 代替ツールのリストについては、以下を参照してください。
- [implementation_plan.md](docs/implementation_plan.md)
- [terminal_and_secrets_design.md](docs/terminal_and_secrets_design.md)

## 運用上の注意点 (Tips)

- **WSL 経由での Git 操作と生体認証**: FIDO2 (Touch ID / Windows Hello) キーを利用した `git push` 時、認証プロンプトが表示されます。WSL の場合、**Windows Hello のポップアップがターミナルの裏（バックグラウンド）で開いてしまい、ターミナルがフリーズしたように見える** ことがあります。応答がない場合は `Alt+Tab` 等でバックグラウンドに隠れた認証ウィンドウを探してください。
- **パッケージのアップデート**: Nix Flakes によってツールのバージョンは `flake.lock` で固定されています。定期的に `nix flake update` を実行し、環境を最新に保ってください。
- **chezmoi の編集**: 設定ファイルを編集する際は `chezmoi edit ~/.zshrc` のように操作し、その後 `chezmoi apply` で反映させてください。直接編集すると上書きされて消える可能性があります。
