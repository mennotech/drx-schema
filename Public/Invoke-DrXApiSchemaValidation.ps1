<#
.SYNOPSIS
Validates the schema against the internal API contract.

.DESCRIPTION
Runs the internal API schema validation workflow for the supplied schema and
backend compose service settings. Results are returned as a table by default,
or as JSON or CSV when the OutputFormat parameter is specified.

.PARAMETER SchemaPath
Optional path to a schema file or directory.

.PARAMETER ComposeService
The compose service name for the backend container.

.PARAMETER EnvFile
Optional path to the environment file used for backend settings.

.PARAMETER OutputFormat
The format used to render validation results. Accepted values are Table (default),
Json, and Csv.

.EXAMPLE
Invoke-DrXApiSchemaValidation -SchemaPath './Example/Schema' -ComposeService 'backend' -EnvFile '.env'

.EXAMPLE
Invoke-DrXApiSchemaValidation -EnvFile '.env' -OutputFormat Json

.EXAMPLE
Invoke-DrXApiSchemaValidation -EnvFile '.env' -OutputFormat Csv

.INPUTS
None. You cannot pipe input to this function.

.OUTPUTS
pscustomobject[]. Returns per-bundle validation results as objects (Table), a JSON string (Json), or a CSV string (Csv).

.NOTES
Author: GitHub Copilot
Version: 0.1.0

.LINK
Invoke-DrXExternalApiSchemaValidation
#>
function Invoke-DrXApiSchemaValidation {
  [CmdletBinding()]
  param(
    [string]$SchemaPath = $null,
    [string]$ComposeService = 'backend',
    [string]$EnvFile,
    [ValidateSet('Table', 'Json', 'Csv')]
    [string]$OutputFormat = 'Table'
  )

  Write-Information 'Starting internal API schema validation...' -InformationAction Continue
  Write-Verbose "Schema path: $(if ($SchemaPath) { $SchemaPath } else { '(from default)' })"
  Write-Verbose "Compose service: $ComposeService"

  $validationResult = Invoke-DrXInternalApiSchemaValidation -SchemaPath $SchemaPath -ComposeService $ComposeService -EnvFile $EnvFile
  $results = @($validationResult.Results)

  $passCount = ($results | Where-Object { $_.Status -eq 'ok' }).Count
  $total = $results.Count
  Write-Information "Internal API validation complete: $passCount/$total bundles passed." -InformationAction Continue

  foreach ($result in $results) {
    Write-Verbose "  Bundle '$($result.Bundle)': $($result.Status)"
    if ($result.Message) {
      Write-Debug "    Error: $($result.Message)"
    }
  }

  if ($validationResult.Failed) {
    $failures = @($results | Where-Object { $_.Status -eq 'error' } | ForEach-Object { '{0}: {1}' -f $_.Bundle, $_.Message })
    throw ('Internal API schema validation failed: ' + ($failures -join '; '))
  }

  switch ($OutputFormat) {
    'Json' { return $results | ConvertTo-Json -Depth 10 }
    'Csv' { return $results | ConvertTo-Csv -NoTypeInformation }
    default { return $results }
  }
}
