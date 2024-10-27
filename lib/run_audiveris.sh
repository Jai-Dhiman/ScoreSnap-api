#!/bin/bash

export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export PATH="$JAVA_HOME/bin:$PATH"

export TESSDATA_PREFIX="/usr/local/share/tessdata"
export AUDIVERIS_OCR_LANGUAGES="eng+deu+fra"

AUDIVERIS_INSTALL="$HOME/Documents/ScoreSnap/audiveris-install/Audiveris-5.3.1"

# "$AUDIVERIS_INSTALL/bin/Audiveris" "$@"

"$AUDIVERIS_INSTALL/bin/Audiveris" \
  -option "staff.line.thickness=3.0" \
  -option "staff.line.peek=3.0" \
  -option "staff.line.max=8.0" \
  -option "staff.pattern.detectAll=true" \
  -option "staff.pattern.checkInBetween=false" \
  -option "beam.minThickness=2.0" \
  -option "beam.maxThickness=6.0" \
  -option "stem.minHeight=25" \
  -option "head.minWidth=1.5" \
  -option "head.minHeight=1.5" \
  -option "clef.minGrade=0.2" \
  -option "clef.lookupRange=20" \
  -option "clef.headerRange=200" \
  "$@"