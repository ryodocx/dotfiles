## 2024-07-25 - Hardcoded socat listener permissions
**Vulnerability:** The UNIX domain socket for SSH agent bridging in WSL was created without explicit permissions `umask`, making it potentially readable/writable by other users on the system (depending on the default umask).
**Learning:** UNIX-LISTEN sockets created by `socat` use the current `umask`. If the `umask` is permissive, other users could hijack the SSH agent connection and use the user's SSH keys.
**Prevention:** Always set an explicit `umask` (like `077`) before creating sensitive UNIX sockets or use `umask=077` in the socat options.

## 2024-08-01 - Avoid command-line arguments for secrets
**Vulnerability:** The setup script (`install.sh`) previously accepted the GitHub token via the `--github-token` argument, which would expose the secret in `ps aux` to all users on the same machine. In addition, the secret was passed via `--promptString githubToken=...` to `chezmoi`, which could also be logged or observed in process lists.
**Learning:** Command-line arguments of processes are often visible system-wide and in shell history. Secrets must not be passed via CLI arguments.
**Prevention:** Always use environment variables, stdin, or interactive prompts to pass sensitive data to processes. Also, use `chezmoi`'s `private_` file prefix so that files containing secrets (like `~/.zshrc`) are generated with secure `0600` permissions.
