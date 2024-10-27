#!/bin/bash

export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export PATH="$JAVA_HOME/bin:$PATH"

export TESSDATA_PREFIX="/usr/local/share/tessdata"
export AUDIVERIS_OCR_LANGUAGES="eng+deu+fra"

AUDIVERIS_INSTALL="$HOME/Documents/ScoreSnap/audiveris-install/Audiveris-5.3.1"

"$AUDIVERIS_INSTALL/bin/Audiveris" "$@"

# "$AUDIVERIS_INSTALL/bin/Audiveris" \
#   -option "staff.line.thickness=2.0" \
#   -option "staff.line.peek=2.0" \
#   -option "staff.line.max=6.0" \
#   -option "staff.lineCleaner.maxCurvature=0.5" \
#   -option "staff.pattern.halfLine=false" \
#   "$@"