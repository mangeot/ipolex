#!/usr/bin/perl

use XML::DOM::XPath;
use utf8::all;

my $cdmvariantdepart='/database/lexGroup/varW/text()';
 
my $parser= XML::DOM::Parser->new();
my $doc = $parser->parsefile ("file.xml");
 
# print all HREF attributes of all CODEBASE elements
# compare with the XML::DOM version to see how much easier it is to use
my @nodes = $doc->findnodes($cdmvariantdepart);
print $_->getData, "\n" foreach (@nodes);
#print $_->getNodeValue, "\n" foreach (@nodes);