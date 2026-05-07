function Get-DrXMd5Hex {
  param([string]$Value)

  $md5 = [System.Security.Cryptography.MD5]::Create()
  try {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Value)
    return -join ($md5.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') })
  } finally {
    $md5.Dispose()
  }
}