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

$count = 0;
while ( 1 )
{
	if ( 0 == $count ) { sleep 10; }
	print "fetch\n";
	@files = `ls /mnt/floppy/|grep "rgb\$"`;
	$count = 0;
	foreach $file (@files)
	{
		chomp $file;
		if ( $count < 3 )
		{
			system("mv /mnt/floppy/$file .");
			$count++;
		} else {
			system("rm /mnt/floppy/$file");
		}
	}
	print "convert\n";
	system("for i in \`ls -l|grep rgb|awk '{print(\$9)}'|awk -F- '{print(\$1)}'\`; do convert \$i-00000.rgb \$i.jpg;rm -f \$i-00000.rgb;chown mjerde:mjerde \$i.jpg;done");
	print "pwn\n";
	system("for i in \`ls -l|grep dialout|awk '{print(\$9)}'\`; do chown mjerde:mjerde \$i;done");
	print "nobody\n";
	system("for i in \`ls -l|grep nobody|awk '{print(\$9)}'\`; do chown mjerde:mjerde \$i;done");
	sleep(1);
}
