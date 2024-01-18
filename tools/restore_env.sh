#!/bin/bash

SCRIPTS=(resquash.sh)

ORIGINAL_SHEBANG_LINE1="#!/bin/bash"
ORIGINAL_SHEBANG_LINE2="#"

for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        # Replace the first two lines with the original shebang lines
        sed -i "1s|.*|${ORIGINAL_SHEBANG_LINE1}|; 2s|.*|${ORIGINAL_SHEBANG_LINE2}|" "$script"
    fi
done

echo "Scripts reverted to original state"
echo
echo "Removing .env file..."
rm ./.env
