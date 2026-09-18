# Community Release Guide

This guide covers sharing Raycast Copy-on-Select beyond a local development machine. The product has two separately distributed parts:

1. A native macOS helper requiring Accessibility and Input Monitoring permission.
2. A Raycast extension that controls the installed helper.

Publish and verify the helper before submitting an extension version that depends on it. The Raycast Store distributes the extension, not the companion application.

## Recommended Release Sequence

| Stage | Audience | Distribution | Exit Condition |
|---|---|---|---|
| Private alpha | Developer and invited technical testers | Direct helper build plus locally imported Raycast extension | Core acceptance tests pass on at least two Macs. |
| Public beta | Opt-in GitHub users | Signed/notarized helper release plus extension source and local import instructions | Permission onboarding, updates, and uninstall instructions work from a clean account. |
| Raycast Store release | Raycast community | Raycast Store extension plus linked helper download | Raycast review passes and the public helper release is stable. |

Do not use public testers to discover whether the helper can be signed, notarized, launched, or granted permissions. Resolve those packaging fundamentals during private alpha.

## 1. Prepare the Project for Public Use

Before inviting testers:

- Choose a permanent product name and reverse-DNS helper bundle identifier.
- Choose a public source repository and an MIT license for the Raycast extension.
- Document which parts are open source if the helper and extension use different licenses or repositories.
- Add a security contact or `SECURITY.md` describing how to report vulnerabilities privately.
- Add a privacy statement confirming that the product does not read, retain, transmit, or analyze selected text or clipboard contents.
- Add screenshots or a short recording showing the shortcut, on/off HUD, text selection, and secure-field rejection without exposing real credentials.
- Document the supported macOS versions, processor architectures, Raycast version, known unsupported applications, and current compatibility matrix.
- Ensure the helper and extension use semantic versions and expose enough version information to diagnose incompatible combinations.

Recommended public repository material:

```text
README.md
PRIVACY.md
SECURITY.md
LICENSE
CHANGELOG.md
docs/
├── installation.md
├── permissions.md
├── troubleshooting.md
├── uninstall.md
└── compatibility.md
```

## 2. Contact Raycast Before Store Submission

The extension depends on a separately installed program and causes that program to request sensitive macOS permissions. Before investing in final Store assets, send Raycast a concise pre-submission description through its developer community or support channel containing:

- the user problem and exact copy-on-select behavior;
- why a persistent native process is required;
- why Accessibility and Input Monitoring are required;
- confirmation that Screen Recording is not required;
- confirmation that selected text and clipboard contents are never read, logged, or transmitted;
- the helper's source and download URLs;
- the installation, update, and uninstall flow;
- a request to confirm that the companion-helper model is acceptable for Store review.

Raycast's guidance permits extensions to depend on locally installed applications or command-line tools, but expects the extension to detect missing dependencies and show helpful guidance. Treat pre-submission confirmation as a release gate because this permission model is more sensitive than an ordinary integration.

## 3. Sign the Native Helper

Community distribution should use a stable Developer ID identity rather than an ad hoc or development signature. A stable identity makes Gatekeeper verification possible and reduces unexpected macOS privacy-permission resets.

Prerequisites:

- Active Apple Developer Program membership.
- A permanent bundle identifier.
- A `Developer ID Application` certificate.
- Hardened Runtime enabled for the app and all executable targets.
- Release entitlements containing only capabilities the helper actually needs.
- `LSUIElement` configuration if the helper should have no Dock presence.

Build a release archive with Xcode and export a Developer ID-signed application. Verify every nested executable is signed by the expected team:

```bash
codesign --verify --deep --strict --verbose=2 "/path/to/RaycastCopySelect.app"
codesign -dv --verbose=4 "/path/to/RaycastCopySelect.app"
```

Review the output locally. Do not paste signing identities, credentials, or notarization secrets into issues or release logs.

Official references:

- [Signing Mac software with Developer ID](https://developer.apple.com/developer-id/)
- [Creating distribution-signed code for macOS](https://developer.apple.com/documentation/xcode/creating-distribution-signed-code-for-the-mac)

## 4. Notarize and Package the Helper

Use a DMG for the first community release. It provides a familiar drag-to-Applications flow and supports stapling the notarization ticket directly.

1. Put the signed `.app` in a release DMG with a visible `/Applications` shortcut.
2. Submit the DMG through Xcode Organizer or `xcrun notarytool`.
3. Wait for acceptance and review the complete notary log, including warnings.
4. Staple the ticket to the DMG.
5. Validate the stapled ticket and Gatekeeper assessment.

Example verification commands, using the actual release path:

```bash
xcrun stapler validate "/path/to/RaycastCopySelect.dmg"
spctl --assess --type open --context context:primary-signature --verbose=4 "/path/to/RaycastCopySelect.dmg"
```

Apple requires Developer ID-distributed software built for modern macOS to be notarized and recommends testing the final packaged artifact on a different Mac. The outer distribution container should be the artifact submitted for notarization.

Official references:

- [Notarizing macOS software before distribution](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
- [Packaging Mac software for distribution](https://developer.apple.com/documentation/xcode/packaging-mac-software-for-distribution)

## 5. Publish a Helper Release

Create a versioned GitHub Release only after verifying the exact DMG intended for users.

Attach:

- the signed, notarized, and stapled DMG;
- a SHA-256 checksum file;
- release notes covering behavior, compatibility, known limitations, and security-relevant changes;
- installation, permission, update, and uninstall instructions.

The installation guide should tell users to:

1. Download the DMG from the canonical release page.
2. Verify the SHA-256 checksum if desired.
3. Drag the app to `/Applications`.
4. Launch it once to register its login item and begin permission onboarding.
5. Grant Accessibility and Input Monitoring to the named helper app.
6. Install the Raycast extension.
7. Assign a Raycast shortcut to `Toggle Copy on Select`.
8. Test with non-sensitive text before relying on it.

Do not ask users to bypass Gatekeeper, remove quarantine attributes, disable macOS protections, or run a remote install script with elevated privileges.

## 6. Prepare the Raycast Extension

The extension should be reviewable independently of the helper binary. Before submission:

- Restrict the platform to macOS in `package.json`.
- Use a clear name, description, 512-by-512 icon, author, category, and MIT license.
- Keep the user-facing command in `no-view` mode.
- Confirm the command detects all of these states:
  - helper missing;
  - helper installed but not running;
  - setup permission missing;
  - helper too old;
  - toggle successful;
  - helper returned an invalid or timed-out response.
- On missing-helper errors, offer to open the canonical HTTPS installation page. Do not silently download, install, or replace the helper.
- Explain the two permissions in the extension README and Store metadata.
- Link directly to privacy, source, security-reporting, and uninstall documentation.
- Include no secrets, signing material, private download tokens, machine-specific paths, or generated binary artifacts.
- Run lint and distribution builds against the current Raycast API.

Typical validation commands:

```bash
npm ci
npm run lint
npm run build
```

Manually import and test the resulting extension with the exact public helper release, not a development helper.

## 7. Submit to the Raycast Store

Raycast's supported publishing path creates a pull request in the public `raycast/extensions` repository.

1. Sign in to Raycast and GitHub with the intended maintainer accounts.
2. Ensure the extension's `package.json` contains:

   ```json
   {
     "scripts": {
       "publish": "npx @raycast/api@latest publish"
     }
   }
   ```

3. From the extension directory, run:

   ```bash
   npm run build
   npm run publish
   ```

4. Authenticate with GitHub when prompted.
5. Review the generated pull request and complete its checklist.
6. In the pull-request description, disclose the companion-helper requirement and link the exact public release tested.
7. Respond to reviewer questions and publish updated commits by running `npm run publish` again when appropriate.
8. After approval and merge, install the Store version on a clean account and repeat the release smoke test.

If the automated publisher does not suit the repository setup, fork `raycast/extensions`, add the extension in the correct directory, and open a pull request to its `main` branch manually.

Official references:

- [Prepare an Extension for Store](https://developers.raycast.com/basics/prepare-an-extension-for-store)
- [Publish an Extension](https://developers.raycast.com/basics/publish-an-extension)
- [Raycast best practices for runtime dependencies](https://developers.raycast.com/information/best-practices)

## 8. Community-Release QA Gate

Test the final public artifacts from a clean macOS user account or, preferably, a separate Mac. Do not count a development-machine pass as distribution verification.

The release is ready only when all checks pass:

- [ ] The downloaded DMG passes Gatekeeper assessment.
- [ ] The DMG has a valid stapled notarization ticket.
- [ ] The helper installs by dragging it to `/Applications`.
- [ ] The helper name shown in Accessibility and Input Monitoring matches the documentation.
- [ ] Permissions survive helper quit/relaunch and system restart.
- [ ] The login item can be enabled, disabled, and uninstalled cleanly.
- [ ] The Raycast Store build finds the public helper release.
- [ ] The toggle HUD always reflects helper-owned state.
- [ ] Secure-field tests produce zero synthetic copy attempts.
- [ ] Unsupported applications fail closed without overwriting the clipboard.
- [ ] Offline operation works after installation.
- [ ] No request leaves the machine during normal operation.
- [ ] Logs contain no selected text, clipboard contents, typed characters, or credentials.
- [ ] The documented uninstall process removes the login item and helper without leaving a running process.

## 9. Announce It Responsibly

After Raycast publishes the extension:

1. In Raycast, open `Manage Extensions`.
2. Find the extension and use `Command-Option-.` to copy its Store link.
3. Publish a concise launch post in the Raycast community, the project's GitHub repository, and relevant macOS productivity communities.

Every announcement should state:

- what happens: selecting supported text automatically invokes normal copy;
- how to stop it: run the same Raycast shortcut to toggle it off;
- which permissions are required and why;
- that the helper does not read, retain, or transmit clipboard contents;
- the supported macOS versions and known compatibility limits;
- where to report bugs and security concerns;
- where to inspect source code and download the canonical helper.

Avoid claiming universal application support. Publish the tested compatibility matrix and distinguish `supported`, `partially supported`, and `unsupported` applications.

## 10. Maintain Community Trust

For every release:

- Publish the helper before any extension version that requires it.
- Never reuse a version number for a different binary.
- Preserve stable bundle and signing identities.
- Update the changelog and compatibility matrix.
- Repeat notarization, Gatekeeper, permission, and secure-field tests.
- Keep the previous compatible helper available until the extension migration is complete.
- Give security fixes explicit release notes without exposing users before a fix is available.
- Monitor Raycast review feedback, GitHub issues, and macOS release changes affecting event taps or privacy permissions.
- If a release introduces a safety regression, remove or disable the affected extension version and publish clear remediation steps.

The public release is complete only when a new user can discover the Store extension, install the canonical helper, understand the permissions, toggle the feature, and uninstall both parts without developer assistance.
