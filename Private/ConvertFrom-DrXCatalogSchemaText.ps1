function ConvertFrom-DrXCatalogSchemaText {
  param([string]$Text)

  $lines = ($Text -replace "`r`n", "`n") -split "`n"
  $schema = [ordered]@{
    version = 2
    catalog = [ordered]@{
      reusable_bundles = [System.Collections.ArrayList]::new()
      application_bundles = [System.Collections.ArrayList]::new()
    }
    notes = [System.Collections.ArrayList]::new()
  }

  $topLevelSection = $null
  $currentBundleListName = $null
  $currentBundle = $null
  $currentSection = $null
  $currentField = $null
  $readingFieldOptions = $false

  foreach ($raw in $lines) {
    if (-not $raw.Trim() -or $raw.Trim().StartsWith('#')) {
      continue
    }

    $indentMatch = [regex]::Match($raw, '^\s*')
    $indent = $indentMatch.Value.Length
    $line = $raw.Trim()

    if ($indent -eq 0) {
      $readingFieldOptions = $false
      $currentBundleListName = $null
      $currentBundle = $null
      $currentSection = $null
      $currentField = $null

      if ($line.StartsWith('version:')) {
        $schema['version'] = ConvertTo-DrXNumber ($line.Substring('version:'.Length)) 2
        continue
      }

      if ($line -eq 'catalog:') {
        $topLevelSection = 'catalog'
        continue
      }

      if ($line -eq 'notes:') {
        $topLevelSection = 'notes'
        continue
      }

      $topLevelSection = $null
      continue
    }

    if ($topLevelSection -eq 'notes') {
      if ($indent -eq 2 -and $line.StartsWith('- ')) {
        [void]$schema['notes'].Add((ConvertTo-DrXUnquotedValue $line.Substring(2)))
      }
      continue
    }

    if ($topLevelSection -ne 'catalog') {
      continue
    }

    if ($readingFieldOptions -and $indent -eq 16 -and $line.StartsWith('- ')) {
      [void]$currentField['options'].Add((ConvertTo-DrXUnquotedValue $line.Substring(2)))
      continue
    }

    if ($readingFieldOptions -and $indent -le 14) {
      $readingFieldOptions = $false
    }

    if ($indent -eq 2 -and ($line -eq 'reusable_bundles:' -or $line -eq 'application_bundles:')) {
      $currentBundleListName = $line.TrimEnd(':')
      $currentBundle = $null
      $currentSection = $null
      $currentField = $null
      continue
    }

    if (-not $currentBundleListName) {
      continue
    }

    if ($indent -eq 4 -and $line.StartsWith('- machine_name:')) {
      $currentBundle = [ordered]@{
        machine_name = ConvertTo-DrXUnquotedValue $line.Substring('- machine_name:'.Length)
        label = ''
        description = ''
        kind = ''
        form_id = ''
        base_bundle = ''
        system_fields = [System.Collections.ArrayList]::new()
        sections = [System.Collections.ArrayList]::new()
      }
      [void]$schema['catalog'][$currentBundleListName].Add($currentBundle)
      $currentSection = $null
      $currentField = $null
      continue
    }

    if (-not $currentBundle) {
      continue
    }

    if ($indent -eq 6 -and $line.StartsWith('label:')) {
      $currentBundle['label'] = ConvertTo-DrXUnquotedValue $line.Substring('label:'.Length)
      continue
    }
    if ($indent -eq 6 -and $line.StartsWith('description:')) {
      $currentBundle['description'] = ConvertTo-DrXUnquotedValue $line.Substring('description:'.Length)
      continue
    }
    if ($indent -eq 6 -and $line.StartsWith('kind:')) {
      $currentBundle['kind'] = ConvertTo-DrXUnquotedValue $line.Substring('kind:'.Length)
      continue
    }
    if ($indent -eq 6 -and $line.StartsWith('form_id:')) {
      $currentBundle['form_id'] = ConvertTo-DrXUnquotedValue $line.Substring('form_id:'.Length)
      continue
    }
    if ($indent -eq 6 -and $line.StartsWith('base_bundle:')) {
      $currentBundle['base_bundle'] = ConvertTo-DrXUnquotedValue $line.Substring('base_bundle:'.Length)
      continue
    }
    if ($indent -eq 6 -and $line.StartsWith('system_fields:')) {
      $currentSection = [ordered]@{
        id = '__system_fields__'
        title = 'System Fields'
        description = 'Non-visual fields stored on the bundle.'
        fields = $currentBundle['system_fields']
      }
      $currentField = $null
      continue
    }
    if ($indent -eq 6 -and $line.StartsWith('sections:')) {
      $currentSection = $null
      continue
    }

    if ($indent -eq 8 -and $line.StartsWith('- id:')) {
      $currentSection = [ordered]@{
        id = ConvertTo-DrXUnquotedValue $line.Substring('- id:'.Length)
        title = ''
        description = ''
        fields = [System.Collections.ArrayList]::new()
      }
      [void]$currentBundle['sections'].Add($currentSection)
      $currentField = $null
      continue
    }

    if (-not $currentSection) {
      continue
    }

    if ($indent -eq 10 -and $line.StartsWith('title:')) {
      $currentSection['title'] = ConvertTo-DrXUnquotedValue $line.Substring('title:'.Length)
      continue
    }
    if ($indent -eq 10 -and $line.StartsWith('description:')) {
      $currentSection['description'] = ConvertTo-DrXUnquotedValue $line.Substring('description:'.Length)
      continue
    }
    if ($indent -eq 10 -and $line.StartsWith('fields:')) {
      continue
    }

    if ($currentSection['id'] -eq '__system_fields__' -and $indent -eq 8 -and $line.StartsWith('- key:')) {
      $currentField = [ordered]@{
        key = ConvertTo-DrXUnquotedValue $line.Substring('- key:'.Length)
        label = ''
        type = 'text'
        required = $false
        default = $null
        has_default = $false
        options = [System.Collections.ArrayList]::new()
        target_bundles = [System.Collections.ArrayList]::new()
        description = ''
      }
      [void]$currentSection['fields'].Add($currentField)
      continue
    }

    if ($indent -eq 12 -and $line.StartsWith('- key:')) {
      $currentField = [ordered]@{
        key = ConvertTo-DrXUnquotedValue $line.Substring('- key:'.Length)
        label = ''
        type = 'text'
        required = $false
        default = $null
        has_default = $false
        options = [System.Collections.ArrayList]::new()
        target_bundles = [System.Collections.ArrayList]::new()
        description = ''
      }
      [void]$currentSection['fields'].Add($currentField)
      continue
    }

    if (-not $currentField -or $indent -ne 14) {
      continue
    }

    if ($line.StartsWith('label:')) {
      $currentField['label'] = ConvertTo-DrXUnquotedValue $line.Substring('label:'.Length)
      continue
    }
    if ($line.StartsWith('type:')) {
      $currentField['type'] = ConvertTo-DrXUnquotedValue $line.Substring('type:'.Length)
      continue
    }
    if ($line.StartsWith('required:')) {
      $currentField['required'] = ConvertTo-DrXBoolean $line.Substring('required:'.Length)
      continue
    }
    if ($line.StartsWith('default:')) {
      $currentField['default'] = ConvertTo-DrXScalarValue $line.Substring('default:'.Length)
      $currentField['has_default'] = $true
      continue
    }
    if ($line.StartsWith('description:')) {
      $currentField['description'] = ConvertTo-DrXUnquotedValue $line.Substring('description:'.Length)
      continue
    }
    if ($line.StartsWith('contact_kind:')) {
      $currentField['contact_kind'] = ConvertTo-DrXUnquotedValue $line.Substring('contact_kind:'.Length)
      continue
    }
    if ($line.StartsWith('cardinality:')) {
      $currentField['cardinality'] = ConvertTo-DrXNumber ($line.Substring('cardinality:'.Length)) 1
      continue
    }
    if ($line.StartsWith('target_bundles:')) {
      $rawTargetBundles = $line.Substring('target_bundles:'.Length).Trim()
      $currentField['target_bundles'] = [System.Collections.ArrayList]::new()
      foreach ($bundleName in (ConvertTo-DrXInlineOption $rawTargetBundles)) {
        [void]$currentField['target_bundles'].Add($bundleName)
      }
      continue
    }
    if ($line.StartsWith('auto_create:')) {
      $currentField['auto_create'] = ConvertTo-DrXBoolean $line.Substring('auto_create:'.Length)
      continue
    }
    if ($line.StartsWith('options:')) {
      $rawOptions = $line.Substring('options:'.Length).Trim()
      if (-not $rawOptions) {
        $readingFieldOptions = $true
        $currentField['options'] = [System.Collections.ArrayList]::new()
      } else {
        $currentField['options'] = [System.Collections.ArrayList]::new()
        foreach ($option in (ConvertTo-DrXInlineOption $rawOptions)) {
          [void]$currentField['options'].Add($option)
        }
      }
    }
  }

  return $schema
}