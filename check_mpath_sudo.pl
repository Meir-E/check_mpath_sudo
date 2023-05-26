#!/usr/bin/perl
# Custom Script, based https://github.com/crphilipp/zabbix-agent-addons/blob/master/zabbix_scripts/check_mpath_sudo
# By Meir-E | https://github.com/Meir-E/check_mpath_sudo
# 26.05.2023
use strict; # 
use warnings; # 
use JSON;
use Getopt::Long;
use File::Which;
# -- Global Variables
my $json   = {};
my $mpath  = undef;
my $help   = 0;
my $pretty = 0;
my $testing = "no";
# -- Some Functions
# -- Some Functions
GetOptions(
	"mpath=s" => \$mpath, # mpath device ? | 
	'h|help'    => \$help,
	't|test=s'    => \$testing,
	"pretty"  => \$pretty
);
# -- Get load balancer here
if ($help or not defined $mpath){
	print <<_EOF;
Usage : $0 --mpath=<name of the mpath device> [--pretty]

  * --mpath : the name of the device to check
  * --pretty : output pretty JSON, easier to read for humans
  * --t|test : for debug purpose. leave some file for manual edit.
  * --help : display this help

_EOF
  exit 2;
}
my $multipathd = which('multipathd'); # multipathd | https://linux.die.net/man/8/multipathd | https://en.wikipedia.org/wiki/Linux_DM_Multipath

if (not defined $multipathd){
	print 'ZBX_NOTSUPPORTED';
	exit 1;
}
$json = {
	mpath              => $mpath,
	size               => 0,
	dm_st              => 'unknown',
	features           => '',
	failures           => 0,
	path_failures      => 0,
	paths_num_total    => 0,
	paths_num_ok       => 0,
	paths_num_ko       => 0,
	paths_num_active   => 0,
	paths_num_inactive => 0,
	paths_details      => [],
	paths_with_issue   => [],
	errors             => [] };
# Meir
print $testing ;
if ($testing eq "yes")
{
	print "-------------ME-deBug\n";
	print "Testin mode here \n";
	print "-------------ME-deBug\n";
} else
{
	#qx(multipathd show maps raw format "%n|%N|%S|%f|%t|%x|%0" > 002_mpath1.txt);
	#qx(multipathd show paths format "%m|%d|%t|%o|%T|%0|%z" > 002_mpath2.txt);
}
my @res = qx(cat 002_mpath1.txt); #execute system commands
if ($? != 0){
	push @{$json->{errors}}, "Failed to run multipathd show maps raw format";
}
# Run over the multipathss.
foreach (@res){  
	chomp;
	next if $_ !~ /^$mpath\|/;
	(undef,
		$json->{paths_num_total},
		$json->{size}, $json->{features},
		$json->{dm_st},
		$json->{failures},
		$json->{path_failures}) = split(/\s*\|\s*/, $_);
	# Cast to int
	foreach (qw(failures path_failures paths_num_total)){
		$json->{$_} = 0 + $json->{$_};
		}
	# Convert size to bytes
	my $unit = chop $json->{size};
	if ($unit eq 'K'){
		$json->{size} *= 1024;
	} elsif ($unit eq 'M'){
		$json->{size} *= 1024 * 1024;
	} elsif ($unit eq 'G'){
		$json->{size} *= 1024 * 1024 * 1024;
	} elsif ($unit eq 'T'){
		$json->{size} *= 1024 * 1024 * 1024 * 1024;
	} elsif ($unit eq 'P'){
		$json->{size} *= 1024 * 1024 * 1024 * 1024 * 1024;
	}
	# No need to process the other mpath here
	last;
}
# Now check status of every path
@res = qx(cat 002_mpath2.txt);
if ($? != 0){
  push @{$json->{errors}}, "Failed to run multipathd show paths format";
}
# Skip header line
shift @res;
foreach (@res){ # grep like over file: 002_mpath1.txt
	chomp; # remove \n here
	my (
		$MEmpath,
		$dev,
		$dm_st,
		$dev_st,
		$chk_st,
		$failures,
		$serial	) = split(/\s*\|\s*/, $_);
	print "-------------ME-deBug\n";
	print "$MEmpath ne $mpath ? \n";
	print "-------------ME-deBug\n";
	next if $MEmpath ne $mpath;
	push @{$json->{paths_details}}, {
		dev      => $dev,
		dm_st    => $dm_st,
		dev_st   => $dev_st,
		chk_st   => $chk_st,
		failures => $failures + 0,
		serial   => $serial };
	if ($dm_st eq 'active'){
		$json->{paths_num_active} += 1;
		if ($dev_st ne 'running'){
			$json->{paths_num_ko} += 1;
			push @{$json->{paths_with_issue}}, $dev;
			push @{$json->{errors}}, "dev $dev is not running";
		} elsif ($chk_st ne 'ready' or $failures > 0){
			$json->{paths_num_ko} += 1;
			push @{$json->{paths_with_issue}}, $dev;
			push @{$json->{errors}}, "dev $dev is not active";
		} else {
			$json->{paths_num_ok} += 1;
		}
	} else {
		$json->{paths_num_inactive} += 1;
	}
}
# We want easy usage from zabbix, so turn thos ones to strings
$json->{paths_with_issue} = join(',', @{$json->{paths_with_issue}});
$json->{errors}           = join(',', @{$json->{errors}});
# Print to file here
print to_json($json, { pretty => $pretty });
exit 0;
