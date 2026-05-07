<#
.SYNOPSIS
Validates schema bundles through the external JSON:API surface.

.DESCRIPTION
Creates fixture nodes for each normalized bundle, verifies JSON:API reads and
updates, and removes created fixtures after each validation attempt.

.PARAMETER SchemaPath
Optional path to a schema file or directory.

.PARAMETER EnvFile
Optional path to the environment file that contains backend credentials.

.EXAMPLE
Invoke-DrXExternalApiSchemaValidation -SchemaPath './Example' -EnvFile '.env'

.INPUTS
None. You cannot pipe input to this function.

.OUTPUTS
pscustomobject. Returns backend URL and per-bundle validation results.

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
    [string]$EnvFile
  )

  $normalizedSchema = ConvertTo-DrXNormalizedSchema -ParsedSchema (Import-DrXSchema -SchemaPath $SchemaPath)
  $bundles = @($normalizedSchema['bundles'])
  if ($bundles.Count -eq 0) {
    throw 'No bundles were found in the schema directory.'
  }

  $bundleMap = @{}
  foreach ($bundle in $bundles) {
    $bundleMap[[string]$bundle['machine_name']] = $bundle
  }

  $connection = Connect-DrXBackend -EnvFile $EnvFile
  $jsonApiIndex = Invoke-DrXDrupalRequest -Method 'GET' -Uri "$($connection.BaseUrl)/jsonapi" -Session $connection.Session -Headers @{ Accept = 'application/vnd.api+json' }
  $availableLinks = @($jsonApiIndex.links.PSObject.Properties.Name)
  $results = [System.Collections.ArrayList]::new()
  $failed = $false

  for ($index = 0; $index -lt $bundles.Count; $index += 1) {
    $bundle = $bundles[$index]
    $bundleName = [string]$bundle['machine_name']
    $createdNodes = [System.Collections.ArrayList]::new()

    try {
      $fixture = New-DrXExternalApiNodeFixture -Bundle $bundle -BundleMap $bundleMap -Connection $connection -CreatedNodes $createdNodes -Seed $index
      $jsonApiType = "node--$bundleName"
      if ($availableLinks -notcontains $jsonApiType) {
        throw "JSON:API index is missing link $jsonApiType"
      }

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

      [void]$results.Add([pscustomobject]@{
        Bundle = $bundleName
        EntityPath = $fixture.EntityPath
        Status = 'ok'
      })
    }
    catch {
      $failed = $true
      [void]$results.Add([pscustomobject]@{
        Bundle = $bundleName
        EntityPath = ''
        Status = 'error'
        Message = $_.Exception.Message
      })
    }
    finally {
      Remove-DrXExternalApiFixture -CreatedNodes @($createdNodes) -Connection $connection
    }
  }

  if ($failed) {
    $failures = @($results | Where-Object { $_.Status -eq 'error' } | ForEach-Object { '{0}: {1}' -f $_.Bundle, $_.Message })
    throw ('External API schema validation failed: ' + ($failures -join '; '))
  }

  return [pscustomobject]@{
    BackendUrl = $connection.BaseUrl
    Results = @($results)
  }
}
