function Get-DrXFormDisplayComponent {
  param(
    [hashtable]$Field,
    [hashtable]$Mapping,
    [int]$Weight
  )

  $type = ([string]$Field['type']).ToLowerInvariant()

  if ($type -eq 'textarea' -or $type -eq 'signature') {
    return [ordered]@{ type = 'text_textarea'; weight = $Weight; region = 'content'; settings = [ordered]@{ rows = 5; placeholder = '' }; third_party_settings = [ordered]@{} }
  }
  if ($type -eq 'email') {
    return [ordered]@{ type = 'email_default'; weight = $Weight; region = 'content'; settings = [ordered]@{ size = 60; placeholder = '' }; third_party_settings = [ordered]@{} }
  }
  if ($type -eq 'date') {
    return [ordered]@{ type = 'datetime_default'; weight = $Weight; region = 'content'; settings = [ordered]@{}; third_party_settings = [ordered]@{} }
  }
  if ($type -eq 'radio') {
    return [ordered]@{ type = 'options_buttons'; weight = $Weight; region = 'content'; settings = [ordered]@{}; third_party_settings = [ordered]@{} }
  }
  if ($type -eq 'select') {
    return [ordered]@{ type = 'options_select'; weight = $Weight; region = 'content'; settings = [ordered]@{}; third_party_settings = [ordered]@{} }
  }
  if ($type -eq 'boolean') {
    return [ordered]@{ type = 'boolean_checkbox'; weight = $Weight; region = 'content'; settings = [ordered]@{ display_label = $true }; third_party_settings = [ordered]@{} }
  }
  if ($Mapping['storageType'] -eq 'entity_reference') {
    return [ordered]@{ type = 'entity_reference_autocomplete'; weight = $Weight; region = 'content'; settings = [ordered]@{ match_operator = 'CONTAINS'; match_limit = 10; size = 60; placeholder = '' }; third_party_settings = [ordered]@{} }
  }

  return [ordered]@{ type = 'string_textfield'; weight = $Weight; region = 'content'; settings = [ordered]@{ size = 60; placeholder = '' }; third_party_settings = [ordered]@{} }
}