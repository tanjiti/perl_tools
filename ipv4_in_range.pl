#!/usr/bin/env perl
use strict;
use warnings;
use feature qw(say);
my $ip = shift;
my $range = shift;

say ipv4_in_range($ip,$range);

sub ipv4_in_range{
    my $ip = shift;
    my $range = shift;
    
    if (index($range,'/') != -1){
        #range is in IP/NETMASK format
        my ($range, $netmask) = split('/',$range,2);
        my $ip_dec = ip2long($ip);
        my $range_dec = ip2long($range);
        my $netmask_dec = 0;
        if(index($netmask,'.') != -1 ){
            #netmask is a 255.255.0.0 format
            $netmask = str_replace('*','0',$netmask);
            $netmask_dec = ip2long($netmask);
      
        }else{
            #netmask is a CIDR size block like 1.2.3.4/24
            my ($a,$b,$c,$d) = split('.',$range,4);
            $range = sprintf("%s.%s.%s.%s",$a?$a:'0',$b?$b:'0',$c?$c:'0',$d?$d:'0');

            my $wildcard_dec = 2 ** (32 - $netmask) -1;
            $netmask_dec = (~$wildcard_dec);

        }
        return (($ip_dec & $netmask_dec) == ($range_dec & $netmask_dec)) ? 1:0;


    }else{
        # range might be 255.255.*.* or 1.2.3.0-1.2.3.255
        if(index($range,'*') != -1){
            #Just convert to A-B format by setting * to 0 for A and 255 for B
            my $lower = str_replace('*','0',$range);
            my $upper = str_replace('*','255',$range);
            $range = $lower.'-'.$upper;
        }
        
        if(index($range,'-') != -1){ 
            my ($lower,$upper) = split('-',$range,2);
            my $lower_dec = ip2long($lower);
            my $upper_dec = ip2long($upper);
            my $ip_dec = ip2long($ip);
            return 1 if $ip_dec >= $lower_dec and $ip_dec <= $upper_dec;
        }
        return 0;
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

sub str_replace{
    my ($from, $to, $string) = @_;

    my $length = length($from);

    my $p = 0;

    while ( ($p = index($string,$from,$p)) >= 0){
        substr($string,$p,$length) = $to;
    }
    return $string;


}

