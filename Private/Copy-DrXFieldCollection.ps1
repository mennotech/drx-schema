function Copy-DrXFieldCollection {
  param(
    [object[]]$Fields,
    [hashtable]$BundleNameMap
  )

  if (-not $Fields) {
    return @()
  }

  $result = [System.Collections.ArrayList]::new()

  foreach ($field in $Fields) {
    $normalizedField = [ordered]@{}
    foreach ($property in $field.GetEnumerator()) {
      if ($property.Value -is [System.Collections.IEnumerable] -and -not ($property.Value -is [string])) {
        if ($property.Key -eq 'options' -or $property.Key -eq 'target_bundles') {
          $normalizedField[$property.Key] = [System.Collections.ArrayList]::new()
          foreach ($item in $property.Value) {
            [void]$normalizedField[$property.Key].Add($item)
          }
        } else {
          $normalizedField[$property.Key] = $property.Value
        }
      } else {
        $normalizedField[$property.Key] = $property.Value
      }
    }

    if ($field.Contains('target_bundles')) {
      $normalizedField['target_bundles'] = [System.Collections.ArrayList]::new()
      foreach ($bundle in $field['target_bundles']) {
        $normalized = ConvertTo-DrXMachineName $bundle
        $resolved = if ($BundleNameMap.ContainsKey($normalized)) { $BundleNameMap[$normalized] } else { ConvertTo-DrXBundleName $bundle }
        [void]$normalizedField['target_bundles'].Add($resolved)
      }
    }

    if ($field.Contains('options')) {
      $normalizedField['options'] = [System.Collections.ArrayList]::new()
      foreach ($option in $field['options']) {
        $normalized = ConvertTo-DrXMachineName $option
        $resolved = if ($BundleNameMap.ContainsKey($normalized)) { $BundleNameMap[$normalized] } else { $option }
        [void]$normalizedField['options'].Add($resolved)
      }
    }

    if ($normalizedField['key'] -eq 'pages' -and $normalizedField.Contains('options')) {
      $normalizedOptions = [System.Collections.ArrayList]::new()
      foreach ($option in $normalizedField['options']) {
        $normalized = ConvertTo-DrXMachineName $option
        $resolved = if ($BundleNameMap.ContainsKey($normalized)) { $BundleNameMap[$normalized] } else { ConvertTo-DrXBundleName $option }
        [void]$normalizedOptions.Add($resolved)
      }
      $normalizedField['options'] = $normalizedOptions
    }

    [void]$result.Add($normalizedField)
  }

  return @($result)
}