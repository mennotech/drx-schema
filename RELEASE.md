# Release Guide

## Release Targets

- Immutable release tag: `v0.1.0`
- Moving major tag for consumers: `v0`

Consumers that pin this repository should prefer the major tag unless they need an exact patch release:

```powershell
Import-Module ./DrX-Schema.psd1
```

If you reference the repository from automation, prefer `v0` over a full patch tag until a stable `v1` is introduced.

## Release Checklist

1. Update `ModuleVersion` in `DrX-Schema.psd1` for the release.
2. Review exported functions in `DrX-Schema.psd1` and confirm the public API matches the intended release scope.
3. Update `README.md` if usage, requirements, or public commands changed.
4. Confirm the repository still imports cleanly from a fresh checkout with `Import-Module ./DrX-Schema.psd1 -Force` and does not rely on uncommitted local files.
5. Run script analysis locally with `Invoke-ScriptAnalyzer -Path . -Settings ./PSScriptAnalyzerSettings.psd1`.
6. Run the focused test suite with `Invoke-Pester -Path ./Tests/DrX-Schema.Tests.ps1`.
7. Generate scaffold output from `./Example/Schema` into `./Example/DrupalConfig` and verify the command succeeds from a clean working tree.
8. If this release changes normalization, bundle naming, or scaffold generation, compare generated output against the previous release and document the downstream impact.
9. Verify example schema files still reflect the current module behavior.
10. Validate the release from the perspective of a consuming Drupal build or deployment pipeline that checks out this repository by tag.
11. Merge the release branch to `main`.
12. Create and push annotated tag `v0.1.0` on the release commit.
13. Create or update tag `v0` to point to the same release commit.
14. Publish a GitHub Release using the `v0.1.0` notes.

## Suggested Release Commands

Run these after the release commit is on `main`:

```powershell
git checkout main
git pull --ff-only origin main
git tag -a v0.1.0 -m "drx-schema v0.1.0"
git tag -f -a v0 -m "drx-schema v0"
git push origin v0.1.0
git push origin v0 --force
```

If you prefer not to force-push tags, delete and recreate `v0` only when intentionally advancing the major tag.

## Build Integration Checks

- Test the tagged release from a clean clone rather than an existing developer checkout.
- Confirm the repository layout expected by consumers is unchanged: `DrX-Schema.psd1`, `DrX-Schema.psm1`, `Public/`, `Private/`, `Example/Schema/`, `Example/DrupalConfig/`, and `PSScriptAnalyzerSettings.psd1` should remain in stable locations.
- Verify PowerShell 7 is still sufficient and document any new module or runtime prerequisites in `README.md`.
- Run at least one end-to-end consumer flow that mirrors the Drupal site build, such as importing the module and running `Export-DrXDrupalScaffoldConfig -SchemaPath ./Example/Schema -OutputDir ./Example/DrupalConfig`.
- If downstream builds commit generated Drupal YAML, inspect the diff produced by the new release and call out any intentional changes in release notes.
- Avoid renaming exported functions, manifest files, or top-level paths in a patch release because build scripts often reference them directly.

## Compatibility

- `v0` may still change in backward-incompatible ways while the module is pre-1.0.
- Breaking changes to exported functions, schema normalization behavior, or generated scaffold structure should be called out explicitly in release notes.
- Additive public commands, optional parameters, and internal implementation changes can ship in minor or patch releases when they do not break existing consumers.

For Drupal build consumers, compatibility also includes stable generated config naming, stable output file layout, and predictable module import behavior from a tagged checkout.

## Release Notes Scope

For `v0.1.0`, the release notes should call out:

- Initial PowerShell 7 module release for DrX schema tooling
- Schema import and normalization commands
- Drupal scaffold config generation support
- Backend connectivity and validation commands for smoke, API, external API, and CRUD checks
- Example schema and focused Pester coverage included in the repository
- Any downstream Drupal build implications, especially changes to generated YAML names, paths, or required release consumption steps

## Consumer Tagging

Consumers that vendor or pin this repository should reference a major tag rather than a full patch tag unless they need strict pinning.

Use `v0` while the module remains in the `0.x` phase. Move consumers to a `v1` tag once the public API is stable.
