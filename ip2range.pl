#!/usr/bin/perl
use strict;
use warnings;
use List::MoreUtils qw(uniq);
use Regexp::Common qw(net);
use feature qw(say);

my $file = shift;
ipList2ipRange($file);

sub ipList2ipRange{
	my $file = shift;

	open my $FH, "<" , $file or die "cannot open $file for transform  $!\n";
	my @ipv4s_tmp = <$FH>;
	close $FH;

	#delete duplicate ip
	my @ipv4s_uniq = uniq @ipv4s_tmp;

	#delete illegal ip
	my @ipv4s_legal = map {/($RE{net}{IPv4})/} @ipv4s_uniq;

	#true ip to long number format
	my @ipv4s_long = map ip2long($_) , @ipv4s_legal;

	#sort ip
	my @ipv4s_final = sort {$a <=> $b} @ipv4s_long;


	for (my $i = 0; $i < $#ipv4s_final;){
		my $j = $i;
		for(; $j < $#ipv4s_final and $ipv4s_final[$j + 1] == $ipv4s_final[$j] + 1; $j++){

		}
		if ($j == $i){
			say long2ip($ipv4s_final[$i]) ;
		}else{
			say long2ip($ipv4s_final[$i])."-".long2ip($ipv4s_final[$j]);
		}

		$i = $j + 1;
	}



}



sub ip2long{

    my $ip = shift;
    my $long = unpack('N',(pack('C4',(split(/\./,$ip)))));
    return $long;
}

sub long2ip{
    my $ip_dec = shift;
    my @ip_parts = unpack('C4',(pack('N',$ip_dec)));
    my $ip = join "\.",@ip_parts;
    return $ip;
}
