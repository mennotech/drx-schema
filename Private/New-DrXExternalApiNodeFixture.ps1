function New-DrXExternalApiNodeFixture {
  [OutputType([System.Collections.Specialized.OrderedDictionary])]
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Mandatory)]
    [hashtable]$Bundle,
    [Parameter(Mandatory)]
    [hashtable]$BundleMap,
    [Parameter(Mandatory)]
    [psobject]$Connection,
    [Parameter(Mandatory)]
    [object]$CreatedNodes,
    [int]$Seed = 0
  )

  $bundleName = [string]$Bundle['machine_name']
  $fieldEntries = @(Get-DrXBundleFieldEntry -Bundle $Bundle -BundleMap $BundleMap)
  $attributes = [ordered]@{
    title = ('External API fixture {0} {1}' -f $bundleName, $Seed)
    status = $false
  }
  $relationships = [ordered]@{}

  foreach ($entry in $fieldEntries) {
    $field = $entry['field']
    $fieldName = Get-DrXFieldName ($field['key'])
    $mapping = Get-DrXFieldMapping -Field $field
    $isRequired = [bool]$field['required']
    $hasDefault = [bool]$field['has_default']

    if (-not $isRequired -and -not $hasDefault) {
      continue
    }

    if ($mapping['storageType'] -eq 'entity_reference') {
      $targetBundleName = $null

      switch (([string]$field['type']).ToLowerInvariant()) {
        'address_reference' { $targetBundleName = 'address' }
        'person_reference' { $targetBundleName = 'person' }
        'student_reference' { $targetBundleName = 'student' }
        'node_reference' {
          if ($field['target_bundles'] -and @($field['target_bundles']).Count -gt 0) {
            $targetBundleName = ConvertTo-DrXBundleName (@($field['target_bundles'])[0])
          }
        }
      }

      if (-not $targetBundleName) {
        throw "Field $fieldName on bundle $bundleName is a required reference with no target bundle."
      }

      if (-not $BundleMap.ContainsKey($targetBundleName)) {
        throw "Bundle $bundleName references missing target bundle $targetBundleName."
      }

      $targetFixture = New-DrXExternalApiNodeFixture -Bundle $BundleMap[$targetBundleName] -BundleMap $BundleMap -Connection $Connection -CreatedNodes $CreatedNodes -Seed ($Seed + 1)
      $resourceIdentifier = [ordered]@{
        type = "node--$targetBundleName"
        id = $targetFixture.Uuid
      }

      $cardinality = if ($field.Contains('cardinality')) { [int]$field['cardinality'] } else { 1 }
      $relationships[$fieldName] = [ordered]@{
        data = $(if ($cardinality -ne 1) { @($resourceIdentifier) } else { $resourceIdentifier })
      }
      continue
    }

    $attributes[$fieldName] = New-DrXExternalApiScalarValue -Field $field -BundleName $bundleName -Seed $Seed
  }

  $payloadData = [ordered]@{
    type = "node--$bundleName"
    attributes = $attributes
  }

  if ($relationships.Count -gt 0) {
    $payloadData['relationships'] = $relationships
  }

  if (-not $PSCmdlet.ShouldProcess($bundleName, 'Create external API fixture node')) {
    return $null
  }

  $response = Invoke-DrXDrupalRequest -Method 'POST' -Uri "$($Connection.BaseUrl)/jsonapi/node/$bundleName" -Session $Connection.Session -Headers @{ Accept = 'application/vnd.api+json'; 'X-CSRF-Token' = $Connection.CsrfToken } -ContentType 'application/vnd.api+json' -Body @{ data = $payloadData }
  $fixture = [ordered]@{
    Bundle = $bundleName
    Uuid = [string]$response.data.id
    EntityPath = "/jsonapi/node/$bundleName/$($response.data.id)"
    Title = [string]$attributes['title']
    Deleted = $false
  }
  [void]$CreatedNodes.Add($fixture)
  return $fixture
}