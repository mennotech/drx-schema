function New-DrXInstanceConfig {
  [OutputType([System.Collections.Specialized.OrderedDictionary])]
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [string]$Bundle,
    [string]$FieldName,
    [hashtable]$Field,
    [hashtable]$Mapping,
    [hashtable]$Section
  )

  if (-not $PSCmdlet.ShouldProcess($FieldName, 'Build field instance configuration')) {
    return $null
  }

  $configDependencies = [System.Collections.ArrayList]::new()
  [void]$configDependencies.Add("field.storage.node.$FieldName")
  [void]$configDependencies.Add("node.type.$Bundle")

  $description = if ($Field['description']) {
    $Field['description']
  } elseif ($Section) {
    "Section: $($Section['title'])"
  } else {
    ''
  }

  if (-not $description -and $Field['type'] -eq 'typed_contact_list' -and $Field['contact_kind']) {
    $description = "Store one $($Field['contact_kind']) per line using type:value formatting."
  }

  foreach ($dependency in @($Mapping['configDependencies'])) {
    if ($dependency) {
      [void]$configDependencies.Add($dependency)
    }
  }

  $defaultValue = [ordered]@{}
  if ($Field['has_default']) {
    if ($Mapping['storageType'] -eq 'entity_reference') {
      $defaultValue = [ordered]@{}
    } elseif ($Mapping['storageType'] -eq 'boolean') {
      $defaultValue = @([ordered]@{ value = $(if ($Field['default']) { 1 } else { 0 }) })
    } else {
      $defaultValue = @([ordered]@{ value = $Field['default'] })
    }
  }

  return [ordered]@{
    langcode = 'en'
    status = $true
    dependencies = [ordered]@{ config = @($configDependencies) }
    id = "node.$Bundle.$FieldName"
    field_name = $FieldName
    entity_type = 'node'
    bundle = $Bundle
    label = $Field['label']
    description = $description
    required = [bool]$Field['required']
    translatable = $false
    default_value = $defaultValue
    default_value_callback = ''
    settings = $Mapping['instanceSettings']
    field_type = $Mapping['storageType']
  }
}