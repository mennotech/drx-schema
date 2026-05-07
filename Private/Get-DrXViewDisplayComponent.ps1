function Get-DrXViewDisplayComponent {
  param(
    [hashtable]$Field,
    [hashtable]$Mapping,
    [int]$Weight
  )

  $type = ([string]$Field['type']).ToLowerInvariant()

  if ($type -eq 'textarea' -or $type -eq 'signature') {
    return [ordered]@{ type = 'text_default'; label = 'above'; settings = [ordered]@{}; third_party_settings = [ordered]@{}; weight = $Weight; region = 'content' }
  }
  if ($type -eq 'email') {
    return [ordered]@{ type = 'email_mailto'; label = 'above'; settings = [ordered]@{}; third_party_settings = [ordered]@{}; weight = $Weight; region = 'content' }
  }
  if ($type -eq 'date') {
    return [ordered]@{ type = 'datetime_default'; label = 'above'; settings = [ordered]@{ timezone_override = ''; format_type = 'medium' }; third_party_settings = [ordered]@{}; weight = $Weight; region = 'content' }
  }
  if ($type -eq 'boolean') {
    return [ordered]@{ type = 'boolean'; label = 'above'; settings = [ordered]@{ format = 'default'; format_custom_true = ''; format_custom_false = '' }; third_party_settings = [ordered]@{}; weight = $Weight; region = 'content' }
  }
  if ($Mapping['storageType'] -eq 'entity_reference') {
    return [ordered]@{ type = 'entity_reference_label'; label = 'above'; settings = [ordered]@{ link = $true }; third_party_settings = [ordered]@{}; weight = $Weight; region = 'content' }
  }

  return [ordered]@{ type = 'string'; label = 'above'; settings = [ordered]@{ link_to_entity = $false }; third_party_settings = [ordered]@{}; weight = $Weight; region = 'content' }
}