function Get-DrXBackendCandidate {
  param([string]$ConfiguredUrl)

  $candidates = [System.Collections.Generic.List[string]]::new()

  if ($ConfiguredUrl) {
    $candidates.Add($ConfiguredUrl.TrimEnd('/'))

    try {
      $uri = [Uri]$ConfiguredUrl
      if ($uri.Host -ne 'localhost' -and $uri.Host -ne '127.0.0.1') {
        $builder = [UriBuilder]::new($uri)
        $builder.Host = 'localhost'
        $candidates.Add($builder.Uri.AbsoluteUri.TrimEnd('/'))
      }
    } catch {
      Write-Verbose ("Ignoring invalid BACKEND_URL '{0}': {1}" -f $ConfiguredUrl, $_.Exception.Message)
    }
  }

  if ($candidates.Count -eq 0) {
    $candidates.Add('http://localhost:8080')
  }

  return $candidates | Select-Object -Unique
}