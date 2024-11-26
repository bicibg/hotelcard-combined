<?php

if ($argc < 3) {
    echo "Usage: php generate_openapi.php <path-to-api.php> <output-file-path>\n";
    exit(1);
}

$routesFilePath = $argv[1];
$outputFilePath = $argv[2];

function generateOpenApiSchema($routesFilePath, $outputFilePath) {
    $openApiTemplate = [
        "openapi" => "3.1.0",
        "info" => [
            "title" => "Laravel API Documentation",
            "description" => "Auto-generated API documentation.",
            "version" => "1.0.0"
        ],
        "servers" => [
            [
                "url" => "http://localhost:8000",
                "description" => "Local development server"
            ]
        ],
        "paths" => [],
        "components" => [
            "schemas" => []
        ]
    ];

    if (!file_exists($routesFilePath)) {
        echo "Error: File $routesFilePath not found.\n";
        exit(1);
    }

    $routes = file($routesFilePath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);

    foreach ($routes as $route) {
        if (preg_match('/Route::([a-z]+)\(\'\/(.*?)\', \[(.*?)::class, \'(.*?)\'\]\)(?:.*?->description\(\'(.*?)\'\))?/', $route, $matches)) {
            $method = strtolower($matches[1]);
            $path = "/" . trim($matches[2], "/");
            $controller = $matches[3];
            $action = $matches[4];
            $description = $matches[5] ?? "No description available.";

            // Build OpenAPI path
            $pathItem = [
                $method => [
                    "summary" => ucfirst($method) . " " . $path,
                    "operationId" => $action,
                    "description" => $description,
                    "parameters" => [],
                    "responses" => [
                        "200" => [
                            "description" => "Successful operation",
                            "content" => [
                                "application/json" => [
                                    "schema" => [
                                        "type" => "object"
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ];

            // Add the path to the OpenAPI schema
            $openApiTemplate["paths"][$path] = $pathItem;
        }
    }

    file_put_contents($outputFilePath, json_encode($openApiTemplate, JSON_PRETTY_PRINT));
    echo "OpenAPI schema has been generated and saved to $outputFilePath.\n";
}

generateOpenApiSchema($routesFilePath, $outputFilePath);

