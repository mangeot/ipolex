#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use XML::Twig; # (non inclus dans le core de Perl), pour le parsing de la source.

binmode(STDOUT, ":utf8");          

my $entry_count = 0;

my $twig = XML::Twig->new
(
output_encoding => "UTF-8", # on reste en utf8
Twig_handlers   => {'article' => \&entry,}, 
);
$twig->parsefile($ARGV[0]);


sub entry 
{
	$entry_count++;
	my $count = 0;
	my ($twig, $twig_entry) = @_;
	my $idWol = $twig_entry->{'att'}->{'id'};
	my $form = $twig_entry->first_child('bloc_forme');
	

	my $headword = $form->first_child_text('mot_vedette');
	my $pron = $form->first_child_text('prononciation');
	my $catégorie_grammaticale=$twig_entry->first_child_text('catégorie_grammaticale');
	my $classe_nominale=$twig_entry->first_child_text('classe_nominale');
	my $bloc_metaonformation=$twig_entry->first_child('bloc_metaonformation');
	





	print "Entrée $entry_count:\n";
	print "\tvedette: $headword\n";	
	print "Entrée wol: <article id='$idWol'><vedette>$headword</vedette><traduction>";
	print "<catégorie_grammaticale>$catégorie_grammaticale<catégorie_grammaticale>\n";
	my @senses = $twig_entry->children('sens');
	foreach my $twig_sense (@senses) {
		my $bloc_traduction = $twig_sense->first_child('bloc_traduction');
		if (defined($bloc_traduction)) {
			my $translation = $bloc_traduction->first_child_text('traduction_française');
			my $transid = $translation;
			$transid =~ s/ /_/g;
			my $idPivot = 'wol.'. $headword.':'.'fra.'.$transid;
			print "<lien volume='Baat_axi' lang='axi' type='axi'>$idPivot</lien>";
			print "</traduction>";
			my $exemple=$twig_sense->first_child('exemple');
			my $illustration=$exemple->first_child_text('phrase_illustration');
			if (defined($exemple)){
			print "<phrase_illustration>$illustration</phrase_illustration></article>\n";
		}


			
			my $id_fra = 'fra.' . $transid . '.' . $entry_count . '.e';

			print "Entrée fra: <article id='$id_fra'><vedette>$translation</vedette><traduction>";
 			print "<lien volume='Baat_axi' lang='axi' type='axi'>$idPivot</lien></traduction></article>\n";

			print "Entrée pivot: <article id='$idPivot'><vedette>$idPivot</vedette><liens>";
		 	print "<lien volume='Baat_fra' lang='fra' type='final'>$id_fra</lien>";
		 	print "<lien volume='Baat_wol' lang='wol' type='final'>$idWol</lien>";
		 	print "</liens></article>\n";

		}
	}



	$twig->purge;
}
