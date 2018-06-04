#!/usr/bin/perl -w

use XML::XPath;
use XML::XPath::XMLParser;
use utf8::all;

my $entry=$ARGV[1];

my $xp = XML::XPath->new(filename => $ARGV[0]);
 
my $nodeset = $xp->find($ARGV[1]); # find all paragraphs
 
foreach my $node ($nodeset->get_nodelist) {
	my $entry = XML::XPath::XMLParser::as_string($node);
	$entry =~ s/\R/ /gsm;
    print STDOUT $entry, "\n";
}