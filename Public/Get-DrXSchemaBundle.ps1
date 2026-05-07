<#
.SYNOPSIS
Lists bundles defined by a DrX schema.

.DESCRIPTION
Imports and normalizes a schema, then returns the unique bundle records that it
defines for downstream generation or validation tasks.

.PARAMETER SchemaPath
Optional path to a schema file or directory.

.EXAMPLE
Get-DrXSchemaBundle -SchemaPath './Example'

.INPUTS
None. You cannot pipe input to this function.

.OUTPUTS
pscustomobject[]. Returns normalized bundle records.

.NOTES
Author: GitHub Copilot
Version: 0.1.0

.LINK
ConvertTo-DrXNormalizedSchema
#>
function Get-DrXSchemaBundle {
  [OutputType([object[]])]
  [CmdletBinding()]
  param(
    [string]$SchemaPath
  )

  $normalizedSchema = ConvertTo-DrXNormalizedSchema -ParsedSchema (Import-DrXSchema -SchemaPath $SchemaPath)
  return @($normalizedSchema['bundles'] | ForEach-Object {
    [pscustomobject]@{
      SchemaMachineName = $_['machine_name']
      Bundle = $_['machine_name']
      Label = $_['label']
      Kind = $_['kind']
    }
  } | Sort-Object Bundle -Unique)
}
