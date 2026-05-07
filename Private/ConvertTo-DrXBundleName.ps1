function ConvertTo-DrXBundleName {
  param([string]$Value)

  $normalized = ConvertTo-DrXMachineName $Value
  if ($normalized.Length -le 32) {
    return $normalized
  }

  $hash = (Get-DrXMd5Hex $normalized).Substring(0, 6)
  $prefixBudget = 32 - (1 + $hash.Length)
  return '{0}_{1}' -f $normalized.Substring(0, $prefixBudget), $hash
}