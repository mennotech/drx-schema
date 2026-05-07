function ConvertTo-DrXMachineName {
  param([string]$Value)

  return (($Value.ToLowerInvariant() -replace '[^a-z0-9_]+', '_' -replace '_+', '_').Trim('_'))
}