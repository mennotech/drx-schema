# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and this project follows semantic versioning as release tags are introduced.

## [0.1.0] - 2026-05-07

Initial tagged release of `DrX-Schema`.

### Added

- PowerShell 7 module manifest and root module loading for public and private functions.
- Schema import and normalization commands for DrX YAML bundles.
- Drupal scaffold config generation for node types, fields, form displays, and view displays.
- Backend-oriented validation commands covering smoke, API schema, external API schema, and CRUD validation flows.
- Example schema documents for local testing and reference.
- Focused Pester coverage for module exports, help content, schema parsing, and lint integration.

### Compatibility

- Consumers can pin the initial release with tag `v0.1.0`.
- Major moving tag `v0` should be treated as pre-1.0 and may include breaking changes between minor releases.
- Downstream Drupal site builds should review generated scaffold output when adopting a new release.