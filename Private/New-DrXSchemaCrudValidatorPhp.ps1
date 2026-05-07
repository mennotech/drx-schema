function New-DrXSchemaCrudValidatorPhp {
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
    $title = sprintf('Schema validator %s %s', $bundle, substr(hash('sha256', microtime(true) . $bundle . random_int(1, PHP_INT_MAX)), 0, 8));

    try {
        $node = Node::create([
            'type' => $bundle,
            'title' => $title,
            'status' => FALSE,
        ]);
        $node->save();

        $nid = (int) $node->id();
        $uuid = $node->uuid();

        $loaded = Node::load($nid);
        if (!$loaded) {
            throw new RuntimeException('Read after create failed.');
        }

        if ($loaded->bundle() !== $bundle) {
            throw new RuntimeException(sprintf('Expected bundle %s, got %s.', $bundle, $loaded->bundle()));
        }

        $updatedTitle = $title . ' updated';
        $loaded->setTitle($updatedTitle);
        $loaded->save();

        $reloaded = Node::load($nid);
        if (!$reloaded) {
            throw new RuntimeException('Read after update failed.');
        }

        if ($reloaded->label() !== $updatedTitle) {
            throw new RuntimeException('Updated title was not persisted.');
        }

        $reloaded->delete();

        if (Node::load($nid)) {
            throw new RuntimeException('Delete failed; node still loads by ID.');
        }

        $results[] = [
            'bundle' => $bundle,
            'nid' => $nid,
            'uuid' => $uuid,
            'status' => 'ok',
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
  throw new RuntimeException('Schema CRUD validation failed.');
}
'@.Replace('__BUNDLE_LIST__', $bundleList)
}