@{
  RootModule = 'DrX-Schema.psm1'
  ModuleVersion = '0.1.0'
  GUID = 'be8dc9f9-3680-42bb-a157-01480e7365b1'
  Author = 'GitHub Copilot'
  CompanyName = 'Mennotech'
  Copyright = '(c) Mennotech'
  Description = 'Backend schema scaffolding and validation helpers for NewSchool Apply.'
  PowerShellVersion = '7.0'
  FunctionsToExport = @(
    'Connect-DrXBackend',
    'ConvertTo-DrXNormalizedSchema',
    'Export-DrXDrupalScaffoldConfig',
    'Get-DrXSchemaBundle',
    'Import-DrXSchema',
    'Invoke-DrXExternalApiSchemaValidation',
    'Invoke-DrXApiSchemaValidation',
    'Invoke-DrXApiSmokeTest',
    'Invoke-DrXSchemaCrudValidation'
  )
  CmdletsToExport = @()
  VariablesToExport = @()
  AliasesToExport = @()
}