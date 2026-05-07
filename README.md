# DrX-Schema

`DrX-Schema` is a PowerShell 7 module for importing DrX schema YAML, normalizing it into a bundle model, generating Drupal scaffold config, and validating backend behavior against that schema.

## Requirements

- PowerShell 7 or newer
- A schema file or directory containing `.yml` or `.yaml` files
- A `.env` file with backend settings for commands that talk to Drupal

Expected `.env` values for backend commands:

```env
BACKEND_URL=http://localhost
DRUPAL_ADMIN_USER=admin
DRUPAL_ADMIN_PASS=admin
DRX_SCHEMA_PATH=Example/Schema
```

If `DRX_SCHEMA_PATH` is set, schema commands can omit `-SchemaPath` and resolve the schema location from the `.env` file.

## Import The Module

From the repository root:

```powershell
Import-Module ./DrX-Schema.psd1 -Force
```

The sample schema used by the tests lives in `./Example/Schema`.

Generated Drupal scaffold snapshots for release validation live in `./Example/DrupalConfig`.

## Typical Workflow

```powershell
$parsed = Import-DrXSchema -SchemaPath ./Example/Schema
$normalized = ConvertTo-DrXNormalizedSchema -ParsedSchema $parsed
$bundles = Get-DrXSchemaBundle -SchemaPath ./Example/Schema

$bundles | Format-Table
```

With a local `.env` file:

```powershell
$parsed = Import-DrXSchema -EnvFile ./.env
Invoke-DrXApiSchemaValidation -EnvFile ./.env
```

## Public Functions

### Import-DrXSchema

Reads a schema file or directory and returns the parsed schema document.

```powershell
$schema = Import-DrXSchema -SchemaPath ./Example/Schema
$schema.catalog.reusable_bundles.Count
```

Use this when you want the raw parsed schema before any normalization.

### ConvertTo-DrXNormalizedSchema

Converts the parsed schema into the normalized bundle structure used by the rest of the module.

```powershell
$parsed = Import-DrXSchema -SchemaPath ./Example/Schema
$normalized = ConvertTo-DrXNormalizedSchema -ParsedSchema $parsed
$normalized.bundles | Select-Object machine_name, label, kind
```

Use this when you need consistent bundle names, sections, and field structures.

### Get-DrXSchemaBundle

Returns the unique normalized bundles defined by a schema.

```powershell
Get-DrXSchemaBundle -SchemaPath ./Example/Schema |
  Format-Table Bundle, Label, Kind
```

Use this for quick inspection of what the schema defines.

### Export-DrXDrupalScaffoldConfig

Generates Drupal configuration files for the schema into an output directory.

```powershell
Export-DrXDrupalScaffoldConfig -SchemaPath ./Example/Schema -OutputDir ./Example/DrupalConfig
```

The command writes node type, field storage, field instance, form display, and view display YAML files.

### Connect-DrXBackend

Authenticates against the configured Drupal backend and returns a session object plus connection metadata.

```powershell
$connection = Connect-DrXBackend -EnvFile ./.env
$connection.BaseUrl
$connection.CsrfToken
```

Use this when you want to script authenticated backend calls yourself.

### Invoke-DrXApiSmokeTest

Checks basic backend connectivity by logging in, fetching a CSRF token, and reading the JSON:API index.

```powershell
Invoke-DrXApiSmokeTest -EnvFile ./.env
```

Use this first when backend-dependent commands are failing.

### Invoke-DrXExternalApiSchemaValidation

Validates schema bundles through the external JSON:API surface by creating, reading, updating, and deleting fixtures.

```powershell
Invoke-DrXExternalApiSchemaValidation -SchemaPath ./Example/Schema -EnvFile ./.env
```

Use this to confirm that the exposed JSON:API behavior matches the schema.

### Invoke-DrXApiSchemaValidation

Runs the internal API schema validation workflow against the backend container.

```powershell
Invoke-DrXApiSchemaValidation -SchemaPath ./Example/Schema -ComposeService backend -EnvFile ./.env
```

Use this when validating the internal API contract generated from the schema.

### Invoke-DrXSchemaCrudValidation

Runs database-oriented CRUD validation for the schema against the backend container.

```powershell
Invoke-DrXSchemaCrudValidation -SchemaPath ./Example/Schema -ComposeService backend
```

Use this to validate persistence behavior below the API layer.

## Validation

Run the focused test suite from the repository root:

```powershell
Invoke-Pester -Path ./Tests/DrX-Schema.Tests.ps1
```

If backend integration commands fail, verify that:

- the backend is running
- the `.env` file exists and contains valid credentials
- `BACKEND_URL` points at the correct Drupal instance