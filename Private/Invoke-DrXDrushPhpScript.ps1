function Invoke-DrXDrushPhpScript {
  param(
    [Parameter(Mandatory)]
    [string]$PhpContents,
    [string]$ComposeService = 'backend',
    [string]$ContainerPhpPath = '/tmp/newschool-backend-testing.php'
  )

  $phpTempPath = Join-Path ([System.IO.Path]::GetTempPath()) ('newschool-backend-testing-{0}.php' -f [System.Guid]::NewGuid().ToString('N'))

  try {
    Set-DrXUtf8File -Path $phpTempPath -Content $PhpContents

    & docker compose cp $phpTempPath "${ComposeService}:${ContainerPhpPath}" | Out-Null
    if ($LASTEXITCODE -ne 0) {
      throw 'docker compose cp failed.'
    }

    $output = & docker compose exec $ComposeService bash -lc "sudo -u www-data /var/www/html/vendor/bin/drush php:script $ContainerPhpPath" 2>&1
    if ($LASTEXITCODE -ne 0) {
      throw (($output | Out-String).Trim())
    }

    $normalizedOutput = ($output | Out-String).Trim()
    return $normalizedOutput.TrimStart([char]0xFEFF)
  }
  finally {
    if (Test-Path $phpTempPath) {
      Remove-Item $phpTempPath -Force
    }

    try {
      & docker compose exec $ComposeService bash -lc "rm -f $ContainerPhpPath" | Out-Null
    } catch {
      Write-Verbose ("Unable to remove temporary container PHP file '{0}': {1}" -f $ContainerPhpPath, $_.Exception.Message)
    }
  }
}