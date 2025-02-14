# Disable specific chromebooks power settings and apply more generic ones:
# - Enable ambient light sensor support
# - Enable keyboard backlight
# - Enable multiple batteries support
# - Enable AC charge port detection
# - Determine the default suspend mode (S0 / S3) according to /sys/power/mem_sleep default value
# - Add "suspend_s0" and "suspend_s3" options to force suspend using S0 or S3 methods
# - Add a more granular backlight management option "advanced_als" (based on pixel slate implementation)

native_chromebook_image=0
for i in $(echo "$1" | sed 's#,# #g')
do
	if [ "$i" == "native_chromebook_image" ]; then native_chromebook_image=1; fi
done

if [ "$native_chromebook_image" -eq 1 ]; then exit 0; fi

if [ -d /roota/usr/share/power_manager/board_specific ]; then rm -r /roota/usr/share/power_manager/board_specific; fi

ret=0

mkdir -p /roota/usr/share/power_manager/board_specific
if [ ! "$?" -eq 0 ]; then ret=$((ret + (2 ** 0))); fi

echo 2 > /roota/usr/share/power_manager/board_specific/has_ambient_light_sensor
if [ ! "$?" -eq 0 ]; then ret=$((ret + (2 ** 1))); fi

echo 1 > /roota/usr/share/power_manager/board_specific/has_keyboard_backlight
if [ ! "$?" -eq 0 ]; then ret=$((ret + (2 ** 2))); fi

echo 1 > /roota/usr/share/power_manager/board_specific/multiple_batteries
if [ ! "$?" -eq 0 ]; then ret=$((ret + (2 ** 3))); fi

echo 4 > /roota/usr/share/power_manager/board_specific/low_battery_shutdown_percent
if [ ! "$?" -eq 0 ]; then ret=$((ret + (2 ** 4))); fi

echo 1 > /roota/usr/share/power_manager/board_specific/has_barreljack
if [ ! "$?" -eq 0 ]; then ret=$((ret + (2 ** 5))); fi

if [ $(cat /sys/power/mem_sleep | cut -d' ' -f1) == '[s2idle]' ]; then
	echo 1 > /roota/usr/share/power_manager/board_specific/suspend_to_idle
	if [ ! "$?" -eq 0 ]; then ret=$((ret + (2 ** 5))); fi
fi

for i in $(echo "$1" | sed 's#,# #g')
do
	if [ "$i" == "suspend_s0" ]; then
		echo 1 > /roota/usr/share/power_manager/board_specific/suspend_to_idle
		if [ ! "$?" -eq 0 ]; then ret=$((ret + (2 ** 6))); fi
	fi
	if [ "$i" == "suspend_s3" ]; then
		echo 0 > /roota/usr/share/power_manager/board_specific/suspend_to_idle
		if [ ! "$?" -eq 0 ]; then ret=$((ret + (2 ** 7))); fi
	fi
	if [ "$i" == "advanced_als" ]; then
		cat >/roota/usr/share/power_manager/board_specific/internal_backlight_als_steps <<ALS
19.88 19.88 -1 15
29.48 29.48 8 40
37.59 37.59 25 100
47.62 47.62 70 250
60.57 60.57 180 360
71.65 71.65 250 500
85.83 85.83 350 1700
93.27 93.27 1100 6750
100.0 100.0 5250 -1
ALS
		if [ ! "$?" -eq 0 ]; then ret=$((ret + (2 ** 8))); fi
	fi
done

exit $ret
