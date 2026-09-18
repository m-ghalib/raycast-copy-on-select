# QA matrix

This document holds the release QA checks for Copy on Select version `1.0.0`. Run every
check on a clean macOS user account. Record the result of each check.

Do not use real credentials in any check. Use non-sensitive test values.

## Success-metric targets

| Metric | Target | Measurement window |
|---|---|---|
| Toggle success rate | 100% across 100 consecutive toggles | Pre-release QA |
| Toggle acknowledgement latency | p95 at or below 300 ms | Pre-release QA |
| Copy success for eligible selections | At least 95% | 200 qualifying gestures across the compatibility matrix |
| False copies after non-selection gestures | No more than 1 per 500 tested gestures | Pre-release QA |
| Synthetic copies in secure fields | 0 | All secure-field test cases |
| Disabled monitoring state | Event tap absent within 500 ms of a disable | 100 toggle cycles |
| Disabled steady-state CPU | At or below 0.1% on the reference Mac | Five-minute sample |
| Enabled steady-state CPU without interaction | At or below 0.5% on the reference Mac | Five-minute sample |
| Process memory footprint | At or below 30 MB resident memory | Five-minute sample |
| Selected-text retention or transmission | 0 bytes | Code and runtime audit |

## Gestures

- [ ] Short text drag from left to right copies once.
- [ ] Short text drag from right to left copies once.
- [ ] Long text drag across several lines copies once.
- [ ] Double-click on a word copies once.
- [ ] Triple-click on a line copies once.
- [ ] Rapid repeated clicks produce no more than one copy per selection.
- [ ] A click without movement produces no copy.
- [ ] Sub-threshold pointer jitter produces no copy.
- [ ] A window drag produces no copy.
- [ ] A scrollbar drag produces no copy.
- [ ] An image drag produces no copy.
- [ ] A link drag produces no copy.
- [ ] A file drag in Finder produces no copy.
- [ ] A right-click produces no copy.
- [ ] A scroll gesture produces no copy.
- [ ] A drag that ends with an empty selection produces no copy.
- [ ] One qualifying gesture produces exactly one synthetic copy.
- [ ] An application switch right after a selection cancels the pending copy.
- [ ] A window switch right after a selection cancels the pending copy.
- [ ] A toggle off during an in-progress drag cancels the pending copy.

## Secure fields

- [ ] A macOS native password field produces zero copy attempts.
- [ ] A Safari password field produces zero copy attempts.
- [ ] A Google Chrome password field produces zero copy attempts.
- [ ] A password manager login field produces zero copy attempts.
- [ ] An inconclusive Accessibility result produces zero copy attempts.
- [ ] An Accessibility timeout produces zero copy attempts.
- [ ] The secure-field decision reads no field value.
- [ ] The log holds no secure-field value after the full secure-field pass.

## Toggle behavior

- [ ] The command runs without a Raycast view.
- [ ] One invocation changes the state exactly one time.
- [ ] A successful toggle reports `Copy on Select: On` or `Copy on Select: Off`.
- [ ] The reported state comes from the background process, not from the extension.
- [ ] 100 consecutive toggles produce 100 correct states.
- [ ] Rapid repeated invocation produces one deterministic transition per accepted call.
- [ ] A stopped process starts on the next command and completes the toggle.
- [ ] An absent or corrupt binary produces an actionable error, not a false state.
- [ ] An invalid response produces an actionable error, not an inferred state.
- [ ] A checksum mismatch stops the start and reports an error.

## Permissions

- [ ] A first run without permissions reports `Setup Required`.
- [ ] The error names `copyonselectd` as the program that requires access.
- [ ] `copyonselectd --selftest` reports the true permission state.
- [ ] Accessibility alone is not sufficient to enable the behavior.
- [ ] Input Monitoring alone is not sufficient to enable the behavior.
- [ ] Both permissions together enable the behavior.
- [ ] A revocation at runtime removes the event tap and turns the behavior off.
- [ ] A revocation at runtime produces setup guidance on the next command.
- [ ] Permission recovery requires no reinstall of the extension.
- [ ] The product requests no Screen Recording permission.
- [ ] The permission grant survives an extension update.

## Persistence and restart

- [ ] The state file is `~/Library/Application Support/CopyOnSelect/state.json`.
- [ ] A state write survives an abrupt process termination without an ambiguous value.
- [ ] A process restart restores the last explicit state.
- [ ] A login does not start the process.
- [ ] The first command after a login restores the last explicit state.
- [ ] A sleep and wake cycle keeps a correct state.
- [ ] A sleep and wake cycle keeps a healthy event tap, or recreates it one time.
- [ ] Only one process instance owns the event tap.
- [ ] A system-disabled event tap triggers one safe recreation attempt.

## Performance

- [ ] Disabled steady-state CPU stays at or below 0.1% over five minutes.
- [ ] Enabled steady-state CPU without interaction stays at or below 0.5% over five minutes.
- [ ] Resident memory stays at or below 30 MB over five minutes.
- [ ] Toggle acknowledgement p95 latency stays at or below 300 ms.
- [ ] The event tap removal completes within 500 ms of a disable.
- [ ] Input latency shows no observable change while the behavior is on.
- [ ] The event-tap callback performs no Accessibility query.

## Privacy audit

- [ ] A network capture during a full session records zero outbound requests.
- [ ] The product works with the network off.
- [ ] The log holds no selected text.
- [ ] The log holds no clipboard contents.
- [ ] The log holds no typed characters.
- [ ] The log holds no window titles, document names, or URLs.
- [ ] The log respects its size limit and rotates.
- [ ] The state file holds only the enabled state, the schema version, and the version.
- [ ] A source audit finds no pasteboard read.
- [ ] A source audit finds no selected-string retrieval on the eligibility path.
- [ ] The uninstall procedure leaves no running process.
- [ ] The uninstall procedure leaves no file in `~/Library/Application Support/CopyOnSelect/`.

## Compatibility pass

- [ ] Every row of [compatibility.md](compatibility.md) holds a verdict other than `Untested`.
- [ ] Every unsupported application fails closed without a clipboard overwrite.

## Related documents

- [Compatibility](compatibility.md)
- [Troubleshooting](troubleshooting.md)
- [Privacy](../PRIVACY.md)
