#!/usr/bin/perl

use strict;
use warnings;

use XML::Twig;

my $result_twig;

foreach my $file ( 'a.xml', 'b.xml')
  { my $current_twig= XML::Twig->new( comments => 'process')->parsefile( $file);
    if( !$result_twig)
      { $result_twig= $current_twig; }
    else
      { $current_twig->root->move( last_child => $result_twig->root)
                           ->erase;
      }
  }

$result_twig->print_to_file('c.xml');
