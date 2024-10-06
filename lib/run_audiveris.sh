#!/bin/bash
export TESSDATA_PREFIX="/usr/local/share/tessdata"
export AUDIVERIS_OCR_LANGUAGES="eng+deu+fra"
AUDIVERIS_INSTALL="$HOME/Documents/ScoreSnap/audiveris-install/Audiveris-5.3.1"
"$AUDIVERIS_INSTALL/bin/Audiveris" "$@"