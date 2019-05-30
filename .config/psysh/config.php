<?php
if (is_file(getcwd() . '/vendor/autoload.php')) {
    require_once getcwd() . '/vendor/autoload.php';
}
return [
    'usePcntl' => false,
];
