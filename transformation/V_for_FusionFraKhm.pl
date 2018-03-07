#!/usr/bin/env perl

# =======================================================================================================================================
######----- V_for_Fusion.pl -----#####
# =======================================================================================================================================
# Auteur : V.GROS
# Version 1.1 
# Dernières modifications : 15 juin 2010
# Synopsis :  - Fusion de deux fichiers XML de même structure XML
#               (type "Mot à Mot").
# Remarques : - La fusion ne modifie pas les deux fichiers sources
#             - Création d'un journal des exécutions (LOG)
# ---------------------------------------------------------------------------------------------------------------------------------------
# Usage : perl V_for_Fusion.pl -v -from source1.xml -and source2.xml -to out.xml 
#
# -v : affiche les informations du STDERR
#
# Pour les options avancées :
#
# -date "date" 				 	 : pour spécifier la date (par défaut : la date du jour (localtime)
# -erreur "message d'erreur" 	 : pour spécifier le message d'erreur (ouverture de fichiers)
# -encodding "format d'encodage" : pour spécifier le format d'encodage (par défaut UTF-8)
# -pretty "indentation" 		 : pour spécifier l'indentation XML ('none' ou 'indented', par exemple)
# -lang "langue"				 : pour spécifier la langue source des ressources qui seront fusionnées
# -help 						 : pour afficher l'aide
# =======================================================================================================================================



# =======================================================================================================================================
###--- METADIRECTIVES ---###
use strict;
use warnings;
use utf8;
use IO::File; 
use Getopt::Long; # pour gérer les arguments.

#use Text::StripAccents; # non inclus dans le core de Perl
use XML::Twig; # (non inclus dans le core de Perl), pour le parsing de la source.
use XML::Writer; # (non inclus dans le core de Perl), pour le fichier de sortie.

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

use POSIX qw(locale_h);
setlocale( LC_ALL, 'fr_FR.UTF-8');


# =======================================================================================================================================
###--- PROLOGUE ---###
my $ref_root = 'm:volume'; # la racine (par exemple : <volume> ou <dictionary>).
my $ref_entry = 'm:entry'; # l'élément de référence pour la fusion (pour MAM : 'entry' par exemple).
my $ref_headword = 'm:headword'; # le sous-élément à comparer pour la fusion
my $ref_sense = 'm:sense'; # le sous-élément qui sera récupéré puis inséré.
 
# ------------------------------------------------------------------------
##-- Gestion des options --##
my ($date, $FichierOne, $FichierTwo, $FichierResultat, $erreur, $encoding) = ();
my ($verbeux, $help, $pretty_print, $langue) = ();
GetOptions( 
  'date|time|t=s'        	    => \$date, # flag de type -date ou --date, ou -time ou --time, ou -t ou --t (=s : string)
  'source|base|in|one|from|i=s' => \$FichierOne, 
  'add|and|two|j=s'        		=> \$FichierTwo,
  'sortie|out|to|o=s'           => \$FichierResultat, 
  'erreur|error|e=s'     	  	=> \$erreur, 
  'encodage|encoding|enc|f=s' 	=> \$encoding, 
  'help|h'                	  	=> \$help, 
  'verbeux|v'             	  	=> \$verbeux, 
  'print|pretty|p=s'       	  	=> \$pretty_print, 
  'langue|lang|l=s'				=> \$langue,
  );
 
if (!(defined $date)) {$date = localtime;};
if (!(defined $FichierOne)) {&help;}; # si le fichier source n'est pas spécifié, affichage de l'aide.
if (!(defined $FichierTwo)) {&help;};
if (!(defined $FichierResultat)) {$FichierResultat = "toto.xml";};
if (!(defined $erreur)) {$erreur = "|ERROR| : problem opening file :";};
if (!(defined $encoding)) {$encoding = "UTF-8";};
if (!(defined $pretty_print)) {$pretty_print = "indented";};
if (!(defined $langue)) {$langue = "XX";};
if (defined $help) {&help;};
 
# ------------------------------------------------------------------------
# Autres variables :
my $count_one = 0; # pour compter les entrées issues de source1.
my $count_two = 0; # idem pour source2.
 
# ------------------------------------------------------------------------
# Input/ Output
open (FILEONE, "<:encoding($encoding)", $FichierOne) or die ("$erreur $!\n");
open (FILETWO, "<:encoding($encoding)", $FichierTwo) or die ("$erreur $!\n");
open (STDERR, ">:encoding($encoding)", 'toto.txt') or die ("$erreur $!\n");
 
# ------------------------------------------------------------------------
if ( defined $verbeux ) {&info('a');};
# message dans le STDERR (voir subroutine 'info') indiquant le démarrage du programme.
 
# ------------------------------------------------------------------------
##-- Début de l'écriture : en-tête XML--##
my $output = new IO::File(">$FichierResultat");
my $writer = new XML::Writer(
  OUTPUT      => $output,
  DATA_INDENT => 3,         # indentation, 3 espaces
  DATA_MODE   => 1,         # changement ligne.
  ENCODING    => $encoding,
);
$writer->xmlDecl($encoding);
 
$writer->startTag
	(
	"m:volume",
	'name'              => "Motamot_" . $langue,
	'source-language'   => $langue,
	'creation-date'     => $date,
	'xmlns:d'  	        => 'http://www-clips.imag.fr/geta/services/dml',
	'xmlns'			    => 'http://www-clips.imag.fr/geta/services/dml/motamot',
	'xmlns:m'			=> 'http://www-clips.imag.fr/geta/services/dml/motamot',
	'xmlns:xsi'		    => 'http://www.w3.org/2001/XMLSchema-instance',
	'xsi:schemaLocation'=> 'http://www-clips.imag.fr/geta/services/dml/motamot' . 
			"http://www-clips.imag.fr/geta/services/dml/motamot_fra.xsd",
	);
 
# =======================================================================================================================================
###--- PREPARATION ---###
my ($twig_one, $twig_two);
my ($entry_one, $entry_two);
$twig_one = XML::Twig->new
  (
   output_encoding => $encoding, 
   pretty_print    => $pretty_print, 
   twig_roots      => {'m:entry' => 1}, 
   Twig_handlers   => {'m:entry' => \&entry_one},
  );
 
sub entry_one {
  $entry_one = $_[1];
  return 1;
}
 
# ------------------------------------------------------------------------
$twig_two = XML::Twig->new
  (
   output_encoding => $encoding, 
   pretty_print    => $pretty_print,
   twig_roots      => {'m:entry' => 1},
   Twig_handlers   => {'m:entry' => \&entry_two},
  );
 
sub entry_two{
  $entry_two = $_[1];
  return 1;
}
 
# ------------------------------------------------------------------------
if ( defined $verbeux ) {&info('b');};
 
# ------------------------------------------------------------------------
$entry_one = next_entry($twig_one, *FILEONE, \$entry_one); # obtenir la première entrée de la source 1.
$entry_two = next_entry($twig_two, *FILETWO, \$entry_two); # obtenir la première entrée de la source 2.
 
# ------------------------------------------------------------------------
if ( defined $verbeux ) {&info('c');};
 
 
# =======================================================================================================================================
###--- ALGORITHME DE LA FUSION ---###

 
# Après avoir récupéré la ou les entrées (sub next_entry), on les compare.
# On écrit dans le fichier de sortie selon la comparaison.
my %entries_one = ();
my %entries_two = ();

my  $last_headword_one = $entry_one ? [$entry_one->findnodes ("//m:headword")]->[0]->text : undef;
my  $last_headword_two = $entry_two ? [$entry_two->findnodes ("//m:headword")]->[0]->text : undef;

my $headword_one = $last_headword_one;
my $headword_two = $last_headword_two;


# Le traitement continuera tant qu'il y a des entrées dans l'une ou l'autre source.
while ($entry_one || $entry_two)
  {
    if ( defined $verbeux )	{print (STDERR "In progress\n");};
    #print "lh1: $last_headword_one h1:$headword_one\n";
    #print "lh2: $last_headword_two h2:$headword_two\n";
    
    while ($headword_one eq $last_headword_one) {
		my $pos_one = $entry_one ? [$entry_one->findnodes ("//m:pos")]->[0]->text : '';
 		$entries_one{$pos_one} = $entry_one;
        $entry_one = next_entry($twig_one, *FILEONE, \$entry_one);
   		$headword_one = $entry_one ? [$entry_one->findnodes ("//m:headword")]->[0]->text : undef;
    }
    if ( defined $verbeux && $headword_one )	{print (STDERR "$FichierOne : entrée [$headword_one]\n");};
 
    while ($headword_two eq $last_headword_two) {
		my $pos_two = $entry_two ? [$entry_two->findnodes ("//m:pos")]->[0]->text : '';
 		$entries_two{$pos_two} = $entry_two;
        $entry_two = next_entry($twig_two, *FILETWO, \$entry_two);
    	$headword_two = $entry_two ? [$entry_two->findnodes ("//m:headword")]->[0]->text : undef;
    }
    if ( defined $verbeux && $headword_two )	{print (STDERR "$FichierTwo : entrée [$headword_two]\n");};
 
    # On compare la présence des headword, et s'ils sont présents tous les deux,
    # on compare les deux headword 'lexicographiquement'
    my $compare = (defined $last_headword_two) - (defined $last_headword_one) || $last_headword_one cmp $last_headword_two;
 	#print 'compare = ',$compare;
 
    # 1) si l'entrée 1 est inférieure à l'entrée 2 (ou s'il n'y a plus d'entrée 2):
    # On écrit l'entrée 1 dans le fichier de sortie.
    # On avance d'une entrée dans le fichier 1
    if ($compare < 0) {
      foreach my $key (sort keys %entries_one) {
      	my $tmp_entry_one = $entries_one{$key};
     	$writer->startTag($tmp_entry_one->root->name, 'id' => $tmp_entry_one->root->id, 'level' => '');
    	$tmp_entry_one->print($output, "indented");
    	$writer->endTag($tmp_entry_one->root->name);
	  } 
	  %entries_one = ();
	  $last_headword_one = $headword_one;
    }
    # 2) si l'entrée 1 est supérieure à l'entrée 2 (ou s'il n'y a plus d'entrée 1):
    # On écrit l'entrée 2 dans le fichier de sortie.
    # On avance d'une entrée dans le fichier 2.
    elsif ($compare > 0) {
      foreach my $key (sort keys %entries_two) {
      	my $tmp_entry_two = $entries_two{$key};
     	$writer->startTag($tmp_entry_two->root->name, 'id' => $tmp_entry_two->root->id, 'level' => '');
    	$tmp_entry_two->print($output, "indented");
    	$writer->endTag($tmp_entry_two->root->name);
	  } 
	  %entries_two = ();
	  $last_headword_two = $headword_two;
    }
    # 3) le dernier cas : entrée 1 = entrée 2 :
    # On ajoute les éléments de entrée 2 dans entrée 1, qu'on écrit dans le fichier de sortie.
    # On avance d'une entrée dans le fichier 1 et dans le fichier 2.
    else
      {
      compare_entries(\%entries_one, \%entries_two);
	  %entries_one = ();
	  %entries_two = ();
	  $last_headword_one = $headword_one;
	  $last_headword_two = $headword_two;
	 }
  }
  
       foreach my $key (sort keys %entries_one) {
      	my $tmp_entry_one = $entries_one{$key};
     	$writer->startTag($tmp_entry_one->root->name, 'id' => $tmp_entry_one->root->id, 'level' => '');
    	$tmp_entry_one->print($output, "indented");
    	$writer->endTag($tmp_entry_one->root->name);
	  } 

      foreach my $key (sort keys %entries_two) {
      	my $tmp_entry_two = $entries_two{$key};
     	$writer->startTag($tmp_entry_two->root->name, 'id' => $tmp_entry_two->root->id, 'level' => '');
    	$tmp_entry_two->print($output, "indented");
    	$writer->endTag($tmp_entry_two->root->name);
	  } 


# ------------------------------------------------------------------------
# Fin de l'écriture :
$writer->endTag("m:volume");
$output->close();
 
# ------------------------------------------------------------------------
if ( defined $verbeux ) {&info('d');};


# =======================================================================================================================================
###--- SUBROUTINES ---###
sub next_entry 
{
my ($twig, $file, $entry) = @_;
 
$$entry = undef;
$/ = "</m:entry>";
while (!$$entry && !eof $file) 
	{
	my $xml = <$file>;
    $twig->safe_parse($xml);
	}
$twig->purge; 
return $$entry;
}

sub compare_entries {
    #print 'compare_entries:',$last_headword_one;
	my ($entries_one, $entries_two) = @_;
		my $size_one = 1+ scalar keys(%$entries_one);
		my $size_two = 1+ scalar keys(%$entries_two);
	
	# special fusion GDEF 1 et FeV 2
#if 0
	if (exists $entries_one->{'n.mf.'} && (exists $entries_two->{'n.m.'} ||  exists $entries_two->{'n.f.'})) {
		my $entry_two = $entries_two->{'n.m.'} || $entries_two->{'n.f.'};
		change_pos($entry_two , 'n.mf.');
		delete $entries_two->{'n.m.'};
		delete $entries_two->{'n.f.'};
		delete $entries_one->{'n.m.'};
		delete $entries_one->{'n.f.'};
		$entries_two{'n.mf.'} = $entry_two;
	}
	if (exists $entries_two->{'n.mf.'} && (exists $entries_one->{'n.m.'} || exists $entries_one->{'n.f.'} )) {
		my $entry_one = $entries_one->{'n.m.'} || $entries_one->{'n.f.'};
		change_pos($entry_one , 'n.mf.');
		delete $entries_two->{'n.m.'};
		delete $entries_two->{'n.f.'};
		delete $entries_one->{'n.m.'};
		delete $entries_one->{'n.f.'};
		$entries_one{'n.mf.'} = $entry_one;
	}
	if (exists $entries_one->{'fonct.'} && exists $entries_two->{'pron.'}) {
		my $entry_one = $entries_one->{'fonct.'};
		change_pos($entry_one , 'pron.');
		delete $entries_one->{'fonct.'};
		$entries_one{'pron.'} = $entry_one;
	}
	if (exists $entries_one->{'fonct.'} && exists $entries_two->{'préf.'}) {
		my $entry_one = $entries_one->{'fonct.'};
		change_pos($entry_one , 'préf.');
		delete $entries_one->{'fonct.'};
		$entries_one{'préf.'} = $entry_one;
	}
	if (exists $entries_one->{'fonct.'} && exists $entries_two->{'prép.'}) {
		my $entry_one = $entries_one->{'fonct.'};
		change_pos($entry_one , 'prép.');
		delete $entries_one->{'fonct.'};
		$entries_one{'prép.'} = $entry_one;
	}
	if (exists $entries_one->{'fonct.'} && exists $entries_two->{'conj.'}) {
		my $entry_one = $entries_one->{'fonct.'};
		change_pos($entry_one , 'conj.');
		delete $entries_one->{'fonct.'};
		$entries_one{'conj.'} = $entry_one;
	}	
	if (exists $entries_one->{'fonct.'} && exists $entries_two->{'adv.'}) {
		my $entry_one = $entries_one->{'fonct.'};
		change_pos($entry_one , 'adv.');
		delete $entries_one->{'fonct.'};
		$entries_one{'adv.'} = $entry_one;
	}	
	if (exists $entries_one->{'fonct.'} && exists $entries_two->{'int.'}) {
		my $entry_one = $entries_one->{'fonct.'};
		change_pos($entry_one , 'int.');
		delete $entries_one->{'fonct.'};
		$entries_one{'int.'} = $entry_one;
	}	
	if (exists $entries_one->{'v.'} && (exists $entries_two->{'v.pr.'} && !exists $entries_two->{'v.'})) {
		my $entry_one = $entries_one->{'v.'};
		change_pos($entry_one , 'v.pr.');
		delete $entries_one->{'v.'};
		$entries_one{'v.pr.'} = $entry_one;
	}
	#endif
	
	foreach my $key_one (sort keys %$entries_one) {
			foreach my $key_two (sort keys %$entries_two) {
				if (index($key_one,$key_two) ==0 && $key_two ne 'v.') {
					my $tmp_entry_one = $entries_one->{$key_one};
					my $tmp_entry_two = $entries_two->{$key_two};
					$tmp_entry_one = fusion($tmp_entry_one,$tmp_entry_two);
    				$writer->startTag($tmp_entry_one->root->name, 'id' => $tmp_entry_one->root->id, 'level' => '');
					$tmp_entry_one->print($output, "indented");
    				$writer->endTag($tmp_entry_one->root->name);
					delete $entries_one->{$key_one};
					delete $entries_two->{$key_two};
					last;
				}
			}
	}

# v.imp.:	5
# v.intr.:	341
# v.pr.:	494
# v.tr.:	139

	foreach my $key_one (sort keys %$entries_one) {
		if (($key_one eq 'v.imp.' || $key_one eq 'v.intr.' || $key_one eq 'v.tr.') && exists $entries_two->{'v.'}) {
				my $tmp_entry_one = $entries_one->{$key_one};
				my $tmp_entry_two = $entries_two->{'v.'};
				$tmp_entry_one = fusion($tmp_entry_one,$tmp_entry_two);
    			$writer->startTag($tmp_entry_one->root->name, 'id' => $tmp_entry_one->root->id, 'level' => '');
				$tmp_entry_one->print($output, "indented");
    			$writer->endTag($tmp_entry_one->root->name);
				delete $entries_one->{$key_one};
		}
	} 

	if (keys(%$entries_one) == 1 && exists $entries_one->{''} && exists $entries_two->{'n.m.'} && exists $entries_two->{'n.f.'}) {
		my $tmp_entry_one = $entries_one->{''};
		my $tmp_entry_two = $entries_two->{'n.m.'};
		change_pos($tmp_entry_one,'n.mf.');
		$tmp_entry_one = fusion($tmp_entry_one,$tmp_entry_two);
    	$writer->startTag($tmp_entry_one->root->name, 'id' => $tmp_entry_one->root->id, 'level' => '');
		$tmp_entry_one->print($output, "indented");
    	$writer->endTag($tmp_entry_one->root->name);
		delete $entries_one->{''};
		delete $entries_two->{'n.m.'};
		delete $entries_two->{'n.f.'};
	}

	if (exists $entries_one->{''} && exists $entries_two->{'v.'} && exists $entries_two->{'v.pr.'}) {
		my $tmp_entry_one = $entries_one->{''};
		my $tmp_entry_two = $entries_two->{'v.'};
		change_pos($tmp_entry_one,'v.');
		$tmp_entry_one = fusion($tmp_entry_one,$tmp_entry_two);
    	$writer->startTag($tmp_entry_one->root->name, 'id' => $tmp_entry_one->root->id, 'level' => '');
		$tmp_entry_one->print($output, "indented");
    	$writer->endTag($tmp_entry_one->root->name);
		delete $entries_one->{''};
		delete $entries_two->{'v.'};
	}
	
	if (exists $entries_one->{'v.pr.'} && exists $entries_two->{'v.'}) {
		my $tmp_entry_one = $entries_one->{'v.pr.'};
		my $tmp_entry_two = $entries_two->{'v.'};
		$tmp_entry_one = fusion($tmp_entry_one,$tmp_entry_two);
    	$writer->startTag($tmp_entry_one->root->name, 'id' => $tmp_entry_one->root->id, 'level' => '');
		$tmp_entry_one->print($output, "indented");
    	$writer->endTag($tmp_entry_one->root->name);
		delete $entries_one->{'v.pr.'};
		delete $entries_two->{'v.'};
	}
	
	if (keys(%$entries_one) == 1 && keys(%$entries_two) == 1) {
		my ($pos_one, $tmp_entry_one) = each(%$entries_one);
		my ($pos_two, $tmp_entry_two) = each(%$entries_two);
		if ($pos_one ne '') {change_pos($tmp_entry_one,$pos_two);}
		$tmp_entry_one = fusion($tmp_entry_one,$tmp_entry_two);
    	$writer->startTag($tmp_entry_one->root->name, 'id' => $tmp_entry_one->root->id, 'level' => '');
		$tmp_entry_one->print($output, "indented");
    	$writer->endTag($tmp_entry_one->root->name);
		delete $entries_one->{$pos_one};
		delete $entries_two->{$pos_two};
	}
	
	if (keys(%$entries_one) == 1 && exists $entries_one->{''} && keys(%$entries_two) >1) {
		my ($pos_one, $tmp_entry_one) = each(%$entries_one);
		foreach my $key_two (sort keys %$entries_two) {
			add_pos($tmp_entry_one,$key_two);
		}
		my ($pos_two, $tmp_entry_two) = each(%$entries_two);
		$tmp_entry_one = fusion($tmp_entry_one,$tmp_entry_two);
    	$writer->startTag($tmp_entry_one->root->name, 'id' => $tmp_entry_one->root->id, 'level' => '');
		$tmp_entry_one->print($output, "indented");
    	$writer->endTag($tmp_entry_one->root->name);
		delete $entries_one->{$pos_one};
	}
	
	
	
	if (keys(%$entries_two) == 0) {
      foreach my $key (sort keys (%$entries_one)) {
        my $tmp_entry_one = $entries_one->{$key};
    	$writer->startTag($tmp_entry_one->root->name, 'id' => $tmp_entry_one->root->id, 'level' => '');
		$tmp_entry_one->print($output, "indented");
    	$writer->endTag($tmp_entry_one->root->name);
	  } 
	}
	elsif (keys(%$entries_one) == 0) {
	  if ($size_one ==0) {
      foreach my $key (sort keys (%$entries_two)) {
        my $tmp_entry_two = $entries_two->{$key};
    	$writer->startTag($tmp_entry_two->root->name, 'id' => $tmp_entry_two->root->id, 'level' => '');
		$tmp_entry_two->print($output, "indented");
    	$writer->endTag($tmp_entry_two->root->name);
	  } 
	  }
	}
	else {
	#	if (keys(%$entries_one) > 1 && keys(%$entries_two) > 1) {
      		print 'compare_entries pos:',$last_headword_one;
			print '1:';
	 		foreach my $key (sort keys %$entries_one) {
     			#print $entries_one->{$key},'|';
     			print $key,'|';
			}
			print '2:';
			 foreach my $key (sort keys %$entries_two) {
     			#print $entries_two->{$key},'|';
     			print $key,'|';
			} 
			print "\n";
		#}
		foreach my $key (sort keys (%$entries_one)) {
        my $tmp_entry_one = $entries_one->{$key};
    	$writer->startTag($tmp_entry_one->root->name, 'id' => $tmp_entry_one->root->id, 'level' => '');
		$tmp_entry_one->print($output, "indented");
    	$writer->endTag($tmp_entry_one->root->name);
	  } 
      foreach my $key (sort keys (%$entries_two)) {
        my $tmp_entry_two = $entries_two->{$key};
    	$writer->startTag($tmp_entry_two->root->name, 'id' => $tmp_entry_two->root->id, 'level' => '');
		$tmp_entry_two->print($output, "indented");
    	$writer->endTag($tmp_entry_two->root->name);
	  } 
 	}
}
 
# ------------------------------------------------------------------------
sub fusion
{
my $entry_one = shift @_;
my $entry_two = shift @_;
my $i = 0;

# fusion des ids si un des 2 est nul
my $id1 = $entry_one->root->id;
my $id2 = $entry_two->root->id;
if (!$id1 || $id1 eq '' && $id2 && $id2 ne '') {
	$entry_one->set_att('id' => $id2);
}

# fusion des head
my $head_one = $entry_one->first_child('m:head');
my $head_two = $entry_two->first_child('m:head');

my $headword_one = $head_one->first_child('m:headword');
my $pos_one = $head_one->first_child('m:pos');
my $pos_two = $head_two->first_child('m:pos');
if ($pos_one->text eq '') {
	$pos_one->set_text($pos_two->text);
}

foreach my $child_two ($head_two->children) {
	my $tagname = $child_two->name;
	if (!$head_one->first_child($tagname)) {
		$child_two->cut;
		if ($tagname eq 'm:pronunciation') {
			$child_two->paste('after' => $headword_one);
		}
		else {
			$child_two->paste('after' => $pos_one);
		}
	}
}

# La fusion consiste à ajouter à la suite les éléments <sense> du second fichier source.
# Il ne faut pas oublier pour cela la gestion de la numérotation des sense.
# Pour les éléments <sense> du premier fichier, rien ne change.
# Pour ceux du second fichier, il existera un décalage selon Sn sense (n = le nombre de <sense> dans le premier fichier).
foreach my $sense_one ($entry_one->findnodes('m:sense'))
  {$i++;}
foreach my $sense_two ($entry_two->findnodes('m:sense'))
  {
  $i++;
  $sense_two->set_id("S" . $i); 
  foreach my $translations ($sense_two->findnodes('m:translations'))
	{
	foreach my $translation ($translations->findnodes('m:translation'))
		{
		$translation->set_att('idreflexie' => "S$i");
		}
	}
  $sense_two->cut;
  my $last_elt = $entry_one->last_child('m:sense');
  $last_elt = $entry_one->last_child('m:head') if !defined $last_elt;
  $sense_two->paste('after' => $last_elt);
  }
return ($entry_one);
}


sub change_pos {
	my $entry = shift @_;
	my $pos_text = shift @_;
	my $head = $entry->first_child('m:head');
	my $pos = $head->first_child('m:pos');
	$pos->set_text($pos_text);
}

sub add_pos {
	my $entry = shift @_;
	my $pos_text = shift @_;
	my $head = $entry->first_child('m:head');
	my $pos = $head->first_child('m:pos');
	my $copy = $pos->copy();
	$copy->set_text($pos_text);
}

 
# ------------------------------------------------------------------------
  
sub info
{
my $info = shift @_;
if ($info =~ 'a')
	{
	print (STDERR "================================================================================\n");
	print (STDERR "\t~~~~ $0 : START ~~~~\n");
	print (STDERR "================================================================================\n");
	}
elsif ($info=~ 'b')
	{
	print (STDERR "================================================================================\n");
	print (STDERR "en-tete du fichier de sortie effective\n");
	print (STDERR "--------------------------------------------------------------------------------\n");
	}
elsif ($info=~ 'c')
	{
	print (STDERR "================================================================================\n");
	print (STDERR "lancement du processus de fusion\n");
	print (STDERR "--------------------------------------------------------------------------------\n");
	}
elsif ($info =~ 'd')
	{
	print (STDERR "~~~~ $0 : END ~~~~\n");
	print (STDERR "================================================================================\n");
	my $time = times ;
	my $FichierLog = 'LOG.txt';
	open(my $FiLo, ">>:encoding($encoding)", $FichierLog) or die ("$erreur $!\n");
	print {$FiLo}
	"==================================================\n",
	"RAPPORT : ~~~~ $0 ~~~~\n",
	"--------------------------------------------------\n",
	"Fichier source1 : $FichierOne\n",
	"--------------------------------------------------\n",
	"Fichier source2 : $FichierTwo\n",
	"--------------------------------------------------\n",
	"Fichier final : $FichierResultat\n",
	"--------------------------------------------------\n",
	"Date du traitement : ", $date, "\n",
	"--------------------------------------------------\n",
	"Lapsed time : ", $time, " s\n",
	"==================================================\n";
	}
}
 
sub help 
{
print (STDERR "================================================================================\n");  
print (STDERR "HELP\n");
print (STDERR "================================================================================\n");
print (STDERR "usage : $0 -i <sourcefile.xml> -o <outfile.xml>\n\n") ;
print (STDERR "options : -h affichage de l'aide\n") ;
print (STDERR "          -e le message d'erreur (ouverture de fichiers)\n") ;
print (STDERR "          -f le format d'encodage\n");
print (STDERR "          -v mode verbeux (STDERR et LOG)\n");
print (STDERR "          -t pour la gestion de la date (initialement : localtime)\n");
print (STDERR "================================================================================\n");
}
 
# =======================================================================================================================================
1 ;
