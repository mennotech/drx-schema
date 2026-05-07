function Resolve-DrXSchemaPath {
  param([string]$SchemaPath)

  if ($SchemaPath) {
    return $SchemaPath
  }

  if ($env:DRX_SCHEMA_PATH) {
    return $env:DRX_SCHEMA_PATH
  }

  $envFilePath = Resolve-DrXEnvFilePath
  if (Test-Path $envFilePath) {
    $envMap = Get-DrXEnvMap -Path $envFilePath
    $configuredSchemaPath = $envMap['DRX_SCHEMA_PATH']
    if ($configuredSchemaPath) {
      if ([System.IO.Path]::IsPathRooted($configuredSchemaPath)) {
        return $configuredSchemaPath
      }

      return (Join-Path (Split-Path -Parent $envFilePath) $configuredSchemaPath)
    }
  }

  return (Join-Path $PSScriptRoot '..\v2')
}