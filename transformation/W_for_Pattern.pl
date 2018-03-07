#!/usr/bin/perl

# =======================================================================================================================================
######----- NOM.pl -----#####
# =======================================================================================================================================
# Auteur : V.GROS
# Version 1.0 
# Dernières modifications : jj mois 2010
# Synopsis :  
#             
# Remarques : - 
#             - 
# ---------------------------------------------------------------------------------------------------------------------------------------
# Usage : perl NOM.pl -v -from source.xml -to MAM.xml 
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

# ----------------------------------------------------------
# MODIFIEZ/SUPPRIMEZ CES VARIABLES SELON LE TRAITEMENT VOULU
# ----------------------------------------------------------

my $ref_root = 'volume'; # la racine (par exemple : <volume> ou <dictionary>).
my $ref_entry = 'entry' ; # l'élément dans la source qui correspond à <m:entry> dans MAM.
my $ref_sense = 'sense' ; # idem pour l'élément <m:sense> dans MAM.

my  $in_root 		   = 'volume'; 
my  $in_entry 		   = 'entry'; 		
my	$in_headword 	   = '';  	
my	$in_sense 		   = 'sense'; 	   
my	$in_translation    = '';   
my	$in_examples 	   = '';   
my	$in_example 	   = ''; 	   
my	$in_else1 		   = ''; 
my  $in_else2 		   = ''; 

# ------------------------------------------------------------------------
##-- Gestion des options --##

my ($date, $FichierXML, $FichierResultat, $erreur, $encoding) = ();
my ($verbeux, $help) = ();
my $count_entry = ;

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
###--- ALGORITHME PRINCIPAL ---###

if ( defined $verbeux ) {&info('b');};

# ------------------------------------------------------------------------


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