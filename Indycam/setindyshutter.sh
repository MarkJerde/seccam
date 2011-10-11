#!/bin/sh

#   Set Indy Shutter
#   Script to automatically adjust Indycam shutter speed and gain level to
#   maintain brightness level in desired range.
#
#   Copyright 2006-2011 Mark Jerde
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
#   OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
#   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
#   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
#   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
#   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Script to automatically adjust Indycam shutter speed and gain level to
# maintain brightness level in desired range.
#
# Written by Mark Jerde (mjerde3@charter.net)
#
# Indycam control based on script from Adrie Kooijman's website:
# E-mail: a.kooijmann@io.tudelft.nl
# WWW:  http://www.io.tudelft.nl/~adrie/IndyShutter
# Pointer to script at: http://sprysgi.sghms.ac.uk/~cspry/computing/Indy_admin/IndyCam.html
# adapted with bits from http://gold.sao.nrc.ca/~cantin/indycam/o2cam_shutter
#
# set up camera, default Indy
agc_enable=1447624704
red_bal=1447624708
blue_bal=1447624709
saturation=1447624710
gain=1447624707
shutter=1447624706
brightness=1447624739

speed=7
level=255
glevel=210
finished=0
warmup=0

    speed=`{
        echo openvideo
        echo getnode 0 source video 0
        echo getnode 1 drain memory 0
        echo createpath 0 0 0 1
        echo addnode 0  0
        echo addnode 0  1
        echo setuppaths 0 share share
        # set shutter speed
        # echo setcontrol $shutter 0 0 0 0
        echo setcontrol $agc_enable 0 0 0 1
        # echo getcontrol $brightness 0 0
        echo getcontrol $shutter 0 0

        echo closevideo
        echo quit
        } | /usr/sbin/vlcmd | tee x | awk -F= '/^Integer value/ {print $2}'`
echo $speed
sleep 1

while [ $finished -eq 0 ]; do
    rest=0
    cspeed=0
    cgain=0

    level=`{
        echo openvideo
        echo getnode 0 source video 0
        echo getnode 1 drain memory 0
        echo createpath 0 0 0 1
        echo addnode 0  0
        echo addnode 0  1
        echo setuppaths 0 share share

    #    echo setcontrol $agc_enable 0 0 1 1
    #    echo setcontrol $agc_enable 0 0 0 1

    # set shutter speed
    #   echo setcontrol $shutter 0 0 $speed 0

    # check gain
    #     echo setcontrol $agc_enable 0 0 1 1

        echo getcontrol $brightness 0 0
        echo closevideo
        echo quit
    } | /usr/sbin/vlcmd | tee x | awk -F= '/^Integer value/ {print $2}'`
#cat x

    if [ $warmup -ne 0 ]; then
      warmup=`echo $warmup - 1 | bc`
    else
      if [ $level -gt 150 ]; then
        if [ $glevel -ne 200 ]; then
          glevel=`echo $glevel - 5 | bc`
          cgain=1
        else
          if [ $speed -ne 8 ]; then
            speed=`echo $speed + 1 | bc`
            glevel=255
            cspeed=1
          else
            if [ $level -ge 255 ]; then
              rest=5
            fi
          fi
        fi
      fi
  
      if [ $level -lt 130 ]; then
        if [ $glevel -ne 255 ]; then
          glevel=`echo $glevel + 5 | bc`
          cgain=1
        else
          if [ $speed -ne 0 ]; then
            speed=`echo $speed - 1 | bc`
            glevel=200
            cspeed=1
          else
            if [ $level -lt 66 ]; then
              rest=5
            fi
          fi
        fi
      fi
    fi

    echo "Level: $level"
    if [ $rest -ne 0 ]; then
      sleep $rest
    else
      /usr/people/mjerde/securitycam
      /usr/people/mjerde/securitycam
      /usr/people/mjerde/securitycam
      /usr/people/mjerde/securitycam
      /usr/people/mjerde/securitycam
    fi

    level=nn
    if [ $cspeed -ne 0 ]; then
      level=`{
          echo openvideo
          echo getnode 0 source video 0
          echo getnode 1 drain memory 0
          echo createpath 0 0 0 1
          echo addnode 0  0
          echo addnode 0  1
          echo setuppaths 0 share share
  
      #   echo setcontrol $agc_enable 0 0 1 1
      #   echo setcontrol $agc_enable 0 0 0 1
  
      # set shutter speed
          echo setcontrol $shutter 0 0 $speed 0
  
      # set gain
      #     echo setcontrol $agc_enable 0 0 1 1
          echo setcontrol $gain 0 0 $glevel 255
  
          echo getcontrol $brightness 0 0
          echo closevideo
          echo quit
      } | /usr/sbin/vlcmd | tee x | awk -F= '/^Integer value/ {print $2}'`
    else
      if [ $cgain -ne 0 ]; then
        level=`{
            echo openvideo
            echo getnode 0 source video 0
            echo getnode 1 drain memory 0
            echo createpath 0 0 0 1
            echo addnode 0  0
            echo addnode 0  1
            echo setuppaths 0 share share
    
        # set gain
            echo setcontrol $gain 0 0 $glevel 255
    
            echo getcontrol $brightness 0 0
            echo closevideo
            echo quit
        } | /usr/sbin/vlcmd | tee x | awk -F= '/^Integer value/ {print $2}'`
      fi
    fi

    echo "Level: $level Speed: $speed Gain: $glevel"
    if [ $rest -ne 0 ]; then
      sleep $rest
    else
      /usr/people/mjerde/securitycam
      /usr/people/mjerde/securitycam
      /usr/people/mjerde/securitycam
      /usr/people/mjerde/securitycam
      /usr/people/mjerde/securitycam
    fi

done

# vidtomem -d -z 1/4

exit


