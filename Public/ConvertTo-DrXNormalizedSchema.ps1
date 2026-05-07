<#
.SYNOPSIS
Normalizes parsed DrX schema data into the module's bundle structure.

.DESCRIPTION
Transforms parsed catalog schema content into the normalized structure consumed by
the scaffold generation and validation commands.

.PARAMETER ParsedSchema
The parsed schema object returned by Import-DrXSchema.

.EXAMPLE
$parsedSchema = Import-DrXSchema -SchemaPath './Example/Schema'
ConvertTo-DrXNormalizedSchema -ParsedSchema $parsedSchema

.INPUTS
None. You cannot pipe input to this function.

.OUTPUTS
hashtable. Returns a normalized schema document with bundles.

.NOTES
Author: GitHub Copilot
Version: 0.1.0

.LINK
Import-DrXSchema
#>
function ConvertTo-DrXNormalizedSchema {
  [OutputType([System.Collections.Specialized.OrderedDictionary])]
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNull()]
    [object]$ParsedSchema
  )

  $reusableBundles = @($ParsedSchema['catalog']['reusable_bundles'])
  $applicationBundles = @($ParsedSchema['catalog']['application_bundles'])
  $allBundles = @($reusableBundles + $applicationBundles)
  $bundleNameMap = @{}

  foreach ($bundle in $allBundles) {
    $sourceName = if ($bundle['machine_name']) { $bundle['machine_name'] } elseif ($bundle['label']) { $bundle['label'] } else { 'application' }
    $normalizedName = ConvertTo-DrXBundleName $sourceName
    foreach ($aliasValue in @($bundle['machine_name'], $bundle['label'])) {
      if ($aliasValue) {
        $bundleNameMap[(ConvertTo-DrXMachineName $aliasValue)] = $normalizedName
      }
    }
  }

  $normalizedBundles = [System.Collections.ArrayList]::new()
  foreach ($bundle in $allBundles) {
    $sourceName = if ($bundle['machine_name']) { $bundle['machine_name'] } elseif ($bundle['label']) { $bundle['label'] } else { 'application' }
    $normalizedBundle = [ordered]@{
      machine_name = ConvertTo-DrXBundleName $sourceName
      label = if ($bundle['label']) { $bundle['label'] } elseif ($bundle['machine_name']) { $bundle['machine_name'] } else { 'Application' }
      description = if ($bundle['description']) { $bundle['description'] } else { 'Generated from form schema catalog' }
      kind = if ($bundle['kind']) { $bundle['kind'] } else { 'bundle' }
      form_id = if ($bundle['form_id']) { $bundle['form_id'] } else { '' }
      base_bundle = if ($bundle['base_bundle']) { ConvertTo-DrXBundleName $bundle['base_bundle'] } else { '' }
      system_fields = @(Copy-DrXFieldCollection -Fields $bundle['system_fields'] -BundleNameMap $bundleNameMap)
      sections = [System.Collections.ArrayList]::new()
    }

    foreach ($section in @($bundle['sections'])) {
      $normalizedSection = [ordered]@{}
      foreach ($property in $section.GetEnumerator()) {
        if ($property.Key -eq 'fields') {
          $normalizedSection['fields'] = @(Copy-DrXFieldCollection -Fields $section['fields'] -BundleNameMap $bundleNameMap)
        } else {
          $normalizedSection[$property.Key] = $property.Value
        }
      }
      [void]$normalizedBundle['sections'].Add($normalizedSection)
    }

    [void]$normalizedBundles.Add($normalizedBundle)
  }

  return [ordered]@{
    version = if ($ParsedSchema['version']) { $ParsedSchema['version'] } else { 2 }
    bundles = @($normalizedBundles)
  }
}
