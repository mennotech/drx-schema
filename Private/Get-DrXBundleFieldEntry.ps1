function Get-DrXBundleFieldEntry {
  param(
    [hashtable]$Bundle,
    [hashtable]$BundleMap,
    [string[]]$Visited = @()
  )

  $bundleId = $Bundle['machine_name']
  if ($Visited -contains $bundleId) {
    throw "Circular base_bundle chain detected for bundle: $bundleId"
  }

  $nextVisited = @($Visited + $bundleId)
  $entries = [System.Collections.ArrayList]::new()

  if ($Bundle['base_bundle']) {
    if (-not $BundleMap.ContainsKey($Bundle['base_bundle'])) {
      throw "Bundle $bundleId references missing base_bundle $($Bundle['base_bundle'])"
    }
    foreach ($entry in (Get-DrXBundleFieldEntry -Bundle $BundleMap[$Bundle['base_bundle']] -BundleMap $BundleMap -Visited $nextVisited)) {
      [void]$entries.Add($entry)
    }
  }

  foreach ($field in @($Bundle['system_fields'])) {
    [void]$entries.Add([ordered]@{ section = $null; field = $field })
  }

  foreach ($section in @($Bundle['sections'])) {
    foreach ($field in @($section['fields'])) {
      [void]$entries.Add([ordered]@{ section = $section; field = $field })
    }
  }

  return @($entries)
}