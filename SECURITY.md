# Security

This policy covers Copy on Select, the Raycast extension `copy-on-select`, and the
bundled background process `copyonselectd`.

## Report a vulnerability

Report a vulnerability privately. Do not open a public issue for a vulnerability. A
public issue exposes every user before a fix exists.

1. Open <https://github.com/m-ghalib/raycast-copy-on-select/security/advisories/new>.
2. Describe the problem and the affected version.
3. List the exact steps that reproduce the problem.
4. Describe the impact on the user.
5. State the macOS version and the processor architecture.
6. Submit the advisory.

Do not include real credentials, real passwords, or personal data in the report. Use
non-sensitive test values.

## Response times

| Stage | Target |
|---|---|
| Acknowledgement of the report | 7 days |
| Initial assessment and severity | 30 days |
| Fix or documented mitigation for a verified high-severity report | 90 days |

## Supported versions

| Version | Status |
|---|---|
| `1.0.0` | Supported |

Only the latest released version receives security fixes.

## In scope

- The background process `copyonselectd` and its source in `macos-helper/`.
- The Raycast extension source in `raycast-extension/`.
- The control socket at `~/Library/Application Support/CopyOnSelect/control.sock`.
- The checksum verification of the bundled binary.
- The secure-text-field rejection logic.
- Any path that writes user content into the log file.
- Any privilege escalation through the support directory.

## Out of scope

- Vulnerabilities in macOS itself. Report those to Apple.
- Vulnerabilities in Raycast itself. Report those to Raycast.
- Vulnerabilities in a target application that this product only triggers through a
  normal copy command.
- An attack that requires an attacker with an existing administrator session on the Mac.
- Missing hardening that produces no exploitable result.

## Security design

The design limits the damage from a defect.

- The event tap is listen-only. The tap passes every observed input through unchanged.
  The tap never modifies and never blocks input.
- The process rejects a gesture when the focused element or a relevant ancestor reports
  the secure-text-field subrole.
- Eligibility fails closed. An Accessibility error, a timeout, or an inconclusive
  result cancels the gesture. No copy occurs.
- An application without usable selection metadata fails closed. The product uses no
  broad copy fallback.
- The product reads no pasteboard content. The target application owns the clipboard.
- The product makes no network request and holds no credentials.
- The event tap exists only while the behavior is on. Off means that the tap is absent.
- The extension verifies the SHA-256 checksum of the bundled binary before every start.
- The runtime path is fixed. A changed binary at that path requires a new permission
  grant from the user.

## Permission scope

The background process requires Accessibility and Input Monitoring. The process does
not require Screen Recording. Read [docs/permissions.md](docs/permissions.md) for the
reason behind each permission and for the revocation procedure.
