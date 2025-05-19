#!/system/bin/sh

############### CUSTOM FUNCTIONS ################

START_ENV="$TMPDIR/env.txt"
NOW_ENV="$TMPDIR/now.txt"
LOGFILE="/sdcard/Quantom.log"

echo "Start installing, definig functions" > "$LOGFILE"

set | sort > "$START_ENV"

log() {
  local ABORT=0
  local TIME=0
  local TIME_PLUS=0
  local SAVE=0
  local UIP=0
  local MSG=""
  local DETINFO=""
  local LOGLINE=""

  while [ $# -gt 0 ]; do
    case "$1" in
      -a) ABORT=1 ;;
      -s) SAVE=1 ;;
      -u) UIP=1 ;;
      -t) local LOGTIME=""
          LOGTIME=$(date "+%H:%M:%S")
          LOGLINE="[$LOGTIME] "
       ;;
      -T) local LOGTIME=""
          LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
          LOGLINE="[$LOGTIME] "
       ;;
      --) shift; break ;;
      -*) echo "Unknown flag: $1 , ignoring" >> $LOGFILE ;;
      *) 
        if [ -z "$MSG" ]; then
          MSG="$1"
        elif [ -z "$DETINFO" ]; then
          DETINFO="$1"
        fi ;;
    esac
    shift
  done

  if [ -n "$DETINFO" ]; then
    LOGLINE="${LOGLINE}> UI: ${MSG}
 > Details: ${DETINFO}
"
  else
    LOGLINE="${LOGLINE}> UI: ${MSG}
"
  fi

  echo "$LOGLINE" >> "$LOGFILE"

  if [ "$SAVE" = "1" ]; then
    set | sort > "$NOW_ENV"
    echo "--- ENV DUMP START ---" >> "$LOGFILE"
    comm -13 "$START_ENV" "$NOW_ENV" >> "$LOGFILE"
    echo "--- ENV DUMP END ---" >> "$LOGFILE"
  fi

  if [ "$UIP" = "1" ]; then
    ui_print "$MSG"
  fi

  if [ "$ABORT" = "1" ]; then
    sleep 2
    abort "$MSG"
  fi
}

handle_input() {
  while true; do
    case $(timeout 0.01 getevent -lqc 1) in
    *KEY_VOLUMEUP*DOWN*)
      log -t "Vol+ pressed"
      echo "up"
      return
      ;;
    *KEY_VOLUMEDOWN*DOWN*)
      log -t "Vol- pressed"
      echo "down"
      return
      ;;
    esac
  done
}

show_menu() {
  local selected=1
  local total=$#
   log -t "Menu started"
    while true; do
      eval "local current=\"\$$selected\""
      ui_print "➔ $current"
      ui_print " "
       log "Now s: $selected, c: $current"
      case $(handle_input) in
      "up") selected=$((selected % total + 1)) ;;
      "down") break ;;
      esac
    done

    ui_print " "
    ui_print " You chose ➔ $current"
    ui_print " "
     log "Menu chose s: $selected, c: $current"
    return $selected
}

compatible_freq() {
 local FREQ=$(cat /sys/devices/system/cpu/cpu${2}/cpufreq/scaling_available_frequencies)
 local MIN=$(echo "$FREQ" | awk '{print $1}')
 local MAX=$(echo "$FREQ" | awk '{print $NF}')

 log -t "Compatible freq gained for ${1}, featuring:
Min:$MIN and Max:$MAX"

 eval "${1}f=\"$MAX\""
 eval "${1}min=\"$MIN\""
}

set_default() {
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
source "${MODPATH/_update/}/settings.txt"
if [ "$1" = 0 ]; then
 ui_print " "
 ui_print " Restoring your previous freq settings...    "
 ui_print "___________________________________________________"

 export PRIMEf PRIMEc BIGf BIGc LITTLEf LITTLEc
 FREQ_EXPORT="1"
 set_default 0 1
 log -t "Settings restored (freq)"
 check_restore

elif [ "$1" = "1" ]; then
 ui_print " "
 ui_print " Restoring your previous NOT freq settings...    "
 ui_print "___________________________________________________"

 export uALGf dALGf ALGc pCOREf bCOREf COREc
 OTHER_EXPORT="1"
 set_default 1 0
 log -t "Settings restored (NOT freq)"
 check_restore

elif [ "$1" = "2" ]; then
 ui_print " "
 ui_print " Restoring all your previous settings... "
 ui_print "___________________________________________________"


 export PRIMEf PRIMEc BIGf BIGc LITTLEf LITTLEc uALGf dALGf ALGc pCOREf bCOREf COREc
 FREQ_EXPORT="1"
 OTHER_EXPORT="1"
 log -t "Settings restored (all)"
 check_restore
fi
}

check_restore() {
 if [ -z "$PRIMEf" ] || [ -z "$PRIMEc" ] || [ -z "$BIGf" ] || [ -z "$BIGc" ] || [ -z "$LITTLEf" ] || [ -z "$LITTLEc" ]; then
 FREQfail="1"
 log "Corrupted values detected after restoring in FREQ"
 fi

 if [ -z "$uALGf" ] || [ -z "$dALGf" ] || [ -z "$ALGc" ] || [ -z "$pCOREf" ] || [ -z "$bCOREf" ] || [ -z "$COREc" ]; then
 ELSEfail="1"
 log "Corrupted values detected after restoring in ELSE"
 fi

if [ "$FREQfail" = "1" ] || [ "ELSEfail" = "1" ]; then
  ui_print " "
  log -t -u " There is a problem with restoring ALL, aborting it" "Restore settings fail (all), setting default"
  ui_print "___________________________________________________"
  set_default 1 1
  sleep 2

elif [ "$FREQfail" = "1" ]; then
  ui_print " "
  log -t -u " There is a problem with restoring FREQ, aborting it" "Restore settings fail (freq), setting default"
  ui_print "___________________________________________________"
  set_default 1 0
  sleep 2

elif [ "ELSEfail" = "1" ]; then
  ui_print " "
  log -t -u " There is a problem with restoring NOT freq, aborting it" "Restore settings fail (NOT freq), setting default"
  ui_print "___________________________________________________"
  set_default 0 1
  sleep 2

elif [ "$FREQfail" != "1" ] || [ "ELSEfail" != "1" ]; then
   log -t "Restoring values successfull"
else
   log -u -s -T -a " There is unexpected error, send log please, aborting" "Values of FREQ or ELSE fail flags corrupt: $FREQfail || $ELSEfail . Tryed to restore settings from old instance, containing this:
\"$(cat "${MODPATH/_update/}/settings.txt") \" "
fi
}


# For future development to universal and forks
PRIMEmin="787200"
BIGmin="633600"
LITTLEmin="300000"

log -T "Functions defined, all OK. Start install"

MODEL=$(getprop ro.boot.prjname)
case "$MODEL" in
  22624|22625|226B2)
    COMPATIBLE="1"
    log "Realme GT3/neo5 detected!"
    ;;
  *)
    COMPATIBLE="0"
    log "UNcompatible device detected!"
    ;;
esac

#compability and settings restore

if [ "$COMPATIBLE" = "0" ]; then

      ui_print "___________________________________________________"
      ui_print " "
      ui_print " Uncompatible device (not Realme GT3/neo5) detected! "
      ui_print " CPU freq unavabilive, but you still can change Governor "
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
 log -u -s -T -a " There is unexpected error, send log please, aborting" "Unexpected error while checking compatible: $COMPATIBLE at start, aborting install"
fi

if [ -f "${MODPATH/_update/}/settings.txt" ] && [ "$COMPATIBLE" = "1" ]; then
      ui_print " "
      log -u " Previous install detected!" "For compatible device"
      ui_print " Choose to restore configuration or setup all again    "
      ui_print "___________________________________________________"
      ui_print " "
      ui_print "   [VOL+] - Change selection | [VOL-] - Confirm    "
      ui_print "___________________________________________________"
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
      ui_print "___________________________________________________"
      ui_print " "
      ui_print "   [VOL+] - Change selection | [VOL-] - Confirm    "
      ui_print "___________________________________________________"
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
log -t "Old instance deleted"

# main part

if [ "$FREQ_EXPORT" != "1" ]; then
   log -T "FREQ setup started due to EXPORT flag: $FREQ_EXPORT
 COMPATIBLE = $COMPATIBLE"
      ui_print " "
      ui_print " Configure your CPU frequency slowdowdown!    "
      ui_print "___________________________________________________"
      ui_print " "
      ui_print "   [VOL+] - Change selection | [VOL-] - Confirm    "
      ui_print "___________________________________________________"
      ui_print " "
      ui_print " Choose frequency cut to PRIME cluster"
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

ui_print "___________________________________________________"
      ui_print " "
      ui_print "   [VOL+] - Change selection | [VOL-] - Confirm    "
      ui_print "___________________________________________________"
      ui_print " "
      ui_print " Choose frequency cut to BIG cluster"
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

ui_print "___________________________________________________"
      ui_print " "
      ui_print "   [VOL+] - Change selection | [VOL-] - Confirm    "
      ui_print "___________________________________________________"
      ui_print " "
      ui_print " Choose frequency cut to LITTLE cluster"
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
   log -T "FREQ setup skipped due to FREQ flag: $ELSE_EXPORT
 COMPATIBLE = $COMPATIBLE"
fi

#other

if [ "$OTHER_EXPORT" != "1" ]; then
log -T "ELSE setup started due to OTHER flag: $OTHER_EXPORT
 COMPATIBLE = $COMPATIBLE"
ui_print " "
ui_print "___________________________________________________"
      ui_print " "
      ui_print " Configure your CPU algorithm!    "
      ui_print "___________________________________________________"
      ui_print " "
      ui_print "   [VOL+] - Change selection | [VOL-] - Confirm    "
      ui_print "___________________________________________________"
      ui_print " "
      ui_print " Choose desired CPU algorithm"
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
      ui_print " Configure your disabled CPU cores!    "
      ui_print "___________________________________________________"
      ui_print " "
      ui_print "   [VOL+] - Change selection | [VOL-] - Confirm    "
      ui_print "___________________________________________________"
      ui_print " "
      ui_print " Choose desired CPU cores to disable"
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
 log -T "ELSE setup skipped due to ELSE flag: $ELSE_EXPORT
 COMPATIBLE = $COMPATIBLE"
fi


#finales

sleep 1

ui_print " "
ui_print "___________________________________________________"
      ui_print " "
      ui_print " Your configured, very own CPU slowdown settings:"
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

log -t "Pre-exporting preparing done. Begin exporting Settings:"

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
log -T "Settings have been saved: \"$SETTINGS\" "
echo "$SETTINGS" > $MODPATH/settings.txt

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
   log "Prime core disabled, CPU_pCOREd: \"$CPU_pCOREd\" "
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
   log "Big cores disabled, CPU_bCOREd: \"$CPU_bCOREd\" "
fi

CPU_COREd="$CPU_bCOREd $CPU_pCOREd"

log -t "CPU cores state defined, contain: \"$CPU_COREd\" "

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

log -t "CPU algorithm defined, contain: $CPU_ALG"

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
   log -u -s -T -a " There is unexpected error, send log please, aborting" "Unexpected error while checking compatible: $COMPATIBLE at CPU alg stage, aborting install"
fi

log -t "CPU freq reimp set, contain: \"$CPU_COREf\" "

CPU="
logcat -v brief | grep -m 1 'android.intent.action.USER_PRESENT'

sleep 90
$CPU_COREf $CPU_ALG $CPU_COREd"

log -t "Service finalized. Contain: \"$CPU\" "

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
   log -u -a -T " There is unexpected error, send log please, aborting" "Unexpected error while checking compatible: $COMPATIBLE at POST stage, aborting install"
fi

log -t "POST finalized. Contain: \"$POST\" "

echo "$POST" > $MODPATH/post-fs-data.sh

#check if all ok

 if [ -z "$PRIMEf" ] || [ -z "$PRIMEc" ] || [ -z "$BIGf" ] || [ -z "$BIGc" ] || [ -z "$LITTLEf" ] || [ -z "$LITTLEc" ] || [ -z "$uALGf" ] || [ -z "$dALGf" ] || [ -z "$ALGc" ] || [ -z "$pCOREf" ] || [ -z "$bCOREf" ] || [ -z "$COREc" ]; then
   log -u -a -T -s " There is unexpected error, send log please, aborting" "Unexpected error while checking values at the end. Exporting all variables to dump. Compatible: $COMPATIBLE . Installing aborted"
 fi

log -T "All main part is done, script is ready for user and checked"
