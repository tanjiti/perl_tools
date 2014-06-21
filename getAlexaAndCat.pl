#!/usr/bin/perl
use strict;
use warnings;
use LWP::UserAgent;
use feature qw(say);

binmode(STDIN, ':encoding(utf8)');
binmode(STDOUT, ':encoding(utf8)');
binmode(STDERR, ':encoding(utf8)');

die "You must specify the file include hostlist for analyze or the hostname
for analyze .\n" if ($#ARGV != 0);
my $host = shift;

if(-e $host){
   my $out = $host."_alexaAndType";
   open my $FH, "<:encoding(UTF-8)", $host or die "cannot open $host for reading $!";
   open my $OUT, ">:encoding(UTF-8)", $out or die "cannot open $out for writing $!";

   while(<$FH>){
      chomp;
      say $OUT getAlexa($_) if $_;
   }
   close $FH;
   close $OUT;
}else{
   say getAlexa($host) if $host ne "";
}

sub getAlexa{
   my $host = shift;
   chomp $host;

   my $UserAgent = "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:12.0) Gecko/20100101 Firefox/12.0";
   my $browser = LWP::UserAgent->new();
   $browser->agent($UserAgent);

   my $uri = 'http://data.alexa.com/data?cli=10&dat=snbamz&url='.$host;
   my $response = $browser->get($uri);
   my $content = $response->decoded_content;
   my $alexa = 0;
   my $catalog = "";

   $alexa = $1 if $content =~ /<COUNTRY CODE="[A-Z]{2}" NAME="[\w\s]+" RANK="(\d+)"\/>/;
   my @cats = ($content =~/<CAT ID="[^"]+" TITLE="([^"]+)" CID="\d+"\/>/g);

   if ($#cats == 0){
      $catalog = $cats[0];
   }else{
      foreach (@cats){
         $catalog .= $_.";";
      }
      chop $catalog;
   }
   $catalog = "NONE" if $catalog eq "";
   return $host."\t".$alexa."\t".$catalog;
}
