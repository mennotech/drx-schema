function Invoke-DrXInternalApiSchemaValidation {
  param(
    [string]$SchemaPath = $null,
    [string]$ComposeService = 'backend',
    [string]$EnvFile
  )

  $schemaBundles = @(Get-DrXSchemaBundle -SchemaPath $SchemaPath -EnvFile $EnvFile)
  if ($schemaBundles.Count -eq 0) {
    throw 'No bundles were found in the schema directory.'
  }

  Write-Verbose "Creating API fixtures for $($schemaBundles.Count) bundle(s) via drush..."
  $fixtureJson = Invoke-DrXDrushPhpScript -PhpContents (New-DrXApiSchemaFixturePhp -Bundles $schemaBundles) -ComposeService $ComposeService -ContainerPhpPath '/tmp/api-schema-fixtures.php'
  Write-Debug "Fixture JSON: $fixtureJson"

  $fixturePayload = $fixtureJson | ConvertFrom-Json
  if ($fixturePayload.failed) {
    throw 'Fixture creation failed for API validation.'
  }

  Write-Verbose 'Connecting to backend...'
  $connection = Connect-DrXBackend -EnvFile $EnvFile
  Write-Debug "Connected to backend: $($connection.BaseUrl)"

  $jsonApiIndex = Invoke-DrXDrupalRequest -Method 'GET' -Uri "$($connection.BaseUrl)/jsonapi" -Session $connection.Session -Headers @{ Accept = 'application/vnd.api+json' }
  $availableLinks = @($jsonApiIndex.links.PSObject.Properties.Name)

  $results = [System.Collections.ArrayList]::new()
  $remainingFixtureNids = [System.Collections.Generic.HashSet[int]]::new()
  foreach ($fixture in @($fixturePayload.results)) {
    [void]$remainingFixtureNids.Add([int]$fixture.nid)
  }

  $failed = $false

  try {
    foreach ($fixture in @($fixturePayload.results)) {
      $bundleName = [string]$fixture.bundle
      Write-Verbose "  Validating bundle: $bundleName"

      try {
        $fixtureStatusProperty = $fixture.PSObject.Properties['status']
        if ($null -ne $fixtureStatusProperty -and $fixtureStatusProperty.Value -eq 'error') {
          throw "Fixture creation failed for bundle ${bundleName}: $($fixture.message)"
        }

        $jsonApiType = "node--$bundleName"
        if ($availableLinks -notcontains $jsonApiType) {
          throw "JSON:API index is missing link $jsonApiType"
        }

        $entity = Invoke-DrXDrupalRequest -Method 'GET' -Uri "$($connection.BaseUrl)$($fixture.entity_path)" -Session $connection.Session -Headers @{ Accept = 'application/vnd.api+json' }
        if ($entity.data.attributes.title -ne $fixture.title) {
          throw "Bundle $bundleName returned unexpected title from JSON:API."
        }

        $updatedTitle = "$($fixture.title) updated via api"
        $patchBody = @{
          data = @{
            type = $jsonApiType
            id   = $fixture.uuid
            attributes = @{
              title = $updatedTitle
            }
          }
        }

        Invoke-DrXDrupalRequest -Method 'PATCH' -Uri "$($connection.BaseUrl)$($fixture.entity_path)" -Session $connection.Session -Headers @{ Accept = 'application/vnd.api+json'; 'X-CSRF-Token' = $connection.CsrfToken } -ContentType 'application/vnd.api+json' -Body $patchBody | Out-Null

        $reloaded = Invoke-DrXDrupalRequest -Method 'GET' -Uri "$($connection.BaseUrl)$($fixture.entity_path)" -Session $connection.Session -Headers @{ Accept = 'application/vnd.api+json' }
        if ($reloaded.data.attributes.title -ne $updatedTitle) {
          throw "Bundle $bundleName did not persist JSON:API PATCH title update."
        }

        Invoke-DrXDrupalRequest -Method 'DELETE' -Uri "$($connection.BaseUrl)$($fixture.entity_path)" -Session $connection.Session -Headers @{ Accept = 'application/vnd.api+json'; 'X-CSRF-Token' = $connection.CsrfToken } | Out-Null

        [void]$remainingFixtureNids.Remove([int]$fixture.nid)
        Write-Debug "  Bundle $bundleName validated successfully at $($fixture.entity_path)"
        [void]$results.Add([pscustomobject]@{
          Bundle     = $bundleName
          EntityPath = [string]$fixture.entity_path
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
    }
  }
  finally {
    if ($remainingFixtureNids.Count -gt 0) {
      Invoke-DrXDrushPhpScript -PhpContents (New-DrXApiFixtureCleanupPhp -Nids @($remainingFixtureNids)) -ComposeService $ComposeService -ContainerPhpPath '/tmp/api-schema-cleanup.php' | Out-Null
    }
  }

  return [pscustomobject]@{
    BackendUrl = $connection.BaseUrl
    Results    = @($results)
    Failed     = $failed
  }
}