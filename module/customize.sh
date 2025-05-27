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

BUFFER_NUM=0

writeinfo() {
  if [ "$1" = "-s" ]; then
    shift
    local VAR_NAME="$1"
    log "Writeinfo export called to variable: \$$1" "Starting building export variable"
    local i=1
    local CONTENT=""
    while [ "$i" -le "$BUFFER_NUM" ]; do
      log "Reading saved content of line № $i"
      eval "LINE=\${SAVED_LINE_$i}"
      CONTENT="${CONTENT}${LINE}"$'\n'
      unset "SAVED_LINE_$i"
      log "Line № $i sucsessfully unsetted"
      i=$((i + 1))
    done
    eval "$VAR_NAME=\"\$CONTENT\""
    BUFFER_NUM=0
    log "Writeinfo export finished" "Final CONTENT = \" $CONTENT\" "
    return
  else
    BUFFER_NUM=$((BUFFER_NUM + 1))
    log "Writeinfo add new line triggered" "№$BUFFER_NUM, Adding:
    $1"
    eval "SAVED_LINE_$BUFFER_NUM=\"\$1\""
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
      ui_print "➔ $current"
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
    log -u " You chose ➔ $current" "Menu result s: $selected, c: $current"
    ui_print " "
    return $selected
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
 ui_print "___________________________________________________"

 export PRIMEf PRIMEc BIGf BIGc LITTLEf LITTLEc
 FREQ_EXPORT="1"
 set_default 0 1
 log "Settings restored (freq)"
 check_restore

elif [ "$1" = "1" ]; then
 ui_print " "
 ui_print " Restoring your previous NOT freq settings...    "
 ui_print "___________________________________________________"

 export uALGf dALGf ALGc pCOREf bCOREf COREc
 OTHER_EXPORT="1"
 set_default 1 0
 log "Settings restored (NOT freq)"
 check_restore

elif [ "$1" = "2" ]; then
 ui_print " "
 ui_print " Restoring all your previous settings... "
 ui_print "___________________________________________________"


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
  ui_print "___________________________________________________"
  set_default 1 1
  sleep 2

elif [ "$FREQfail" = "1" ]; then
  ui_print " "
  log -u " There is a problem with restoring FREQ, aborting it" "Restore settings fail (freq), setting default"
  ui_print "___________________________________________________"
  set_default 1 0
  sleep 2

elif [ "ELSEfail" = "1" ]; then
  ui_print " "
  log -u " There is a problem with restoring NOT freq, aborting it" "Restore settings fail (NOT freq), setting default"
  ui_print "___________________________________________________"
  set_default 0 1
  sleep 2

elif [ "$FREQfail" != "1" ] && [ "ELSEfail" != "1" ]; then
   log "Restoring values successfull"
else
   log -a -u " There is unexpected error, send log please, aborting" "Values of FREQ or ELSE fail flags corrupt: $FREQfail || $ELSEfail . Tryed to restore settings from old instance, containing this:
\"$(cat "${MODPATH/_update/}/settings.txt") \" "
fi
}

remind_controls() {
ui_print "___________________________________________________"
ui_print " "
ui_print "   [VOL+] - Change selection | [VOL-] - Confirm    "
ui_print "___________________________________________________"
}

WIDTH=52

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

      ui_print "___________________________________________________"
      ui_print " "
      ui_print " Uncompatible device (not Realme GT3/neo5) detected! "
      ui_print " CPU freq unavabilive, but you can change Governor "
      ui_print "___________________________________________________"
      ui_print " "

elif [ "$COMPATIBLE" = "1" ]; then

      ui_print "___________________________________________________"
      ui_print " "
      ui_print " Realme GT3/neo5 detected!    "
      ui_print " All settings fully avalible  "
      ui_print "___________________________________________________"
      ui_print " "

else
 log -a -u " There is unexpected error, send log please, aborting" "Unexpected error while checking compatible: $COMPATIBLE at start, aborting install"
fi

if [ -f "${MODPATH/_update/}/settings.txt" ] && [ "$COMPATIBLE" = "1" ]; then
      ui_print " "
      log -u " Previous install detected!" "For compatible device"
      ui_print " Choose to restore configuration or setup all again    "
      remind_controls
      ui_print " "
      ui_print "   1. Restore all settings       "
      ui_print "   2. Restore only freq settings "
      ui_print "   3. Restore only not freq settings "
      ui_print "   4. Setup all from scratch     "
      ui_print " "
   show_menu "Restore all settings" "Restore only freq settings" "Restore only not freq settings" "Setup all from scratch"
    case $? in
    1) restore_settings 2 ;;
    2) restore_settings 1 ;;
    3) restore_settings 0 ;;
    4) set_default 1 1 ;;
    esac
elif [ -f "${MODPATH/_update/}/settings.txt" ] && [ "$COMPATIBLE" = "0" ]; then

      ui_print " "
      log -u " Previous install detected!" "For incompatible device"
      ui_print " Choose to restore configuration or setup all again    "
      remind_controls
      ui_print " "
      ui_print "   1. Restore only compatible settings "
      ui_print "   2. Setup all from scratch     "
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
      ui_print "___________________________________________________"
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
      center_print "Choose frequency cut to PRIME cluster"
      ui_print "   1. Stock freq           (3.0Gh)"
      ui_print "   2. Light cut to freq    (2.4Gh)"
      ui_print "   3. Medium cut to freq   (2.0Gh)"
      ui_print "   4. Huge cut to freq     (1.7Gh)"
      ui_print "   5. Maximum cut to freq  (1.4Gh)"
      ui_print " "
      ui_print " Note: Medium setting are recommended"
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
      center_print "Choose frequency cut to BIG cluster"
      ui_print "   1. Stock freq           (2.5Gh)"
      ui_print "   2. Light cut to freq    (1.9Gh)"
      ui_print "   3. Medium cut to freq   (1.7Gh)"
      ui_print "   4. Huge cut to freq     (1.5Gh)"
      ui_print "   5. Maximum cut to freq  (1.3Gh)"
      ui_print " "
      ui_print " Note: Medium setting are recommended"
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
      center_print "Choose frequency cut to LITTLE cluster"
      ui_print "   1. Stock freq           (1.8Gh)"
      ui_print "   2. Light cut to freq    (1.6Gh)"
      ui_print "   3. Medium cut to freq   (1.4Gh)"
      ui_print "   4. Huge cut to freq     (1.2Gh)"
      ui_print "   5. Maximum cut to freq  (1.0Gh)"
      ui_print " "
      ui_print " Note: Medium setting are recommended"
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
ui_print "___________________________________________________"
      ui_print " "
      center_print "Configure your CPU algorithm!    "
      remind_controls
      ui_print " "
      center_print "Choose desired CPU algorithm"
      ui_print "   1. Stock                "
      ui_print "   2. Conservative light   "
      ui_print "   3. Conservative medium  "
      ui_print "   4. Conservative max     "
      ui_print "   5. Powersave            "
      ui_print " "
      ui_print " Note: Learn more about difference in README"
      ui_print " Note: Medium conservative recommended"
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
ui_print "___________________________________________________"
      ui_print " "
      center_print "Configure your disabled CPU cores!    "
      remind_controls
      ui_print " "
      center_print "Choose desired CPU cores to disable"
      ui_print "   1. Not disable                 "
      ui_print "   2. Disable 1 BIG core          "
      ui_print "   3. Disable PRIME core          "
      ui_print "   4. Disable 2 BIG cores         "
      ui_print "   5. Disable PRIME + 1 BIG cores "
      ui_print "   6. Disable 3 BIG cores         "
      ui_print "   7. Disable PRIME + 2 BIG cores "
      ui_print "   8. Disable PRIME + 3 BIG cores "
      ui_print " "
      ui_print " Note: Options sorted from least to most impacting"
      ui_print " Note: Options 4 and 5 recommended,"
      ui_print "       4 if play demanding games, 5 if not"
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
ui_print "___________________________________________________"
      ui_print " "
      center_print "Your configured, very own CPU slowdown settings:"
      ui_print "___________________________________________________"
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
      ui_print "___________________________________________________"
      ui_print " "
      log -u " Generating your chosen configuration..."
      ui_print " Please wait..."

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
echo powersave > /sys/devices/system/cpu/cpu7/cpufreq/scaling_governor
"
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

sleep 5

echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/conservative/ignore_nice_load
echo 1 > /sys/devices/system/cpu/cpu4/cpufreq/conservative/ignore_nice_load
echo 1 > /sys/devices/system/cpu/cpu7/cpufreq/conservative/ignore_nice_load
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

CPU="
logcat -v brief | grep -m 1 'android.intent.action.USER_PRESENT'

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


#experimentals

if [ "$COMPATIBLE" = "1" ]; then
   log "Proceed to EXPIRIMENTAL settings due to compatible: $COMPATIBLE"
EXIT_EXTRA="0"
SCREENOFF_LOW_FREQ="OFF"
SCREENOFF_DISABLE_CORES="OFF"
SCREENOFF_POWERSAVE="UNAVAILABLE"
MANUAL_CORES_ACTION="UNAVAILABLE"

      ui_print " "
      ui_print "___________________________________________________"
      ui_print " "
      center_print "EXPERIMENTAL SETTINGS, BE CAREFULL!"


   while true; do
      remind_controls
      ui_print " "
      ui_print " Choose which experiment to activate:"
      ui_print "  1. Exit (finalize setings)     "
      ui_print "  2. Cut freq down on sleep: $SCREENOFF_LOW_FREQ "
      ui_print "  3. Disable cores on sleep: $SCREENOFF_DISABLE_CORES "
#      ui_print "  4. Set governor to Powersave on sleep: $SCREENOFF_POWERSAVE "
#      ui_print "  5. Manually enable and disable cores:  $MANUAL_CORES_ACTION "
#      ui_print "  6. Cut down CPU freq table to chosen freq: "
#      ui_print "  7. Undervolting. WARNING: could cause DAMAGE: "
#      ui_print "  8. - "
      ui_print " "
      ui_print " Note: List and choose is dynamic and changes"
      ui_print "       until you exit menu "
      ui_print " "

flip_state "SCREENOFF_LOW_FREQ" "SCREENOFF_DISABLE_CORES"

   show_menu "Exit extra settings" "Cut freq on screenoff [TURN ${SCREENOFF_LOW_FREQ_FLIP}]" "Disable cores on screenoff [TURN ${SCREENOFF_DISABLE_CORES_FLIP}]" # "CPU governor to Powersave on screenoff [UNAVAILABLE]" "Manually enable and disable cores by Action button [UNAVAILABLE]"
    case $? in
    1) EXIT_EXTRA="1"
    ;;
    2) SCREENOFF_LOW_FREQ="$SCREENOFF_LOW_FREQ_FLIP"
    ;;
    3) SCREENOFF_DISABLE_CORES="$SCREENOFF_DISABLE_CORES_FLIP"
    ;;
#    4) SCREENOFF_POWERSAVE="$SCREENOFF_POWERSAVE_FLIP"
#    ;;
#    5) MANUAL_CORES_ACTION="$MANUAL_CORES_ACTION_FLIP"
#    ;;
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

if [ "$SCREENOFF_LOW_FREQ" = "ON" ] || [ "$SCREENOFF_DISABLE_CORES" = "ON" ]; then
   log "Logging settings started due to user enabled screenoff experiment"
   
      ui_print " "
      ui_print "___________________________________________________"
      ui_print " "
      center_print "CHOOSE YOUR LOGGING DETAILS"
      ui_print "___________________________________________________"
      ui_print " "
      ui_print " You activated some of experimental settings "
      ui_print " please choose how detailed to log it, cause logs "
      ui_print " puts additional pressure on your system, combating"
      ui_print " power efficiency that you gain "
      remind_controls
      ui_print " "
      center_print "Choose which log depth to activate:"
      ui_print "  1. No any logs at all "
      ui_print "     Do not put any additional code in "
      ui_print "  2. Slight logs (record when state changes) "
      ui_print "     If you wanna know are it working or no"
      ui_print "  3. Full logging (record every ~10 seconds!) "
      ui_print "     If you want to check everything "
      ui_print "     Or you beta tester, etc... "
      ui_print " "

   show_menu "LOGGING: NONE" "LOGGING: GENERAL" "LOGGING: FULL"
    case $? in
    1) LOGGING="NONE" ;;
    2) LOGGING="SOME" ;;
    3) LOGGING="FULL" ;;
    esac
else
   log "Logging menu skipped due to user skipped experimental"
fi

# final conf

if [ $pCOREf = 0 ] && [ $bCOREf = 0 ]; then
      SCREENOFF_DISABLE_CORES="OFF"
fi

if [ "$SCREENOFF_DISABLE_CORES" = "ON" ]; then
   log "Starting recalculating disabled cores due to:" "SCREENOFF_DISABLE_CORES = \"$SCREENOFF_DISABLE_CORES\" "
   if [ $pCOREf = 0 ]; then
      CPU_pCOREe=" "
      CPU_pCOREd=" "
   elif [ $pCOREf = 1 ]; then
      CPU_pCOREe="
sleep 1
echo 1 > /sys/devices/system/cpu/cpu7/online
"
      CPU_pCOREd="
sleep 1
echo 0 > /sys/devices/system/cpu/cpu7/online
"
   fi

   if [ $bCOREf = 0 ]; then
      CPU_bCOREe=" "
      CPU_bCOREd=" "
   elif [ $bCOREf = 1 ]; then
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

   CPU_COREd="$CPU_bCOREd $CPU_pCOREd"
   CPU_COREe="$CPU_bCOREe $CPU_pCOREe"
   
fi

if [ "$SCREENOFF_LOW_FREQ" = "ON" ] || [ "$SCREENOFF_DISABLE_CORES" = "ON" ]; then
   if [ "$LOGGING" = "SOME" ] || [ "$LOGGING" = "FULL" ]; then
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
STATE=\$(dumpsys power | grep -i 'mHoldingDisplaySuspendBlocker' | awk -F= '{print \$2}' | tr -d '\r')"
    if [ "$LOGGING" = "FULL" ]; then
      writeinfo  '      log "Cycle alive: Current state: $STATE" '
    fi
    writeinfo 'if [ "$STATE" = "true" ]; then 
   if [ "$SCREEN" = "1" ]; then
      sleep 2'
   if [ "$LOGGING" = "FULL" ]; then
      writeinfo '      log "Skipped action: screen was ON and still ON" '
   fi
writeinfo '   else
      SCREEN="1"'
   if [ "$LOGGING" = "SOME" ] ||[ "$LOGGING" = "FULL" ]; then
      writeinfo '      log "Reverting action: screen was OFF and turned ON" '
   fi
   if [ "$SCREENOFF_LOW_FREQ" = "ON" ] && [ "$SCREENOFF_DISABLE_CORES" = "ON" ]; then
      writeinfo "echo $LITTLEf >> /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
echo $BIGf >> /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
echo $PRIMEf >> /sys/devices/system/cpu/cpu7/cpufreq/scaling_max_freq
sleep 2
$CPU_COREe"

   elif [ "$SCREENOFF_LOW_FREQ" = "ON" ] && [ "$SCREENOFF_DISABLE_CORES" = "OFF" ]; then
      writeinfo "echo $LITTLEf >> /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
echo $BIGf >> /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
echo $PRIMEf >> /sys/devices/system/cpu/cpu7/cpufreq/scaling_max_freq
sleep 2"

   elif [ "$SCREENOFF_DISABLE_CORES" = "ON" ] && [ "$SCREENOFF_LOW_FREQ" = "OFF" ]; then
      writeinfo "echo $PRIMEf > /sys/devices/system/cpu/cpu7/cpufreq/scaling_max_freq
echo $BIGf > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
sleep 2
$CPU_COREe" 

   fi
writeinfo '   fi
elif [ "$STATE" = "false" ]; then 
   if [ "$SCREEN" = "0" ]; then'

   if [ "$LOGGING" = "FULL" ]; then
      writeinfo '      log "Skipped action: screen was OFF and still OFF" '
   fi
   # second part, when screen is off
   writeinfo '      sleep 2
   else
      SCREEN="0"'

   if [ "$LOGGING" = "SOME" ] ||[ "$LOGGING" = "FULL" ]; then
      writeinfo '      log "Executing action: screen was ON and turned OFF" '
   fi
   if [ "$SCREENOFF_LOW_FREQ" = "ON" ] && [ "$SCREENOFF_DISABLE_CORES" = "ON" ]; then
      writeinfo "echo $LITTLEmin >> /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
echo $LITTLEmin >> /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq
echo $BIGmin >> /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
echo $BIGmin >> /sys/devices/system/cpu/cpu4/cpufreq/scaling_cur_freq
echo $PRIMEmin >> /sys/devices/system/cpu/cpu7/cpufreq/scaling_max_freq
echo $PRIMEmin >> /sys/devices/system/cpu/cpu7/cpufreq/scaling_cur_freq
sleep 2
$CPU_COREd"

   elif [ "$SCREENOFF_LOW_FREQ" = "ON" ] && [ "$SCREENOFF_DISABLE_CORES" = "OFF" ]; then
      writeinfo "echo $LITTLEmin >> /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
echo $LITTLEmin >> /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq
echo $BIGmin >> /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
echo $BIGmin >> /sys/devices/system/cpu/cpu4/cpufreq/scaling_cur_freq
echo $PRIMEmin >> /sys/devices/system/cpu/cpu7/cpufreq/scaling_max_freq
echo $PRIMEmin >> /sys/devices/system/cpu/cpu7/cpufreq/scaling_cur_freq
sleep 2"

   elif [ "$SCREENOFF_DISABLE_CORES" = "ON" ] && [ "$SCREENOFF_LOW_FREQ" = "OFF" ]; then
      writeinfo "echo $BIGmin >> /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
echo $BIGmin >> /sys/devices/system/cpu/cpu4/cpufreq/scaling_cur_freq
echo $PRIMEmin >> /sys/devices/system/cpu/cpu7/cpufreq/scaling_max_freq
echo $PRIMEmin >> /sys/devices/system/cpu/cpu7/cpufreq/scaling_cur_freq
sleep 2
$CPU_COREd"

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

else
   log "Experimental settings skipped due to compatible: $COMPATIBLE"
fi

log "Install complete. Dumping values for debug" #"$(set | sort)"