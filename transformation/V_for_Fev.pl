#!/usr/bin/env perl

# =======================================================================================================================================
######----- V_for_Fev.pl -----#####
# =======================================================================================================================================
# Auteur : V.GROS
# Version 1.0 
# Dernières modifications : 11 juin 2010
# Synopsis :  - transformation d'une structure XML type "Fev"
#               vers une structure XML type "Mot à Mot".
# Remarques : - Structure plate qui nécessite un travail supplémentaire pour unifier le <sense>
#             - Création d'un journal des exécutions (LOG)
# ---------------------------------------------------------------------------------------------------------------------------------------
# Usage : perl V_for_Fev.pl -v -from source.xml -to MAM.xml 
#
# -v : affiche les informations du STDERR
#
# Pour les options avancées :
# -date "date" : pour spécifier la date (par défaut : la date du jour (localtime)
# -erreur "message d'erreur" : pour spécifier le message d'erreur (ouverture de fichiers)
# -encodding "format d'encodage" : pour spécifier le format d'encodage (par défaut UTF-8)
# -help : pour afficher l'aide
# -total : pour indiquer le nombre total d'entrées de la source (pour la barre de progression)
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

my $name = "Fev";

my $ref_root = 'dictionary'; # la racine (par exemple : <volume> ou <dictionary>).
my $ref_entry = 'entry' ; # l'élément dans la source qui correspond à <m:entry> dans MAM.
my $ref_sense = 'french_gloss' ; # idem pour l'élément <sense> de MAM.

my  $in_root 		   = 'dictionary'; 
my  $in_entry 		   = 'entry'; 		
my	$in_headword 	   = 'headword';  	
my	$in_pronunciation  = 'french_pron'; 
my	$in_pos 		   = 'french_cat'; 		    
my	$in_sense 		   = 'french_gloss'; 	   
my	$in_definition     = 'definition';    
my	$in_label 		   = 'french_label'; 	   
my	$in_formula 	   = 'formula'; 	     
my	$in_gloss 		   = 'gloss';  	    
my	$in_translations   = 'translations';  
my	$in_translation    = 'viet_equ';   
my	$in_examples 	   = 'examples';   
my	$in_example 	   = 'french_sentence'; 	   
my	$in_idioms 	       = 'idioms'; 
my	$in_idiom	 	   = 'french_phrase';  	  	  
my	$in_else1 		   = 'english_equ'; 
my  $in_else2 		   = 'malay_equ';	
my  $in_else3		   = 'thai_equ'; 
my	$in_else1b 		   = 'english_sentence'; 
my  $in_else2b 		   = 'malay_sentence';	
my  $in_else3b		   = 'thai_sentence'; 
my	$in_else1c 		   = 'english_phrase'; 
my  $in_else2c 		   = 'malay_phrase';	
my  $in_else3c		   = 'thai_phrase'; 

my @sense = ($in_translation, $in_example, $in_idiom, $in_else1, 
$in_else2, $in_else3, $in_else1b, $in_else2b, $in_else3b, $in_else1c, $in_else2c, $in_else3c);

# ------------------------------------------------------------------------

##-- Gestion des options --##

my ($date, $FichierXML, $FichierResultat, $erreur, $encoding) = ();
my ($verbeux, $help) = ();
GetOptions( 
  'date|time|t=s'        	  => \$date, # flag de type -date ou --date, ou -time ou --time, ou -t ou --t (=s : string)
  'source|in|from|i=s'        => \$FichierXML, 
  'sortie|out|to|o=s'         => \$FichierResultat, 
  'erreur|error|e=s'     	  => \$erreur, 
  'encodage|encoding|enc|f=s' => \$encoding, 
  'help|h'                	  => \$help, 
  'verbeux|v'             	  => \$verbeux, 
  );

if (!( defined $date ))
	{
	$date = localtime;
	};
if (!( defined $FichierXML ))
	{
	&help ; # si le fichier source n'est pas spécifié, affichage de l'aide.
	};
if (!( defined $FichierResultat ))
	{
	$FichierResultat = "toto.xml" ;
	};
if (!( defined $erreur ))
	{
	$erreur = "|ERROR| : problem opening file :";
	};
if (!( defined $encoding ))
	{
	$encoding = "UTF-8"; 
	};
if ( defined $help )
	{
	&help;
	};

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

if ( defined $verbeux )
	{
	&info('a'); 
	};
# message dans le STDERR (voir subroutine 'info') indiquant le démarrage du programme.


# =======================================================================================================================================
###--- TWIG ---###

if ( defined $verbeux )
	{
	&info('b'); 
	};

# ------------------------------------------------------------------------

# Début du fichier en sortie :
$writer->startTag
	(
  "m:$ref_root",
  'name'          => $name,
  'creation-date' => $date,
	);

my $twig = XML::Twig->new
(
output_encoding => $encoding, # on reste en utf8
Twig_handlers   => {$ref_entry => \&entry,}, 
);
$twig->parsefile($FichierXML);
my $root = $twig->root; 

# ------------------------------------------------------------------------

if ( defined $verbeux )
	{
	&info('c'); 
	};
	
# ------------------------------------------------------------------------	
# Fin du fichier en sortie :
$writer->endTag("m:$ref_root");
$output->close();

# ------------------------------------------------------------------------

if ( defined $verbeux )
	{
	&info('d'); 
	};


# =======================================================================================================================================
###--- SUBROUTINES ---###

sub entry 
{
my $count = 0;
my ($twig, $twig_entry) = @_;
my @stop = $twig_entry->children($ref_sense);
my $first_child = $twig_entry->first_child($in_headword);
my $first_child_text = $twig_entry->first_child_text($in_headword);
my $first_pron = $first_child->next_sibling_text($in_pronunciation);
my $first_pos = $first_child->next_sibling_text($in_pos);

$writer->startTag( "m:entry", 'id' => $twig_entry->field($in_headword), );
	$writer->startTag("m:head");
		$writer->startTag("m:headword");
		$writer->characters($first_child_text);
		$writer->endTag("m:headword");

		$writer->startTag("m:pronunciation");
		$writer->characters($first_pron);
		$writer->endTag("m:pronunciation");

		$writer->startTag("m:pos");
		$writer->characters($first_pos);
		$writer->endTag("m:pos");
	$writer->endTag("m:head");	

my $child = $first_child;

foreach my $twig_sense (@stop)
	{
	$count++;
	my $stop = $child->next_sibling_text($ref_sense);
	my $stop2 = $child->next_sibling($ref_sense);
	
	$writer->startTag("m:sense", 'id' => $count);
	
	$writer->startTag("m:gloss");
	$writer->characters($stop);
	$writer->endTag("m:gloss");
	
	until ($stop2->next_elt_matches('french_gloss'))
		{
		$writer->startTag($stop2->next_elt->tag);
		$writer->characters($stop2->next_elt->text);
		$writer->endTag($stop2->next_elt->tag);
		};
	
	$writer->endTag("m:sense");
	$child = $twig_sense;
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
	print (STDERR "\t~~~~ $0 : START ~~~~\n");
	print (STDERR "================================================================================\n");
	}
elsif ($info=~ 'b')
	{
	print (STDERR "================================================================================\n");
	print (STDERR "Parsing\n");
	print (STDERR "--------------------------------------------------------------------------------\n");
	}
elsif ($info=~ 'c')
	{
	print (STDERR "Process done : $FichierXML parsed\n");
	print (STDERR "--------------------------------------------------------------------------------\n");
	print (STDERR "Applying changes and write into $FichierResultat \n");
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