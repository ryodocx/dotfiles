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

## 2024-08-24 - Secret leak via wrapper script command line arguments
**Vulnerability:** The wrapper script `install.sh` accepted a sensitive GitHub token via a command-line argument (`--github-token`). Command-line arguments for wrapper scripts are just as vulnerable to exposure via process lists (`ps`) or shell history as the underlying tools they call.
**Learning:** The prohibition against passing secrets via CLI arguments applies universally across the codebase, not just to specific tools like `chezmoi`. Any script or executable that takes a secret as an argument is a vulnerability.
**Prevention:** Never add command-line options for secrets in any shell scripts or wrappers. Always design scripts to read sensitive information directly from environment variables (e.g., `TOKEN="${TOKEN:-}"`), standard input, or secure files.
