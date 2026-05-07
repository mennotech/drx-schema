function Get-DrXFieldName {
  param([string]$Key)

  $normalized = ConvertTo-DrXMachineName $Key
  $prefixed = "field_$normalized"
  if ($prefixed.Length -le 32) {
    return $prefixed
  }

  $hash = (Get-DrXMd5Hex $prefixed).Substring(0, 6)
  $prefixBudget = 32 - (1 + $hash.Length)
  return '{0}_{1}' -f $prefixed.Substring(0, $prefixBudget), $hash
}