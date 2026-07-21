## 2024-06-21 - Insecure permissions on UNIX socket for WSL SSH bridge

**Vulnerability:** The SSH agent socket created by `socat` for the WSL to Windows OpenSSH bridge had default permissions, which allowed any local user on the machine to use the SSH agent and authenticate as the user.
**Learning:** By default, UNIX sockets created by `socat` use the process's umask which may not be restrictive enough for sensitive sockets like an SSH agent.
**Prevention:** Always explicitly set `mode=0600` when using `socat UNIX-LISTEN` for sensitive sockets like SSH agent bridges to ensure that only the owner can read/write to the socket.

## 2024-07-25 - Hardcoded socat listener permissions

**Vulnerability:** The UNIX domain socket for SSH agent bridging in WSL was created without explicit permissions `umask`, making it potentially readable/writable by other users on the system (depending on the default umask).
**Learning:** UNIX-LISTEN sockets created by `socat` use the current `umask`. If the `umask` is permissive, other users could hijack the SSH agent connection and use the user's SSH keys.
**Prevention:** Always set an explicit `umask` (like `077`) before creating sensitive UNIX sockets or use `umask=077` in the socat options.

## 2024-08-23 - GitHub Token leak via command line arguments

**Vulnerability:** The GitHub token (`DOTFILES_GITHUB_TOKEN`) was passed to `chezmoi init` using a command line argument (`--promptString githubToken=...`). Command line arguments are visible to all users on the same machine via tools like `ps`, exposing the secret token.
**Learning:** Never pass sensitive information (secrets, tokens, passwords) via command line arguments. They are logged in shell history and visible to other processes and users.
**Prevention:** Use environment variables, standard input (stdin), or files with restricted permissions to pass secrets to processes.

## 2024-10-26 - GitHub Token leak via install.sh command line arguments

**Vulnerability:** While a previous fix prevented `chezmoi init` from leaking the GitHub token, `install.sh` itself still accepted the token via the `--github-token` command-line argument. This exposed the token in the process list (`ps`) to any user on the system while `install.sh` was running, and in the user's shell history.
**Learning:** When fixing command-line argument leaks for sub-processes, you must also ensure the parent script does not accept the same secrets via its own command-line arguments.
**Prevention:** Remove command-line options for secrets in wrapper scripts and require them to be passed as environment variables or via secure interactive prompts.

## 2024-10-27 - GitHub Token exposure via world-readable .zshrc

**Vulnerability:** The GitHub token (`GITHUB_TOKEN`) was exported directly in `~/.zshrc`, which is typically created with default file permissions (e.g., `0644`), making the token readable by any local user on the machine.
**Learning:** Storing secrets directly in general configuration files like `.zshrc` exposes them if the file's permissions are not tightly restricted.
**Prevention:** Use chezmoi's `private_` prefix (e.g., `private_dot_secrets.tmpl`) to generate a dedicated secrets file with `0600` permissions, and source this secure file from the main configuration.

## 2024-11-20 - CI/CD Token leak via .git/config

**Vulnerability:** The GitLab CI pipeline push token (`CI_PUSH_TOKEN`) was embedded in the Git remote URL via `git remote set-url origin`. This operation writes the cleartext token directly to the `.git/config` file on the CI runner's local filesystem.
**Learning:** Writing credentials to `.git/config` (via `git remote add` or `git remote set-url`) leaves persistent secrets on disk. These can easily be exposed if the workspace is cached, passed as artifacts, or if a failing step dumps the git configuration to the logs.
**Prevention:** Never configure remotes with embedded credentials in CI/CD. Instead, pass the authenticated URL directly to the `git push` command, which keeps the token entirely in memory and out of configuration files.

## 2024-11-20 - Git credential storage in plaintext

**Vulnerability:** The Git credential helper was configured to `store` on some operating systems. This stores credentials in plaintext on disk in the `~/.git-credentials` file, exposing them to any user or malicious process that can read the file.
**Learning:** Hardcoding credentials on disk in plaintext creates a significant risk of exposure.
**Prevention:** Use an OS-native secure credential manager (like macOS Keychain or Windows Credential Manager), or use `cache` to store credentials temporarily in memory instead of on disk.
