#!/usr/bin/perl -w

#   Security Camera
#   Motion-detecting software for filtering a series of images.
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

@nfsbug = ("touch /mnt/floppy/that","rm -f /mnt/floppy/that");
$nbc = 0;

$delay = 1;
while ( 1 )
{
	print "fetch\n";
	@files = `ls /mnt/floppy/|grep "rgb\$"`;
	$count = 0;
	foreach $file (@files)
	{
		chomp $file;
		if ( $count < 30 )
		{
			system("mv /mnt/floppy/$file .");
			$file =~ s/-00000.*//;
			print "$file\n";
			system("convert $file-00000.rgb $file.jpg;rm -f $file-00000.rgb;chown mjerde:mjerde $file.jpg");
			$count++;
		} else {
			system("rm /mnt/floppy/$file");
		}
	}
	if ( 0 == $count )
	{
		###############################################
		# We didn't get anything, so we should rest.
		# Increment each consecutive down time up to
		# a 10 sec delay.
		###############################################

		if ( 5 > $delay )
		{
			###############################################
			# Poke the NFS to update itself if delay is
			# still short.  This avoids 30-second dead
			# windows.
			###############################################
			system $nfsbug[$nbc];
			if ( $nbc ) { $nbc = 0; }
			else { $nbc = 1; }
		}

		if ( $delay != 10 ) { $delay++; }
	}
	else { $delay = 1; }
	print "s$delay\n";
	sleep $delay;
}
