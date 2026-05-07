<#
.SYNOPSIS
Validates schema bundles through the external JSON:API surface.

.DESCRIPTION
Creates fixture nodes for each normalized bundle, verifies JSON:API reads and
updates, and removes created fixtures after each validation attempt. Results are
returned as a table by default, or as JSON or CSV when the OutputFormat parameter
is specified.

.PARAMETER SchemaPath
Optional path to a schema file or directory.

.PARAMETER EnvFile
Optional path to the environment file that contains backend credentials.

.PARAMETER OutputFormat
The format used to render validation results. Accepted values are Table (default),
Json, and Csv.

.EXAMPLE
Invoke-DrXExternalApiSchemaValidation -SchemaPath './Example/Schema' -EnvFile '.env'

.EXAMPLE
Invoke-DrXExternalApiSchemaValidation -EnvFile '.env' -OutputFormat Json

.EXAMPLE
Invoke-DrXExternalApiSchemaValidation -EnvFile '.env' -OutputFormat Csv

.INPUTS
None. You cannot pipe input to this function.

.OUTPUTS
pscustomobject[]. Returns per-bundle validation results as objects (Table), a JSON string (Json), or a CSV string (Csv).

.NOTES
Author: GitHub Copilot
Version: 0.1.0

.LINK
Invoke-DrXApiSchemaValidation
#>
function Invoke-DrXExternalApiSchemaValidation {
  [CmdletBinding()]
  param(
    [string]$SchemaPath = $null,
    [string]$EnvFile,
    [ValidateSet('Table', 'Json', 'Csv')]
    [string]$OutputFormat = 'Table'
  )

  Write-Information 'Starting external API schema validation...' -InformationAction Continue

  $normalizedSchema = ConvertTo-DrXNormalizedSchema -ParsedSchema (Import-DrXSchema -SchemaPath $SchemaPath)
  $bundles = @($normalizedSchema['bundles'])
  if ($bundles.Count -eq 0) {
    throw 'No bundles were found in the schema directory.'
  }

  Write-Information "Found $($bundles.Count) bundle(s) to validate." -InformationAction Continue
  Write-Verbose 'Connecting to backend...'

  $bundleMap = @{}
  foreach ($bundle in $bundles) {
    $bundleMap[[string]$bundle['machine_name']] = $bundle
  }

  $connection = Connect-DrXBackend -EnvFile $EnvFile
  Write-Debug "Connected to backend: $($connection.BaseUrl)"

  $jsonApiIndex = Invoke-DrXDrupalRequest -Method 'GET' -Uri "$($connection.BaseUrl)/jsonapi" -Session $connection.Session -Headers @{ Accept = 'application/vnd.api+json' }
  $availableLinks = @($jsonApiIndex.links.PSObject.Properties.Name)
  $results = [System.Collections.ArrayList]::new()
  $failed = $false

  for ($index = 0; $index -lt $bundles.Count; $index += 1) {
    $bundle = $bundles[$index]
    $bundleName = [string]$bundle['machine_name']
    $createdNodes = [System.Collections.ArrayList]::new()

    Write-Verbose "  Validating bundle: $bundleName"

    try {
      $fixture = New-DrXExternalApiNodeFixture -Bundle $bundle -BundleMap $bundleMap -Connection $connection -CreatedNodes $createdNodes -Seed $index
      $jsonApiType = "node--$bundleName"
      if ($availableLinks -notcontains $jsonApiType) {
        throw "JSON:API index is missing link $jsonApiType"
      }

      Write-Debug "  Fixture created: $($fixture.EntityPath)"

      $entity = Invoke-DrXDrupalRequest -Method 'GET' -Uri "$($connection.BaseUrl)$($fixture.EntityPath)" -Session $connection.Session -Headers @{ Accept = 'application/vnd.api+json' }
      if ($entity.data.attributes.title -ne $fixture.Title) {
        throw "Bundle $bundleName returned unexpected title from JSON:API."
      }

      $updatedTitle = "$($fixture.Title) updated via external api"
      $patchBody = @{
        data = @{
          type = $jsonApiType
          id = $fixture.Uuid
          attributes = @{
            title = $updatedTitle
          }
        }
      }

      Invoke-DrXDrupalRequest -Method 'PATCH' -Uri "$($connection.BaseUrl)$($fixture.EntityPath)" -Session $connection.Session -Headers @{ Accept = 'application/vnd.api+json'; 'X-CSRF-Token' = $connection.CsrfToken } -ContentType 'application/vnd.api+json' -Body $patchBody | Out-Null

      $reloaded = Invoke-DrXDrupalRequest -Method 'GET' -Uri "$($connection.BaseUrl)$($fixture.EntityPath)" -Session $connection.Session -Headers @{ Accept = 'application/vnd.api+json' }
      if ($reloaded.data.attributes.title -ne $updatedTitle) {
        throw "Bundle $bundleName did not persist JSON:API PATCH title update."
      }

      Invoke-DrXDrupalRequest -Method 'DELETE' -Uri "$($connection.BaseUrl)$($fixture.EntityPath)" -Session $connection.Session -Headers @{ Accept = 'application/vnd.api+json'; 'X-CSRF-Token' = $connection.CsrfToken } | Out-Null
      $fixture.Deleted = $true

      Write-Debug "  Bundle $bundleName validated successfully."
      [void]$results.Add([pscustomobject]@{
        Bundle     = $bundleName
        EntityPath = $fixture.EntityPath
        Status     = 'ok'
        Message    = $null
      })
    }
    catch {
      $failed = $true
      Write-Debug "  Bundle $bundleName validation error: $($_.Exception.Message)"
      [void]$results.Add([pscustomobject]@{
        Bundle     = $bundleName
        EntityPath = ''
        Status     = 'error'
        Message    = $_.Exception.Message
      })
    }
    finally {
      Remove-DrXExternalApiFixture -CreatedNodes @($createdNodes) -Connection $connection
    }
  }

  $passCount = ($results | Where-Object { $_.Status -eq 'ok' }).Count
  $total = $results.Count
  Write-Information "External API validation complete: $passCount/$total bundles passed." -InformationAction Continue

  foreach ($result in @($results)) {
    Write-Verbose "  Bundle '$($result.Bundle)': $($result.Status)"
  }

  if ($failed) {
    $failures = @($results | Where-Object { $_.Status -eq 'error' } | ForEach-Object { '{0}: {1}' -f $_.Bundle, $_.Message })
    throw ('External API schema validation failed: ' + ($failures -join '; '))
  }

  $resultArray = @($results)

  switch ($OutputFormat) {
    'Json' { return $resultArray | ConvertTo-Json -Depth 10 }
    'Csv' { return $resultArray | ConvertTo-Csv -NoTypeInformation }
    default { return $resultArray }
  }
}
