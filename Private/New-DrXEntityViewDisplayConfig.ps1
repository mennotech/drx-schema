function New-DrXEntityViewDisplayConfig {
  [OutputType([System.Collections.Specialized.OrderedDictionary])]
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [hashtable]$Bundle,
    [object[]]$FieldEntries
  )

  if (-not $PSCmdlet.ShouldProcess([string]$Bundle['machine_name'], 'Build entity view display configuration')) {
    return $null
  }

  $configDependencies = [System.Collections.ArrayList]::new()
  [void]$configDependencies.Add("node.type.$($Bundle['machine_name'])")
  $moduleDependencies = [System.Collections.Generic.HashSet[string]]::new()
  [void]$moduleDependencies.Add('node')
  $content = [ordered]@{}

  for ($index = 0; $index -lt $FieldEntries.Count; $index += 1) {
    $entry = $FieldEntries[$index]
    $fieldName = Get-DrXFieldName ($entry['field']['key'])
    [void]$configDependencies.Add("field.field.node.$($Bundle['machine_name']).$fieldName")
    if ($entry['mapping']['module'] -and $entry['mapping']['module'] -ne 'core') {
      [void]$moduleDependencies.Add([string]$entry['mapping']['module'])
    }
    $content[$fieldName] = Get-DrXViewDisplayComponent -Field $entry['field'] -Mapping $entry['mapping'] -Weight $index
  }

  return [ordered]@{
    langcode = 'en'
    status = $true
    dependencies = [ordered]@{
      config = @($configDependencies)
      module = @($moduleDependencies)
    }
    id = "node.$($Bundle['machine_name']).default"
    targetEntityType = 'node'
    bundle = $Bundle['machine_name']
    mode = 'default'
    content = $content
    hidden = [ordered]@{}
  }
}