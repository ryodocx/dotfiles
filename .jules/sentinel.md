## 2024-07-25 - Hardcoded socat listener permissions
**Vulnerability:** The UNIX domain socket for SSH agent bridging in WSL was created without explicit permissions `umask`, making it potentially readable/writable by other users on the system (depending on the default umask).
**Learning:** UNIX-LISTEN sockets created by `socat` use the current `umask`. If the `umask` is permissive, other users could hijack the SSH agent connection and use the user's SSH keys.
**Prevention:** Always set an explicit `umask` (like `077`) before creating sensitive UNIX sockets or use `umask=077` in the socat options.
