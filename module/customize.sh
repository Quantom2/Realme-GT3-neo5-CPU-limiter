#!/system/bin/sh

############### CUSTOM FUNCTIONS ################

LOGFILE="/sdcard/Quantom.log"
NUM_LOG=1

echo "Start installing, definig functions, logfile clear" > "$LOGFILE"

log() {
  while [ $# -gt 0 ]; do
    case "$1" in
      -a) local ABORT=1 ;;
      -u) local UIP=1 ;;
      --) shift; break ;;
      -*) echo "Unknown flag: $1 , ignoring" >> $LOGFILE ;;
      *) 
        if [ -z "$MSG" ]; then
          local MSG="$1"
        elif [ -z "$DETINFO" ]; then
          local DETINFO="$1"
        fi ;;
    esac
    shift
  done

  if [ -n "$DETINFO" ]; then
    local LOGLINE=" > UI: ${MSG}
 > Details: ${DETINFO}
"
  else
    local LOGLINE=" > UI: ${MSG}
"
  fi

  echo "| [№ $NUM_LOG] || [TIME: $(date "+%H:%M:%S")] |
$LOGLINE" >> "$LOGFILE"

  if [ "$UIP" = "1" ]; then
    ui_print "$MSG"
  fi

  if [ "$ABORT" = "1" ]; then
    set > "$NOW_ENV"
    echo "--- ENV DUMP START ---" >> "$LOGFILE"
    grep -Fvxf "$START_ENV" "$NOW_ENV" >> "$LOGFILE"
    echo "--- ENV DUMP END ---" >> "$LOGFILE"

    sleep 2
    abort "$MSG"
  fi
  
  NUM_LOG=$((NUM_LOG + 1))
}

#for debug why log doubleing
log "DEBUG: Script entry started" "PID: $$, started: $(date '+%H:%M:%S')"

flip_state() {
  for VAR_NAME in "$@"; do
    eval "local VAL=\"\$$VAR_NAME\""
    log "Flipping state for \$$VAR_NAME" "Now value: $VAL"
    if [ "$VAL" = "ON" ]; then
      eval "${VAR_NAME}_FLIP=OFF"
      log "Flipped to OFF"
    elif [ "$VAL" = "OFF" ]; then
      eval "${VAR_NAME}_FLIP=ON"
      log "Flipped to ON"
    else
      eval "${VAR_NAME}_FLIP=UNAVAILABLE"
      log "Not flipped due to UNAVAILABLE"
    fi
  done
}

writeinfo() {
  if [ "$1" = "-s" ]; then
    shift
    local VAR_NAME="$1"
    log "Writeinfo export called to variable: \$$1" "Starting building export variable. Namespace: \"$2\""
    local i=1
    local CONTENT=""
    eval "NAMESAPCE_COUNT=\"\$BUFFER_NUM_${2}\""
    while [ "$i" -le "$NAMESAPCE_COUNT" ]; do
      log "Reading saved content of line № $i"
      eval "LINE=\${SAVED_LINE_${i}_${2}}"
      CONTENT="${CONTENT}
${LINE}"
      unset "SAVED_LINE_${i}_${2}"
      log "Line № $i sucsessfully unsetted"
      i=$((i + 1))
    done
    eval "$VAR_NAME=\"\$CONTENT\""
    eval "BUFFER_NUM_${2}=0"
    log "Writeinfo export finished" "Final CONTENT = \" $CONTENT\" "
    return
  else
    eval "BUFFER_NUM_${2}=$((BUFFER_NUM_${2} + 1))" && eval "NUM=\"\$BUFFER_NUM_${2}\""
    log "Writeinfo add new line triggered. Namespace: \"$2\"" "№$NUM, Adding:
    $1"
    eval "SAVED_LINE_${NUM}_${2}=\"\$1\""
  fi
}

handle_input() {
  while true; do
    case $(timeout 0.01 getevent -lqc 1) in
    *KEY_VOLUMEUP*DOWN*)
      echo "up"
      return
      ;;
    *KEY_VOLUMEDOWN*DOWN*)
      echo "down"
      return
      ;;
    esac
  done
}

show_menu() {
  local selected=1
  local total=$#
   log "Menu started for $# arguments"
    while true; do
      eval "local current=\"\$$selected\""
      cut_print "➔ $current"
      ui_print " "
       log "Now s: $selected, c: $current"
      case $(handle_input) in
      "up") selected=$((selected % total + 1))
      log "Vol+ pressed. Next option triggered"
      ;;
      "down") break
      log "Vol- pressed. Menu termination triggered"
       ;;
      esac
    done

    ui_print " "
    cut_print "Chose: ➔ $current"
    log  "Menu result s: $selected, c: $current"
    ui_print " "
    return $selected
}

smart_menu() {
   log "Smart menu called. Begin first stage"
  local i=1
  local ARG_STRING=""
  
  while [ "$i" -le "$#" ]; do
    eval "local ARG=\${$i}"
    log "First stage for arg №$i" "Arg: $ARG"
    echo "$ARG" | grep -q "UNAVAILABLE" || ARG_STRING="$ARG_STRING \"$ARG\""
    i=$(( i + 1 ))
  done

   log "First stage done with result:" "$ARG_STRING"

  eval "show_menu $ARG_STRING"
  local RES=$?
  
  log "Starting second stage with RES: $RES"
  
  local j=1
  local SKIPPED=0
  while [ "$j" -le "$RES" ]; do
    eval "local ARG=\${$j}"
    log "Second stage for arg №$j" "Arg: $ARG"
    echo "$ARG" | grep -q "UNAVAILABLE" && SKIPPED=$(( SKIPPED + 1 ))
    j=$(( j + 1 ))
  done

   log "Check for UNAVALIBLE art finished. Result:" "$SKIPPED was skipped"

  RES=$(( RES + SKIPPED ))
  log "Smart menu finished with final result: $RES"
  return $RES
}

# UI system rework functions stacked below:

SIZE="$(settings get system display_density_index_manual)"
log "SIZE had been get trough settings. Value: $SIZE"
if [ -z "$SIZE" ] || [ "$SIZE" = "null" ]; then

PHY="$(wm density | grep 'Physical' | cut -d:  -f2)"
OVR="$(wm density | grep 'Override' | cut -d:  -f2)"

log "SIZE had been wrong. Got PHY: $PHY , and OVR: $OVR"
if [ -z "${OVR/ /}" ]; then
log "Screen width defined as MID since OVR isn't available"
WIDTH="MID"
elif [ "${PHY/ /}" -gt "${OVR/ /}" ]; then
log "Screen width defined as WIDE since OVR are less than PHY"
WIDTH="WIDE"
elif [ "${PHY/ /}" -gt "${OVR/ /}" ]; then
WIDTH="NARROW"
log "Screen width defined as NARROW since OVR are greater than PHY"
else
log "Screen width had been unavailable to get. Defining as MID"
WIDTH="MID"
fi

elif [ "$SIZE" -le "1" ]; then
log "Screen width defined as WIDE since SIZE is 0 or 1"
WIDTH="WIDE"
elif [ "$SIZE" = "2" ]; then
log "Screen width defined as MID since SIZE = 2"
WIDTH="MID"
elif [ "$SIZE" -gt "3" ]; then
WIDTH="NARROW"
log "Screen width defined as NARROW since SIZE is 3 or 4"
else
log "Fallback: all methods to define screen width failed. Defining as MID"
WIDTH="MID"
fi

if [ "$WIDTH" = "NARROW" ]; then
WIDTH=39
remind_controls() {
div
ui_print " "
ui_print "       [VOL+] - Change selection"
ui_print "       [VOL-] - Confirm choice"
div
}
elif [ "$WIDTH" = "MID" ]; then
WIDTH=44
remind_controls() {
div
ui_print " "
ui_print "         [VOL+] - Change selection"
ui_print "         [VOL-] - Confirm choice"
div
}
elif [ "$WIDTH" = "WIDE" ]; then
WIDTH=53
remind_controls() {
div
ui_print " "
ui_print " [VOL+] - Change selection | [VOL-] - Confirm choice"
div
}
else
log -a -u " There is unexpected error, send log please, aborting" "Unexpected error while checking screen WIDTH: $WIDTH at start, aborting install"
fi

DIV=""
while [ "${#DIV}" -lt "$WIDTH" ]; do
    DIV="_$DIV"
done

div() {
  ui_print "$DIV"
}

wordcut() {
   while [ ${#REMAINING} -gt $LEN ]; do
      PART=$(echo "$REMAINING" | cut -c1-$LEN)
      [ "${PART% }" = "$PART" ] && PART="${PART% *} "
      ui_print "${PREFIX}${PART% }"
      REMAINING="${REMAINING/${PART}}"
   done
}

list_print() {
   local LIST_COUNTER=1
   local LEN=$((WIDTH - 3))

for TEXT in "$@"; do
   TEXT="$TEXT "
   local PREFIX=" $LIST_COUNTER. "
   local PART=$(echo "${TEXT}" | cut -c1-$LEN)
   [ "${PART% }" = "$PART" ] && PART="${PART% *} "
   ui_print "${PREFIX}${PART% }"
   local REMAINING="${TEXT/${PART}}"
   PREFIX="    "
      
   if ! [ -z "$REMAINING" ]; then
      wordcut
      ui_print "${PREFIX}${REMAINING}"
    fi

    LIST_COUNTER=$((LIST_COUNTER + 1))
done
}

note_print() {
   local LEN=$((WIDTH - 6))
   local TEXT="$1 "
   local PREFIX=" Note: "
   local PART=$(echo "${TEXT}" | cut -c1-$LEN)
   [ "${PART% }" = "$PART" ] && PART="${PART% *} "
   ui_print "${PREFIX}${PART% }"
   local REMAINING="${TEXT/${PART}}"
   PREFIX="       "

if ! [ -z "$REMAINING" ]; then
   wordcut
   ui_print "${PREFIX}${REMAINING}"
fi
}

cut_print(){
   local LEN=$WIDTH
   local TEXT="$1 "
   local PREFIX=" "
   local PART=$(echo "${TEXT}" | cut -c1-$LEN)
   [ "${PART% }" = "$PART" ] && PART="${PART% *} "
   ui_print "${PREFIX}${PART% }"
   local REMAINING="${TEXT/${PART}}"

if ! [ -z "$REMAINING" ]; then
   wordcut
   ui_print "${PREFIX}${REMAINING}"
fi
}

center_print() {
  local LENGTH=${#1}
  local PADDING=$(( (WIDTH - LENGTH) / 2 ))

  local SPACE=""
  while [ $PADDING -gt 0 ]; do
    SPACE="$SPACE "
    PADDING=$((PADDING - 1))
  done

  ui_print "${SPACE}${1}"
}

show_tip() {
  # Tips
case "$(( RANDOM % 9 ))" in
   0) TIP="Tip: use experimental features carefully, they can make battery worse in your particular scenario!" ;;
   1) TIP="Tip: try out more configurations to find one that you like the most! Try to find what better for you!" ;;
   2) TIP="Tip: you can cut down your frequency for BIG and PRIME much more than for LITTLE!" ;;
   3) TIP="Tip: if you disabling cores, it is better to disable full cluster, not separate ones!" ;;
   4) TIP="Tip: some settings is better not to mix! Becarefull and exprore description or README!" ;;
   5) TIP="Tip: if you feel noticeable lag with normal use, try give more room to LITTLE cluster!" ;;
   6) TIP="Tip: if you feel lag in games, try give more room to PRIME and BIG clusters!" ;;
   7) TIP="Tip: if you have any problems with Camera, try to give CPU more juice!" ;;
   8) TIP="Tip: if you have any wierd problem, contact me immidiately: @QuantomPC" ;;
   esac
   cut_print "$TIP"
   div
}

compatible_freq() {
log "compatible_freq triggered with arguments" "№1 - $1;  №2 - $2; COMPATIBLE: $COMPATIBLE"
 local FREQ=$(cat /sys/devices/system/cpu/cpu${2}/cpufreq/scaling_available_frequencies)
 local MIN=$(echo "$FREQ" | awk '{print $1}')
 local MAX=$(echo "$FREQ" | awk '{print $NF}')

 log "Compatible freq gained for ${1}, featuring:
Min:$MIN and Max:$MAX"

 eval "${1}f=\"$MAX\""
 eval "${1}min=\"$MIN\""
}

set_default() {
log "set_default triggered with arguments" "№1 - $1;  №2 - $2; COMPATIBLE: $COMPATIBLE"
 if [ "$1" != "0" ]; then
  if [ "$COMPATIBLE" = "1" ]; then
   PRIMEf="2995200"
   PRIMEc="Stock freq           (3.0Gh)"
   BIGf="2496000"
   BIGc="Stock freq           (2.5Gh)"
   LITTLEf="1804800"
   LITTLEc="Stock freq           (1.8Gh)"
   log "Default (GT3/neo5) freq set successfully"
   FREQ_EXPORT="0"
  else
   compatible_freq PRIME 7
   PRIMEc="[NONE] (Compatibility mode)"
   compatible_freq BIG 4
   BIGc="[NONE] (Compatibility mode)"
   compatible_freq LITTLE 0
   LITTLEc="[NONE] (Compatibility mode)"
   log "Default (Compatible mode) freq set successfully"
   FREQ_EXPORT="1"
  fi
 fi
 
 if [ "$2" != "0" ]; then
  uALGf="0"
  dALGf="0"
  ALGc="Stock algorithm"
  pCOREf="0"
  bCOREf="0"
  COREc="Not disable"
  CPU_pCOREd=" "
  CPU_bCOREd=" "
  CPU_ALG=" "
  log "Default NOT freq set successfully"
  OTHER_EXPORT="0"
 fi

}

restore_settings() {
log "restore_settings triggered with argument" "№1 - $1;  COMPATIBLE: $COMPATIBLE"
source "${MODPATH/_update/}/settings.txt"
if [ "$1" = 0 ]; then
 ui_print " "
 ui_print " Restoring your previous freq settings...    "

 export PRIMEf PRIMEc BIGf BIGc LITTLEf LITTLEc
 FREQ_EXPORT="1"
 set_default 0 1
 log "Settings restored (freq)"
 check_restore

elif [ "$1" = "1" ]; then
 ui_print " "
 ui_print " Restoring your previous NOT freq settings...    "

 export uALGf dALGf ALGc pCOREf bCOREf COREc
 OTHER_EXPORT="1"
 set_default 1 0
 log "Settings restored (NOT freq)"
 check_restore

elif [ "$1" = "2" ]; then
 ui_print " "
 ui_print " Restoring all your previous settings... "


 export PRIMEf PRIMEc BIGf BIGc LITTLEf LITTLEc uALGf dALGf ALGc pCOREf bCOREf COREc
 FREQ_EXPORT="1"
 OTHER_EXPORT="1"
 log "Settings restored (all)"
 check_restore
 else
 log -a -u " There is unexpected error, send log please, aborting"  "Failed check in restore_settings, incorrect argument"
fi
}

check_restore() {
log "check_restore triggered; COMPATIBLE: $COMPATIBLE"
 if [ -z "$PRIMEf" ] || [ -z "$PRIMEc" ] || [ -z "$BIGf" ] || [ -z "$BIGc" ] || [ -z "$LITTLEf" ] || [ -z "$LITTLEc" ]; then
 FREQfail="1"
 log "Corrupted values detected after restoring in FREQ"
 fi

 if [ -z "$uALGf" ] || [ -z "$dALGf" ] || [ -z "$ALGc" ] || [ -z "$pCOREf" ] || [ -z "$bCOREf" ] || [ -z "$COREc" ]; then
 ELSEfail="1"
 log "Corrupted values detected after restoring in ELSE"
 fi

if [ "$FREQfail" = "1" ] && [ "ELSEfail" = "1" ]; then
  ui_print " "
  log -u " There is a problem with restoring ALL, aborting it" "Restore settings fail (all), setting default"
  div
  set_default 1 1
  sleep 2

elif [ "$FREQfail" = "1" ]; then
  ui_print " "
  log -u " There is a problem with restoring FREQ, aborting it" "Restore settings fail (freq), setting default"
  div
  set_default 1 0
  sleep 2

elif [ "ELSEfail" = "1" ]; then
  ui_print " "
  log -u " There is a problem with restoring NOT freq, aborting it" "Restore settings fail (NOT freq), setting default"
  div
  set_default 0 1
  sleep 2

elif [ "$FREQfail" != "1" ] && [ "ELSEfail" != "1" ]; then
   log "Restoring values successfull"
else
   log -a -u " There is unexpected error, send log please, aborting" "Values of FREQ or ELSE fail flags corrupt: $FREQfail || $ELSEfail . Tryed to restore settings from old instance, containing this:
\"$(cat "${MODPATH/_update/}/settings.txt") \" "
fi
}

# For dumping if error

if ! [ -d "$TMPDIR" ] // [ "$TMPDIR" = "/dev/tmp"]; then
  TMPDIR="/data/local/tmp"
fi

START_ENV="$TMPDIR/env.txt"
NOW_ENV="$TMPDIR/now.txt"
touch "$START_ENV"
set > "$START_ENV"
touch "$NOW_ENV"

# For future development to universal and forks

PRIMEmin="787200"
BIGmin="633600"
LITTLEmin="300000"

log "Functions defined, all OK. Starting install"

MODEL=$(getprop ro.boot.prjname)
case "$MODEL" in
  22624|22625|226B2)
    COMPATIBLE="1"
    log "Realme GT3/neo5 detected!" "MODEL=$MODEL"
    ;;
  *)
    COMPATIBLE="0"
    log "UNcompatible device detected!" "MODEL=$MODEL"
    for CPU in 1 2 3 5 6; do
       if [ -f "/sys/devices/system/cpu/cpu${CPU}/cpufreq_health/cpu_voltage" ]; then
          log -a -u "Fully incompatible device detected" "Found CPU freq table for core $CPU"
       fi
    done
    ;;
esac

#compability and settings restore

if [ "$COMPATIBLE" = "0" ]; then

      div
      ui_print " "
      ui_print " Uncompatible device (not Realme GT3/neo5) detected! "
      ui_print " CPU freq unavabilive, but you can change Governor "
      div
      ui_print " "

elif [ "$COMPATIBLE" = "1" ]; then

      div
      ui_print " "
      center_print " Realme GT3/neo5 detected!    "
      center_print " All settings fully avalible  "
      div
      ui_print " "

else
 log -a -u " There is unexpected error, send log please, aborting" "Unexpected error while checking compatible: $COMPATIBLE at start, aborting install"
fi

#Disclaimer

if [ -f "${MODPATH/_update/}/disclaimer.txt" ]; then
source "${MODPATH/_update/}/disclaimer.txt"
export EXP_DISCLAIMER

else

center_print "DISCLAIMER FOR EVERYONE USING MODULE"
div
ui_print " "

note_print "Please, understand that all that you do using this module you doing at your own responsibility and risk! I'm not responsible for bricked devices (especially if they are incompatible), missed alarms and lags in system. YOU DOING EVERYTHING AT YOUR OWN RISK!!!"
ui_print " "

if [ "$COMPATIBLE" = "1" ]; then

cut_print "As your device is compatible (GT3/neo5) you can feel more secure about this, since all changes are highly tested on same devices and guaranteed to be more or less safe. Anyway, you still have to confirm that you readed this disclaimer and take your own responsibility for your device, performing modifications to your system using this module. This modifications (especially EXPERIMENTAL) can have unexpected consequences various from not being effective (less screen time for nothing) to damage system that it needs to be wiped to factory (oplus services dyind since modifications). By pressing VOL+ TWICE you confirm that you read this disclaimer and agree with it. Press VOL- to disagree and exit immediately"

elif [ "$COMPATIBLE" = "0" ]; then

cut_print "As your device is incompatible (not GT3/neo5) I'm need to warn you more serious about possible side effects of this module, since all changes are mostly NOT tested on incompatible devices and NOT guaranteed to be safe. You have to confirm that you readed this disclaimer and take your own responsibility for your device, performing modifications to your system using this module. This modifications (especially EXPERIMENTAL) can have unexpected consequences various from not being effective (less screen time for nothing) to damage system that it needs to be wiped to factory (oplus services dyind since modifications). By pressing VOL+ TWICE you confirm that you read this disclaimer and agree with it. Press VOL- to disagree and exit immediately"

else

   log -a -u "There is unexpected error, send log please" "Error in COMPATIBLE: $COMPATIBLE , while proceed to disclaimer"

fi

div
ui_print " "

center_print "PRESS VOL+ TWICE TO CONFIRM"
ui_print " "

if [ "$(handle_input)" = "up" ]; then
   center_print "PRESS VOL+ SECOND TIME TO CONFIRM"
   log "First Vol+ pressed"
   if [ "$(handle_input)" = "up" ]; then
      div
      ui_print " "
      center_print "YOU AGREED WITH THIS DISCLAIMER"
      div
      log "User agreed with disclaimer, Vol+ pressed"
   else
      center_print "YOU DISAGREED WITH DISCLAIMER"
      log -a "User disagreed with disclaimer, Vol- pressed. Terminating"
   fi
else
   center_print "YOU DISAGREED WITH DISCLAIMER"
   log -a "User disagreed with disclaimer, Vol- pressed. Terminating"
fi

touch "$MODPATH/disclaimer.txt"
fi
   
   #end disclaimer

if [ -f "${MODPATH/_update/}/settings.txt" ] && [ "$COMPATIBLE" = "1" ]; then
      ui_print " "
      log -u " Previous install detected!" "For compatible device"
      ui_print " Choose to restore configuration or setup all again    "
      remind_controls
      ui_print " "
      list_print "Restore all settings" "Restore only freq settings" "Restore only not freq settings" "Setup all from scratch"
      ui_print " "
   show_menu "Restore all settings" "Restore only freq settings" "Restore only not freq settings" "Setup all from scratch"
    case $? in
    1) restore_settings 2 ;;
    2) restore_settings 0 ;;
    3) restore_settings 1 ;;
    4) set_default 1 1 ;;
    esac
elif [ -f "${MODPATH/_update/}/settings.txt" ] && [ "$COMPATIBLE" = "0" ]; then

      ui_print " "
      log -u " Previous install detected!" "For incompatible device"
      ui_print " Choose to restore configuration or setup all again    "
      remind_controls
      ui_print " "
      list_print "Restore only compatible settings" "Setup all from scratch"
      ui_print " "
   show_menu "Restore only compatible settings" "Setup all from scratch"
    case $? in
    1) restore_settings 1 ;;
    2) set_default 1 1 ;;
    esac

else

      ui_print " "
      log -u " No any previous install detected!"
      ui_print " Setting all up from scratch:    "
      div
 set_default 1 1

fi

rm -rf "${MODPATH/_update/}"
log "Old instance deleted"

# main part

if [ "$FREQ_EXPORT" != "1" ]; then
   log "FREQ setup started due to EXPORT flag: $FREQ_EXPORT" "COMPATIBLE = $COMPATIBLE"
      ui_print " "
      center_print "Configure your CPU frequency slowdowdown!"
      remind_controls
      ui_print " "
      show_tip
      ui_print " "
      center_print "Choose frequency cut to PRIME cluster"
      list_print \
      "Stock freq           (3.0Gh)" \
      "Light cut to freq    (2.4Gh)" \
      "Medium cut to freq   (2.0Gh)" \
      "Huge cut to freq     (1.7Gh)" \
      "Maximum cut to freq  (1.4Gh)"
      ui_print " "
      note_print "Medium setting are recommended"
      ui_print " "
   show_menu "Stock freq (3.0Gh)" "Light cut to freq (2.4Gh)" "Medium cut to freq (2.0Gh)" "Huge cut to freq (1.7Gh)" "Maximum cut to freq (1.4Gh)"
    case $? in
    1) PRIMEf="2995200" PRIMEc="Stock freq           (3.0Gh)" ;;
    2) PRIMEf="2476800" PRIMEc="Light cut to freq    (2.4Gh)" ;;
    3) PRIMEf="1996800" PRIMEc="Medium cut to freq   (2.0Gh)" ;;
    4) PRIMEf="1766400" PRIMEc="Huge cut to freq     (1.7Gh)" ;;
    5) PRIMEf="1401600" PRIMEc="Maximum cut to freq  (1.4Gh)" ;;
    esac

      remind_controls
      ui_print " "
      show_tip
      ui_print " "
      center_print "Choose frequency cut to BIG cluster"
      list_print \
      "Stock freq           (2.5Gh)" \
      "Light cut to freq    (1.9Gh)" \
      "Medium cut to freq   (1.7Gh)" \
      "Huge cut to freq     (1.5Gh)" \
      "Maximum cut to freq  (1.3Gh)"
      ui_print " "
      note_print "Medium setting are recommended"
      ui_print " "
   show_menu "Stock freq (2.5Gh)" "Light cut to freq (1.9Gh)" "Medium cut to freq (1.7Gh)" "Huge cut to freq (1.5Gh)" "Maximum cut to freq (1.3Gh)"
    case $? in
    1) BIGf="2496000" BIGc="Stock freq           (2.5Gh)" ;;
    2) BIGf="1996800" BIGc="Light cut to freq    (1.9Gh)" ;;
    3) BIGf="1766400" BIGc="Medium cut to freq   (1.7Gh)" ;;
    4) BIGf="1555200" BIGc="Huge cut to freq     (1.5Gh)" ;;
    5) BIGf="1324800" BIGc="Maximum cut to freq  (1.3Gh)" ;;
    esac


      remind_controls
      ui_print " "
      show_tip
      ui_print " "
      center_print "Choose frequency cut to LITTLE cluster"
      list_print \
      "Stock freq           (1.8Gh)" \
      "Light cut to freq    (1.6Gh)" \
      "Medium cut to freq   (1.4Gh)" \
      "Huge cut to freq     (1.2Gh)" \
      "Maximum cut to freq  (1.0Gh)"
      ui_print " "
      note_print "Medium setting are recommended"
      ui_print " "
   show_menu "Stock freq (1.8Gh)" "Light cut to freq (1.6Gh)" "Medium cut to freq (1.4Gh)" "Huge cut to freq (1.2Gh)" "Maximum cut to freq (1.0Gh)"
    case $? in
    1) LITTLEf="1804800" LITTLEc="Stock freq           (1.8Gh)" ;;
    2) LITTLEf="1670400" LITTLEc="Light cut to freq    (1.6Gh)" ;;
    3) LITTLEf="1440000" LITTLEc="Medium cut to freq   (1.4Gh)" ;;
    4) LITTLEf="1228800" LITTLEc="Huge cut to freq     (1.2Gh)" ;;
    5) LITTLEf="1056000" LITTLEc="Maximum cut to freq  (1.0Gh)" ;;
    esac
else
   log "FREQ setup skipped due to FREQ flag: $ELSE_EXPORT" "COMPATIBLE = $COMPATIBLE"
fi

#other

if [ "$OTHER_EXPORT" != "1" ]; then
log "ELSE setup started due to OTHER flag: $OTHER_EXPORT" "COMPATIBLE = $COMPATIBLE"
  ui_print " "
  div
      ui_print " "
      center_print "Configure your CPU algorithm!    "
      remind_controls
      ui_print " "
      show_tip
      ui_print " "
      center_print "Choose desired CPU algorithm"
      list_print \
      "Stock                " \
      "Conservative light   " \
      "Conservative medium  " \
      "Conservative max     " \
      "Powersave            "
      ui_print " "
      note_print "Learn more about difference in README"
      note_print "Medium conservative recommended"
      ui_print " "
   show_menu "Stock algorithm" "Conservative light" "Conservative medium" "Conservative max" "Powersave algorithm"
    case $? in
    1) uALGf="1" dALGf="0" ALGc="Stock algorithm" ;;
    2) uALGf="75" dALGf="55" ALGc="Conservative light algorithm" ;;
    3) uALGf="80" dALGf="60" ALGc="Conservative medium algorithm" ;;
    4) uALGf="85" dALGf="65" ALGc="Conservative max algorithm" ;;
    5) uALGf="0" dALGf="1" ALGc="Powersave algorithm" ;;
    esac

  ui_print " "
  div
      ui_print " "
      center_print "Configure your disabled CPU cores!    "
      remind_controls
      ui_print " "
      show_tip
      ui_print " "
      center_print "Choose desired CPU cores to disable"
      list_print \
      "Not disable                 " \
      "Disable 1 BIG core          " \
      "Disable PRIME core          " \
      "Disable 2 BIG cores         " \
      "Disable PRIME + 1 BIG cores " \
      "Disable 3 BIG cores         " \
      "Disable PRIME + 2 BIG cores " \
      "Disable PRIME + 3 BIG cores "
      ui_print " "
      note_print "Options sorted from least to most impacting"
      note_print "Options 4 and 5 recommended, 4 if play demanding games, 5 if not"
      note_print "This setting soon would be deprecated, option 3 recommended if using Experimental settings"
      ui_print " "
   show_menu "Not disable" "Disable 1 BIG core" "Disable PRIME core" "Disable 2 BIG cores" "Disable PRIME + 1 BIG cores" "Disable 3 BIG cores" "Disable PRIME + 2 BIG cores" "Disable PRIME + 3 BIG cores"
    case $? in
    1) pCOREf="0" bCOREf="0" COREc="Not disable any cores" ;;
    2) pCOREf="0" bCOREf="1" COREc="Disable 1 BIG core" ;;
    3) pCOREf="1" bCOREf="0" COREc="Disable PRIME core" ;;
    4) pCOREf="0" bCOREf="2" COREc="Disable 2 BIG cores" ;;
    5) pCOREf="1" bCOREf="1" COREc="Disable PRIME and 1 BIG core" ;;
    6) pCOREf="0" bCOREf="3" COREc="Disable 3 BIG cores" ;;
    7) pCOREf="1" bCOREf="2" COREc="Disable PRIME and 2 BIG cores" ;;
    8) pCOREf="1" bCOREf="3" COREc="Disable PRIME and 3 BIG cores" ;;
    esac

else
 log "ELSE setup skipped due to ELSE flag: $ELSE_EXPORT
 COMPATIBLE = $COMPATIBLE"
fi


#finales

sleep 1

ui_print " "
div
      ui_print " "
      show_tip
      ui_print " "
      center_print "Your configured, very own CPU slowdown settings:"
      div
      ui_print " "
      ui_print " PRIME core cluster frequency:
  ➔ $PRIMEc"
      ui_print " "
      ui_print " BIG cores cluster frequency:
  ➔ $BIGc"
      ui_print " "
      ui_print " LITTLE cores clister frequency:
  ➔ $LITTLEc"
      ui_print " "
      ui_print " Your CPU would run on:
  ➔ $ALGc"
      ui_print " "
      ui_print " You chose to:
  ➔ $COREc of your CPU"
      div
      ui_print " "
      log -u " Generating your chosen configuration..."
      ui_print " Please wait..."
      div
      ui_print " "

mkdir -p "$MODPATH"
touch "$MODPATH/service.sh"
touch "$MODPATH/post-fs-data.sh"
touch "$MODPATH/system.prop"
touch "$MODPATH/settings.txt"
chmod 755 "$MODPATH/service.sh" "$MODPATH/post-fs-data.sh" "$MODPATH/system.prop" "$MODPATH/settings.txt"

log "Pre-exporting preparing done. Begin exporting Settings:"

SETTINGS="
PRIMEf=\"$PRIMEf\"
PRIMEc=\"$PRIMEc\"
BIGf=\"$BIGf\"
BIGc=\"$BIGc\"
LITTLEf=\"$LITTLEf\"
LITTLEc=\"$LITTLEc\"
uALGf=\"$uALGf\"
dALGf=\"$dALGf\"
ALGc=\"$ALGc\"
pCOREf=\"$pCOREf\"
bCOREf=\"$bCOREf\"
COREc=\"$COREc\"
"

echo "$SETTINGS" > $MODPATH/settings.txt
log "Settings have been saved:" "\"$SETTINGS\" "

sleep 3

#Calculating .sh files

if [ $pCOREf = 0 ]; then
   CPU_pCOREd=" "
   log "Prime core not disabled, CPU_pCOREd empty"
elif [ $pCOREf = 1 ]; then
   CPU_pCOREd="
echo $PRIMEmin > /sys/devices/system/cpu/cpu7/cpufreq/scaling_max_freq
echo $PRIMEmin > /sys/devices/system/cpu/cpu7/cpufreq/scaling_cur_freq
sleep 1
echo 0 > /sys/devices/system/cpu/cpu7/online
"
   log "Prime core disabled" "CPU_pCOREd: \"$CPU_pCOREd\" "
fi

if [ $bCOREf = 0 ]; then
   CPU_bCOREd=" "
   echo "dalvik.vm.background-dex2oat-cpu-set=0,1,2,3,4,5,6" > $MODPATH/system.prop
   log "Big cores not disabled, CPU_bCOREd empty"
else
   if [ $bCOREf = 1 ]; then
      CPU_bCOREd="
sleep 1
echo 0 > /sys/devices/system/cpu/cpu6/online
"
      echo "dalvik.vm.background-dex2oat-cpu-set=0,1,2,3,4,5" > $MODPATH/system.prop
      log "Big cores: 6 disabled"
   elif [ $bCOREf = 2 ]; then
      CPU_bCOREd="
sleep 1
echo 0 > /sys/devices/system/cpu/cpu5/online
sleep 1
echo 0 > /sys/devices/system/cpu/cpu6/online
"
      echo "dalvik.vm.background-dex2oat-cpu-set=0,1,2,3,4" > $MODPATH/system.prop
      log "Big cores: 6,5 disabled"
   elif [ $bCOREf = 3 ]; then
      CPU_bCOREd="
echo $BIGmin > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
echo $BIGmin > /sys/devices/system/cpu/cpu4/cpufreq/scaling_cur_freq
sleep 1
echo 0 > /sys/devices/system/cpu/cpu4/online
sleep 1
echo 0 > /sys/devices/system/cpu/cpu5/online
sleep 1
echo 0 > /sys/devices/system/cpu/cpu6/online
"
    echo "dalvik.vm.background-dex2oat-cpu-set=0,1,2,3" > $MODPATH/system.prop
      log "Big cores: 6,5,4 disabled"
   fi
   log "Big cores disabled" "CPU_bCOREd: \"$CPU_bCOREd\" "
fi

CPU_COREd="$CPU_bCOREd $CPU_pCOREd"

log "CPU cores state defined" "CPU_COREd: \"$CPU_COREd\" "

if [ $uALGf = 1 ]; then
   CPU_ALG=" "
   log "CPU algorithm unchanged (stock)"
elif [ $dALGf = 1 ]; then
   CPU_ALG="
echo powersave > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo powersave > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor
# echo powersave > /sys/devices/system/cpu/cpu7/cpufreq/scaling_governor
" #Disabled due to lags
   log "CPU algorithm set up to Powersave"
elif [ "$uALGf" != 0 ] && [ "$dALGf" != 0 ]; then
   CPU_ALG="
echo conservative > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo conservative > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor
echo conservative > /sys/devices/system/cpu/cpu7/cpufreq/scaling_governor

sleep 5

echo $uALGf > /sys/devices/system/cpu/cpu0/cpufreq/conservative/up_threshold
echo $dALGf > /sys/devices/system/cpu/cpu0/cpufreq/conservative/down_threshold
echo 10 > /sys/devices/system/cpu/cpu0/cpufreq/conservative/freq_step
echo $uALGf > /sys/devices/system/cpu/cpu4/cpufreq/conservative/up_threshold
echo $dALGf > /sys/devices/system/cpu/cpu4/cpufreq/conservative/down_threshold
echo 10 > /sys/devices/system/cpu/cpu4/cpufreq/conservative/freq_step
echo $uALGf > /sys/devices/system/cpu/cpu7/cpufreq/conservative/up_threshold
echo $dALGf > /sys/devices/system/cpu/cpu7/cpufreq/conservative/down_threshold
echo 10 > /sys/devices/system/cpu/cpu7/cpufreq/conservative/freq_step
"
   log "CPU algorithm set up to Conservative featuring:
 > $uALGf threshold up
 > $dALGf threshold down"
fi

log "CPU algorithm defined" "CPU_ALG: \"$CPU_ALG\" "

if [ "$COMPATIBLE" = "1" ]; then
   CPU_COREf="
echo $LITTLEmin > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
echo $LITTLEf > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
echo $BIGmin > /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq
echo $BIGf > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
echo $PRIMEmin > /sys/devices/system/cpu/cpu7/cpufreq/scaling_min_freq
echo $PRIMEf > /sys/devices/system/cpu/cpu7/cpufreq/scaling_max_freq

sleep 5
"
   log "CPU Freq set up to real cause of COMPATIBLE: $COMPATIBLE"
elif [ "$COMPATIBLE" = "0" ]; then
   CPU_COREf=" "
   log "CPU Freq NOT set up cause of COMPATIBLE: $COMPATIBLE"
else
   log -a -u " There is unexpected error, send log please, aborting" "Unexpected error while checking compatible: $COMPATIBLE at CPU alg stage, aborting install"
fi

log "CPU freq reapply in system made" "CPU_COREf: \"$CPU_COREf\" "

# Add random description to service.sh!
DESCVAR='
MODPATH=${0%/*}
# description is assembled with 3 parts: main text, second text, and a tip
# Main text
case "$(( RANDOM % 4 ))" in
   0) DESC1="Module for lasting your battery longer!" ;;
   1) DESC1="Extend your battery by limiting CPU!" ;;
   2) DESC1="Makes your Screen On Time better!" ;;
   3) DESC1="Highly customizable battery extender!" ;;
esac
# second text
case "$(( RANDOM % 5 ))" in
   0) DESC2="Better suit for Realme GT3/neo5 but can be used for other phones as well!" ;;
   1) DESC2="Working the best if you are NOT a heavy gamer!" ;;
   2) DESC2="Do NOT combine this module with any kind of \"system boosters\"!" ;;
   3) DESC2="Made with love and passion. 100% free from ChatGPT!" ;;
   4) DESC2="Becoming better with each update! I always researching for something new for you."
esac
# Tips
case "$(( RANDOM % 9 ))" in
   0) TIP="Tip: use experimental features carefully, they can make battery worse in your particular scenario!" ;;
   1) TIP="Tip: try out more configurations to find one that you like the most! Try to find what better for you!" ;;
   2) TIP="Tip: you can cut down your frequency for BIG and PRIME much more than for LITTLE!" ;;
   3) TIP="Tip: if you disabling cores, it is better to disable full cluster, not separate ones!" ;;
   4) TIP="Tip: some settings is better not to mix! Becarefull and exprore description or README!" ;;
   5) TIP="Tip: if you feel noticeable lag with normal use, try give more room to LITTLE cluster!" ;;
   6) TIP="Tip: if you feel lag in games, try give more room to PRIME and BIG clusters!" ;;
   7) TIP="Tip: if you have any problems with Camera, try to give CPU more juice! Espetially for PRIME and BIG." ;;
   8) TIP="Tip: if you have any wierd problem, contact me immidiately: @QuantomPC" ;;
esac
DESC="$DESC1 $DESC2 $TIP"
sed -i "/description=/s|.*|$DESC|" $MODPATH/module.prop
'

CPU="
logcat -v brief | grep -m 1 'android.intent.action.USER_PRESENT'
$DESCVAR
sleep 90
$CPU_COREf $CPU_ALG $CPU_COREd"

log "Service finalized" "Contain: \"$CPU\" "

echo "$CPU" > $MODPATH/service.sh

if [ "$COMPATIBLE" = "1" ]; then
   POST="
lock_val() {
    [ ! -f "$2" ] && return
    umount "$2"

    chmod +w "$2"
    echo "$1" | tee -a /dev/mount_mask "$2"
    mount --bind /dev/mount_mask "$2"
    rm /dev/mount_mask
}

lock_val $LITTLEmin /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
lock_val $LITTLEf /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
lock_val $BIGmin /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq
lock_val $BIGf /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
lock_val $PRIMEmin /sys/devices/system/cpu/cpu7/cpufreq/scaling_min_freq
lock_val $PRIMEf /sys/devices/system/cpu/cpu7/cpufreq/scaling_max_freq
"
   log "POST script set up to full power cause of COMPATIBLE: $COMPATIBLE"

elif [ "$COMPATIBLE" = "0" ]; then
   POST="
lock_val() {
    [ ! -f "$2" ] && return
    umount "$2"

    chmod +w "$2"
    echo "$1" | tee -a /dev/mount_mask "$2"
    mount --bind /dev/mount_mask "$2"
    rm /dev/mount_mask
}

lock_val $LITTLEmin /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
lock_val $BIGmin /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq
lock_val $PRIMEmin /sys/devices/system/cpu/cpu7/cpufreq/scaling_min_freq
"
   log "POST DONT set up to full, cause of COMPATIBLE: $COMPATIBLE"
else
   log -a -u " There is unexpected error, send log please, aborting" "Unexpected error while checking compatible: $COMPATIBLE at POST stage, aborting install"
fi

log "POST finalized" "Contain: \"$POST\" "

echo "$POST" > $MODPATH/post-fs-data.sh

#check if all ok

 if [ -z "$PRIMEf" ] || [ -z "$PRIMEc" ] || [ -z "$BIGf" ] || [ -z "$BIGc" ] || [ -z "$LITTLEf" ] || [ -z "$LITTLEc" ] || [ -z "$uALGf" ] || [ -z "$dALGf" ] || [ -z "$ALGc" ] || [ -z "$pCOREf" ] || [ -z "$bCOREf" ] || [ -z "$COREc" ]; then
   log -a -u " There is unexpected error, send log please, aborting" "Unexpected error while checking values at the end. Exporting all variables to dump. Compatible: $COMPATIBLE . Installing aborted"
 fi

log "All main part is done, script is ready for user and checked"

# EXP settings

if [ "$EXP_DISCLAIMER" != "1" ]; then
center_print "DISCLAIMER FOR EXPERIMENTAL SETTINGS"
div
ui_print " "

cut_print "Please, confirm that you understand that EXPERIMENTAL settings can be highly unstable and lead to unexpected results. Often this features have almost no effect, and sometimes even make your autonomy worse. Please, use them with caution and test your configuration on does this work, using build-in highly detail LOG feature. After you check that all of this works and your battery juice became better, I recommend disable logging completely or leave only ACTION logs. Please confirm that you readed this disclaimer and agree with that"

div
ui_print " "

center_print "PRESS VOL+ TWICE TO CONFIRM"
ui_print " "

if [ "$(handle_input)" = "up" ]; then
   center_print "PRESS VOL+ SECOND TIME TO CONFIRM"
   ui_print " "
   log "First Vol+ pressed"
   if [ "$(handle_input)" = "up" ]; then
      div
      center_print "YOU AGREED WITH THIS DISCLAIMER"
      div
      ui_print " "
      log "User agreed with disclaimer, Vol+ pressed"
      EXP_DISCLAIMER="1"
   else
      center_print "YOU DISAGREED WITH DISCLAIMER"
      log "User disagreed with EXP disclaimer, Vol- pressed. Terminating"
      EXP_DISCLAIMER="0"
   fi
else
   center_print "YOU DISAGREED WITH DISCLAIMER"
   log "User disagreed with EXP disclaimer, Vol- pressed. Terminating"
   EXP_DISCLAIMER="0"
fi

fi

log  "Saving EXP_DISCLAIMER to disclaimer.txt"
echo "EXP_DISCLAIMER=\"$EXP_DISCLAIMER\"" > "$MODPATH/disclaimer.txt"

if [ "$EXP_DISCLAIMER" = "1" ]; then
   log "Proceed to EXPIRIMENTAL settings due to EXP_DISCLAIMER: $EXP_DISCLAIMER"
EXIT_EXTRA="0"
SCREENOFF_LOW_FREQ="OFF"
SCREENOFF_DISABLE_CORES="OFF"
SCREENOFF_POWERSAVE="OFF"
MANUAL_CORES_ACTION="OFF"

#Check if cores disabled

if [ $pCOREf = 0 ] && [ $bCOREf = 0 ]; then
      SCREENOFF_DISABLE_CORES="UNAVAILABLE"
      MANUAL_CORES_ACTION="UNAVAILABLE"
      log "Resetting SCREENOFF_DISABLE_CORES and MANUAL_CORES_ACTION to UNAVAILABLE since no one core is disabled"
fi

if [ $dALGf = 1 ]; then
   SCREENOFF_POWERSAVE="UNAVAILABLE"
   log "Screenoff Powersave setting disabled since user chose permanent powersave"
elif [ $uALGf = 1 ]; then
   CPU_ALG="
echo walt > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo walt > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor
echo walt > /sys/devices/system/cpu/cpu7/cpufreq/scaling_governor
"
   log "CPU algorithm for screenoff set to walt (stock)"
fi

      ui_print " "
      div
      ui_print " "
      center_print "EXPERIMENTAL SETTINGS, BE CAREFULL!"


   while true; do
      remind_controls
      ui_print " "
      center_print " Choose which experiment to activate:"
      list_print \
      "Exit (finalize setings)     " \
      "Cut freq down on sleep: $SCREENOFF_LOW_FREQ " \
      "Disable cores on sleep: $SCREENOFF_DISABLE_CORES " \
      "Set governor to Powersave on sleep: $SCREENOFF_POWERSAVE " \
      "Manually enable and disable cores:  $MANUAL_CORES_ACTION "
#      ui_print "  6. Cut down CPU freq table to chosen freq: "
#      ui_print "  7. Undervolting. WARNING: could cause DAMAGE: "
#      ui_print "  8. - "
      ui_print " "
      note_print "List and choose is dynamic and changes after you choose something, until you exit menu "
      note_print "Some options are unavailable if you don't have right configuration for this experiment's, or because your device is incompatible"
      ui_print " "

flip_state "SCREENOFF_LOW_FREQ" "SCREENOFF_DISABLE_CORES" "SCREENOFF_POWERSAVE" "MANUAL_CORES_ACTION"

   smart_menu "Exit extra settings" "Cut freq on screenoff »TURN ${SCREENOFF_LOW_FREQ_FLIP}«" "Disable cores on screenoff »TURN ${SCREENOFF_DISABLE_CORES_FLIP}«" "CPU governor to Powersave on screenoff »TURN ${SCREENOFF_POWERSAVE_FLIP}«" "Manually enable and disable cores by Action button »TURN ${MANUAL_CORES_ACTION_FLIP}«"

    case $? in
    1) EXIT_EXTRA="1"
    ;;
    2) SCREENOFF_LOW_FREQ="$SCREENOFF_LOW_FREQ_FLIP"
    if [ "$SCREENOFF_POWERSAVE" = "ON" ] && [ "$SCREENOFF_LOW_FREQ" = "ON" ]; then
       SCREENOFF_POWERSAVE="OFF"
    fi
    ;; 
    3) SCREENOFF_DISABLE_CORES="$SCREENOFF_DISABLE_CORES_FLIP"
    if [ "$MANUAL_CORES_ACTION" = "ON" ] && [ "$SCREENOFF_DISABLE_CORES" = "ON" ]; then
       MANUAL_CORES_ACTION="OFF"
    fi
    ;;
    4) SCREENOFF_POWERSAVE="$SCREENOFF_POWERSAVE_FLIP"
    if [ "$SCREENOFF_LOW_FREQ" = "ON" ] && [ "$SCREENOFF_POWERSAVE" = "ON" ]; then
       SCREENOFF_LOW_FREQ="OFF"
    fi
    ;;
    5) MANUAL_CORES_ACTION="$MANUAL_CORES_ACTION_FLIP"
    if [ "$SCREENOFF_DISABLE_CORES" = "ON" ] && [ "$MANUAL_CORES_ACTION" = "ON" ]; then
       SCREENOFF_DISABLE_CORES="OFF"
    fi
    ;;
#    6) 
#    ;;
#    7)
#    ;;
#    8)
#    ;;
    esac
    if [ "$EXIT_EXTRA" = "1" ]; then
       break
    fi
   done

# logging menu

if [ "$SCREENOFF_LOW_FREQ" = "ON" ] || [ "$SCREENOFF_DISABLE_CORES" = "ON" ] || [ "$SCREENOFF_POWERSAVE" = "ON" ]; then
   log "Logging settings started due to user enabled screenoff experiment"
   
      ui_print " "
      div
      ui_print " "
      center_print "CHOOSE YOUR LOGGING DETAILS"
      div
      ui_print " "
      cut_print "You activated some of experimental settings please choose how detailed to log it, cause logs puts additional pressure on your system, combating power efficiency that you gain "
      
      note_print "Log options: \"Cycle alive\" log would print into log \"Cycle alive\" every time cycle repeats (e.g. 8-9 seconds), \"Check result\" log would print result of check (screen ON or OFF?) every time, \"Executing action\" log would print to log only when screen state was changed (\"ON→OFF\", or \"ON←OFF\"), and only one recommended due to light impact on performance, \"Result of action\" log would check if action was successfull, thus making it most \"Heavy\" option of all"
      
      EXIT_LOG="0"
      LOG_ALIVE="OFF"
      LOG_CHECK="OFF"
      LOG_ACTION="OFF"
      LOG_RESULT="OFF"
      
    while true; do
      remind_controls
      ui_print " "
      center_print "Choose which log option to activate:"
      list_print \
      "Exit (finalize setings) " \
      "\"Cycle alive\" log:       $LOG_ALIVE " \
      "\"Check result\" log:      $LOG_CHECK " \
      "\"Executing action\" log:  $LOG_ACTION " \
      "\"Result of action\" log:  $LOG_RESULT "
      
      note_print "\"Cycle alive\", \"Check result\" and especially \"Result of action\" log option HIGHLY unrecommended to use on daily basis, use them only when trying catch bugs or for detailed testing!"
      
      flip_state "LOG_ALIVE" "LOG_CHECK" "LOG_ACTION" "LOG_RESULT"

   show_menu "Exit log settings" "\"Cycle alive\" log »TURN ${LOG_ALIVE_FLIP}«" "\"Check result\" log »TURN ${LOG_CHECK_FLIP}«" "\"Executing action\" log »TURN ${LOG_ACTION_FLIP}«" "\"Result of action\" log »TURN ${LOG_RESULT_FLIP}«"
    case $? in
    1) EXIT_LOG="1" ;;
    2) LOG_ALIVE="$LOG_ALIVE_FLIP" ;;
    3) LOG_CHECK="$LOG_CHECK_FLIP" ;;
    4) LOG_ACTION="$LOG_ACTION_FLIP" ;;
    5) LOG_RESULT="$LOG_RESULT_FLIP" ;;
    esac
    if [ "$EXIT_LOG" = "1" ]; then
       break
    fi
  done
else
   log "Logging menu skipped due to user skipped experimental"
fi

#user repeat

   div
   ui_print " "
   center_print "Your activated experiments:"
   div
   list_print \
      "Cut freq down on sleep: $SCREENOFF_LOW_FREQ " \
      "Disable cores on sleep: $SCREENOFF_DISABLE_CORES " \
      "Set governor to Powersave on sleep: $SCREENOFF_POWERSAVE " \
      "Manually enable and disable cores:  $MANUAL_CORES_ACTION "
   div
   ui_print " "
if [ "$LOG_ALIVE" = "ON" ] || [ "$LOG_CHECK" = "ON" ] || [ "$LOG_ACTION" = "ON" ] || [ "$LOG_RESULT" = "ON" ]; then
   center_print "And logging setup:"
   div
   ui_print " "
   list_print \
      "\"Cycle alive\" log:       $LOG_ALIVE " \
      "\"Check result\" log:      $LOG_CHECK " \
      "\"Executing action\" log:  $LOG_ACTION " \
      "\"Result of action\" log:  $LOG_RESULT "
   div
   ui_print " "
   log -u " Generating your chosen configuration..."
   ui_print " Please wait..."
   div
   ui_print " "
fi

sleep 1
   
# final conf

if [ "$SCREENOFF_DISABLE_CORES" = "ON" ] || [ "$MANUAL_CORES_ACTION" = "ON" ]; then
   log "Starting recalculating disabled cores due to:" "SCREENOFF_DISABLE_CORES = \"$SCREENOFF_DISABLE_CORES\" "
   if [ $pCOREf = 0 ]; then
      CPU_pCOREe=" "
      CPU_pCOREd=" "
      SCREENOFF_CORES_FREQe=" "
      SCREENOFF_CORES_FREQd=" "
   elif [ $pCOREf = 1 ]; then
      CPU_pCOREe="
sleep 1
echo 1 > /sys/devices/system/cpu/cpu7/online
"
      CPU_pCOREd="
sleep 1
echo 0 > /sys/devices/system/cpu/cpu7/online
"
      MANUAL_STATE='$(cat /sys/devices/system/cpu/cpu7/online)'

      SCREENOFF_CORES_FREQd="
echo $PRIMEmin > /sys/devices/system/cpu/cpu7/cpufreq/scaling_max_freq
echo $PRIMEmin > /sys/devices/system/cpu/cpu7/cpufreq/scaling_cur_freq
"

      if [ $uALGf = 1 ] || [ $dALGf = 1 ]; then
            SCREENOFF_CORES_FREQe="
echo $PRIMEf > /sys/devices/system/cpu/cpu7/cpufreq/scaling_max_freq"
      else
           SCREENOFF_CORES_FREQe="
echo $PRIMEf > /sys/devices/system/cpu/cpu7/cpufreq/scaling_max_freq 
echo $uALGf > /sys/devices/system/cpu/cpu7/cpufreq/conservative/up_threshold
echo $dALGf > /sys/devices/system/cpu/cpu7/cpufreq/conservative/down_threshold
echo 10 > /sys/devices/system/cpu/cpu7/cpufreq/conservative/freq_step
"
      fi
   fi

   if [ $bCOREf = 0 ]; then
      CPU_bCOREe=" "
      CPU_bCOREd=" "
SCREENOFF_CORES_FREQe="$SCREENOFF_CORES_FREQe "
      SCREENOFF_CORES_FREQd="$SCREENOFF_CORES_FREQd "
   else
      if [ $bCOREf = 1 ]; then
         CPU_bCOREe="
echo 1 > /sys/devices/system/cpu/cpu6/online
"
         CPU_bCOREd="
echo 0 > /sys/devices/system/cpu/cpu6/online
"
    elif [ $bCOREf = 2 ]; then
          CPU_bCOREe="
echo 1 > /sys/devices/system/cpu/cpu5/online
echo 1 > /sys/devices/system/cpu/cpu6/online
"
          CPU_bCOREd="
echo 0 > /sys/devices/system/cpu/cpu5/online
echo 0 > /sys/devices/system/cpu/cpu6/online
"
       elif [ $bCOREf = 3 ]; then
          CPU_bCOREe="
echo 1 > /sys/devices/system/cpu/cpu4/online
echo 1 > /sys/devices/system/cpu/cpu5/online
echo 1 > /sys/devices/system/cpu/cpu6/online
"
          CPU_bCOREd="
echo 0 > /sys/devices/system/cpu/cpu4/online
echo 0 > /sys/devices/system/cpu/cpu5/online
echo 0 > /sys/devices/system/cpu/cpu6/online
"
      fi

      MANUAL_STATE='$(cat /sys/devices/system/cpu/cpu6/online)'
      SCREENOFF_CORES_FREQd="$SCREENOFF_CORES_FREQd 
echo $BIGmin > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
echo $BIGmin > /sys/devices/system/cpu/cpu4/cpufreq/scaling_cur_freq
"
      if [ $uALGf = 1 ] || [ $dALGf = 1 ]; then
         SCREENOFF_CORES_FREQe="$SCREENOFF_CORES_FREQe 
echo $BIGf > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
"
      else
         SCREENOFF_CORES_FREQe="$SCREENOFF_CORES_FREQe 
echo $BIGf > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
echo $uALGf > /sys/devices/system/cpu/cpu4/cpufreq/conservative/up_threshold
echo $dALGf > /sys/devices/system/cpu/cpu4/cpufreq/conservative/down_threshold
echo 10 > /sys/devices/system/cpu/cpu4/cpufreq/conservative/freq_step
"
      fi
   fi

   CPU_COREd="$CPU_bCOREd $CPU_pCOREd"
   CPU_COREe="$CPU_bCOREe $CPU_pCOREe"
   
fi

if [ "$SCREENOFF_LOW_FREQ" = "ON" ] || [ "$SCREENOFF_DISABLE_CORES" = "ON" ] || [ "$SCREENOFF_POWERSAVE" = "ON" ]; then
   if [ "$LOG_ALIVE" = "ON" ] || [ "$LOG_CHECK" = "ON" ] || [ "$LOG_ACTION" = "ON" ] || [ "$LOG_RESULT" = "ON" ]; then
   writeinfo '
LOGFILE="/sdcard/Quantom_Screenoff.log"

echo "Start logging, clearing logfile" > "$LOGFILE"

log() {
  echo "[$(date "+%H:%M:%S")] > $1" >> "$LOGFILE"
}
' 
   fi

   #first part
   writeinfo "SCREEN=\"1\"
while true; do
STATE=\$(dumpsys power | grep -i 'mHoldingDisplaySuspendBlocker' | cut -d= -f2)"
   if [ "$LOG_ALIVE" = "ON" ]; then
      writeinfo  '      log "Cycle alive: Current state: $STATE" ' # REDO LATER
   fi
   writeinfo 'if [ "$STATE" = "true" ]; then 
   if [ "$SCREEN" = "1" ]; then
      sleep 2'
   if [ "$LOG_CHECK" = "ON" ]; then
      writeinfo '      log "Action: [SKIP] screen ON  -  ON " '
   fi
   writeinfo '   else
      SCREEN="1"'
   if [ "$LOG_CHECK" = "ON" ] || [ "$LOG_ACTION" = "ON" ]; then
      writeinfo '      log "Action: [BACK] screen OFF →  ON " '
   fi
   if [ "$SCREENOFF_LOW_FREQ" = "ON" ] && [ "$SCREENOFF_DISABLE_CORES" = "ON" ]; then
      writeinfo "
$CPU_COREe
sleep 2
echo $BIGmin > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
echo $PRIMEf > /sys/devices/system/cpu/cpu7/cpufreq/scaling_max_freq 
$SCREENOFF_CORES_FREQe
"

   elif [ "$SCREENOFF_LOW_FREQ" = "ON" ] && [ "$SCREENOFF_DISABLE_CORES" = "OFF" ]; then
      writeinfo "
echo $BIGf > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
echo $PRIMEf > /sys/devices/system/cpu/cpu7/cpufreq/scaling_max_freq
sleep 2"

   elif [ "$SCREENOFF_DISABLE_CORES" = "ON" ] && [ "$SCREENOFF_LOW_FREQ" = "OFF" ]; then
      writeinfo "
$CPU_COREe
sleep 2
$SCREENOFF_CORES_FREQe" 

   fi
   if [ "$SCREENOFF_POWERSAVE" = "ON" ]; then
      writeinfo "$CPU_ALG" 
   fi

   if [ "$LOG_RESULT" = "ON" ]; then
      if [ "$SCREENOFF_LOW_FREQ" = "ON" ]; then
         writeinfo '      log "Result: [FREQ] now:
> for LITTLE → $(cat "/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq") ;
> for BIG    → $(cat "/sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq") ;
> for PRIME  → $(cat "/sys/devices/system/cpu/cpu7/cpufreq/scaling_max_freq") ;" '
      fi
      if [ "$SCREENOFF_DISABLE_CORES" = "ON" ]; then
         writeinfo '      log "Result: [CORE] now:
> PRIME → $(cat "/sys/devices/system/cpu/cpu7/online") ;
> BIG 1 → $(cat "/sys/devices/system/cpu/cpu6/online") ;
> BIG 2 → $(cat "/sys/devices/system/cpu/cpu5/online") ;
> BIG 3 → $(cat "/sys/devices/system/cpu/cpu4/online") ;" '
      fi
      if [ "$SCREENOFF_POWERSAVE" = "ON" ]; then
         writeinfo '      log "Result: [GOV] now:
> for LITTLE → $(cat "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor") ;
> for BIG    → $(cat "/sys/devices/system/cpu/cpu4/cpufreq/scaling_governor") ;
> for PRIME  → $(cat "/sys/devices/system/cpu/cpu7/cpufreq/scaling_governor") ;" '
      fi
   fi

writeinfo '   fi
elif [ "$STATE" = "false" ]; then 
   if [ "$SCREEN" = "0" ]; then'

   if [ "$LOG_CHECK" = "ON" ]; then
      writeinfo '      log "Action: [SKIP] screen OFF - OFF " '
   fi
   # second part, when screen is off
   writeinfo '      sleep 2
   else
      SCREEN="0"'

   if [ "$LOG_CHECK" = "ON" ] || [ "$LOG_ACTION" = "ON" ]; then
      writeinfo '      log "Action: [EXEC] screen ON  → OFF " '
   fi
   if [ "$SCREENOFF_LOW_FREQ" = "ON" ] && [ "$SCREENOFF_DISABLE_CORES" = "ON" ]; then
      writeinfo "
echo $BIGmin > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
echo $BIGmin > /sys/devices/system/cpu/cpu4/cpufreq/scaling_cur_freq
echo $PRIMEmin > /sys/devices/system/cpu/cpu7/cpufreq/scaling_max_freq
echo $PRIMEmin > /sys/devices/system/cpu/cpu7/cpufreq/scaling_cur_freq
sleep 2
$CPU_COREd"

   elif [ "$SCREENOFF_LOW_FREQ" = "ON" ] && [ "$SCREENOFF_DISABLE_CORES" = "OFF" ]; then
      writeinfo "
echo $BIGmin > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
echo $BIGmin > /sys/devices/system/cpu/cpu4/cpufreq/scaling_cur_freq
echo $PRIMEmin > /sys/devices/system/cpu/cpu7/cpufreq/scaling_max_freq
echo $PRIMEmin > /sys/devices/system/cpu/cpu7/cpufreq/scaling_cur_freq
sleep 2"

   elif [ "$SCREENOFF_DISABLE_CORES" = "ON" ] && [ "$SCREENOFF_LOW_FREQ" = "OFF" ]; then
      writeinfo "
$SCREENOFF_CORES_FREQd
sleep 2
$CPU_COREd"

   fi
   if [ "$SCREENOFF_POWERSAVE" = "ON" ]; then
      writeinfo "
#echo powersave > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo powersave > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor
echo powersave > /sys/devices/system/cpu/cpu7/cpufreq/scaling_governor" 
   fi

      if [ "$LOG_RESULT" = "ON" ]; then
      if [ "$SCREENOFF_LOW_FREQ" = "ON" ]; then
         writeinfo '      log "Result: [FREQ] now:
> for LITTLE → $(cat "/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq") ;
> for BIG    → $(cat "/sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq") ;
> for PRIME  → $(cat "/sys/devices/system/cpu/cpu7/cpufreq/scaling_max_freq") ;" '
      fi
      if [ "$SCREENOFF_DISABLE_CORES" = "ON" ]; then
         writeinfo '      log "Result: [CORE] now:
> PRIME → $(cat "/sys/devices/system/cpu/cpu7/online") ;
> BIG 1 → $(cat "/sys/devices/system/cpu/cpu6/online") ;
> BIG 2 → $(cat "/sys/devices/system/cpu/cpu5/online") ;
> BIG 3 → $(cat "/sys/devices/system/cpu/cpu4/online") ;" '
      fi
      if [ "$SCREENOFF_POWERSAVE" = "ON" ]; then
         writeinfo '      log "Result: [GOV] now:
> for LITTLE → $(cat "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor") ;
> for BIG    → $(cat "/sys/devices/system/cpu/cpu4/cpufreq/scaling_governor") ;
> for PRIME  → $(cat "/sys/devices/system/cpu/cpu7/cpufreq/scaling_governor") ;" '
      fi
   fi

writeinfo '   fi
fi
   sleep 8
done'

fi

writeinfo -s "EXP_SERVICE"
log "Writeinfo finished. Insetring it to SERVICE"
echo "$EXP_SERVICE" >> "$MODPATH/service.sh"

log "Experimental settings finalized. Service: " "\"$(cat $MODPATH/service.sh)\""


if [ "$MANUAL_CORES_ACTION" = "ON" ]; then
   log "Started exporting action.sh due to user settings"
   touch "$MODPATH/action.sh"
   MANUAL_SCRIPT="
CORES_STATE=$MANUAL_STATE
if [ \"\$CORES_STATE\" = \"1\" ]; then 
echo 'Core(s) now enable(d). Turning them OFF'
sleep 1
$SCREENOFF_CORES_FREQd $CPU_COREd sleep 1
elif [ \"\$CORES_STATE\" = \"0\" ]; then 
echo 'Core(s) now disable(d). Turning them ON'
sleep 1
$CPU_COREe $SCREENOFF_CORES_FREQe sleep 1
fi

CORES_STATE=$MANUAL_STATE
if [ \"\$CORES_STATE\" = \"1\" ]; then  
echo '[RESULT]: Core(s) now enable(d)'
elif [ \"\$CORES_STATE\" = \"0\" ]; then 
echo '[RESULT]: Core(s) now disable(d)'
fi

sleep 2"
   log "Manual script for cores made, featuring:" "\"$MANUAL_SCRIPT\""
   echo "$MANUAL_SCRIPT" > "$MODPATH/action.sh"
fi


else
   log "Experimental settings skipped due to EXP_DISCLAIMER: $EXP_DISCLAIMER"
fi

log "Install complete. Dumping values for debug"

set > "$NOW_ENV"; echo "--- ENV DUMP START ---" >> "$LOGFILE"; grep -Fvxf "$START_ENV" "$NOW_ENV" >> "$LOGFILE"; echo "--- ENV DUMP END ---" >> "$LOGFILE"; rm -rf "$NOW_ENV" "$START_ENV"