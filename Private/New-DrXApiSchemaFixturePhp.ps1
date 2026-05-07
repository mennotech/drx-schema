function New-DrXApiSchemaFixturePhp {
    [CmdletBinding(SupportsShouldProcess)]
    param([object[]]$Bundles)

  $bundleList = ($Bundles | ForEach-Object { "    '{0}'" -f $_.Bundle }) -join ",`n"

  @'
<?php

use Drupal\node\Entity\Node;

$bundles = [
__BUNDLE_LIST__
];

$results = [];
$failed = false;

foreach ($bundles as $bundle) {
    $title = sprintf('API schema fixture %s %s', $bundle, substr(hash('sha256', microtime(true) . $bundle . random_int(1, PHP_INT_MAX)), 0, 8));

    try {
        $node = Node::create([
            'type' => $bundle,
            'title' => $title,
            'status' => FALSE,
        ]);
        $node->save();

        $results[] = [
            'bundle' => $bundle,
            'nid' => (int) $node->id(),
            'uuid' => $node->uuid(),
            'title' => $title,
            'jsonapi_type' => 'node--' . $bundle,
            'collection_path' => '/jsonapi/node/' . $bundle,
            'entity_path' => '/jsonapi/node/' . $bundle . '/' . $node->uuid(),
        ];
    }
    catch (Throwable $exception) {
        $failed = true;
        $results[] = [
            'bundle' => $bundle,
            'status' => 'error',
            'message' => $exception->getMessage(),
        ];
    }
}

print json_encode([
    'failed' => $failed,
    'results' => $results,
], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . PHP_EOL;

if ($failed) {
  throw new RuntimeException('Fixture creation failed.');
}
'@.Replace('__BUNDLE_LIST__', $bundleList)
}