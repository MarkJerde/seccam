# Script to compare various image comparison methods.

sub atoi
{
	my $t;
	$dot = 0;
	foreach my $d (split(//, shift()))
	{
		if ( $d eq "." ) { $dot = 10; }
		elsif ( !$dot ) { $t = $t * 10 + $d; }
		else { $t = $t + ($d/$dot); $dot *= 10; }
	}
	return $t;
}

$prevfile = "";
@files = `ls 29_09_3[5-9]*.jpg`;
foreach $file (@files)
{
	chomp $file;
	if ( "" ne $prevfile )
	{
		$result = `findimagedupes $prevfile $file`;
		if ( $result =~ m/seem to be.*similar/ )
		{
			$result =~ s/.*seem to be //;
			$result =~ s/. similar.*//;
			$result = atoi($result);
			print "$result";
		}
		print "\t";
		$result = `compare -metric MAE $prevfile $file /dev/null`;
		$result =~ s/^\s*//; $result =~ s/\s*db\s*$//i;
		print "$result\t";
		$result = `compare -metric MSE $prevfile $file /dev/null`;
		$result =~ s/^\s*//; $result =~ s/\s*db\s*$//i;
		print "$result\t";
		$result = `compare -metric PSE $prevfile $file /dev/null`;
		$result =~ s/^\s*//; $result =~ s/\s*db\s*$//i;
		print "$result\t";
		$result = `compare -metric PSNR $prevfile $file /dev/null`;
		$result =~ s/^\s*//; $result =~ s/\s*db\s*$//i;
		print "$result\t";
		$result = `compare -metric RMSE $prevfile $file /dev/null`;
		$result =~ s/^\s*//; $result =~ s/\s*db\s*$//i;
		print "$result\t$file\n";
	}
	$prevfile = $file;
}
