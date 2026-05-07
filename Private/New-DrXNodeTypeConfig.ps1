function New-DrXNodeTypeConfig {
  [OutputType([System.Collections.Specialized.OrderedDictionary])]
  [CmdletBinding(SupportsShouldProcess)]
  param([hashtable]$Bundle)

  if (-not $PSCmdlet.ShouldProcess([string]$Bundle['machine_name'], 'Build node type configuration')) {
    return $null
  }

  return [ordered]@{
    langcode = 'en'
    status = $true
    dependencies = [ordered]@{ module = @('node') }
    name = if ($Bundle['label']) { $Bundle['label'] } else { 'Application' }
    type = if ($Bundle['machine_name']) { $Bundle['machine_name'] } else { 'application' }
    description = if ($Bundle['description']) { $Bundle['description'] } else { 'Generated application content type' }
    help = ''
    new_revision = $false
    preview_mode = 1
    display_submitted = $false
  }
}