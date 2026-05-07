<#
.SYNOPSIS
Connects to a configured Drupal backend and returns an authenticated session.

.DESCRIPTION
Reads backend connection settings from an environment file, authenticates with the
configured Drupal backend, and returns the session, CSRF token, and login response.

.PARAMETER EnvFile
Optional path to the environment file that contains backend credentials.

.EXAMPLE
Connect-DrXBackend -EnvFile '.env'

.INPUTS
None. You cannot pipe input to this function.

.OUTPUTS
pscustomobject. Returns connection details for the authenticated backend session.

.NOTES
Author: GitHub Copilot
Version: 0.1.0

.LINK
Invoke-DrXApiSmokeTest
#>
function Connect-DrXBackend {
  [CmdletBinding()]
  param(
    [string]$EnvFile
  )

  $envMap = Get-DrXEnvMap -Path (Resolve-DrXEnvFilePath -EnvFile $EnvFile)
  $adminUser = $envMap['DRUPAL_ADMIN_USER']
  $adminPass = $envMap['DRUPAL_ADMIN_PASS']
  $backendUrl = $envMap['BACKEND_URL']

  if (-not $adminUser -or -not $adminPass) {
    throw 'DRUPAL_ADMIN_USER and DRUPAL_ADMIN_PASS are required in .env.'
  }

  $lastError = $null

  foreach ($candidateUrl in Get-DrXBackendCandidate -ConfiguredUrl $backendUrl) {
    $session = [Microsoft.PowerShell.Commands.WebRequestSession]::new()

    try {
      $loginResponse = Invoke-DrXDrupalRequest -Method 'POST' -Uri "$candidateUrl/user/login?_format=json" -Session $session -Body @{
        name = $adminUser
        pass = $adminPass
      }

      if (-not $loginResponse.current_user.uid) {
        throw 'Login response did not include current_user.uid.'
      }

      $csrfToken = Invoke-DrXDrupalRequest -Method 'GET' -Uri "$candidateUrl/session/token" -Session $session
      if (-not $csrfToken) {
        throw 'Session token endpoint returned an empty response.'
      }

      return [pscustomobject]@{
        EnvMap = $envMap
        BaseUrl = $candidateUrl
        Session = $session
        CsrfToken = [string]$csrfToken
        LoginResponse = $loginResponse
      }
    } catch {
      $lastError = $_
    }
  }

  if ($null -ne $lastError) {
    throw $lastError
  }

  throw 'No backend URL candidates were available to test.'
}
