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

    // Read and preprocess the file
    $routes = file_get_contents($routesFilePath);
    $compressedRoutes = preg_replace('/\s+/', ' ', $routes); // Remove extra spaces and newlines

    // Updated regex to capture description properly
    preg_match_all(
        "/Route::([a-z]+)\s*\(\s*'\/([^']*)'\s*,\s*\[(.*?)::class,\s*'(.*?)'\]\)\s*(?:->name\('([^']+)'\))?\s*(?:->description\('([^']+)'\))?/i",
        $compressedRoutes,
        $matches,
        PREG_SET_ORDER
    );

    foreach ($matches as $match) {
        $method = strtolower($match[1]); // HTTP method
        $path = "/" . trim($match[2], "/"); // Route path
        $controller = $match[3]; // Controller class
        $action = $match[4]; // Controller method
        $name = $match[5] ?? ""; // Optional route name
        $description = $match[6] ?? "No description available."; // Optional description

        // Debug output
        echo "Matched Route: Method = $method, Path = $path, Description = $description\n";

        // Build OpenAPI path entry
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

        // Add to OpenAPI paths
        $openApiTemplate["paths"][$path] = $pathItem;
    }

    file_put_contents($outputFilePath, json_encode($openApiTemplate, JSON_PRETTY_PRINT));
    echo "OpenAPI schema has been generated and saved to $outputFilePath.\n";
}

generateOpenApiSchema($routesFilePath, $outputFilePath);

