function Remove-DrXExternalApiFixture {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [object[]]$CreatedNodes,
    [Parameter(Mandatory)]
    [psobject]$Connection
  )

  for ($index = $CreatedNodes.Count - 1; $index -ge 0; $index -= 1) {
    $node = $CreatedNodes[$index]
    if ($node.Deleted) {
      continue
    }

    try {
      if ($PSCmdlet.ShouldProcess($node.EntityPath, 'Delete external API fixture node')) {
        Invoke-DrXDrupalRequest -Method 'DELETE' -Uri "$($Connection.BaseUrl)$($node.EntityPath)" -Session $Connection.Session -Headers @{ Accept = 'application/vnd.api+json'; 'X-CSRF-Token' = $Connection.CsrfToken } | Out-Null
        $node.Deleted = $true
      }
    } catch {
      Write-Verbose ("Unable to delete external API fixture '{0}': {1}" -f $node.EntityPath, $_.Exception.Message)
    }
  }
}