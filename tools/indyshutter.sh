#!/bin/sh

# Script from Adrie Kooijman's website:
# E-mail: a.kooijmann@io.tudelft.nl  
# WWW:  http://www.io.tudelft.nl/~adrie/IndyShutter
# Pointer to script at: http://sprysgi.sghms.ac.uk/~cspry/computing/Indy_admin/IndyCam.html
#
# set up camera, default Indy
agc_enable=1447624704
red_bal=1447624708
blue_bal=1447624709
saturation=1447624710
gain=1447624707
shutter=1447624706

speed=7
level=255
finished=0
onemore=0

    level=`{
        echo openvideo
        echo getnode 0 source video 0
        echo getnode 1 drain memory 0
        echo createpath 0 0 0 1
        echo addnode 0  0
        echo addnode 0  1
        echo setuppaths 0 share share
        # set shutter speed
        echo setcontrol $shutter 0 0 0 0
        echo setcontrol $agc_enable 0 0 0 1
        echo getcontrol $gain 0 0

        echo closevideo
        echo quit
        } | /usr/sbin/vlcmd `
echo $level
sleep 1

while [ $finished -eq 0 ]; do

    level=`{
        echo openvideo
        echo getnode 0 source video 0
        echo getnode 1 drain memory 0
        echo createpath 0 0 0 1
        echo addnode 0  0
        echo addnode 0  1
        echo setuppaths 0 share share

        echo setcontrol $agc_enable 0 0 1 1
        echo setcontrol $agc_enable 0 0 0 1

    # set shutter speed
        echo setcontrol $shutter 0 0 $speed 0

    # check gain
        echo setcontrol $agc_enable 0 0 1 1

        echo getcontrol $gain 0 0
        echo closevideo
        echo quit
    } | /usr/sbin/vlcmd | tee x | awk -F= '/^Integer value/ {print $2}'`
#cat x

    if [ $speed -le 0 ]; then
      echo "speed le 0"
           finished=1
    fi

    if [ $onemore -ne 0 ]; then
      echo "onemore ne 0"
           finished=1
    fi

    if [ $level -lt 240 ]; then
      echo "level lt 240"
           onemore=1
    fi
    echo "Level: $level"
    echo "Speed: $speed"

    speed=`echo $speed - 1 | bc`

done

# vidtomem -d -z 1/4

exit


