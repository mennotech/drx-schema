<#
.SYNOPSIS
Generates Drupal configuration files from a DrX schema.

.DESCRIPTION
Imports and normalizes a schema, then writes Drupal node, field, and display
configuration files for each bundle into the target output directory.

.PARAMETER SchemaPath
Optional path to a schema file or directory.

.PARAMETER OutputDir
The directory where generated Drupal configuration files will be written.

.EXAMPLE
Export-DrXDrupalScaffoldConfig -SchemaPath './Example' -OutputDir './out/config'

.INPUTS
None. You cannot pipe input to this function.

.OUTPUTS
pscustomobject. Returns the output directory, written bundles, and field count.

.NOTES
Author: GitHub Copilot
Version: 0.1.0

.LINK
Import-DrXSchema
#>
function Export-DrXDrupalScaffoldConfig {
  [CmdletBinding()]
  param(
    [string]$SchemaPath = $null,
    [string]$OutputDir = (Join-Path $PSScriptRoot '..\..\backend\config\generated')
  )

  $normalizedSchema = ConvertTo-DrXNormalizedSchema -ParsedSchema (Import-DrXSchema -SchemaPath $SchemaPath)
  if (-not $normalizedSchema['bundles'] -or @($normalizedSchema['bundles']).Count -eq 0) {
    throw 'No bundles found in schema input.'
  }

  $resolvedOutputDir = [System.IO.Path]::GetFullPath($OutputDir)
  [System.IO.Directory]::CreateDirectory($resolvedOutputDir) | Out-Null

  $bundleMap = @{}
  foreach ($bundle in @($normalizedSchema['bundles'])) {
    $bundleMap[$bundle['machine_name']] = $bundle
  }

  $writtenFields = [System.Collections.Generic.HashSet[string]]::new()
  $writtenBundles = [System.Collections.ArrayList]::new()

  foreach ($bundle in @($normalizedSchema['bundles'])) {
    $nodeTypeFile = Join-Path $resolvedOutputDir "node.type.$($bundle['machine_name']).yml"
    Set-DrXUtf8File -Path $nodeTypeFile -Content ((ConvertTo-DrXYaml -Value (New-DrXNodeTypeConfig -Bundle $bundle)) + "`n")
    [void]$writtenBundles.Add($bundle['machine_name'])

    $fieldEntries = [System.Collections.ArrayList]::new()
    foreach ($entry in (Get-DrXBundleFieldEntry -Bundle $bundle -BundleMap $bundleMap)) {
      $field = $entry['field']
      $fieldName = Get-DrXFieldName ($field['key'])
      $mapping = Get-DrXFieldMapping -Field $field
      $storage = New-DrXStorageConfig -FieldName $fieldName -Mapping $mapping -Field $field
      $instance = New-DrXInstanceConfig -Bundle $bundle['machine_name'] -FieldName $fieldName -Field $field -Mapping $mapping -Section $entry['section']

      if (-not $writtenFields.Contains($fieldName)) {
        $storagePath = Join-Path $resolvedOutputDir "field.storage.node.$fieldName.yml"
        Set-DrXUtf8File -Path $storagePath -Content ((ConvertTo-DrXYaml -Value $storage) + "`n")
        [void]$writtenFields.Add($fieldName)
      }

      $instancePath = Join-Path $resolvedOutputDir "field.field.node.$($bundle['machine_name']).$fieldName.yml"
      Set-DrXUtf8File -Path $instancePath -Content ((ConvertTo-DrXYaml -Value $instance) + "`n")

      [void]$fieldEntries.Add([ordered]@{ section = $entry['section']; field = $field; mapping = $mapping })
    }

    $formDisplayPath = Join-Path $resolvedOutputDir "core.entity_form_display.node.$($bundle['machine_name']).default.yml"
    Set-DrXUtf8File -Path $formDisplayPath -Content ((ConvertTo-DrXYaml -Value (New-DrXEntityFormDisplayConfig -Bundle $bundle -FieldEntries @($fieldEntries))) + "`n")

    $viewDisplayPath = Join-Path $resolvedOutputDir "core.entity_view_display.node.$($bundle['machine_name']).default.yml"
    Set-DrXUtf8File -Path $viewDisplayPath -Content ((ConvertTo-DrXYaml -Value (New-DrXEntityViewDisplayConfig -Bundle $bundle -FieldEntries @($fieldEntries))) + "`n")
  }

  return [pscustomobject]@{
    OutputDir = $resolvedOutputDir
    Bundles = @($writtenBundles)
    FieldCount = $writtenFields.Count
  }
}
