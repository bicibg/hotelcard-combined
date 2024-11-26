#!/bin/bash

# Define the Laravel project directory and output file
PROJECT_PATH=$1
OUTPUT_FILE="combined_laravel_project.txt"
REPO_PATH=$2
COMMIT_MESSAGE=${3:-"Update combined Laravel project file"}

# Check if the project path and repo path are provided
if [ -z "$PROJECT_PATH" ] || [ -z "$REPO_PATH" ]; then
  echo "Usage: $0 <path-to-laravel-project> <path-to-repo> [commit-message]"
  exit 1
fi

# Exclude directories and specify file extensions
EXCLUDE_DIRS=("vendor" "node_modules" ".git" "storage")
#INCLUDE_EXTENSIONS=("php" "blade.php" "js" "css" "env" "json" "md")
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

# Move the combined file to the repository directory
mv "$OUTPUT_FILE" "$REPO_PATH"

# Change to the repository directory
cd "$REPO_PATH" || exit

# Add, commit, and push the changes to the

