#!/usr/bin/env perl

# =======================================================================================================================================
######----- listeElement.pl -----#####
# =======================================================================================================================================
# Auteur : M. MANGEOT
# Version 1.0 
# Dernières modifications : 24 juin 2012
# Synopsis :  - liste le contenu d'un élément par ordre alphabétique
# ---------------------------------------------------------------------------------------------------------------------------------------
# Usage : perl ParseDico.pl -v -from source.xml
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

#<dilaf>
#<article>
#	<kalma>aboki</kalma>
#	<furici>[àbóokíi]</furici>
#	<nau_i>s.</nau_i>
#	<rukunin_ma_ana>
#		<ma_ana>mutum wanda ake rayuwa da shi cikin yarda da gane wa juna.</ma_ana>
#		<misali>Cikin wahala ko cikin daɗi aboki yana da amfani</misali>
#		<jinsi>n.</jinsi>
#		<mace>abokiya, abukkiya.</mace>
#		<jam_i>abokai, abukkai.</jam_i>
#		<makwatanci lang="far">ami, compagnon, camarade</makwatanci>
#	</rukunin_ma_ana>
#</article>

# ------------------------------------------------------------------------

##-- Gestion des options --##

my ($date, $FichierXML, $FichierResultat, $in_entry, $erreur, $encoding) = ();
my ($verbeux, $help) = ();
GetOptions( 
  'date|time|d=s'        	  => \$date, # flag de type -date ou --date, ou -time ou --time, ou -t ou --t (=s : string)
  'source|in|from|i=s'        => \$FichierXML, 
  'sortie|out|to|o=s'         => \$FichierResultat, 
  'element_entry|entry|a=s' => \$in_entry, 
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
	$FichierResultat = "out" ;
	};
if (!( defined $in_entry ))
	{
	$erreur = "|ERROR| : balise de l'entrée non définie";
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

binmode STDERR, ":utf8";
binmode STDOUT, ":utf8";
my $output = new IO::File(">$FichierResultat");

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

my $entry_count = 0;

my $twig = XML::Twig->new
(
output_encoding => $encoding, # on reste en utf8
twig_print_outside_roots => 0,
no_prolog => 1,
pretty_print => 'indented',
Twig_handlers   => {
	$in_entry => \&entry,}, 
);

$twig->parsefile($FichierXML);

# ------------------------------------------------------------------------

if ( defined $verbeux )
	{
	&info('c'); 
	};
	
# ------------------------------------------------------------------------	

# ------------------------------------------------------------------------

if ( defined $verbeux )
	{
	&info('d'); 
	};


# =======================================================================================================================================
###--- SUBROUTINES ---###

sub entry 
{

my ($twig, $article) = @_;
	my @jam_i = ();
	my @mace = ();
	my @nau_i = ();
	my @sens = $article->children('rukunin_ma_ana');
	foreach my $sens (@sens) {
		if ($sens->has_child('jam_i')) {
			my $dnode = $sens->first_child('jam_i');
			my $texte = $dnode->text();
			push @jam_i,$texte;
			$dnode->delete;
		}	
		if ($sens->has_child('mace')) {
			my $dnode = $sens->first_child('mace');
			my $texte = $dnode->text();
			push @mace,$texte;
			$dnode->delete;
		}	
		if ($sens->has_child('nau_i')) {
			my $dnode = $sens->first_child('nau_i');
			my $texte = $dnode->text();
			push @nau_i,$texte;
			$dnode->delete;
		}	
	}
	my $the_jam_i = '';
	foreach my $temp_jam_i  (@jam_i) {
		if ($the_jam_i ne '' && $the_jam_i ne $temp_jam_i) {
				print STDERR 'ERREUR: il y a plusieurs jam_i différents dans ', $article->first_child_text('kalma');
		}
		$the_jam_i = $temp_jam_i;
	}
	my $the_mace = '';
	foreach my $temp_mace (@mace) {
		if ($the_mace ne '' && $the_mace ne $temp_mace) {
				print STDERR 'ERREUR: il y a plusieurs mace différents dans ', $article->first_child_text('kalma');
		}
		$the_mace = $temp_mace;
	}
	my $the_nau_i = '';
	foreach my $temp_nau_i (@nau_i) {
		if ($the_nau_i ne '' && $the_nau_i ne $temp_nau_i) {
				print STDERR 'ERREUR: il y a plusieurs nau_i différents dans ', $article-first_child_text('kalma');
		}
		$the_nau_i = $temp_nau_i;
	}
	
	my $premier_sens = $article->first_child('rukunin_ma_ana');
	
	if ($the_nau_i && $premier_sens) {
		print STDERR 'ERREUR: je remonte nau_i  dans ', $article->first_child_text('kalma');
		my $new_elt= XML::Twig::Elt->new( nau_i => $the_nau_i);
		$new_elt->paste( before => $premier_sens);
		$the_nau_i->paste(before => $premier_sens);
	}
	if ($the_mace && $premier_sens) {
		print STDERR 'ERREUR: je remonte mace  dans ', $article->first_child_text('kalma');
		my $new_elt= XML::Twig::Elt->new( mace => $the_mace);
		$new_elt->paste(before => $premier_sens);
	}
	if ($the_jam_i && $premier_sens) {
		print STDERR 'ERREUR: je remonte jam_i  dans ', $article->first_child_text('kalma');
		my $new_elt= XML::Twig::Elt->new( jam_i => $the_jam_i);
		$new_elt->paste(before => $premier_sens);
	}
	$twig->print($output, "indented");
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
print (STDERR "          -l élément dont le contenu est à lister\n") ;
print (STDERR "          -e le message d'erreur (ouverture de fichiers)\n") ;
print (STDERR "          -f le format d'encodage\n");
print (STDERR "          -v mode verbeux (STDERR et LOG)\n");
print (STDERR "================================================================================\n");
}

# =======================================================================================================================================
1 ;