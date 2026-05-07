function New-DrXStorageConfig {
  [OutputType([System.Collections.Specialized.OrderedDictionary])]
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [string]$FieldName,
    [hashtable]$Mapping,
    [hashtable]$Field
  )

  if (-not $PSCmdlet.ShouldProcess($FieldName, 'Build field storage configuration')) {
    return $null
  }

  $deps = [System.Collections.ArrayList]::new()
  [void]$deps.Add('node')
  if ($Mapping['module'] -ne 'core') {
    [void]$deps.Add($Mapping['module'])
  }

  return [ordered]@{
    langcode = 'en'
    status = $true
    dependencies = [ordered]@{ module = @($deps) }
    id = "node.$FieldName"
    field_name = $FieldName
    entity_type = 'node'
    type = $Mapping['storageType']
    settings = $Mapping['storageSettings']
    module = $Mapping['module']
    locked = $false
    cardinality = if ($Field.Contains('cardinality')) { [int]$Field['cardinality'] } else { 1 }
    translatable = [bool]$Mapping['translatable']
    indexes = [ordered]@{}
    persist_with_no_fields = $false
    custom_storage = $false
  }
}