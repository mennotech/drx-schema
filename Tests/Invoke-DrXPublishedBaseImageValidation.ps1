<#
.SYNOPSIS
Pulls the published drx-drupal-base image and validates the generated schema against it.

.DESCRIPTION
Generates Drupal scaffold configuration from the example schema, mounts that
configuration into a running drx-drupal-base container, waits for the Drupal
healthcheck to report healthy, and then runs the existing smoke, external API,
internal API, and CRUD validation commands against that container.

.PARAMETER BaseImage
Published drx-drupal-base image tag to validate against.

.PARAMETER SchemaPath
Schema file or directory used to generate Drupal configuration.

.PARAMETER ContainerName
Docker container name used for the validation run.

.PARAMETER HostPort
Host port mapped to the container's port 80.

.PARAMETER BackendUrl
Public backend URL written to the generated env file and injected into the container.

.PARAMETER FrontendUrl
Frontend URL injected into the container for CORS defaults.

.PARAMETER AdminUser
Drupal admin username used by the validation commands.

.PARAMETER AdminPass
Drupal admin password required for first install and login.

.PARAMETER StartupTimeoutSeconds
Maximum number of seconds to wait for the container healthcheck.

.PARAMETER ResultDir
Optional directory where smoke and validation JSON payloads are written.

.PARAMETER KeepArtifacts
Keeps the generated config, env file, and result payloads on disk after the run.

.EXAMPLE
pwsh ./Tests/Invoke-DrXPublishedBaseImageValidation.ps1

.EXAMPLE
pwsh ./Tests/Invoke-DrXPublishedBaseImageValidation.ps1 -BaseImage 'ghcr.io/mennotech/drx-drupal-base:0.0.1-rc1' -KeepArtifacts
#>
[CmdletBinding()]
param(
  [string]$BaseImage = 'ghcr.io/mennotech/drx-drupal-base:0.0.1-rc1',
  [string]$SchemaPath = (Join-Path $PSScriptRoot '..\Example\Schema'),
  [string]$ContainerName = 'backend',
  [int]$HostPort = 8080,
  [string]$BackendUrl = 'http://localhost:8080',
  [string]$FrontendUrl = 'http://localhost:3000',
  [string]$AdminUser = 'admin',
  [string]$AdminPass = 'admin',
  [ValidateRange(30, 900)]
  [int]$StartupTimeoutSeconds = 300,
  [string]$ResultDir,
  [switch]$KeepArtifacts
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

function Invoke-DrXDockerCommand {
  param(
    [Parameter(Mandatory)]
    [string[]]$Arguments,
    [switch]$AllowFailure
  )

  $output = & docker @Arguments 2>&1
  if (-not $AllowFailure -and $LASTEXITCODE -ne 0) {
    throw ((@(
      'docker {0} failed with exit code {1}.' -f ($Arguments -join ' '),
      ($output | Out-String).Trim()
    ) -join [Environment]::NewLine).Trim())
  }

  return $output
}

function Write-DrXUtf8NoBomFile {
  param(
    [Parameter(Mandatory)]
    [string]$Path,
    [Parameter(Mandatory)]
    [string[]]$Lines
  )

  $directory = Split-Path -Path $Path -Parent
  if ($directory) {
    [System.IO.Directory]::CreateDirectory($directory) | Out-Null
  }

  $encoding = [System.Text.UTF8Encoding]::new($false)
  [System.IO.File]::WriteAllLines($Path, $Lines, $encoding)
}

function Wait-DrXContainerHealthy {
  param(
    [Parameter(Mandatory)]
    [string]$Name,
    [Parameter(Mandatory)]
    [int]$TimeoutSeconds
  )

  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    $stateJson = Invoke-DrXDockerCommand -Arguments @('inspect', $Name, '--format', '{{json .State}}')
    $state = ($stateJson | Out-String).Trim() | ConvertFrom-Json

    if ($state.Status -in @('exited', 'dead')) {
      $logs = Invoke-DrXDockerCommand -Arguments @('logs', $Name) -AllowFailure
      throw ((@(
        "Container '$Name' exited before becoming healthy.",
        ($logs | Out-String).Trim()
      ) -join [Environment]::NewLine).Trim())
    }

    if ($state.PSObject.Properties.Name -contains 'Health' -and $state.Health.Status -eq 'healthy') {
      return
    }

    Start-Sleep -Seconds 2
  }

  $finalState = Invoke-DrXDockerCommand -Arguments @('inspect', $Name, '--format', '{{json .State}}')
  $logs = Invoke-DrXDockerCommand -Arguments @('logs', $Name) -AllowFailure
  throw ((@(
    "Timed out waiting $TimeoutSeconds second(s) for container '$Name' to become healthy.",
    "Final state: $($finalState | Out-String).Trim()",
    ($logs | Out-String).Trim()
  ) -join [Environment]::NewLine).Trim())
}

$modulePath = Join-Path $PSScriptRoot '..\DrX-Schema.psd1'
Import-Module $modulePath -Force

$resolvedSchemaPath = [System.IO.Path]::GetFullPath($SchemaPath)
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('drx-published-image-validation-' + [System.Guid]::NewGuid().ToString('N'))
$configDir = Join-Path $tempRoot 'config/sync'
$resolvedConfigDir = [System.IO.Path]::GetFullPath($configDir)
$resolvedResultDir = if ($ResultDir) {
  [System.IO.Path]::GetFullPath($ResultDir)
} else {
  Join-Path $tempRoot 'results'
}
$envFile = Join-Path $tempRoot '.env'

[System.IO.Directory]::CreateDirectory($resolvedConfigDir) | Out-Null
[System.IO.Directory]::CreateDirectory($resolvedResultDir) | Out-Null

try {
  Write-Information "Pulling published image $BaseImage..." -InformationAction Continue
  Invoke-DrXDockerCommand -Arguments @('pull', $BaseImage) | Write-Verbose

  Write-Information 'Generating Drupal scaffold config from schema...' -InformationAction Continue
  $exportResult = Export-DrXDrupalScaffoldConfig -SchemaPath $resolvedSchemaPath -OutputDir $resolvedConfigDir

  Write-DrXUtf8NoBomFile -Path $envFile -Lines @(
    "BACKEND_URL=$BackendUrl",
    "FRONTEND_URL=$FrontendUrl",
    "DRUPAL_ADMIN_USER=$AdminUser",
    "DRUPAL_ADMIN_PASS=$AdminPass",
    "DRX_SCHEMA_PATH=$resolvedSchemaPath"
  )

  Invoke-DrXDockerCommand -Arguments @('rm', '-f', $ContainerName) -AllowFailure | Out-Null

  Write-Information "Starting backend container '$ContainerName'..." -InformationAction Continue
  $containerId = (Invoke-DrXDockerCommand -Arguments @(
    'run',
    '--detach',
    '--name', $ContainerName,
    '--publish', ("{0}:80" -f $HostPort),
    '--env', ("DRUPAL_ADMIN_USER={0}" -f $AdminUser),
    '--env', ("DRUPAL_ADMIN_PASS={0}" -f $AdminPass),
    '--env', ("BACKEND_URL={0}" -f $BackendUrl),
    '--env', ("FRONTEND_URL={0}" -f $FrontendUrl),
    '--env', 'DRUPAL_JSONAPI_READ_ONLY=0',
    '--mount', ("type=bind,source={0},target=/var/www/html/config/sync,readonly" -f $resolvedConfigDir),
    $BaseImage
  ) | Select-Object -Last 1).ToString().Trim()

  if (-not $containerId) {
    throw "Docker did not return a container id for '$ContainerName'."
  }

  Write-Information 'Waiting for Drupal healthcheck...' -InformationAction Continue
  Wait-DrXContainerHealthy -Name $ContainerName -TimeoutSeconds $StartupTimeoutSeconds

  Write-Information 'Running backend smoke test...' -InformationAction Continue
  $smokeResult = Invoke-DrXApiSmokeTest -EnvFile $envFile
  $smokeResult | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path $resolvedResultDir 'smoke.json') -Encoding utf8

  Write-Information 'Running external API schema validation...' -InformationAction Continue
  $externalResult = @(Invoke-DrXExternalApiSchemaValidation -SchemaPath $resolvedSchemaPath -EnvFile $envFile)
  $externalResult | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path $resolvedResultDir 'external-api-validation.json') -Encoding utf8

  Write-Information 'Running internal API schema validation...' -InformationAction Continue
  $internalResult = @(Invoke-DrXApiSchemaValidation -SchemaPath $resolvedSchemaPath -ComposeService $ContainerName -EnvFile $envFile)
  $internalResult | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path $resolvedResultDir 'internal-api-validation.json') -Encoding utf8

  Write-Information 'Running CRUD schema validation...' -InformationAction Continue
  $crudResult = @(Invoke-DrXSchemaCrudValidation -SchemaPath $resolvedSchemaPath -ComposeService $ContainerName)
  $crudResult | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path $resolvedResultDir 'crud-validation.json') -Encoding utf8

  return [pscustomobject]@{
    BaseImage = $BaseImage
    ContainerName = $ContainerName
    ContainerId = $containerId
    SchemaPath = $resolvedSchemaPath
    GeneratedConfigDir = $resolvedConfigDir
    ResultDir = $resolvedResultDir
    BackendUrl = $BackendUrl
    BundleCount = @($exportResult.Bundles).Count
    FieldCount = $exportResult.FieldCount
    SmokeTest = $smokeResult
    ExternalApiResults = $externalResult
    InternalApiResults = $internalResult
    CrudResults = $crudResult
  }
}
finally {
  Invoke-DrXDockerCommand -Arguments @('rm', '-f', $ContainerName) -AllowFailure | Out-Null

  if (-not $KeepArtifacts -and (Test-Path $tempRoot)) {
    Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
}
