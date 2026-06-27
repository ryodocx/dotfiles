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

## 2026-06-27 - Hardcoded secret leak via install.sh arguments
**Vulnerability:** The GitHub token was accepted as a command line argument (`--github-token`) by the `install.sh` wrapper script. This exposed the token in the system's process list (`ps`) during installation.
**Learning:** The rule against passing secrets via CLI arguments applies not just to sub-commands (like `chezmoi`) but also to the parent wrapper scripts themselves. Any command typed into the shell becomes visible to all local users.
**Prevention:** Only use environment variables or interactive prompts for sensitive values in setup scripts. Remove `--github-token` from CLI parsing logic.
