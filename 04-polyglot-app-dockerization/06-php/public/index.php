<?php
header('Content-Type: application/json; charset=utf-8');

$requestUri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

if ($requestUri === '/health') {
    echo json_encode(['status' => 'healthy', 'service' => 'php-api', 'php_version' => PHP_VERSION]);
    exit;
}

echo json_encode([
    'message' => 'PHP 8.3 Web API Basariyla Calisiyor!',
    'php_version' => PHP_VERSION,
    'sapi' => php_sapi_name(),
    'opcache_enabled' => extension_loaded('Zend OPcache') && ini_get('opcache.enable'),
    'timestamp' => gmdate('Y-m-d\TH:i:s\Z')
]);
