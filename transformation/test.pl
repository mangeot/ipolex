#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Unicode::Collate;

my $collator = Unicode::Collate::->new();

my $cmp = $collator->cmp('Aadama','aadama');
$cmp = $collator->cmp('aadama','Aadama');
print 'cmp:',$cmp;