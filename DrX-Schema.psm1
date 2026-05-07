Set-StrictMode -Version Latest

$privateFunctionFiles = @(
  Get-ChildItem -Path (Join-Path $PSScriptRoot 'Private') -Filter *.ps1 -File -ErrorAction SilentlyContinue |
    Sort-Object Name
)

foreach ($file in $privateFunctionFiles) {
  . $file.FullName
}

$publicFunctionFiles = @(
  Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public') -Filter *.ps1 -File -ErrorAction SilentlyContinue |
    Sort-Object Name
)

foreach ($file in $publicFunctionFiles) {
  . $file.FullName
}

$moduleManifest = Import-PowerShellDataFile -Path (Join-Path $PSScriptRoot 'DrX-Schema.psd1')
Export-ModuleMember -Function $moduleManifest.FunctionsToExport