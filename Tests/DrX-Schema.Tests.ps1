BeforeAll {
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\DrX-Schema.psd1'
  Import-Module $modulePath -Force
  $script:Manifest = Import-PowerShellDataFile -Path $modulePath
}

Describe 'DrX-Schema module structure' {
  It 'exports the manifest functions' {
    $exportedCommands = Get-Command -Module DrX-Schema | Select-Object -ExpandProperty Name | Sort-Object

    $exportedCommands | Should -Be ($script:Manifest.FunctionsToExport | Sort-Object)
  }

  It 'keeps helper functions private' {
    { Get-Command -Name Resolve-DrXSchemaPath -Module DrX-Schema -ErrorAction Stop } | Should -Throw
    { Get-Command -Name ConvertFrom-DrXSchemaText -Module DrX-Schema -ErrorAction Stop } | Should -Throw
  }

  It 'exports advanced functions with comment-based help' {
    foreach ($functionName in $script:Manifest.FunctionsToExport) {
      $command = Get-Command -Name $functionName -Module DrX-Schema -ErrorAction Stop
      $help = Get-Help -Name $functionName -ErrorAction Stop

      $command.CmdletBinding | Should -BeTrue
      $help.Synopsis | Should -Not -BeNullOrEmpty
      $help.description.Text | Should -Not -BeNullOrEmpty
      $help.examples.example.code | Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'DrX-Schema schema import' {
  It 'parses and normalizes the example schema directory' {
    $schemaPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Example'
    $parsedSchema = Import-DrXSchema -SchemaPath $schemaPath
    $normalizedSchema = ConvertTo-DrXNormalizedSchema -ParsedSchema $parsedSchema
    $bundleCount = @($parsedSchema.catalog.reusable_bundles).Count + @($parsedSchema.catalog.application_bundles).Count

    $parsedSchema.catalog.reusable_bundles.Count | Should -BeGreaterThan 0
    $bundleCount | Should -BeGreaterThan 0
    $normalizedSchema.bundles.Count | Should -Be $bundleCount
  }

  It 'resolves schema path from the provided env file when schema path is omitted' {
    $tempRoot = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.Guid]::NewGuid().ToString())
    $schemaDir = Join-Path -Path $tempRoot -ChildPath 'schema'
    $envFile = Join-Path -Path $tempRoot -ChildPath '.env'

    New-Item -ItemType Directory -Path $schemaDir -Force | Out-Null
    Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\Example\*.yaml') -Destination $schemaDir
    Set-Content -Path $envFile -Value 'DRX_SCHEMA_PATH=./schema'

    try {
      $parsedSchema = Import-DrXSchema -EnvFile $envFile
      $bundles = Get-DrXSchemaBundle -EnvFile $envFile

      $parsedSchema.catalog.reusable_bundles.Count | Should -BeGreaterThan 0
      $bundles.Count | Should -BeGreaterThan 0
    }
    finally {
      Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
  }
}

Describe 'DrX-Schema lint' -Tag 'Lint' {
  It 'passes the focused PSScriptAnalyzer ruleset' -Skip:(-not (Get-Command -Name Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue)) {
    $settingsPath = Join-Path -Path $PSScriptRoot -ChildPath '..\PSScriptAnalyzerSettings.psd1'
    $files = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath '..') -Recurse -File -Include '*.ps1', '*.psm1', '*.psd1'
    $results = foreach ($file in $files) {
      Invoke-ScriptAnalyzer -Path $file.FullName -Settings $settingsPath
    }

    $results | Should -BeNullOrEmpty
  }
}

Describe 'DrX-Schema backend smoke test' -Tag 'Integration' {
  It 'authenticates against the configured backend' -Skip:(-not (Test-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\.env'))) {
    $result = Invoke-DrXApiSmokeTest -EnvFile (Join-Path -Path $PSScriptRoot -ChildPath '..\.env')

    $result.LoginStatus | Should -BeTrue
    $result.CsrfToken | Should -Not -BeNullOrEmpty
    $result.JsonApiLinks.Count | Should -BeGreaterThan 0
  }
}