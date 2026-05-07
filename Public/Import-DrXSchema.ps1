<#
.SYNOPSIS
Imports a DrX schema file or directory.

.DESCRIPTION
Resolves a schema path, reads one or more YAML schema files, parses them, and
returns the combined schema document used by the rest of the module.

.PARAMETER SchemaPath
Path to a schema file or directory containing schema YAML files.

.EXAMPLE
Import-DrXSchema -SchemaPath './Example'

.INPUTS
None. You cannot pipe input to this function.

.OUTPUTS
hashtable. Returns the parsed schema document.

.NOTES
Author: GitHub Copilot
Version: 0.1.0

.LINK
ConvertTo-DrXNormalizedSchema
#>
function Import-DrXSchema {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$SchemaPath
  )

  $resolvedSchemaPath = Resolve-DrXSchemaPath -SchemaPath $SchemaPath
  $resolvedPath = (Resolve-Path -Path $resolvedSchemaPath -ErrorAction Stop).Path
  $item = Get-Item $resolvedPath
  if ($item.PSIsContainer) {
    $files = Get-ChildItem -Path $resolvedPath -Filter *.y*ml | Sort-Object Name
    if ($files.Count -eq 0) {
      throw "No schema YAML files found in directory: $SchemaPath"
    }

    $parsedSchemas = @()
    foreach ($file in $files) {
      $parsedSchemas += ConvertFrom-DrXSchemaText -Text ([System.IO.File]::ReadAllText($file.FullName))
    }
    return Join-DrXCatalogSchema -ParsedSchemas $parsedSchemas
  }

  return ConvertFrom-DrXSchemaText -Text ([System.IO.File]::ReadAllText($resolvedPath))
}
