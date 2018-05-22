#!/usr/bin/perl -w

use strict;
use utf8;


open (IN,$ARGV[0]);
open (OUT,">",$ARGV[1]);
my $entry=$ARGV[2];
#my @lignes=<IN>;
my $content=join (" ",<IN>);
close (IN);
$content=~s/\s/ /gi;
$content=~/(<$entry.+<\/$entry>)/gi;
	my $articles=$1;
		$articles=~s/(<\/$entry>)/$1\n/gi;
		print OUT $articles."\n";

