#!/usr/bin/perl

# =======================================================================================================================================
######----- V_for_Changing_one_Tag.pl -----#####
# =======================================================================================================================================
# Auteur : V.GROS
# Version 1.0 
# Dernières modifications : 14 juin 2010
# Synopsis :  - Changement d'une balise
# Remarques : - Utilisation simple du handler de twig
#             - fonctionne pour n'importe quelle balise
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
##-- Gestion des options --##
my ($date, $FichierXML, $FichierResultat, $erreur, $encoding) = ();
my ($verbeux, $help, $pretty_print, $tag, $new_tag) = ();
GetOptions( 
  'date|time|t=s'        	  => \$date, # flag de type -date ou --date, ou -time ou --time, ou -t ou --t (=s : string)
  'source|in|from|i=s'        => \$FichierXML, 
  'sortie|out|to|o=s'         => \$FichierResultat, 
  'erreur|error|e=s'     	  => \$erreur, 
  'encodage|encoding|enc|f=s' => \$encoding, 
  'help|h'                	  => \$help, 
  'verbeux|v'             	  => \$verbeux, 
  'prettyprint|pretty|p=s'	  => \$pretty_print,
  'tag|old=s'	 			  => \$tag,
  'new|change=s'			  => \$new_tag,
  );

if (!(defined $date))	{$date = localtime;};
if (!(defined $FichierXML)) {&help;};
	# si le fichier source n'est pas spécifié, affichage de l'aide.
if (!(defined $FichierResultat)) {$FichierResultat = $FichierXML;};
if (!(defined $erreur)) {$erreur = "|ERROR| : problem opening file :";};
if (!(defined $encoding)) {$encoding = "UTF-8";};
if (!(defined $pretty_print)) {$pretty_print = 'indented';};
if (!(defined $tag)) {&help;};
if (!(defined $new_tag)) {&help;};
if (defined $help) {&help;};

# ------------------------------------------------------------------------
if ( defined $verbeux )	{&info('a');};
# message dans le STDERR (voir subroutine 'info') indiquant le démarrage du programme.


# =======================================================================================================================================
###--- TWIG ---###
my $twig = XML::Twig->new
	(
	pretty_print    => $pretty_print, 
	twig_handlers =>{$tag => sub {$_ ->set_tag ($new_tag)},},
	);
$twig->parsefile($FichierXML);

# ------------------------------------------------------------------------
if ( defined $verbeux ) {&info('b');};
	
# ------------------------------------------------------------------------
$twig->print_to_file($FichierResultat);

# ------------------------------------------------------------------------
if ( defined $verbeux ) {&info('c');};


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
elsif ($info=~ 'b')
	{
	print (STDERR "================================================================================\n");
	print (STDERR "Process done : $FichierXML parsed\n");
	print (STDERR "--------------------------------------------------------------------------------\n");
	}
elsif ($info =~ 'c')
	{
	print (STDERR "================================================================================\n");
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