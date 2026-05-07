<#
.SYNOPSIS
Performs a backend authentication and JSON:API smoke test.

.DESCRIPTION
Authenticates against the configured backend and verifies that login status,
CSRF token retrieval, and JSON:API index access all succeed.

.PARAMETER EnvFile
Optional path to the environment file that contains backend credentials.

.EXAMPLE
Invoke-DrXApiSmokeTest -EnvFile '.env'

.INPUTS
None. You cannot pipe input to this function.

.OUTPUTS
pscustomobject. Returns backend connectivity and JSON:API smoke test details.

.NOTES
Author: GitHub Copilot
Version: 0.1.0

.LINK
Connect-DrXBackend
#>
function Invoke-DrXApiSmokeTest {
  [CmdletBinding()]
  param(
    [string]$EnvFile
  )

  $connection = Connect-DrXBackend -EnvFile $EnvFile
  $loginStatus = Invoke-DrXDrupalRequest -Method 'GET' -Uri "$($connection.BaseUrl)/user/login_status?_format=json" -Session $connection.Session
  if (-not $loginStatus) {
    throw 'Login status endpoint returned a falsy value.'
  }

  $jsonApiIndex = Invoke-DrXDrupalRequest -Method 'GET' -Uri "$($connection.BaseUrl)/jsonapi" -Session $connection.Session -Headers @{ Accept = 'application/vnd.api+json' }

  return [pscustomobject]@{
    BackendUrl = $connection.BaseUrl
    LoginUserId = $connection.LoginResponse.current_user.uid
    LoginUserName = $connection.LoginResponse.current_user.name
    LoginStatus = [bool]$loginStatus
    CsrfToken = $connection.CsrfToken
    JsonApiLinks = @($jsonApiIndex.links.PSObject.Properties.Name)
  }
}
