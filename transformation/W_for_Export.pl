#!/usr/bin/perl

# =======================================================================================================================================
######----- W_for_Export.pl -----#####
# =======================================================================================================================================
# Auteur : M. MANGEOT
# Version 1.0 
# Dernières modifications : 27 nov 2012
# Synopsis :  - transformation de toutes les balises du fichier XML
# Remarques : - La structure est obligatoirement de type "Mot à Mot";
#             - Les variables doivent être changées au sein du programme (début).
# ---------------------------------------------------------------------------------------------------------------------------------------
# Usage : perl W_for_Export.pl -v -source source.xml -out out.xml -export export.xml
#
# -v : affiche les informations du STDERR
#
# Pour les options avancées :
# -source "out.xml"					 : pour spécifier un fichier de sortie (par défaut il s'agit du fichier source)
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
# éléments de la source :
# ------------------------------------------------
# Si les balises ne changent pas indiquez le même nom.
my $in_entry 		   = 'd:contribution'; 		
my $in_match 		   = 'g:variante';  		

# ------------------------------------------------------------------------
##-- Gestion des options --##
my ($date, $FichierXML, $FichierResultat, $FichierExport, $erreur, $encoding) = ();
my ($verbeux, $help, $pretty_print, $parse) = ();
GetOptions( 
  'date|time|t=s'        	  => \$date, # flag de type -date ou --date, ou -time ou --time, ou -t ou --t (=s : string)
  'source|in|from|i=s'        => \$FichierXML, 
  'sortie|out|to|o=s'         => \$FichierResultat, 
  'export|export|x=s'         => \$FichierExport, 
  'erreur|error|e=s'     	  => \$erreur, 
  'encodage|encoding|enc|f=s' => \$encoding, 
  'help|h'                	  => \$help, 
  'verbeux|v'             	  => \$verbeux, 
  'prettyprint|pretty|p=s'	  => \$pretty_print,
  );

if (!(defined $date))	{$date = localtime;};
if (!(defined $FichierXML)) {&help;};
	# si le fichier source n'est pas spécifié, affichage de l'aide.
if (!(defined $FichierResultat)) {$FichierResultat = $FichierXML.'.out';};
if (!(defined $FichierExport)) {$FichierExport = $FichierXML.'.export';};
if (!(defined $erreur)) {$erreur = "|ERROR| : problem opening file :";};
if (!(defined $encoding)) {$encoding = "UTF-8";};
if (!(defined $pretty_print)) {$pretty_print = 'indented';};
if (defined $help) {&help;};

# ------------------------------------------------------------------------
if ( defined $verbeux )	{&info('a');};
# message dans le STDERR (voir subroutine 'info') indiquant le démarrage du programme.

my $output = new IO::File(">$FichierResultat");
my $export = new IO::File(">$FichierExport");

# =======================================================================================================================================
###--- TWIG ---###

my $twig = XML::Twig->new
(
output_encoding => $encoding, # on reste en utf8
Twig_handlers   => {$in_entry => \&entry,}, 
);
$twig->parsefile($FichierXML);
my $root = $twig->root; 


sub entry 
{
my ($twig, $twig_entry) = @_;

if ($twig_entry->findvalue('//'.$in_match) ne '') {
	$twig->print($export);
}
else {
	$twig->print($output);
}

$twig->purge();
return;
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