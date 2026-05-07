function ConvertTo-DrXYaml {
  param(
    [object]$Value,
    [int]$Indent = 0
  )

  $sp = ' ' * $Indent

  if ($null -ne $Value -and -not ($Value -is [string]) -and $Value -is [System.Collections.IEnumerable] -and -not ($Value -is [System.Collections.IDictionary]) -and -not ($Value -is [pscustomobject])) {
    $items = @($Value)
    if ($items.Count -eq 0) {
      return "$sp[]"
    }

    $lines = foreach ($item in $items) {
      if (($item -is [System.Collections.IDictionary]) -or ($item -is [pscustomobject]) -or ($item -is [System.Collections.IEnumerable] -and -not ($item -is [string]))) {
        $nested = ConvertTo-DrXYaml -Value $item -Indent ($Indent + 2)
        $nestedLines = $nested -split "`n"
        $first = $nestedLines[0].TrimStart()
        $rest = @($nestedLines | Select-Object -Skip 1)
        if ($rest.Count -eq 0) {
          "$sp- $first"
        } else {
          "$sp- $first`n$($rest -join "`n")"
        }
      } else {
        "$sp- $(Format-DrXYamlScalar $item)"
      }
    }
    return ($lines -join "`n")
  }

  if ($Value -is [System.Collections.IDictionary]) {
    $entries = @($Value.GetEnumerator())
    if ($entries.Count -eq 0) {
      return "$sp{}"
    }

    $lines = foreach ($entry in $entries) {
      $key = [string]$entry.Key
      $entryValue = $entry.Value
      if (($entryValue -is [System.Collections.IDictionary]) -or ($entryValue -is [pscustomobject]) -or ($entryValue -is [System.Collections.IEnumerable] -and -not ($entryValue -is [string]))) {
        $nested = ConvertTo-DrXYaml -Value $entryValue -Indent ($Indent + 2)
        $trimmed = $nested.Trim()
        if ($trimmed -eq '[]' -or $trimmed -eq '{}') {
          "${sp}${key}: $trimmed"
        } else {
          "${sp}${key}:`n$nested"
        }
      } else {
        "${sp}${key}: $(Format-DrXYamlScalar $entryValue)"
      }
    }
    return ($lines -join "`n")
  }

  if ($Value -is [pscustomobject]) {
    $ordered = [ordered]@{}
    foreach ($property in $Value.PSObject.Properties) {
      $ordered[$property.Name] = $property.Value
    }
    return ConvertTo-DrXYaml -Value $ordered -Indent $Indent
  }

  return "$sp$(Format-DrXYamlScalar $Value)"
}