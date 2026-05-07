<#
.SYNOPSIS
Validates schema CRUD behavior against the backing database.

.DESCRIPTION
Runs the database-oriented schema CRUD validation workflow for the supplied
schema and backend compose service.

.PARAMETER SchemaPath
Optional path to a schema file or directory.

.PARAMETER ComposeService
The compose service name for the backend container.

.EXAMPLE
Invoke-DrXSchemaCrudValidation -SchemaPath './Example/Schema' -ComposeService 'backend'

.INPUTS
None. You cannot pipe input to this function.

.OUTPUTS
object. Returns the result from the database validation command.

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
    [string]$ComposeService = 'backend'
  )

  return Invoke-DrXDbSchemaValidation -SchemaPath $SchemaPath -ComposeService $ComposeService
}
