#!/usr/bin/env perl

# usage : W_for_Sort.pl infile.xml > infile-sorted.xml

use strict;
use warnings;
use utf8;

use locale; # si les variables d'environnement sont correctement positionnées, cela devrait suffire
use POSIX qw(locale_h setlocale); # pour forcer une locale donnée
#setlocale(LC_ALL,"km_KH.UTF-8"); # pour forcer la locale fr_FR
setlocale(LC_ALL,"fr_FR.UTF-8"); # pour forcer la locale fr_FR
#use Text::StripAccents;
use Unicode::Collate;

my $collator = Unicode::Collate::->new();
#use Text::StripAccents;
my $encoding = "UTF-8";

binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

my $entry = 'article';
my $headword = 'mot_vedette';
my $pos = 'categorie_grammaticale';


 
my $lines = 0;
$/ = "<\/$entry>";
open my $FILE, "<:encoding($encoding)",$ARGV[0] or die ("$! \n");
my @lines = <$FILE>;
my @dico = sort { 
	$a =~ /<$headword>([^<]+)<\/$headword>/m;
	my $m1 = $1;
	$b =~ /<$headword>([^<]+)<\/$headword>/m;
	my $m2 = $1;
	my $cmp = $collator->cmp($m1,$m2);
	if ($cmp == 0) {
		$a =~ /<$pos>([^<]+)<\/$pos>/m;
		$m1 = $1;
		$b =~ /<$pos>([^<]+)<\/$pos>/m;
		$m2 = $1;
		$cmp = $collator->cmp($m1,$m2);	
	}
	return $cmp 
	} 
	@lines;
#my @dico =
 # map  { $_->[0] }
 # sort { $a->[1] cmp $b->[1] }
#  map  { [ $_ => stripaccents($_) ] } 
# @lines;
print @dico;
