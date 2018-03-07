#!/usr/bin/perl

# =======================================================================================================================================
######----- V_for_VietDict_fravie.pl -----#####
# =======================================================================================================================================
# Auteur : V.GROS
# Version 1.1 
# Dernières modifications : 10 juin 2010
# Synopsis :  - transformation d'une structure XML type "VietDict"
#               vers une structure XML type "Mot à Mot".
# Remarques : - Les entrées sont en français (traduction en vietnamien)
#             - Création d'un journal des exécutions (LOG)
# ---------------------------------------------------------------------------------------------------------------------------------------
# Usage : perl V_VietDict_fravie.pl -v -from source.xml -to MAM.xml 
#
# -v : affiche les informations du STDERR
#
# Pour les options avancées :
#
# -date "date" 					 : pour spécifier la date (par défaut : la date du jour (localtime)
# -erreur "message d'erreur" 	 : pour spécifier le message d'erreur (ouverture de fichiers)
# -encodding "format d'encodage" : pour spécifier le format d'encodage (par défaut UTF-8)
# -help 						 : pour afficher l'aide
# =======================================================================================================================================



# =======================================================================================================================================
###--- METADIRECTIVES ---###

use strict;
use warnings;
use utf8;
use IO::File; 
use Getopt::Long; # pour gérer les arguments.

use XML::Twig; # (non inclus dans le core de Perl), pour le parsing de la source.
use XML::Writer; # (non inclus dans le core de Perl), pour le fichier de sortie.


# =======================================================================================================================================
###--- PROLOGUE ---###

# ------------------------------------------------------------------------
##-- Les balises de la source/de la sortie (MAM) --##

# ------------------------------------------------
# MODIFIEZ CES VARIABLES SELON LE TRAITEMENT VOULU
# ------------------------------------------------

my $ref_root = 'volume'; # la racine (par exemple : <volume> ou <dictionary>).
my $ref_entry = 'entry' ; # l'élément dans la source qui correspond à <m:entry> dans MAM.
my $ref_sense = 'syntactic-sense' ; # idem pour l'élément <m:sense> dans MAM.

my  $in_root 		   = 'volume'; 
my  $in_entry 		   = 'entry'; 		
my	$in_headword 	   = 'headword';  	
my	$in_sense 		   = 'syntactic-sense'; 	   
my	$in_translation    = 'translation';   
my	$in_examples 	   = 'example';   
my	$in_example 	   = 'fra'; 	   
my	$in_else1 		   = 'example'; 
my	$in_else1b 		   = 'vie'; 
my  $in_else2 		   = 'pos'; 

# ------------------------------------------------------------------------
##-- Gestion des options --##

my ($date, $FichierXML, $FichierResultat, $erreur, $encoding) = ();
my ($verbeux, $help) = ();
my $count_entry = 8670000000; # 8670 = VF (Pour Vietdict Français).
GetOptions( 
  'date|time|t=s'        	  => \$date, # flag de type -date ou --date, ou -time ou --time, ou -t ou --t (=s : string)
  'source|in|from|i=s'        => \$FichierXML, 
  'sortie|out|to|o=s'         => \$FichierResultat, 
  'erreur|error|e=s'     	  => \$erreur, 
  'encodage|encoding|enc|f=s' => \$encoding, 
  'help|h'                	  => \$help, 
  'verbeux|v'             	  => \$verbeux, 
  );

if (!(defined $date))	{$date = localtime;};
if (!(defined $FichierXML)) {&help;};
	# si le fichier source n'est pas spécifié, affichage de l'aide.
if (!(defined $FichierResultat)) {$FichierResultat = $FichierXML;};
if (!(defined $erreur)) {$erreur = "|ERROR| : problem opening file :";};
if (!(defined $encoding)) {$encoding = "UTF-8";};
if (defined $help) {&help;};
	
# ------------------------------------------------------------------------
##-- Configuration de l'output --##

my $output = new IO::File(">$FichierResultat");
my $writer = new XML::Writer(
  OUTPUT      => $output,
  DATA_INDENT => 3,         # indentation, 3 espaces
  DATA_MODE   => 1,         # changement ligne.
  ENCODING    => $encoding,
);
$writer->xmlDecl($encoding);

# ------------------------------------------------------------------------
if ( defined $verbeux )	{&info('a');};
# message dans le STDERR (voir subroutine 'info') indiquant le démarrage du programme.

# =======================================================================================================================================
###--- TWIG ---###
if ( defined $verbeux ) {&info('b');};

# ------------------------------------------------------------------------
# Writer et Twig :
my $name = "VietDict_Fra-Vie";
$writer->startTag
	(
	"m:$ref_root",
	'name'           => $name,
	'source-langage' => "fra",
	'target-langage' => "vie",
	'creation-date'  => $date,
	);

my $twig = XML::Twig->new
	(
	output_encoding => $encoding, # on reste en utf8
	Twig_handlers   => {$in_entry => \&entry,}, 
	);
$twig->parsefile($FichierXML);
my $root = $twig->root; 

# ------------------------------------------------------------------------
if ( defined $verbeux ) {&info('c');};
	
# ------------------------------------------------------------------------	
# Fin du fichier en sortie :
$writer->endTag("m:$ref_root");
$output->close();


# ------------------------------------------------------------------------
if ( defined $verbeux ) {&info('d');};


# =======================================================================================================================================
###--- SUBROUTINES ---###

sub entry 
{
my ($twig, $twig_entry) = @_;
my $entry = $twig_entry->name;
$count_entry++;
my $count_sense = 0;
 
$writer->startTag(
	"m:entry", 
	'id' => 'fra.' . $twig_entry->field($in_headword) . '.' . $count_entry, 
	'level' => ""
	);
	$writer->startTag("m:head");
		$writer->startTag("m:headword");
		$writer->characters($twig_entry->field($in_headword));
		$writer->endTag("m:headword");

		$writer->startTag("m:pronunciation");
		$writer->endTag("m:pronunciation");

		$writer->startTag("m:pos");
		$writer->endTag("m:pos");
	$writer->endTag("m:head");	

foreach my $twig_sense ($twig_entry->children($in_sense))
	{
	$count_sense++;
	$writer->startTag(
		"m:sense", 
		'id' => 's' . $count_sense, 
		'level' => "");
		$writer->startTag("m:definition");
			$writer->startTag("m:label");
			$writer->endTag("m:label");
		
			$writer->startTag("m:formula");
			$writer->endTag("m:formula");
		$writer->endTag("m:definition");
	
		$writer->startTag("m:gloss");
		$writer->endTag("m:gloss");
	
		$writer->startTag("m:translations");
		foreach my $twig_translation ($twig_sense->findnodes($in_translation))
			{
			$writer->emptyTag(
				"m:translation",
				'idrefaxie'=> $twig_translation->text,
				'idreflexie' => "s" . $count_sense,
				'lang' => "vie"
				);
			}
		$writer->endTag("m:translations");
	
		$writer->startTag("m:examples");
		foreach my $twig_examples ($twig_sense->children($in_examples))
			{
			foreach my $twig_example ($twig_examples->children($in_example))
				{
				$writer->startTag("m:example");
				$writer->characters($twig_example->text);
				$writer->endTag("m:example");
				}
			}
		$writer->endTag("m:examples");	

		$writer->startTag("m:idioms");
			$writer->startTag("m:idiom");
			$writer->endTag("m:idiom");
		$writer->endTag("m:idioms");

		$writer->startTag("more-info");
		foreach my $twig_examples ($twig_sense->children($in_examples))
			{
			foreach my $twig_else1 ($twig_sense->findnodes($in_else1b))
				{
				$writer->startTag("more", 'source' => $in_else1 . '/' . $in_else1b);
				$writer->characters($twig_else1->text);
				$writer->endTag("more");
				}
			}
		foreach my $twig_else2 ($twig_sense->findnodes($in_else2))
			{
			$writer->startTag("more", 'source' => $in_else2);
			$writer->characters($twig_else2->text);
			$writer->endTag("more");
			}
		$writer->endTag("more-info");
	$writer->endTag('m:sense');
	}
$writer->endTag("m:entry");
$twig->purge;
return;
}

sub info
{
my $info = shift @_;
if ($info =~ 'a')
	{
	print (STDERR "================================================================================\n");
	print (STDERR "\t~~~~ Mise en route du programme $0 ~~~~\n");
	print (STDERR "================================================================================\n");
	}
elsif ($info=~ 'b')
	{
	print (STDERR "================================================================================\n");
	print (STDERR "Parcours du fichier source\n");
	print (STDERR "--------------------------------------------------------------------------------\n");
	}
elsif ($info=~ 'c')
	{
	print (STDERR "Le fichier source a ete correctement evalue\n");
	print (STDERR "--------------------------------------------------------------------------------\n");
	print (STDERR "Ecriture des changements dans le fichier final $FichierResultat \n");
	print (STDERR "--------------------------------------------------------------------------------\n");
	}
elsif ($info =~ 'd')
	{
	print (STDERR "~~~~ Fermeture du programme $0 ~~~~\n");
	print (STDERR "================================================================================\n");
	my $time = times ;
	my $FichierLog = 'LOG.txt';
	open(my $FiLo, ">>:encoding($encoding)", $FichierLog) or die ("$erreur $!\n");
	print {$FiLo}
	"==================================================\n",
	"RAPPORT : ~~~~ $0 ~~~~\n",
	"--------------------------------------------------\n",
	"Fichier source : $FichierXML\n",
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