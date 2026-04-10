#!/bin/bash

SETTINGS_FILE="settings.xml"

# Check if the file exists
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "Error: $SETTINGS_FILE does not exist"
    exit 1
fi

python3 << 'EOF'
import xml.etree.ElementTree as ET
import re

settings_file = "settings.xml"

try:
    with open(settings_file, 'r', encoding='utf-8') as f:
        content = f.read()

    new_value = 'xoj/template&#10;copyLastPageSize=true&#10;copyLastPageSettings=false&#10;size=595.275591x841.889764&#10;backgroundType=ruled&#10;backgroundTypeConfig=r1=20,f1=0xD6D8D6&#10;backgroundColor=#f8f7e9&#10;'

    pattern = r'(<property name="pageTemplate" value=")([^"]*)(")'
    replacement = r'\1' + new_value + r'\3'

    new_content = re.sub(pattern, replacement, content)

    with open(settings_file, 'w', encoding='utf-8') as f:
        f.write(new_content)

    print("Replacement complete!")

except Exception as e:
    print(f"Error: {e}")
    exit(1)
EOF

