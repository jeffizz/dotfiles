#!/usr/bin/env bash

# Remove sellect-all binding
perl -i -0pe 's/<section>\s*<item>\s*<attribute name="label" translatable="yes">Select All<\/attribute>.*?<\/section>//s' /Applications/./Xournal++.app/Contents/Resources/ui/mainmenubar.xml
# [Toggle toolbar/sidebar] Changed from F9\/F12 to Meta+t\/Meta+b
perl -i -pe 's/F9/&lt;Meta&gt;t/g; s/F12/&lt;Meta&gt;b/g' /Applications/./Xournal++.app/Contents/Resources/ui/mainmenubar.xml
