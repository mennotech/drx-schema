function Invoke-DrXDrupalRequest {
  param(
    [Parameter(Mandatory)]
    [string]$Method,
    [Parameter(Mandatory)]
    [string]$Uri,
    [Parameter(Mandatory)]
    [Microsoft.PowerShell.Commands.WebRequestSession]$Session,
    [object]$Body = $null,
    [hashtable]$Headers = @{},
    [string]$ContentType = 'application/json'
  )

  $request = @{
    Method = $Method
    Uri = $Uri
    WebSession = $Session
    Headers = $Headers
    ErrorAction = 'Stop'
  }

  if ($null -ne $Body) {
    $request.Body = if ($Body -is [string]) { $Body } else { $Body | ConvertTo-Json -Depth 20 }
    $request.ContentType = $ContentType
  }

  return Invoke-RestMethod @request
}