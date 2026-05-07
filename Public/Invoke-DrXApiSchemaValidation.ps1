<#
.SYNOPSIS
Validates the schema against the internal API contract.

.DESCRIPTION
Runs the internal API schema validation workflow for the supplied schema and
backend compose service settings.

.PARAMETER SchemaPath
Optional path to a schema file or directory.

.PARAMETER ComposeService
The compose service name for the backend container.

.PARAMETER EnvFile
Optional path to the environment file used for backend settings.

.EXAMPLE
Invoke-DrXApiSchemaValidation -SchemaPath './Example' -ComposeService 'backend' -EnvFile '.env'

.INPUTS
None. You cannot pipe input to this function.

.OUTPUTS
object. Returns the result from the internal API validation command.

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
    [string]$EnvFile
  )

  return Invoke-DrXInternalApiSchemaValidation -SchemaPath $SchemaPath -ComposeService $ComposeService -EnvFile $EnvFile
}
