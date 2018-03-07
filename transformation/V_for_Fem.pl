#!/usr/bin/perl

# =======================================================================================================================================
######----- V_for_Fem.pl -----#####
# =======================================================================================================================================
# Auteur : V.GROS
# Version 1.0 
# Dernières modifications : 16 juin 2010
# Synopsis :  - transformation d'une structure XML type "Fem"
#               vers une structure XML type "Mot à Mot".
# Remarques : - Les entrées sont en français (traduction en vietnamien)
#             - Création d'un journal des exécutions (LOG)
# ---------------------------------------------------------------------------------------------------------------------------------------
# Usage : perl V_for_Fem.pl -v -from source.xml -to MAM.xml 
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
my  $in_pron		   = 'prnc'; 	

my	$in_body 		   = 'body';
my  $in_sense_list	   = 'sense-list'; # fils de body

my  $in_sense		   = 'sense'; # fils de sense-list
my  $in_sense1_list    = 'sense1-list'; # fils de sense
my  $in_sense1		   = 'sense1'; 	   # fils de sense1-list
my  $in_label		   = 'label'; # "" de sense1
my  $in_gloss		   = 'gloss'; # ""

my	$in_translations   = 'trans-list'; # ""
my  $in_translation	   = 'trans'; # fils de trans-list
my	$in_eng			   = 'eng-list'; # "" de translation
my  $in_msa			   = 'msa-list'; # ""

my	$in_examples 	   = 'expl-list';   # fils de sense1-list
my	$in_example 	   = 'expl'; # fils de expl-list
my  $in_expl_fra	   = 'fra'; # "" de expl
my  $in_expl_eng	   = 'eng'; # ""
my  $in_expl_msa	   = 'msa'; # ""   

# ------------------------------------------------------------------------
##-- Gestion des options --##
my ($date, $FichierXML, $FichierResultat, $erreur, $encoding) = ();
my ($verbeux, $help) = ();
my $count_entry = 7077000000; # 7077 = FM (Pour FeM).
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
if (!(defined $FichierResultat)) {$FichierResultat = "toto.xml";};
if (!(defined $erreur)) {$erreur = "|ERROR| : problem opening file :";};
if (!(defined $encoding))	{$encoding = "UTF-8";};
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
my $name = "FeM";
$writer->startTag
	(
	"m:$ref_root",
	'name'           => $name,
	'source-langage' => "fra",
	'target-langage' => "msa, en",
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
if ( defined $verbeux )	{&info('c');};
	
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
$count_entry = $count_entry + 1;
my $count_sense = 0;
 
$writer->startTag(
	"m:entry", 
	'id' => 'fra.' . $twig_entry->field($in_headword). '.' . $count_entry, 
	'level' => ""
	);
	$writer->startTag("m:head");
		$writer->startTag("m:headword");
		$writer->characters($twig_entry->field($in_headword));
		$writer->endTag("m:headword");

		$writer->startTag("m:pronunciation");
		$writer->characters($twig_entry->field($in_pron));
		$writer->endTag("m:pronunciation");

		$writer->startTag("m:pos");
		$writer->endTag("m:pos");
	$writer->endTag("m:head");	

foreach my $twig_body ($twig_entry->children($in_body)) # body
	{
	foreach my $twig_sense_list ($twig_body->children($in_sense_list))
		{
		foreach my $twig_sense ($twig_sense_list->children($in_sense))
			{
			foreach my $twig_sense1_list ($twig_sense->children($in_sense1_list))
				{
				$count_sense++;
				$writer->startTag(
				"m:sense", 
				'id' => 's' . $count_sense, 
				'level' => "");
				foreach my $twig_sense1 ($twig_sense1_list->children($in_sense1))
					{
					$writer->startTag("m:definition");
					$writer->startTag("m:label");
					$writer->characters($twig_entry->field($in_label));
					$writer->endTag("m:label");
		
					$writer->startTag("m:formula");
					$writer->endTag("m:formula");
					$writer->endTag("m:definition");
						
					$writer->startTag("m:gloss");
					$writer->characters($twig_entry->field($in_gloss));
					$writer->endTag("m:gloss");
					foreach my $twig_translations ($twig_sense1->children($in_translations))
						{
						$writer->startTag("m:translations");
						foreach my $twig_translation ($twig_translations->children($in_translation))
							{
							foreach my $twig_msa ($twig_translation->findnodes($in_msa))
								{
								$writer->emptyTag(
									"m:translation",
									'idrefaxie'=> $twig_msa->text,
									'idreflexie' => "s" . $count_sense,
									'lang' => "msa"
									);
								}
							foreach my $twig_eng ($twig_translation->findnodes($in_eng))
								{
								$writer->emptyTag(
									"m:translation",
									'idrefaxie'=> $twig_eng->text,
									'idreflexie' => "s" . $count_sense,
									'lang' => "eng"
									);
								}
							}
						$writer->endTag("m:translations");
						}
					foreach my $twig_examples ($twig_sense1->children($in_examples))
						{
						$writer->startTag("m:examples");
						foreach my $twig_example ($twig_examples->children($in_example))
							{
							foreach my $twig_expl_fra ($twig_example->findnodes($in_expl_fra))
								{
								$writer->startTag("m:example");
								$writer->characters($twig_expl_fra->text);
								$writer->endTag("m:example");
								}
							}
						$writer->endTag("m:examples");
						}
					}
				$writer->endTag('m:sense');	
				}
			}
		}
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