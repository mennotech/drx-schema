function Join-DrXCatalogSchema {
  param([object[]]$ParsedSchemas)

  $merged = [ordered]@{
    version = 2
    catalog = [ordered]@{
      reusable_bundles = [System.Collections.ArrayList]::new()
      application_bundles = [System.Collections.ArrayList]::new()
    }
    notes = [System.Collections.ArrayList]::new()
  }

  foreach ($schema in $ParsedSchemas) {
    if ($schema['version']) {
      $merged['version'] = [Math]::Max([int]$merged['version'], [int]$schema['version'])
    }

    foreach ($bundle in $schema['catalog']['reusable_bundles']) {
      [void]$merged['catalog']['reusable_bundles'].Add($bundle)
    }
    foreach ($bundle in $schema['catalog']['application_bundles']) {
      [void]$merged['catalog']['application_bundles'].Add($bundle)
    }
    foreach ($note in $schema['notes']) {
      [void]$merged['notes'].Add($note)
    }
  }

  return $merged
}