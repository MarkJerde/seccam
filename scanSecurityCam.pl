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
$min = 4228.07;
$max = 36686.4;
$premin = 11500;
$premax = 27500;
$current = "7_19_12_31.jpg";
$prevRes = 0;
$checklumi = 0;

sub atoi
{
	$_ = shift();
	$tab .= "\t";
	my $e = "";
	if ( s/e(.*)//i ) { $e = $1; }
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
	$tab =~ s/.$//;
	return $t;
}

while ( 1 )
{
	$next = "";
	while ( ! ($current =~ m/\d?\d_\d\d_\d\d_\d\d\.jpg/ ) )
	{
		$current = `ls |grep jpg|grep -v diff|grep -v crop|tail -1`;
		chomp($current);
		$current = $current;
	}
	while ( ! ($next =~ m/\d?\d_\d\d_\d\d_\d\d\.jpg/ ) )
	{
		$currentg = $current;
		$currentg =~ s/.*\///;
		$next = `ls |grep jpg|grep -v diff|grep -v crop|grep -A 1 $currentg|tail -1`;
		chomp($next);
		$next = $next;

		if (( ! ($next =~ m/\d?\d_\d\d_\d\d_\d\d\.jpg/ ) )||( $next =~ m/$current/ ))
		{}
		else
		{
			$perms = `ls -l $next`;
			if ( !($perms =~ m/mjerde/) )
			{
				$next = "";
			} elsif ( $checklumi )  {
				$result = `compare -metric RMSE /tmp/indydump/00black.jpg $next /dev/null`;
				if ( $result =~ m/([\d\.]+)\s*dB/ )
				{
					$result = atoi($1);
					print "luminance next $next res $result\n";
					if ( ($result >= $max) || ($result <= $min) )
					{
						if ( $result >= $max ) { print "ADJUST FASTER\n"; }
						else { print "ADJUST SLOWER\n"; }
						if ( $result >= $max ) { system "date >> lumilog";system "echo way up >> lumilog"; }
						else { system "date >> lumilog";system "echo way down >> lumilog"; }
						system("echo rm -f $next");
						$next = "";
					} else {
						if ( $result >= $premax ) { print "PRE ADJUST FASTER\n"; }
						elsif ( $result <= $premin ) { print "PRE ADJUST SLOWER\n"; }
						if ( $result >= $premax ) { system "date >> lumilog";system "echo up >> lumilog"; }
						elsif ( $result <= $premin ) { system "date >> lumilog";system "echo down >> lumilog"; }
					}
				}
			}
		}
	}
	if ( ! ( $next =~ m/$current/ ) )
	{
		$result="";
		$chopdiff = 1;
		if ( 0 == $chopdiff )
		{
			$result = `findimagedupes $current $next`;
		} else {
			$threshold = 85;
			$low = 100;
			#$max = 0;
			$total = 0;
			if ( ! -e "$current.crop.jpg.0" )
			{
				`convert -crop 160x120 $current $current.crop.jpg`;
			}
			`convert -crop 160x120 $next $next.crop.jpg`;
			$i = 0;
			$end = 10;
			for ( ; $i < $end; $i++ )
			{
				#$result = `findimagedupes $current.crop.jpg.$i $next.crop.jpg.$i`;
				$metric = "MAE"; # Promising.  Has bush trouble.  Maybe frost issues.
				$metric = "MSE"; # Similar.  Maybe better.  Numbers go up with morning frost.  Moderate threshold based on average?
				$metric = "PSE"; # Pretty darn good at 20k threshold.
				#$metric = "PSNR"; # So so.  Fairly good at threshold of 30 but a bit weak at times.
				#$metric = "RMSE"; # Ok at a threshold of 15, but has a bit of bush issues.
				$result = `compare -metric $metric $current.crop.jpg.$i $next.crop.jpg.$i /dev/null`;
				chomp $result;
				$result =~ s/^\s*(\S+)\s.*/$1/;
			$result = "seem to be $result. similar";
				if ( $result =~ m/seem to be.*similar/ )
				{
					system("chmod 644 $next");
					$result =~ s/.*seem to be //;
					$result =~ s/. similar.*//;
					$result = atoi($result);
					$total += $result;
					if ( $low > $result ) { $low = $result; }
					#if ( $max < $result ) { $max = $result; }
					#print "res $result\n";
					#system("xli $current.crop.jpg.$i $next.crop.jpg.$i");
				}
				system("rm -f $current.crop.jpg.$i");
				print "$result";
				if ( ($i+1) % 4 ) { print "\t"; }
				else { print "\n"; }
			}
			system "xli $current $next";
			$total /= 10;
			system("rm -f $current.crop.jpg.*");
#			if ( 80 > $low ) { print "select $next\n"; }
#			elsif ( 96 < $total ) { print "del $next\n"; $low = $total;}
			if ( $threshold <= $low)
			{
				if (90 < $total) { $low = $total; }
			}
			#print "$next min $low max $max avg $total\n";
			#system("xli $current $next");
			$result = "seem to be $low. similar";
		}
		if ( $result =~ m/seem to be.*similar/ )
		{
			system("chmod 644 $next");
			$result =~ s/.*seem to be //;
			$result =~ s/. similar.*//;
			$result = atoi($result);
	print "current $current next $next res $result\n";
			if ( $threshold > $result )
			{
				system("touch $next.$result.ndiff");
				system("chmod 644 $next.$result.ndiff");
				#system("play ~/media/sounds/clap.wav");
				#system("play ~/media/sounds/clap.wav");
				print "tag\n";
			}
			if ( 90 < $prevRes ) {
				system("echo rm -f $current");
			}
			$current = $next;
			$prevRes = $result;
		}
	}
}
