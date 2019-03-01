#!/usr/bin/perl
#
use strict;
use warnings;
use utf8::all;

use XML::Parser::PerlSAX;
use XMLReader;
# Create an instance of the Parser, passing as argument
# an instance of the event handler "XMLReader" that we are
# going to implement
my $parser = XML::Parser::PerlSAX->new( Handler => XMLReader->new( ) );

my $file= "t13";
my @tree_stack;
$parser->parse( Source => {SystemId => $file} );
exit;

