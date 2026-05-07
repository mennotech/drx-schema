function New-DrXApiFixtureCleanupPhp {
  [CmdletBinding(SupportsShouldProcess)]
  param([int[]]$Nids)

  $nidList = ($Nids | ForEach-Object { "    {0}" -f $_ }) -join ",`n"

  @'
<?php

use Drupal\node\Entity\Node;

$nids = [
__NID_LIST__
];

foreach ($nids as $nid) {
  $node = Node::load($nid);
  if ($node) {
    $node->delete();
  }
}
'@.Replace('__NID_LIST__', $nidList)
}