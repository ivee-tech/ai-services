#!/bin/bash

# Function to pull all tags for a given image
pullpush_aisvc_image() {
    local image_name="$1"
    local target_registry="${2:-localhost:8090}"  # default to localhost:8090 if not provided
    shift 2
    local tags=("$@")  # remaining arguments are tags
    
    echo "================================================================================"
    echo -e "\033[32mProcessing image: $image_name\033[0m"
    echo "================================================================================"
    
    for tag in "${tags[@]}"; do
        local full_image_name="${image_name}:${tag}"
        echo -e "\033[33mPulling: $full_image_name\033[0m"
        
        if docker pull "$full_image_name"; then
            if [[ -n "$target_registry" ]]; then
                docker tag "$full_image_name" "$target_registry/library/$full_image_name"
                docker push "$target_registry/library/$full_image_name"
            fi
            
            if [[ $? -eq 0 ]]; then
                echo -e "\033[32m✓ Successfully pulled: $full_image_name\033[0m"
            else
                echo -e "\033[31m✗ Failed to pull: $full_image_name\033[0m"
            fi
        else
            echo -e "\033[31m✗ Error pulling $full_image_name\033[0m"
        fi
        
        echo ""
    done
}

# Example usage:
# pullpush_aisvc_image "myimage" "localhost:8090" "tag1" "tag2" "tag3"
# or with default registry:
# pullpush_aisvc_image "myimage" "" "tag1" "tag2" "tag3"