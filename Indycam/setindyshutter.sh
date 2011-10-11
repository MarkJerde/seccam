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
# set up camera parameter enumerations, default Indy
agc_enable=1447624704
red_bal=1447624708
blue_bal=1447624709
saturation=1447624710
gain=1447624707
shutter=1447624706
brightness=1447624739

# Shutter speed (read immediately below)
speed=7
# Brightness level (read before use)
level=255
# Gain level (never actually read.  Just set.  Don't know why.  It might just trim in fast enough)
glevel=210
# Prevent adjusting settings for n iterations of ten photos each. (don't remember why)
warmup=0

# Set agc_enable (disable automatic gain control, most likely), get shutter speed from hardware.
speed=`{
        # setup
        echo openvideo
        echo getnode 0 source video 0
        echo getnode 1 drain memory 0
        echo createpath 0 0 0 1
        echo addnode 0  0
        echo addnode 0  1
        echo setuppaths 0 share share

        # set agc_enable
        echo setcontrol $agc_enable 0 0 0 1

        # get shutter speed
        echo getcontrol $shutter 0 0

        # cleanup
        echo closevideo
        echo quit
        } | /usr/sbin/vlcmd  | awk -F= '/^Integer value/ {print $2}'`
echo $speed
sleep 1

# Loop indefinitely, evaluating brightness, taking five pictures, adjusting settings, taking five pictures, repeat.
while [ 0 -eq 0 ]; do
	# Flag to indicate that brightness level is outside usable limits, requiring rest.
    rest=0
	# Flags to indicate that shutter speed or gain level are to be changed.
    cspeed=0
    cgain=0

	# Read brightness level from hardware.
    level=`{
        # setup
        echo openvideo
        echo getnode 0 source video 0
        echo getnode 1 drain memory 0
        echo createpath 0 0 0 1
        echo addnode 0  0
        echo addnode 0  1
        echo setuppaths 0 share share

        # set shutter speed
        #echo setcontrol $shutter 0 0 $speed 0

        # get brightness level
        echo getcontrol $brightness 0 0

        # cleanup
        echo closevideo
        echo quit
    } | /usr/sbin/vlcmd | awk -F= '/^Integer value/ {print $2}'`

    if [ $warmup -ne 0 ]; then
      # Do not make adjustments within warmup period.
      warmup=`echo $warmup - 1 | bc`
    else
      # Is brightness level above desired range?
      if [ $level -gt 150 ]; then
        # Is gain level not minimum?
        if [ $glevel -ne 200 ]; then
          # Reduce gain and flag for update.
          glevel=`echo $glevel - 5 | bc`
          cgain=1
        else
          # Can shutter speed be increased?
          if [ $speed -ne 8 ]; then
            # Increase shutter speed, increase gain level to maximum, and flag for update.
            speed=`echo $speed + 1 | bc`
            glevel=255
            cspeed=1
          else
            # Is brightness level above usable limits?
            if [ $level -ge 255 ]; then
              # Flag for rest instead of taking pictures.
              rest=5
            fi
          fi
        fi
      fi

      # Is brightness level below desired range?
      if [ $level -lt 130 ]; then
        # Is gain level not maximum?
        if [ $glevel -ne 255 ]; then
          # Increase gain and flag for update.
          glevel=`echo $glevel + 5 | bc`
          cgain=1
        else
          # Can shutter speed be decreased?
          if [ $speed -ne 0 ]; then
            # Decrease shutter speed, decreased gain level to minimum, and flag for update.
            speed=`echo $speed - 1 | bc`
            glevel=200
            cspeed=1
          else
            # Is brightness level below usable limits?
            if [ $level -lt 66 ]; then
              # Flag for rest instead of taking pictures.
              rest=5
            fi
          fi
        fi
      fi
    fi

    echo "Level: $level"
    if [ $rest -ne 0 ]; then
      # Sleep for a while if brightness level is outside usable limits.
      sleep $rest
    else
      # Take five pictures.
      /usr/people/mjerde/securitycam
      /usr/people/mjerde/securitycam
      /usr/people/mjerde/securitycam
      /usr/people/mjerde/securitycam
      /usr/people/mjerde/securitycam
    fi

    level=nn
    if [ $cspeed -ne 0 ]; then
      # If shutter speed change is requested.

      # Set shutter speed and gain level, get brightness level from hardware.
      level=`{
          # setup
          echo openvideo
          echo getnode 0 source video 0
          echo getnode 1 drain memory 0
          echo createpath 0 0 0 1
          echo addnode 0  0
          echo addnode 0  1
          echo setuppaths 0 share share

          # set shutter speed
          echo setcontrol $shutter 0 0 $speed 0

          # set gain level
          echo setcontrol $gain 0 0 $glevel 255

          # get brightness level
          echo getcontrol $brightness 0 0

          # cleanup
          echo closevideo
          echo quit
      } | /usr/sbin/vlcmd | awk -F= '/^Integer value/ {print $2}'`
    else
      # If shutter speed change isn't requested.
      if [ $cgain -ne 0 ]; then
        # If gain level change is requested.

        # Set gain level, get brightness level from hardware.
        level=`{
            # setup
            echo openvideo
            echo getnode 0 source video 0
            echo getnode 1 drain memory 0
            echo createpath 0 0 0 1
            echo addnode 0  0
            echo addnode 0  1
            echo setuppaths 0 share share

            # set gain level
            echo setcontrol $gain 0 0 $glevel 255

            # get brightness level
            echo getcontrol $brightness 0 0

            # cleanup
            echo closevideo
            echo quit
        } | /usr/sbin/vlcmd | awk -F= '/^Integer value/ {print $2}'`
      fi
    fi

    echo "Level: $level Speed: $speed Gain: $glevel"
    if [ $rest -ne 0 ]; then
      # Sleep for a while if brightness level is outside usable limits.
      sleep $rest
    else
      # Take five pictures.
      /usr/people/mjerde/securitycam
      /usr/people/mjerde/securitycam
      /usr/people/mjerde/securitycam
      /usr/people/mjerde/securitycam
      /usr/people/mjerde/securitycam
    fi

done

exit


