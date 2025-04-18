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
    while true; do
      eval "local current=\"\$$selected\""
      ui_print "➔ $current"
      ui_print " "
      case $(handle_input) in
      "up") selected=$((selected % total + 1)) ;;
      "down") break ;;
      esac
    done

    ui_print " "
    ui_print " You chose ➔ $current"
    ui_print " "

    return $selected
}

set_default() {
 PRIMEf="2995200"
 PRIMEc="Stock freq           (3.0Gh)"
 BIGf="2496000"
 BIGc="Stock freq           (2.5Gh)"
 LITTLEf="1804800"
 LITTLEc="Stock freq           (1.8Gh)"
 uALGf="0"
 dALGf="0"
 ALGc="Stock algorithm"
 pCOREf="0"
 bCOREf="0"
 COREc="Not disable"
 CPU_pCOREd=" "
 CPU_bCOREd=" "
 CPU_ALG=" "
 FREQ_EXPORT="0"
 OTHER_EXPORT="0"
}

restore_settings() {
source "${MODPATH/_update/}/settings.txt"
if [ "$1" = 0 ]; then
 ui_print " "
 ui_print " Restoring your previous freq settings...    "
 ui_print "___________________________________________________"

 export PRIMEf PRIMEc BIGf BIGc LITTLEf LITTLEc
 FREQ_EXPORT="1"
 OTHER_EXPORT="0"

 if [ -z "$PRIMEf" ] || [ -z "$PRIMEc" ] || [ -z "$BIGf" ] || [ -z "$BIGc" ] || [ -z "$LITTLEf" ] || [ -z "$LITTLEc" ]; then
  ui_print " "
  ui_print " There is a problem with restoring, aborting "
  ui_print "___________________________________________________"
  set_default
  sleep 2
 fi

elif [ "$1" = 1 ]; then
 ui_print " "
 ui_print " Restoring all your previous settings...    "
 ui_print "___________________________________________________"

 export PRIMEf PRIMEc BIGf BIGc LITTLEf LITTLEc uALGf dALGf ALGc pCOREf bCOREf COREc
 FREQ_EXPORT="1"
 OTHER_EXPORT="1"

 if [ -z "$PRIMEf" ] || [ -z "$PRIMEc" ] || [ -z "$BIGf" ] || [ -z "$BIGc" ] || [ -z "$LITTLEf" ] || [ -z "$LITTLEc" ] || [ -z "$uALGf" ] || [ -z "$dALGf" ] || [ -z "$ALGc" ] || [ -z "$pCOREf" ] || [ -z "$bCOREf" ] || [ -z "$COREc" ]; then
  ui_print " "
  ui_print " There is a problem with restoring, aborting "
  ui_print "___________________________________________________"
  set_default
  sleep 2
 fi
fi
}

if [ -f "${MODPATH/_update/}/settings.txt" ]; then
      ui_print " "
      ui_print " Previous install detected!    "
      ui_print " Choose to restore configuration or setup again    "
      ui_print "___________________________________________________"
      ui_print " "
      ui_print "   [VOL+] - Change selection | [VOL-] - Confirm    "
      ui_print "___________________________________________________"
      ui_print " "
      ui_print "   1. Restore all settings       "
      ui_print "   2. Restore only freq settings "
      ui_print "   3. Setup all from scratch     "
      ui_print " "
   show_menu "Restore all settings" "Restore only freq settings" "Setup all from scratch"
    case $? in
    1) restore_settings 1 ;;
    2) restore_settings 0 ;;
    3) set_default ;;
    esac
else

      ui_print " "
      ui_print " No any previous install detected!    "
      ui_print " Setting all up from scratch:    "
      ui_print "___________________________________________________"
 set_default
fi

rm -rf "${MODPATH/_update/}"


if [ "$FREQ_EXPORT" != 1 ]; then
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

fi

if [ "$OTHER_EXPORT" != 1 ]; then
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
      ui_print " Generating your chosen configuration..."
      ui_print " Please wait..."

echo "
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
" > $MODPATH/settings.txt

sleep 5

#Calculating .sh files

if [ $pCOREf = 0 ]; then
CPU_pCOREd=" "
elif [ $pCOREf = 1 ]; then
CPU_pCOREd="
sleep 1
echo 0 > /sys/devices/system/cpu/cpu7/online
"
fi

if [ $bCOREf = 0 ]; then
CPU_bCOREd=" "
echo "dalvik.vm.background-dex2oat-cpu-set=0,1,2,3,4,5,6" > $MODPATH/system.prop
elif [ $bCOREf = 1 ]; then
CPU_bCOREd="
sleep 1
echo 0 > /sys/devices/system/cpu/cpu6/online
"
echo "dalvik.vm.background-dex2oat-cpu-set=0,1,2,3,4,5" > $MODPATH/system.prop
elif [ $bCOREf = 2 ]; then
CPU_bCOREd="
sleep 1
echo 0 > /sys/devices/system/cpu/cpu5/online
sleep 1
echo 0 > /sys/devices/system/cpu/cpu6/online
"
echo "dalvik.vm.background-dex2oat-cpu-set=0,1,2,3,4" > $MODPATH/system.prop
elif [ $bCOREf = 3 ]; then
CPU_bCOREd="
sleep 1
echo 0 > /sys/devices/system/cpu/cpu4/online
sleep 1
echo 0 > /sys/devices/system/cpu/cpu5/online
sleep 1
echo 0 > /sys/devices/system/cpu/cpu6/online
"
echo "dalvik.vm.background-dex2oat-cpu-set=0,1,2,3" > $MODPATH/system.prop
fi

CPU_COREd="$CPU_bCOREd $CPU_pCOREd"


if [ $uALGf = 1 ]; then
CPU_ALG=" "
elif [ $dALGf = 1 ]; then
CPU_ALG="
echo powersave > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo powersave > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor
echo powersave > /sys/devices/system/cpu/cpu7/cpufreq/scaling_governor
"
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
fi

CPU_COREf="
echo 300000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
echo $LITTLEf > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
echo 633600 > /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq
echo $BIGf > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
echo 787200 > /sys/devices/system/cpu/cpu7/cpufreq/scaling_min_freq
echo $PRIMEf > /sys/devices/system/cpu/cpu7/cpufreq/scaling_max_freq

sleep 5
"

CPU="logcat -v brief | grep -m 1 'android.intent.action.USER_PRESENT'

sleep 60
$CPU_COREf $CPU_ALG $CPU_COREd"

echo "$CPU" > $MODPATH/service.sh

POST="
lock_val() {
    [ ! -f "$2" ] && return
    umount "$2"

    chmod +w "$2"
    echo "$1" | tee -a /dev/mount_mask "$2"
    mount --bind /dev/mount_mask "$2"
    rm /dev/mount_mask
}

lock_val 300000 /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
lock_val $LITTLEf /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
lock_val 633600 /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq
lock_val $BIGf /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
lock_val 787200 /sys/devices/system/cpu/cpu7/cpufreq/scaling_min_freq
lock_val $PRIMEf /sys/devices/system/cpu/cpu7/cpufreq/scaling_max_freq
"

echo "$POST" > $MODPATH/post-fs-data.sh
