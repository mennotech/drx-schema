function Invoke-DrXDbSchemaValidation {
  param(
    [string]$SchemaPath = $null,
    [string]$ComposeService = 'backend'
  )

  $schemaBundles = @(Get-DrXSchemaBundle -SchemaPath $SchemaPath)
  if ($schemaBundles.Count -eq 0) {
    throw 'No bundles were found in the schema directory.'
  }

  Write-Verbose "Running CRUD validation for $($schemaBundles.Count) bundle(s) via drush..."
  $rawOutput = Invoke-DrXDrushPhpScript -PhpContents (New-DrXSchemaCrudValidatorPhp -Bundles $schemaBundles) -ComposeService $ComposeService -ContainerPhpPath '/tmp/schema-validator.php'

  Write-Debug "Raw drush output: $rawOutput"
  $payload = $rawOutput | ConvertFrom-Json

  $results = [System.Collections.ArrayList]::new()
  foreach ($item in @($payload.results)) {
    $message = if ($item.PSObject.Properties['message']) { [string]$item.message } else { $null }
    [void]$results.Add([pscustomobject]@{
      Bundle  = [string]$item.bundle
      Nid     = if ($null -ne $item.PSObject.Properties['nid']) { [int]$item.nid } else { $null }
      Uuid    = if ($null -ne $item.PSObject.Properties['uuid']) { [string]$item.uuid } else { $null }
      Status  = [string]$item.status
      Message = $message
    })
  }

  return [pscustomobject]@{
    Results = @($results)
    Failed  = [bool]$payload.failed
  }
}