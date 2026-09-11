# AGENTS.md

## Project goal

Remote Service Manager is a portable Windows GUI for remotely managing Windows services and Linux systemd units, plus monitoring and terminating remote processes.

## Supported environment

- Controller: Windows 10/11, Windows PowerShell 5.1, WPF.
- Windows target: WinRM/WS-Man with Kerberos and a DNS host name.
- Linux target: OpenSSH plus systemd; administrative actions use root or `sudo -n`.
- Do not add dependencies that require administrator installation without explicit approval.

## Source of truth

- Runtime version: `VERSION.txt`.
- Service groups and additional protected services: `service-groups.json`.
- Architecture and navigation: `PROJECT_MAP.md` and `docs/ARCHITECTURE.md`.
- Security boundaries: `docs/SECURITY.md`.
- Required verification: `docs/TESTING.md`.
- User-facing changes: `CHANGELOG.md` and `README.md`.

## Change rules

- Preserve Windows PowerShell 5.1 compatibility and UTF-8 BOM in `.ps1` and Russian `.txt` files.
- Use WPF only; do not mix Windows Forms event pumping into the UI.
- Keep remote operations bounded by a timeout and keep the window responsive.
- Pass collections as structured values or JSON; never join several service names into one logical name.
- Validate every host, user, service name, unit name, PID and file path at the trust boundary.
- Never use `Invoke-Expression`, plaintext passwords, `TrustedHosts=*`, disabled host-key checks, or automatic acceptance of SSH host keys.
- Windows current-account sessions must remain Kerberos-only and use a DNS name, not an IP address.
- Linux commands must remain non-interactive and use `sudo -n`; do not request or store a sudo password.
- Revalidate PID identity immediately before terminating a process.
- Preserve protection for critical connectivity, authentication and system services.
- Sanitize CSV strings that Excel could interpret as formulas.
- Store mutable runtime data outside the application folder in `%LOCALAPPDATA%\RemoteServiceManager`.
- Do not edit generated archives directly; rebuild them from the project directory.

## Required workflow

1. Read `PROJECT_MAP.md` and the relevant document under `docs/`.
2. Inspect existing behavior before editing; preserve unrelated user changes.
3. Make the smallest coherent change.
4. Run every applicable check from `docs/TESTING.md`.
5. If either executable `.ps1` changes, update both SHA-256 values in `Запустить.bat`.
6. Update `VERSION.txt`, `CHANGELOG.md`, `README.md` and detailed `README.txt` when behavior changes.
7. Rebuild and test the ZIP before publishing.

## Code review rules

- Block changes that can silently downgrade authentication from Kerberos to NTLM.
- Block SSH options that bypass `known_hosts` or enable agent/port/X11 forwarding.
- Block unvalidated interpolation into a remote shell command.
- Block UI-thread waits without a timeout or cancellation path.
- Block destructive actions without confirmation, protection checks and audit logging.
- Treat failure to verify the final remote state as an operation failure.

## Known constraints

- The Linux backend starts a new `ssh` process per request; do not assume SSH multiplexing is available in Windows OpenSSH.
- Exact Windows and ALT Linux integration tests require corporate test hosts and cannot be replaced by static checks.
- `Запустить.bat` integrity hashes detect accidental modification but are not a substitute for Authenticode/WDAC.
