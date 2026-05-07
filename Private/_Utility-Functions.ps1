function Resolve-DrXEnvFilePath {
  param([string]$EnvFile)

  if ($EnvFile) {
    return $EnvFile
  }

  $currentDirectoryEnv = Join-Path -Path (Get-Location).Path -ChildPath '.env'
  if (Test-Path $currentDirectoryEnv) {
    return $currentDirectoryEnv
  }

  return (Join-Path -Path $PSScriptRoot -ChildPath '..\..\.env')
}

function Set-DrXUtf8File {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Mandatory)]
    [string]$Path,
    [Parameter(Mandatory)]
    [string]$Content
  )

  if ($PSCmdlet.ShouldProcess($Path, 'Write UTF-8 file content')) {
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
  }
}

function ConvertTo-DrXBoolean {
  param([string]$Value)

  $normalized = $Value.Trim().ToLowerInvariant()
  if ($normalized -eq 'true') { return $true }
  if ($normalized -eq 'false') { return $false }
  return [bool]$normalized
}

function ConvertTo-DrXNumber {
  param(
    [string]$Value,
    [int]$Fallback = 0
  )

  $parsed = 0
  if ([int]::TryParse($Value.Trim(), [ref]$parsed)) {
    return $parsed
  }

  $doubleValue = 0.0
  if ([double]::TryParse($Value.Trim(), [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$doubleValue)) {
    return [int]$doubleValue
  }

  return $Fallback
}

function ConvertTo-DrXUnquotedValue {
  param([string]$Value)

  $trimmed = $Value.Trim()
  if (($trimmed.StartsWith("'") -and $trimmed.EndsWith("'")) -or ($trimmed.StartsWith('"') -and $trimmed.EndsWith('"'))) {
    return $trimmed.Substring(1, $trimmed.Length - 2)
  }

  return $trimmed
}

function ConvertTo-DrXScalarValue {
  param([string]$Value)

  $trimmed = $Value.Trim()
  if ($trimmed -eq '') {
    return ''
  }

  $unquoted = ConvertTo-DrXUnquotedValue $trimmed
  switch ($unquoted.ToLowerInvariant()) {
    'true' { return $true }
    'false' { return $false }
  }

  $intValue = 0
  if ([int]::TryParse($unquoted, [ref]$intValue)) {
    return $intValue
  }

  $doubleValue = 0.0
  if ([double]::TryParse($unquoted, [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$doubleValue)) {
    return $doubleValue
  }

  return $unquoted
}

function ConvertTo-DrXInlineOption {
  param([string]$Value)

  $match = [regex]::Match($Value.Trim(), '^\[(.*)\]$')
  if (-not $match.Success) {
    return $null
  }

  $inner = $match.Groups[1].Value.Trim()
  if (-not $inner) {
    return @()
  }

  return @($inner.Split(',') | ForEach-Object { ConvertTo-DrXUnquotedValue $_.Trim() })
}

function Format-DrXYamlScalar {
  param([object]$Value)

  if ($Value -is [bool]) {
    return $(if ($Value) { 'true' } else { 'false' })
  }
  if ($Value -is [byte] -or $Value -is [int16] -or $Value -is [int] -or $Value -is [int64] -or $Value -is [double] -or $Value -is [decimal]) {
    return [string]$Value
  }
  if ($null -eq $Value) {
    return "''"
  }

  $stringValue = [string]$Value
  if ($stringValue -eq '') {
    return "''"
  }

  if ($stringValue -match '[:#{}\[\],&*!?|<>=''''"%@`]|^\s|\s$') {
    return "'" + $stringValue.Replace("'", "''") + "'"
  }

  return $stringValue
}