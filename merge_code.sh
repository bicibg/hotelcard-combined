#!/bin/bash

# Define the Laravel project directory and output files
PROJECT_PATH=$1
REPO_PATH="." # Replace with the local path to your Git repo
PROJECT_NAME=$(basename "$PROJECT_PATH") # Extract the directory name
OUTPUT_FILE="$REPO_PATH/${PROJECT_NAME}.txt"
OPENAPI_FILE="$PROJECT_PATH/openapi.json" # Place openapi.json in the project root
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
COMMIT_MESSAGE="Update ${PROJECT_NAME} file and OpenAPI schema - $TIMESTAMP"

# Check if the project path is provided
if [ -z "$PROJECT_PATH" ]; then
  echo "Usage: $0 <path-to-laravel-project>"
  exit 1
fi

# Exclude directories and specify file extensions
EXCLUDE_DIRS=("vendor" "node_modules" ".git" "storage")
INCLUDE_EXTENSIONS=("php")

# Convert the exclude dirs to find command parameters
EXCLUDE_FIND_PARAMS=()
for dir in "${EXCLUDE_DIRS[@]}"; do
  EXCLUDE_FIND_PARAMS+=(-path "*/$dir/*" -prune -o)
done

# Create or empty the output file
> "$OUTPUT_FILE"

# Function to check if a file extension is in the allowed list
is_allowed_extension() {
  local filename="$1"
  for ext in "${INCLUDE_EXTENSIONS[@]}"; do
    if [[ "$filename" == *.$ext ]]; then
      return 0
    fi
  done
  return 1
}

# Combine files
while IFS= read -r -d '' file; do
  if is_allowed_extension "$file"; then
    relative_path=${file#$PROJECT_PATH/}
    echo -e "\n\n# START OF FILE: $relative_path\n" >> "$OUTPUT_FILE"
    cat "$file" >> "$OUTPUT_FILE"
    echo -e "\n# END OF FILE: $relative_path\n" >> "$OUTPUT_FILE"
  fi
done < <(find "$PROJECT_PATH" "${EXCLUDE_FIND_PARAMS[@]}" -type f -print0)

echo "Combined Laravel project files into $OUTPUT_FILE"

# Generate OpenAPI schema from routes/api.php
API_FILE="$PROJECT_PATH/routes/api.php"
if [ -f "$API_FILE" ]; then
  echo "Generating OpenAPI schema from $API_FILE..."
  php generate_openapi.php "$API_FILE" "$OPENAPI_FILE"
else
  echo "No api.php file found at $API_FILE. Skipping OpenAPI schema generation."
fi

# Change to the repository directory
cd "$REPO_PATH" || exit

# Add, commit, and push the changes to the remote repository
git add "$OUTPUT_FILE" "$OPENAPI_FILE"
git commit -m "$COMMIT_MESSAGE"
git push origin main

echo "Files pushed to https://github.com/bicibg/hotelcard-combined.git (main branch)"

