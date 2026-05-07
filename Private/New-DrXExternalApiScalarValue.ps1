function New-DrXExternalApiScalarValue {
  [OutputType([object[]])]
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [hashtable]$Field,
    [string]$BundleName,
    [int]$Seed = 0
  )

  if (-not $PSCmdlet.ShouldProcess([string]$Field['key'], 'Build external API scalar value')) {
    return $null
  }

  if ($Field['has_default']) {
    $value = $Field['default']
  } else {
    $type = ([string]$Field['type']).ToLowerInvariant()
    $key = [string]$Field['key']

    switch ($type) {
      'boolean' { $value = $false; break }
      'date' { $value = '2026-05-06'; break }
      'email' { $value = ('{0}-{1}@example.test' -f $BundleName, $Seed); break }
      'phone' { $value = ('555-010{0}' -f ($Seed % 10)); break }
      'radio' {
        if ($Field['options']) { $value = @($Field['options'])[0] } else { $value = ('option-{0}' -f $Seed) }
        break
      }
      'select' {
        if ($Field['options']) { $value = @($Field['options'])[0] } else { $value = ('option-{0}' -f $Seed) }
        break
      }
      'typed_contact_list' { $value = ('primary:{0}-{1}@example.test' -f $BundleName, $Seed); break }
      default { $value = ('{0} {1} {2}' -f $BundleName, $key, $Seed).Trim() }
    }
  }

  $cardinality = if ($Field.Contains('cardinality')) { [int]$Field['cardinality'] } else { 1 }
  if ($cardinality -ne 1) {
    return @($value)
  }

  return $value
}