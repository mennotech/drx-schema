function Get-DrXFieldMapping {
  param([hashtable]$Field)

  $type = ([string]$Field['type']).ToLowerInvariant()

  if ($type -eq 'boolean') {
    return [ordered]@{
      storageType = 'boolean'
      module = 'core'
      storageSettings = [ordered]@{ on_label = 'On'; off_label = 'Off' }
      instanceSettings = [ordered]@{ display_label = $true }
    }
  }

  if ($type -eq 'textarea' -or $type -eq 'signature') {
    return [ordered]@{
      storageType = 'text_long'
      module = 'text'
      storageSettings = [ordered]@{}
      instanceSettings = [ordered]@{}
    }
  }

  if ($type -eq 'email') {
    return [ordered]@{
      storageType = 'email'
      module = 'core'
      storageSettings = [ordered]@{}
      instanceSettings = [ordered]@{}
    }
  }

  if ($type -eq 'date') {
    return [ordered]@{
      storageType = 'datetime'
      module = 'datetime'
      storageSettings = [ordered]@{ datetime_type = 'date' }
      instanceSettings = [ordered]@{}
    }
  }

  if (($type -eq 'radio' -or $type -eq 'select') -and $Field['options'] -and @($Field['options']).Count -gt 0) {
    $allowedValues = [System.Collections.ArrayList]::new()
    foreach ($option in @($Field['options'])) {
      [void]$allowedValues.Add([ordered]@{ value = $option; label = $option })
    }

    return [ordered]@{
      storageType = 'list_string'
      module = 'options'
      storageSettings = [ordered]@{
        allowed_values = @($allowedValues)
        allowed_values_function = ''
      }
      instanceSettings = [ordered]@{}
    }
  }

  if ($type -eq 'phone') {
    return [ordered]@{
      storageType = 'string'
      module = 'core'
      storageSettings = [ordered]@{ max_length = 64; is_ascii = $false; case_sensitive = $false }
      instanceSettings = [ordered]@{}
    }
  }

  if ($type -eq 'typed_contact_list') {
    return [ordered]@{
      storageType = 'string'
      module = 'core'
      storageSettings = [ordered]@{ max_length = 255; is_ascii = $false; case_sensitive = $false }
      instanceSettings = [ordered]@{}
    }
  }

  $nodeReferenceMap = @{
    address_reference = 'address'
    person_reference = 'person'
    student_reference = 'student'
  }

  if ($nodeReferenceMap.ContainsKey($type)) {
    $targetBundle = $nodeReferenceMap[$type]
    return [ordered]@{
      storageType = 'entity_reference'
      module = 'core'
      storageSettings = [ordered]@{ target_type = 'node' }
      instanceSettings = [ordered]@{
        handler = 'default:node'
        handler_settings = [ordered]@{
          target_bundles = [ordered]@{ $targetBundle = $targetBundle }
          sort = [ordered]@{ field = '_none' }
          auto_create = $false
          auto_create_bundle = ''
        }
      }
      translatable = $true
      configDependencies = @("node.type.$targetBundle")
    }
  }

  if ($type -eq 'node_reference') {
    $targetBundles = @()
    foreach ($bundle in @($Field['target_bundles'])) {
      $normalized = ConvertTo-DrXBundleName $bundle
      if ($normalized) {
        $targetBundles += $normalized
      }
    }

    $targetBundleMap = [ordered]@{}
    foreach ($bundle in $targetBundles) {
      $targetBundleMap[$bundle] = $bundle
    }

    return [ordered]@{
      storageType = 'entity_reference'
      module = 'core'
      storageSettings = [ordered]@{ target_type = 'node' }
      instanceSettings = [ordered]@{
        handler = 'default:node'
        handler_settings = [ordered]@{
          target_bundles = $targetBundleMap
          sort = [ordered]@{ field = '_none' }
          auto_create = [bool]$Field['auto_create']
          auto_create_bundle = ''
        }
      }
      translatable = $true
      configDependencies = @($targetBundles | ForEach-Object { "node.type.$_" })
    }
  }

  return [ordered]@{
    storageType = 'string'
    module = 'core'
    storageSettings = [ordered]@{ max_length = 255; is_ascii = $false; case_sensitive = $false }
    instanceSettings = [ordered]@{}
  }
}