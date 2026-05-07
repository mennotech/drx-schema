function Invoke-DrXDbSchemaValidation {
  param(
    [string]$SchemaPath = $null,
    [string]$ComposeService = 'backend'
  )

  $schemaBundles = @(Get-DrXSchemaBundle -SchemaPath $SchemaPath)
  if ($schemaBundles.Count -eq 0) {
    throw 'No bundles were found in the schema directory.'
  }

  return Invoke-DrXDrushPhpScript -PhpContents (New-DrXSchemaCrudValidatorPhp -Bundles $schemaBundles) -ComposeService $ComposeService -ContainerPhpPath '/tmp/schema-validator.php'
}