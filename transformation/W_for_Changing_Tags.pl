#!/usr/bin/perl

# =======================================================================================================================================
######----- V_for_Changing_Tags.pl -----#####
# =======================================================================================================================================
# Auteur : V.GROS
# Version 1.0 
# Dernières modifications : 7 juin 2010
# Synopsis :  - transformation de toutes les balises du fichier XML
# Remarques : - La structure est obligatoirement de type "Mot à Mot";
#             - Les variables doivent être changées au sein du programme (début).
# ---------------------------------------------------------------------------------------------------------------------------------------
# Usage : perl V_for_Changing_one_Tag.pl -v -from source.xml -old tag -new newtag
#
# -v : affiche les informations du STDERR
#
# Pour les options avancées :
# -to "out.xml"					 : pour spécifier un fichier de sortie (par défaut il s'agit du fichier source)
# -date "date" 					 : pour spécifier la date (par défaut : la date du jour (localtime)
# -erreur "message d'erreur" 	 : pour spécifier le message d'erreur (ouverture de fichiers)
# -encodding "format d'encodage" : pour spécifier le format d'encodage (par défaut UTF-8)
# -pretty "pretty_print" 		 : pour spécifier l'indentation du twig
# -parse 'numeric'				 : le parsing se fait sur plusieurs niveaux :
#									- 0 : la racine
#									- 1 : l'entrée 
#									- 2 : le 'head' et les 'sense'
#									- 3 : les fils du 'head' et du 'sense'
#									- 4 : les petits-fils du 'sense'
# -help 				 		 : pour afficher l'aide
# =======================================================================================================================================



# =======================================================================================================================================
###--- METADIRECTIVES ---###
use strict;
use warnings;
use utf8;
use IO::File;
use Getopt::Long; # pour gérer les arguments.

use XML::Twig; # (non inclus dans le core de Perl), pour le parsing de la source.


# =======================================================================================================================================
###--- PROLOGUE ---###
# ------------------------------------------------------------------------
##-- Les balises de la source/de la sortie (MAM) --##

# ------------------------------------------------
# MODIFIEZ CES VARIABLES SELON LE TRAITEMENT VOULU
# ------------------------------------------------
my $ref_root = 'volume';
my $ref_entry = 'entry';

# ------------------------------------------------
# éléments de la source :
# ------------------------------------------------
# Si les balises ne changent pas indiquez le même nom.
my  $in_root 		   = 'm:volume'; 
my  $in_entry 		   = 'm:entry'; 		
my	$in_head 		   = 'm:head';  		
my	$in_headword 	   = 'm:headword';  	
my	$in_pronunciation  = 'm:pronunciation'; 
my	$in_pos 		   = 'm:pos'; 		    
my	$in_sense 		   = 'm:sense'; 	   
my	$in_definition     = 'm:definition';    
my	$in_label 		   = 'm:label'; 	   
my	$in_formula 	   = 'm:formula'; 	     
my	$in_gloss 		   = 'm:gloss';  	    
my	$in_translations   = 'm:translations';  
my	$in_translation    = 'm:translation';   
my	$in_examples 	   = 'm:examples';   
my	$in_example 	   = 'm:example'; 	   
my	$in_idioms 	       = 'm:idioms'; 
my	$in_idiom	 	   = 'm:idiom';  	  	  
my	$in_else1 		   = 'm:more-info'; 
my  $in_else2 		   = 'm:else2';	 

# ------------------------------------------------
# nouveaux éléments correspondants :
# ------------------------------------------------
# Si les balises ne changent pas indiquez le même nom.
my  $out_root 		   = 'volume';
my  $out_entry 		   = 'entry'; 		
my	$out_head 		   = 'head';  		
my	$out_headword 	   = 'headword';  	
my	$out_pronunciation = 'pronunciation'; 
my	$out_pos 		   = 'pos'; 		    
my	$out_sense 		   = 'sense'; 	   
my	$out_definition    = 'definition';    
my	$out_label 		   = 'label'; 	   
my	$out_formula 	   = 'formula'; 	     
my	$out_gloss 		   = 'gloss';  	    
my	$out_translations  = 'translations';  
my	$out_translation   = 'translation';   
my	$out_examples 	   = 'examples';   
my	$out_example 	   = 'example'; 	   
my	$out_idioms 	   = 'idioms'; 
my	$out_idiom	 	   = 'idiom';  	  	  
my	$out_else1 		   = 'more_info'; 
my  $out_else2 		   = 'else2';	 

# ------------------------------------------------------------------------
##-- Gestion des options --##
my ($date, $FichierXML, $FichierResultat, $erreur, $encoding) = ();
my ($verbeux, $help, $pretty_print, $parse) = ();
GetOptions( 
  'date|time|t=s'        	  => \$date, # flag de type -date ou --date, ou -time ou --time, ou -t ou --t (=s : string)
  'source|in|from|i=s'        => \$FichierXML, 
  'sortie|out|to|o=s'         => \$FichierResultat, 
  'erreur|error|e=s'     	  => \$erreur, 
  'encodage|encoding|enc|f=s' => \$encoding, 
  'help|h'                	  => \$help, 
  'verbeux|v'             	  => \$verbeux, 
  'prettyprint|pretty|p=s'	  => \$pretty_print,
  'parse|p|twig=i'			  => \$parse,
  );

if (!(defined $date))	{$date = localtime;};
if (!(defined $FichierXML)) {&help;};
	# si le fichier source n'est pas spécifié, affichage de l'aide.
if (!(defined $FichierResultat)) {$FichierResultat = $FichierXML;};
if (!(defined $erreur)) {$erreur = "|ERROR| : problem opening file :";};
if (!(defined $encoding)) {$encoding = "UTF-8";};
if (!(defined $pretty_print)) {$pretty_print = 'indented';};
if (!(defined $parse)) {&help;};
if (defined $help) {&help;};

# ------------------------------------------------------------------------
if ( defined $verbeux )	{&info('a');};
# message dans le STDERR (voir subroutine 'info') indiquant le démarrage du programme.


# =======================================================================================================================================
###--- TWIG ---###

if ($parse == 0)
{
my $twig_root = XML::Twig->new
	(
	pretty_print    => $pretty_print, # par défaut le style est 'none'
	twig_handlers =>{$in_root => sub {$_ ->set_tag ($out_root)},},
	);
$twig_root->parsefile($FichierXML);
$twig_root->print_to_file($FichierResultat);
$twig_root->purge;
}

# ------------------------------------------------------------------------
if ($parse == 1)
{	
my $twig_one = XML::Twig->new
	(
	pretty_print    => $pretty_print, # par défaut le style est 'none'
	twig_handlers =>{$in_entry => sub {$_ ->set_tag ($out_entry)},},
	);
$twig_one->parsefile($FichierXML);
$twig_one->print_to_file($FichierResultat);
$twig_one->purge;
}

# ------------------------------------------------------------------------
if ($parse == 2)
{	
my $twig_two = XML::Twig->new
	(
	pretty_print    => $pretty_print, # par défaut le style est 'none'
	twig_handlers =>
		{
		$in_head => sub {$_ ->set_tag ($out_head)},
		$in_sense => sub {$_ ->set_tag ($out_sense)},
		},
	);
$twig_two->parsefile($FichierXML);
$twig_two->print_to_file($FichierResultat);
$twig_two->purge;
}

# ------------------------------------------------------------------------
if ($parse == 3)
{	
my $twig_three = XML::Twig->new
	(
	pretty_print    => $pretty_print, # par défaut le style est 'none'
	twig_handlers =>
		{
		$in_headword 	  => sub {$_ ->set_tag ($out_headword)},
		$in_pos 		  => sub {$_ ->set_tag ($out_pos)},
		$in_pronunciation => sub {$_ ->set_tag ($out_pronunciation)},
		$in_definition 	  => sub {$_ ->set_tag ($out_definition)},
		$in_translations  => sub {$_ ->set_tag ($out_translations)},
		$in_examples 	  => sub {$_ ->set_tag ($out_examples)},
		$in_idioms 		  => sub {$_ ->set_tag ($out_idioms)},
		$in_else1 		  => sub {$_ ->set_tag ($out_else1)},
		$in_else2 		  => sub {$_ ->set_tag ($out_else2)},
		},
	);
$twig_three->parsefile($FichierXML);
$twig_three->print_to_file($FichierResultat);
$twig_three->purge;
}

# ------------------------------------------------------------------------
if ($parse == 4)
{
my $twig_four = XML::Twig->new
	(
	pretty_print    => $pretty_print, # par défaut le style est 'none'
	twig_handlers =>
		{
		$in_label 	    => sub {$_ ->set_tag ($out_label)},
		$in_formula 	=> sub {$_ ->set_tag ($out_formula)},
		$in_gloss 		=> sub {$_ ->set_tag ($out_gloss)},
		$in_translation => sub {$_ ->set_tag ($out_translation)},
		$in_example 	=> sub {$_ ->set_tag ($out_example)},
		$in_idiom 		=> sub {$_ ->set_tag ($out_idiom)},
		},
	);
$twig_four->parsefile($FichierXML);
$twig_four->print_to_file($FichierResultat);
}

# ------------------------------------------------------------------------
if ( defined $verbeux ) {&info('d');};


# =======================================================================================================================================
###--- SUBROUTINES ---###
sub info
{
my $info = shift @_;
if ($info =~ 'a')
	{
	print (STDERR "================================================================================\n");
	print (STDERR "\t~~~~ $0 : START ~~~~\n");
	print (STDERR "================================================================================\n");
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