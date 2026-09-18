---
artifact: prd
version: "1.0"
created: 2026-09-17
status: draft
---

# PRD: Raycast Copy-on-Select Toggle

## Overview

### Problem Statement

macOS users must normally select text and then press `Command-C` to copy it. Utilities such as Pluks remove the second action by copying text immediately after a selection gesture, but this behavior may not be desirable at all times. The target user wants the convenience of copy-on-select with one reliable Raycast shortcut that turns the behavior on or off, without maintaining another visible menu-bar interface.

Raycast commands are suitable as a control surface but are not a reliable home for continuous global input monitoring. The product therefore needs a small persistent native helper for gesture monitoring and macOS security checks, with Raycast acting as the user-facing toggle.

### Why Now

- The desired workflow and first-release scope are concrete: toggle, monitor selection gestures, reject secure fields, and synthesize `Command-C`.
- Raycast provides the shortcut and command experience the target user already uses.
- A native macOS helper can use the required Accessibility, Input Monitoring, and login-item APIs while remaining invisible during normal use.

### Solution Summary

Build a macOS-only system composed of:

1. A no-view Raycast command that the user assigns a global shortcut.
2. A signed Swift helper that runs without a Dock or menu-bar presence.
3. Local control communication through which Raycast asks the helper to toggle its state and receives the resulting state.
4. A global mouse-gesture monitor that exists only while copy-on-select is enabled.
5. An Accessibility-based safety gate that rejects secure text fields before posting a synthetic `Command-C`.

The helper owns and persists the enabled state. The Raycast command is the control plane, not the source of truth.

### Target Users

#### Primary user

A macOS Raycast user who frequently copies text across native applications, browsers, and Electron applications and wants to reduce repeated `Command-C` keystrokes while retaining explicit control over when automatic copying is active.

#### Initial release audience

One technical user installing a local Raycast extension and companion helper on a personally controlled Mac. Public Raycast Store distribution is not required for the MVP.

## Goals & Success Metrics

### Goals

1. Let the user enable or disable copy-on-select with one Raycast-assigned global shortcut.
2. Automatically perform the equivalent of `Command-C` after supported text-selection gestures while enabled.
3. Never intentionally synthesize copy when focus is in a secure text field.
4. Remain invisible and consume negligible resources during normal use, especially while disabled.
5. Keep all processing local and avoid reading, storing, logging, or transmitting selected text.

### Success Metrics

Metrics apply to the defined MVP compatibility matrix in the Appendix.

| Metric | Current Baseline | MVP Target | Measurement Window |
|---|---:|---:|---|
| Toggle success rate | Feature absent | 100% across 100 consecutive toggles | Pre-release QA |
| Toggle acknowledgement latency | Feature absent | p95 at or below 300 ms | Pre-release QA |
| Eligible selection copy success | Manual `Command-C` required | At least 95% | 200 qualifying gestures across the compatibility matrix |
| False copies after non-selection mouse gestures | Not applicable | No more than 1 per 500 tested gestures | Pre-release QA |
| Secure-field synthetic copy attempts | Not applicable | 0 | All secure-field test cases |
| Disabled monitoring state | Not applicable | Global event tap absent within 500 ms of disabling | 100 toggle cycles |
| Disabled steady-state CPU | Not applicable | At or below 0.1% on the reference Mac | Five-minute sample |
| Enabled steady-state CPU without interaction | Not applicable | At or below 0.5% on the reference Mac | Five-minute sample |
| Helper memory footprint | Not applicable | At or below 30 MB resident memory | Five-minute sample |
| Selected-text retention or transmission | Not applicable | 0 bytes intentionally retained or transmitted | Code and runtime audit |

### Non-Goals

- Building clipboard history, search, synchronization, or a clipboard manager.
- Reproducing Pluks beyond copy-on-select behavior.
- Reading selected text and placing it on the pasteboard directly.
- Supporting Windows, Linux, iOS, or macOS users who do not use Raycast.
- Supporting keyboard-created selections in the MVP.
- Automatically pasting copied content.
- Guaranteeing compatibility with applications that neither implement normal `Command-C` behavior nor expose usable Accessibility metadata.
- Shipping through the public Raycast Store in the MVP.

## User Stories

| ID | User Story | Priority |
|---|---|---|
| US-1 | As a Raycast user, I want one shortcut to toggle copy-on-select so that I can control the behavior without opening settings. | P0 |
| US-2 | As a user, I want dragged text selections copied automatically so that I can paste them without pressing `Command-C`. | P0 |
| US-3 | As a user, I want double- and triple-click text selections copied automatically so that common selection gestures work consistently. | P0 |
| US-4 | As a security-conscious user, I want secure text fields excluded so that the helper does not trigger copy in password inputs. | P0 |
| US-5 | As a user, I want visible confirmation of the resulting on/off state so that I never have to guess whether monitoring is active. | P0 |
| US-6 | As a user, I want the setting to survive helper restarts and login so that the system returns to its last intentional state. | P1 |
| US-7 | As a user, I want actionable permission errors so that I can recover when macOS access is missing or revoked. | P1 |
| US-8 | As a user, I want ordinary clicks and non-text dragging left alone so that the tool does not unexpectedly overwrite my clipboard. | P0 |

### User-Story Acceptance Criteria

#### US-1: Toggle from Raycast

- The command runs without opening a Raycast view.
- One invocation changes the helper state exactly once.
- If the helper is installed but not running, the command launches it and completes the toggle.
- If the helper is unavailable, the command reports a failure and the next corrective action.

#### US-2 and US-3: Automatic copy

- A supported drag, double-click, or triple-click that produces a non-empty text selection causes exactly one synthetic `Command-C`.
- The copy is sent to the application in which the selection completed.
- The helper does not prevent or modify the original mouse events.

#### US-4: Secure fields

- When the focused Accessibility element or a relevant ancestor has the secure-text-field subrole, the helper does not synthesize `Command-C`.
- A failed or inconclusive secure-field check fails closed for that gesture.
- Secure-field decisions do not require reading the field value.

#### US-5: State confirmation

- A successful toggle produces a Raycast HUD indicating `Copy on Select: On` or `Copy on Select: Off`.
- The displayed state comes from the helper's response rather than an independently toggled Raycast value.

## Scope

### In Scope

- One macOS-only no-view Raycast toggle command.
- User-assigned global shortcut through Raycast.
- A Swift companion helper with no persistent visible UI during ordinary use.
- Helper startup on demand and at user login.
- Helper-owned persistent enabled/disabled state.
- Local request/response communication between the Raycast command and helper.
- Global observation of left-mouse selection gestures only while enabled.
- Drag-selection detection using a movement threshold.
- Double-click and triple-click selection detection.
- Accessibility validation before every synthetic copy attempt.
- Secure-text-field rejection.
- Synthetic `Command-C` after a qualifying selection completes.
- On/off HUD confirmation.
- Permission onboarding and recovery instructions.
- Local diagnostic logging that excludes selected text, clipboard contents, and keystroke contents.
- Automated unit tests for the gesture state machine and manual compatibility testing.

### Out of Scope

- Clipboard history or content inspection.
- Menu-bar controls, a settings window after onboarding, or a Dock icon.
- Copying while the mouse button remains down.
- Keyboard selections such as `Shift-Arrow`, `Command-A`, or keyboard-only editor commands.
- Shift-click range extension.
- Context-menu selections, touch-and-hold gestures, or application-specific selection commands.
- Automatic per-application rules or a user-managed exclusion interface.
- Images, files, table cells, canvas objects, or other non-text selections.
- Analytics, telemetry, accounts, or cloud services.
- Automatic updates for the companion helper.
- Public Raycast Store submission, App Store distribution, or a consumer installer.

### Future Considerations

- Public Raycast Store distribution and signed/notarized companion-app onboarding — deferred until the local workflow proves valuable and stable; follow [COMMUNITY_RELEASE.md](COMMUNITY_RELEASE.md) when promoting the MVP.
- Per-application allow and deny lists — deferred until compatibility testing identifies a real need.
- Keyboard-selection support — deferred because it requires broader global keyboard monitoring and additional false-positive controls.
- Shift-click and application-specific gesture adapters — deferred until the core gesture state machine is validated.
- A temporary pause mode with an automatic timeout — deferred to preserve a single binary toggle model.
- Menu-bar status or settings — deferred because the product goal is Raycast-only control during normal use.

## Solution Design

### Product Flow

```text
Raycast shortcut
      ↓
No-view Toggle Copy on Select command
      ↓ local request/response
Swift helper toggles and persists its state
      ↓
On: install gesture event tap     Off: remove event tap
      ↓
Selection candidate completes
      ↓
Verify same target app + eligible text selection
      ↓
Reject secure or inconclusive focus
      ↓
Post one synthetic Command-C
```

### Functional Requirements

#### Raycast Control Plane

- FR-1: The extension must expose a macOS-only command titled `Toggle Copy on Select` in `no-view` mode.
- FR-2: The command must support assignment of a global shortcut through Raycast's standard shortcut settings.
- FR-3: Each invocation must send one toggle request to the helper and await the resulting authoritative state.
- FR-4: On success, the command must display a HUD containing the resulting state.
- FR-5: If the helper is installed but not running, the command must attempt one on-demand launch before returning an error.
- FR-6: If the helper is missing, unreachable, or returns an invalid response, the command must not infer a new state and must show an actionable error.
- FR-7: The extension must not use Raycast LocalStorage as the state shared with the native helper.

#### Helper Lifecycle and State

- FR-8: The helper must run as a per-user macOS process without a Dock icon or persistent menu-bar item.
- FR-9: The helper must own the enabled/disabled value and persist it locally.
- FR-10: The helper must return its resulting state for every valid toggle request.
- FR-11: The helper must support launch at user login using a supported macOS service-management mechanism.
- FR-12: After a normal restart or login, the helper must restore the last explicitly selected state.
- FR-13: Only one active helper instance may own the gesture monitor at a time.

#### Gesture Monitoring

- FR-14: Enabling must create and activate a listen-only global event tap for the minimum mouse events needed by the gesture state machine.
- FR-15: Disabling must remove the event tap, clear in-progress gesture state, and stop selection monitoring within 500 ms.
- FR-16: The event tap must pass all observed input through unchanged.
- FR-17: A left-button drag must become a selection candidate only after crossing a configurable movement threshold.
- FR-18: A double-click or triple-click must become a selection candidate using the event's click count.
- FR-19: An ordinary click, right-click, scroll, window move, scrollbar drag, or detected file/object drag must not produce a synthetic copy.
- FR-20: A candidate must be evaluated only after selection completion, normally after the relevant mouse-up event is delivered.
- FR-21: The helper must associate each candidate with the frontmost target application and cancel it if focus moves to another application before copy dispatch.
- FR-22: One qualifying gesture must produce no more than one synthetic copy attempt.

#### Eligibility and Security Gate

- FR-23: Before posting `Command-C`, the helper must identify the currently focused Accessibility element in the target application.
- FR-24: The helper must reject the gesture if the focused element or a relevant ancestor reports the secure-text-field subrole.
- FR-25: The secure-field check must fail closed when Accessibility returns an error, times out, or provides an inconclusive result.
- FR-26: The helper must require evidence of an eligible, non-empty text selection when the target application's Accessibility implementation provides reliable selection metadata.
- FR-27: The MVP must not use a broad copy fallback in applications lacking sufficient Accessibility metadata; unsupported candidates must be skipped.
- FR-28: Eligibility checks must not retrieve or log the selected string when a range-length or equivalent non-content check is available.

#### Synthetic Copy

- FR-29: For an eligible candidate, the helper must post the equivalent of one `Command-C` key-down/key-up sequence to the active user session.
- FR-30: Synthetic copy must occur only after the original selection event has passed through and the selection has had an opportunity to commit.
- FR-31: The helper must not read, transform, store, restore, upload, or otherwise process the resulting pasteboard content.
- FR-32: Failure to post the synthetic event must be recorded as a content-free diagnostic event and must not be retried more than once for the gesture.

#### Permissions and Recovery

- FR-33: On first run, the helper must check Accessibility and Input Monitoring authorization before enabling monitoring.
- FR-34: Missing permissions must prevent activation and produce clear instructions that identify the helper application requiring access.
- FR-35: The onboarding experience must provide a direct route to the relevant System Settings panes where supported.
- FR-36: If permission is revoked at runtime, the helper must disable and tear down the event tap safely rather than continuing in a degraded state.
- FR-37: Re-enabling after permission recovery must not require reinstalling the Raycast extension or helper.

#### Privacy and Diagnostics

- FR-38: The product must operate without network access.
- FR-39: Logs must never contain selected text, clipboard contents, typed characters, secure-field values, or a history of application usage.
- FR-40: Permitted diagnostic fields are limited to timestamps, state transitions, permission state, coarse gesture classification, non-content error codes, and helper version.
- FR-41: Diagnostic logging must be bounded through rotation or size limits.

### User Experience

#### First run

1. The user installs the helper and imports the Raycast extension.
2. The user invokes `Toggle Copy on Select` or its assigned shortcut.
3. If permissions are missing, the helper presents the one-time onboarding flow and Raycast reports `Setup Required`.
4. The user grants Accessibility and Input Monitoring to the stable helper application.
5. The user invokes the toggle again and sees `Copy on Select: On`.

#### Normal use

1. The user presses the shortcut.
2. Raycast displays the resulting state.
3. While on, supported mouse text selections trigger the target application's normal copy command.
4. The user presses the same shortcut to turn the behavior off.

There is no persistent UI during normal use. Permission or installation failures must be explicit; silent fallback is not acceptable.

### Edge Cases

| Scenario | Expected Behavior |
|---|---|
| User performs an ordinary click | No copy attempt. |
| User drags a window or scrollbar | No copy attempt. |
| User drags a file in Finder | No copy attempt. |
| User double-clicks a selectable word | Copy once after the selection completes. |
| User triple-clicks selectable text | Copy once after the final click selection completes. |
| Drag ends without a non-empty text selection | Skip copy. |
| Focused element is a secure text field | Skip copy and do not read the field. |
| Secure-field status is inconclusive | Skip copy. |
| Target app changes before delayed dispatch | Cancel the candidate. |
| Target app does not expose usable selection metadata | Skip copy in the MVP. |
| Target app ignores or overrides `Command-C` | Record a content-free failure if detectable; do not retry repeatedly. |
| Helper is not running when toggled | Launch once, then retry the request once. |
| Helper is not installed | Show an installation-path error; do not report a false state. |
| Accessibility or Input Monitoring is revoked at runtime | Remove the event tap, mark the feature off, and surface setup guidance on the next command invocation. |
| Event tap is disabled by the system | Attempt one safe recreation if permission remains valid; otherwise disable and report an error. |
| User toggles rapidly | Serialize requests so each accepted invocation produces one deterministic transition. |
| Helper crashes while enabled | macOS may relaunch it; monitoring resumes only after permission and single-instance checks pass. |
| Mac wakes from sleep | Validate permission and event-tap health before resuming. |

## Technical Considerations

### Constraints

- The Raycast process must not be treated as the permanent gesture-monitoring runtime; Raycast commands are transient.
- The persistent component needs a stable identity and installation path so macOS privacy permissions remain attributable across launches and updates.
- The helper requires Accessibility for focused-element inspection and synthetic input, and Input Monitoring for global gesture observation.
- No Screen Recording permission should be required.
- Accessibility support varies across AppKit, WebKit, Chromium, Electron, terminal, PDF, and custom-rendered interfaces.
- The global event callback must remain lightweight. Accessibility queries and delayed dispatch should execute outside the event-tap callback so input is never blocked.
- Disabled means the event tap is absent, not merely that callbacks are ignored.
- The MVP should target macOS 13 or later so the helper can use `SMAppService` for supported login-item management.
- The helper should be signed consistently during testing; rebuilding with an unstable identity may invalidate privacy permissions.

### Integration Points

- Raycast command API: no-view command execution, HUD feedback, platform restriction, and user-assigned shortcut.
- Local helper control channel: one request/response interface supporting at least `toggle`, `status`, and version/error responses.
- macOS Quartz Event Services: listen-only mouse event tap and synthetic keyboard event posting.
- macOS Accessibility API: process trust, focused-element lookup, role/subrole inspection, and selection metadata.
- macOS Service Management: per-user login-item registration and lifecycle.
- macOS privacy controls: Accessibility and Input Monitoring authorization and recovery.

### Architectural Boundaries

- Raycast owns command discovery, shortcut assignment, helper reachability checks, and HUD feedback.
- The helper owns state, permissions, event monitoring, gesture classification, safety checks, and synthetic copy.
- The target application owns selection semantics and actual pasteboard generation, exactly as it does for a physical `Command-C`.
- No component in this product owns clipboard history or content.

### Data Requirements

The helper may persist only:

- enabled/disabled state;
- helper version and schema version;
- bounded content-free diagnostics;
- onboarding completion state if needed.

No selected text, pasteboard payload, application-content snapshot, keystroke history, account information, or analytics identifier may be stored or transmitted. No data migration is required for the MVP. State-file or preferences writes must be atomic enough to survive abrupt termination without producing an ambiguous enabled state.

### Suggested Repository Shape

This is implementation guidance rather than a required final structure.

```text
raycast_ctrl_c/
├── PRD.md
├── raycast-extension/
│   ├── package.json
│   └── src/
│       └── toggle-copy-on-select.ts
├── macos-helper/
│   ├── Package.swift or Xcode project
│   ├── Sources/
│   └── Tests/
└── docs/
    ├── installation.md
    └── qa-matrix.md
```

## Dependencies & Risks

### Dependencies

| Dependency | Owner | Status | Impact if Delayed |
|---|---|---|---|
| Raycast installed with support for local extensions and no-view commands | User | Assumed available | Toggle command cannot run. |
| Xcode/Swift toolchain suitable for the target macOS version | Engineering | To verify | Native helper cannot be built or signed. |
| Stable helper bundle identifier and code-signing identity | Engineering | Decision required before permission QA | Privacy permissions may reset or attach to the wrong binary. |
| macOS Accessibility and Input Monitoring approval | User | Granted during onboarding | Core behavior remains disabled. |
| Representative applications for the compatibility matrix | QA/User | To assemble | Accuracy and false-positive targets cannot be validated. |
| Distribution choice for post-MVP release | Product | Deferred | Does not block local MVP; blocks public release. |

### Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| False-positive gestures overwrite the user's clipboard | Medium | High | Require positive selection evidence, begin with a conservative allow path, and test non-selection gestures extensively. |
| A secure field is not correctly identified | Low-Medium | Critical | Check focused element and ancestors, fail closed on errors, test native/browser/password-manager fields, and never enable broad fallback for ambiguous elements. |
| Accessibility implementations vary by application | High | Medium | Define an explicit compatibility matrix, skip unsupported apps safely, and add adapters only from observed evidence. |
| Synthetic copy fires after focus moves | Medium | High | Bind candidates to the target process and cancel on process/focus change before dispatch. |
| macOS revokes or resets permissions after rebuild/update | Medium | High | Use a stable signed app identity and installation path before final QA; document permission recovery. |
| Event tap blocks or destabilizes input | Low | Critical | Use listen-only mode, return immediately from callbacks, move AX work off-callback, handle tap-disabled events, and tear down on permission changes. |
| Helper remains active when Raycast reports off | Low | High | Make helper state authoritative, require acknowledgement, test 100 rapid and ordinary toggle cycles, and remove the tap rather than gating callbacks. |
| Helper installation makes a public Raycast release cumbersome | High | Medium | Keep public distribution out of MVP; validate companion-app policy and packaging separately. |
| App review rejects or questions the permission model | Medium | Medium | Provide narrow permission explanations, local-only behavior, source transparency, and contact Raycast before public submission. |

## Timeline & Milestones

The schedule is relative and assumes one engineer familiar with Swift but not necessarily with macOS event taps.

| Milestone | Description | Target |
|---|---|---|
| M0: Technical spike | Prove global gesture observation, secure-field lookup, and synthetic `Command-C` in TextEdit and one browser. | End of Day 2 |
| M1: Helper core | Implement single-instance lifecycle, state ownership, event-tap enable/disable, gesture state machine, and unit tests. | End of Week 1 |
| M2: Raycast control | Implement the no-view toggle, helper launch/reachability, authoritative response handling, and HUD states. | Early Week 2 |
| M3: Permissions and persistence | Add stable signing identity, first-run onboarding, runtime permission recovery, login startup, and state restoration. | Mid Week 2 |
| M4: Compatibility hardening | Execute the application and gesture matrices; fix P0 false positives, focus races, and tap-lifecycle failures. | End of Week 2 |
| M5: Local MVP release | Complete privacy review, performance checks, installation documentation, and acceptance test pass. | Start of Week 3 |

### MVP Exit Criteria

- All P0 user stories meet their acceptance criteria.
- Every functional requirement from FR-1 through FR-41 is either verified or explicitly waived with a documented rationale.
- All success-metric targets pass on the reference Mac.
- Secure-field testing records zero synthetic copy attempts.
- The compatibility matrix contains an explicit supported, partially supported, or unsupported verdict for every listed application.
- Installation and permission recovery can be completed from a clean user account using written instructions.

## Open Questions

- [ ] Should the post-MVP product remain a private local extension or target the public Raycast Store? — Owner: Product
- [ ] Is Apple Silicon-only sufficient, or is a universal Apple Silicon/Intel helper required? — Owner: Product
- [ ] Which exact macOS versions must be supported beyond the proposed macOS 13 minimum? — Owner: Product/Engineering
- [ ] Which local IPC mechanism best balances reliable request/response behavior with simple signing and installation? — Owner: Engineering
- [ ] Should the helper restore `On` after login, or always start `Off` despite the last saved state? The current requirement restores the last explicit state. — Owner: Product/Security
- [ ] Should terminal applications be eligible in the MVP if their selection semantics differ from standard text controls? — Owner: Product/QA
- [ ] Should the helper show a one-time native onboarding window, or should all setup guidance be initiated from Raycast? — Owner: Product/Design
- [ ] What diagnostic log retention limit is appropriate for a local MVP? — Owner: Engineering

## Appendix

### Initial Compatibility Matrix

The matrix is a QA commitment, not a guarantee that every application will ultimately be supported.

| Category | Initial Application | Required Scenarios |
|---|---|---|
| Native text editor | TextEdit | Drag, double-click, triple-click, ordinary click, secure-check control |
| Native productivity | Notes | Drag, double-click, focus change before dispatch |
| WebKit browser | Safari | Page text, form text, password field, tab switch race |
| Chromium browser | Google Chrome | Page text, form text, password field, browser chrome exclusion |
| Electron editor | Visual Studio Code | Editor selection, sidebar drag, terminal pane |
| PDF viewer | Preview | Selectable PDF text, page drag, unsupported scanned PDF |
| Terminal | Terminal.app | Drag selection, ordinary click, application-specific copy behavior |
| File manager | Finder | File drag and filename selection must not cause text auto-copy unless explicitly supported |
| Password manager | Installed password manager, if available | Secure/login fields must never trigger synthetic copy |

### Gesture Test Matrix

- Short and long text drags in both directions.
- Double-click, triple-click, and rapid repeated clicks.
- Click without movement.
- Sub-threshold pointer jitter.
- Window, scrollbar, image, link, file, and text dragging.
- Selection followed immediately by application or window switching.
- Toggle off during an in-progress drag.
- Toggle on/off repeatedly and concurrently.
- Sleep/wake and login restoration.
- Permissions granted, missing, and revoked while running.

### Source Notes

- Pluks documents the reference interaction and its use of gesture observation, secure-field checking, and synthetic copy: <https://pluks.app/>
- Raycast documents its transient extension runtime: <https://developers.raycast.com/information/security>
- Raycast background refresh is scheduled rather than a permanent listener: <https://developers.raycast.com/information/lifecycle/background-refresh>
- Raycast LocalStorage is extension-scoped: <https://developers.raycast.com/api-reference/storage>
- Apple documents Quartz Event Services and event taps: <https://developer.apple.com/documentation/coregraphics/quartz-event-services>
- Apple documents Accessibility trust checks: <https://developer.apple.com/documentation/applicationservices/1459186-axisprocesstrustedwithoptions>
- Apple documents the secure text-field subrole: <https://developer.apple.com/documentation/applicationservices/carbon_accessibility/subroles>
- Apple documents `SMAppService` for login items and launch agents on macOS 13 and later: <https://developer.apple.com/documentation/servicemanagement/smappservice>

### Related Documents

- Problem statement: captured in this PRD under Overview.
- User research: not yet conducted; the initial requirement comes from the target user's stated workflow.
- Design specifications: not required for the invisible local MVP beyond the first-run permission experience.
- Technical design: to be created after the M0 spike validates the core macOS APIs.
- QA matrix: to be expanded in `docs/qa-matrix.md` during implementation.
- Community release instructions: [COMMUNITY_RELEASE.md](COMMUNITY_RELEASE.md).

### Revision History

| Version | Date | Author | Changes |
|---|---|---|---|
| 1.0 | 2026-09-17 | Codex | Initial draft based on the agreed Raycast toggle plus persistent Swift helper architecture. |
