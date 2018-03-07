#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use locale;

use POSIX qw(locale_h setlocale);



# my $locale= 'fr_FR.UTF-8';
 my $locale= 'km_KH.UTF-8';
 
#my $locale= 'zh_TW.UTF-8';

 setlocale( LC_ALL, $locale);
 
  print '1ŋɔ̄ŋɘt-slop<=>ŋɘ̥̄p-lāɘŋ : ', 'ŋɔ̄ŋɘt-slop' cmp 'ŋɘ̥̄p-lāɘŋ', "\n";

  print '2ŋɔ̄ŋɘt-slop<=>ŋɘ̥̄p-lāɘŋ : ', 'ŋɔ̄ŋɘt-slop' cmp 'ŋɘ̥̄p-lāɘŋ', "\n";

 
 print 'ɲ<=>ŋ : ', '(dāel) āc-bɑɲcoh-bɑɲcōl-bān' cmp '(dāel) āc-bɑŋkāɘt-kōn', "\n";
 
 print 'a<=>A : ', 'a' cmp 'A', "\n";
 print 'a<=>b : ', 'a' cmp 'b', "\n";
 
 
