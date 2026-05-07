function ConvertFrom-DrXSchemaText {
  param([string]$Text)

  $hasCatalog = $Text.Contains('catalog:')
  $hasReusableBundles = $Text.Contains('reusable_bundles:')
  $hasApplicationBundles = $Text.Contains('application_bundles:')

  if (-not $hasCatalog -or (-not $hasReusableBundles -and -not $hasApplicationBundles)) {
    throw 'Unsupported schema format. This module only supports schema v2 catalog format.'
  }

  return ConvertFrom-DrXCatalogSchemaText -Text $Text
}