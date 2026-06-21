## 2024-06-21 - Insecure permissions on UNIX socket for WSL SSH bridge
**Vulnerability:** The SSH agent socket created by `socat` for the WSL to Windows OpenSSH bridge had default permissions, which allowed any local user on the machine to use the SSH agent and authenticate as the user.
**Learning:** By default, UNIX sockets created by `socat` use the process's umask which may not be restrictive enough for sensitive sockets like an SSH agent.
**Prevention:** Always explicitly set `mode=0600` when using `socat UNIX-LISTEN` for sensitive sockets like SSH agent bridges to ensure that only the owner can read/write to the socket.
