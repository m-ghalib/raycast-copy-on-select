# Compatibility

This document holds the application compatibility matrix for Copy on Select version
`1.0.0`.

## System requirements

| Item | Value |
|---|---|
| Minimum operating system | macOS 13.0 |
| Architecture | Apple silicon (`arm64`) and Intel (`x86_64`) |
| Raycast | A version with support for no-view commands |

## Verdict legend

| Verdict | Meaning |
|---|---|
| Supported | Every required scenario passed. The application copies reliably. |
| Partially supported | At least one required scenario passed and at least one failed. The document names the limit. |
| Unsupported | A required scenario failed in a way that blocks safe use. The product skips the application or produces wrong results. |
| Untested | No release QA pass exists for this application yet. |

## Application matrix

Every row is `Untested`. Release QA fills in the verdict column.

| Category | Application | Required scenarios | Verdict |
|---|---|---|---|
| Native text editor | TextEdit | Drag, double-click, triple-click, ordinary click, secure-field control | Untested |
| Native productivity | Notes | Drag, double-click, focus change before dispatch | Untested |
| WebKit browser | Safari | Page text, form text, password field, tab switch race | Untested |
| Chromium browser | Google Chrome | Page text, form text, password field, browser chrome exclusion | Untested |
| Electron editor | Visual Studio Code | Editor selection, sidebar drag, terminal pane | Untested |
| PDF viewer | Preview | Selectable PDF text, page drag, unsupported scanned PDF | Untested |
| Terminal | Terminal.app | Drag selection, ordinary click, application-specific copy behavior | Untested |
| File manager | Finder | File drag and filename selection must not cause an automatic copy | Untested |
| Password manager | Installed password manager | Secure and login fields must never trigger a synthetic copy | Untested |

## Failure behavior

An application without usable Accessibility selection metadata fails closed. The
product skips the copy in that application. The clipboard keeps its previous content.

The product uses no broad copy fallback. A fallback overwrites the clipboard after a
gesture that produced no text selection. That risk is not acceptable.

A secure text field always fails closed. An Accessibility error, a timeout, or an
inconclusive result also fails closed.

## Known limits across all applications

- Keyboard selections do not trigger a copy. Examples are `Shift-Arrow` and `Command-A`.
- Shift-click range extension does not trigger a copy.
- A context-menu selection does not trigger a copy.
- A non-text selection does not trigger a copy. Examples are images, files, table cells,
  and canvas objects.
- An application that overrides `Command-C` with a non-standard action produces a
  non-standard result. The product posts the same key sequence as a physical key press.

## Report a result

To add an application to this matrix, open an issue at
<https://github.com/m-ghalib/raycast-copy-on-select/issues>. Include the application
name, the application version, the macOS version, the gesture, and the result. Do not
include sensitive text.
