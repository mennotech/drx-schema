<#
.SYNOPSIS
Validates schema CRUD behavior against the backing database.

.DESCRIPTION
Runs the database-oriented schema CRUD validation workflow for the supplied
schema and backend compose service. Results are returned as a table by default,
or as JSON or CSV when the OutputFormat parameter is specified.

.PARAMETER SchemaPath
Optional path to a schema file or directory.

.PARAMETER ComposeService
The compose service name for the backend container.

.PARAMETER OutputFormat
The format used to render validation results. Accepted values are Table (default),
Json, and Csv.

.EXAMPLE
Invoke-DrXSchemaCrudValidation -SchemaPath './Example/Schema' -ComposeService 'backend'

.EXAMPLE
Invoke-DrXSchemaCrudValidation -ComposeService 'backend' -OutputFormat Json

.EXAMPLE
Invoke-DrXSchemaCrudValidation -ComposeService 'backend' -OutputFormat Csv

.INPUTS
None. You cannot pipe input to this function.

.OUTPUTS
pscustomobject[]. Returns per-bundle validation results as objects (Table), a JSON string (Json), or a CSV string (Csv).

.NOTES
Author: GitHub Copilot
Version: 0.1.0

.LINK
Invoke-DrXApiSchemaValidation
#>
function Invoke-DrXSchemaCrudValidation {
  [CmdletBinding()]
  param(
    [string]$SchemaPath = $null,
    [string]$ComposeService = 'backend',
    [ValidateSet('Table', 'Json', 'Csv')]
    [string]$OutputFormat = 'Table'
  )

  Write-Information 'Starting CRUD schema validation...' -InformationAction Continue
  Write-Verbose "Schema path: $(if ($SchemaPath) { $SchemaPath } else { '(from default)' })"
  Write-Verbose "Compose service: $ComposeService"

  $validationResult = Invoke-DrXDbSchemaValidation -SchemaPath $SchemaPath -ComposeService $ComposeService
  $results = @($validationResult.Results)

  $passCount = ($results | Where-Object { $_.Status -eq 'ok' }).Count
  $total = $results.Count
  Write-Information "CRUD validation complete: $passCount/$total bundles passed." -InformationAction Continue

  foreach ($result in $results) {
    Write-Verbose "  Bundle '$($result.Bundle)': $($result.Status)"
    if ($result.Message) {
      Write-Debug "    Error: $($result.Message)"
    }
  }

  switch ($OutputFormat) {
    'Json' { return $results | ConvertTo-Json -Depth 10 }
    'Csv' { return $results | ConvertTo-Csv -NoTypeInformation }
    default { return $results }
  }
}
