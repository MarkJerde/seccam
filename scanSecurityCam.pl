#!/usr/bin/perl

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

$threshold = 93;
$delthreshold = -10000; # CFID 90; # FID 96;
$min = 4228.07;
$max = 36686.4;
$premin = 11500;
$premax = 27500;
$current = "";
$prevRes = 0;
$checklumi = 0;
$delay = 0;
@average = ((),());
for ( $i = 0; $i < 10; $i++ ) { $average[0][$i] = -20000; }
for ( $i = 0; $i < 10; $i++ ) { $average[1][$i] = 0; }
$avgCount = 0;
$tagCount = 0;
$avgSize = 30;
$avgSet = 0;
$devthreshold = 2.0;
$delCurrent = 1;
$streak = 0;
$streakl = "";
$streakt = "";

sub atoi
{
	$_ = shift();
	my $e = "";
	my $neg = 1;
	if ( s/e(.*)//i ) { $e = $1; }
	if ( s/^-// ) { $neg = -1; }
	my $t;
	$dot = 0;
	foreach my $d (split(//, $_))
	{
		if ( $d eq "." ) { $dot = 10; }
		elsif ( !$dot ) { $t = $t * 10 + $d; }
		else { $t = $t + ($d/$dot); $dot *= 10; }
	}
	if ( $e ne "" )
	{
		my $ten = 10;
		if ( $e =~ s/-// ) { $ten = 1/10; }
		else { $e =~ s/\+//; }

		$e = atoi($e);
		while ( $e != 0 )
		{
			$t *= $ten;
			$e--;
		}
	}
	$t *= $neg;
	return $t;
}

while ( 1 )
{
	$next = "";
	while ( ! ($current =~ m/\d?\d_\d\d_\d\d_\d\d\.jpg/ ) )
	{
		$current = `ls /tmp/indydump|grep jpg|grep -v diff|grep -v crop|tail -1`;
		chomp($current);
		$current = "/tmp/indydump/".$current;
	}
	while ( ! ($next =~ m/\d?\d_\d\d_\d\d_\d\d\.jpg/ ) )
	{
		$currentg = $current;
		$currentg =~ s/.*\///;
		$next = `ls /tmp/indydump|grep jpg|grep -v diff|grep -v crop|grep -A 1 $currentg|tail -1`;
		chomp($next);
		$next = "/tmp/indydump/".$next;

		if (( ! ($next =~ m/\d?\d_\d\d_\d\d_\d\d\.jpg/ ) )||( $next =~ m/$current/ ))
		{}
		else
		{
			$perms = `ls -l $next`;
			if ( !($perms =~ m/mjerde/) )
			{
				$next = "";
			}
		}
	}
	if ( ! ( $next =~ m/$current/ ) )
	{
		$target = "z";
		$result="";
		$delNext = 0;
		$threshold = -20000; # FID 85;
		@results = ();
		$high = 0;
		#$max = 0;
		$total = 0;
		$target = 10;
		if ( ! -e "$current.crop.jpg.0" )
		{
			`convert -crop 160x120 $current $current.crop.jpg`;
		}
		`convert -crop 160x120 $next $next.crop.jpg`;
		$i = 5;
		$end = 10;
		if ( $pid = fork )
		{
			$i = 0;
			$end = 5;
		}
		for ( ; $i < $end; $i++ )
		{
#				$result = `findimagedupes $current.crop.jpg.$i $next.crop.jpg.$i`;
#				$metric = "MAE"; # Promising.  Has bush trouble.  Maybe frost issues.
#				$metric = "MSE"; # Similar.  Maybe better.  Numbers go up with morning frost.  Moderate threshold based on average?
			$metric = "PSE"; # Pretty darn good at 20k threshold.  Detect on high, so add dash in "seem to be" to negate.
#				$metric = "PSNR"; # So so.  Fairly good at threshold of 30 but a bit weak at times.
#				$metric = "RMSE"; # Ok at a threshold of 15, but has a bit of bush issues.
			$result = `compare -metric $metric $current.crop.jpg.$i $next.crop.jpg.$i /dev/null`;
			chomp $result;
			$result =~ s/^\s*(\S+)\s.*/$1/;
			$result = "seem to be -$result. similar";

			if ( $result =~ m/seem to be.*similar/ )
			{
				system("chmod 644 $next");
				$result =~ s/.*seem to be //;
				$result =~ s/. similar.*//;
				$result = atoi($result);
				if ( $pid )
				{
					push(@results,$result);
				} else {
					system "echo $result >> /tmp/indydump/status";
				}
				#if ( $max < $result ) { $max = $result; }
				#print "res $result\n";
				#system("xli $current.crop.jpg.$i $next.crop.jpg.$i");
			}
			system("rm -f $current.crop.jpg.$i");
		}
		unless ( $pid )
		{
			exit;
		}
		system("rm -f $current.crop.jpg.1*");
		waitpid($pid,0);
		push(@results, split(/\s/,`cat /tmp/indydump/status`));
		for ( $i = 0; $i < 10; $i++ )
		{
			$result = $results[$i];
			$average[($avgSet+1)%2][$i] += $result;
			$deviation = (($result / $average[$avgSet][$i])-1);
			$total += $deviation;
			print "\t$i.  $deviation $average[$avgSet][$i]\n";
			if ( $deviation > $devthreshold )
			{
				if ( $high < $deviation ) { $high = $deviation; $target = $i; }
			}
		}
		$avgCount++;
		if ( $avgSize == $avgCount )
		{
			$avgCount = 0;
			$average[$avgSet][$i] = (0,0,0,0,0,0,0,0,0,0);
			$avgSet = (($avgSet+1)%2);
			for ( $i = 0; $i < 10; $i++ )
			{
				$average[$avgSet][$i] /= $avgSize;
			}
		}
		system("rm -f /tmp/indydump/status");
		if ( 0 == $high)
		{
			print "No hits.  Total: $total\n";
			if ((5*$devthreshold) > $total)
			{
				print "delNext\n";
				$delNext = 1;
			}
			$streak = 0;
		} else {
			system("touch $next.$high.$target.ndiff");
			system("chmod 644 $next.$high.$target.ndiff");
			#system("play ~/media/sounds/clap.wav");
			#system("play ~/media/sounds/clap.wav");
			print "tag\n";
			$streak++;

			if ( $streak < 3 )
			{
				if ( $streak == 1 ) { $streakl = ""; }
				$streakl .= "$next.$high.$target.ndiff\n";
			}
			elsif ( $streak == 3 )
			{
				$streakt = "$current.streak";
				$streakl .= "$next.$high.$target.ndiff";
				system("echo \"$streakl\" > $streakt");
			} elsif ( $streak > 3 ) {
				system("echo $next.$high.$target.ndiff >> $streakt");
			}
		}
		print "high $high dc $delCurrent\n";
		if ( ($delCurrent) && (0 == $high) ) {
			#system("touch $current.$high.$target.del");
			system("rm -f $current");
		}
		$delCurrent = $delNext;
		$current = $next;
		$prevRes = $result;
		$delay = 0;
	} else {
		if ( $delay < 10 ) { $delay++; }
		print "s$delay at $current\n";
		sleep $delay;
	}
}
