#!/usr/bin/perl -w

use strict;
use warnings;
use Data::Dumper;

my $fichierXML=$ARGV[0];
my %dicoCdm=();

sub load_cdm {
    my ($fichier)=@_;
  open (IN,$fichier);
  my %dico=();
  while(my $ligne=<IN>){
      
      if($ligne=~/^\s*<(\S+)\s+xpath=\"([^\"]+[(\sd:lang=\"w+\"\")]?)/gi){
           my $cdm=$1; my $xpath=$2; 
           $dico{$cdm}=$xpath;
      }
  }
  return %dico;
}

%dicoCdm=load_cdm($fichierXML);
print Dumper(%dicoCdm);