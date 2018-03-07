#!/usr/bin/perl

# =======================================================================================================================================
######----- V_for_RenumerotationAxies.pl -----#####
# =======================================================================================================================================
# Auteur : M.MANGEOT
# Version 1.1 
# Dernières modifications : 15 juin 2010
# Synopsis :  - Renumérotation d'un fichier d'axies suite à une fusion d'un volume de langue. 
# Recalcule les identifiants des sens et les liens correspondants dans le fichier d'axies.
# Remarques : ATTENTION : le fichier source d'origine doit commencer par <m:entry. Il faut effacer l'en-tête XML et l'élément racine !
#             - La fusion ne modifie pas les deux fichiers sources
#             - Création d'un journal des exécutions (LOG)
# ---------------------------------------------------------------------------------------------------------------------------------------
# Usage : perl V_for_RenumerotationAxies.pl -v -from source1.xml -axi source2.xml -to out.xml 
#
# -v : affiche les informations du STDERR
#
# Pour les options avancées :
#
# -date "date" 				 	 : pour spécifier la date (par défaut : la date du jour (localtime)
# -erreur "message d'erreur" 	 : pour spécifier le message d'erreur (ouverture de fichiers)
# -encoding "format d'encodage" : pour spécifier le format d'encodage (par défaut UTF-8)
# -pretty "indentation" 		 : pour spécifier l'indentation XML ('none' ou 'indented', par exemple)
# -locale "locale"				 : pour spécifier la locale (langue source) des ressources qui seront fusionnées
# -help 						 : pour afficher l'aide
# =======================================================================================================================================



# =======================================================================================================================================
###--- METADIRECTIVES ---###
use strict;
use warnings;
use utf8;
use locale;
use IO::File; 
use Getopt::Long; # pour gérer les arguments.

#use Text::StripAccents; # non inclus dans le core de Perl
use XML::Twig; # (non inclus dans le core de Perl), pour le parsing de la source.
use XML::Writer; # (non inclus dans le core de Perl), pour le fichier de sortie.

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

use POSIX qw(locale_h setlocale);

# =======================================================================================================================================
###--- PROLOGUE ---###
my $ref_root = 'm:volume'; # la racine (par exemple : <volume> ou <dictionary>).
my $ref_entry = 'm:entry'; # l'élément de référence pour la fusion (pour MAM : 'entry' par exemple).
my $ref_headword = 'm:headword'; # le sous-élément à comparer pour la fusion
my $ref_sense = 'm:sense'; # le sous-élément qui sera récupéré puis inséré.
 
# ------------------------------------------------------------------------
##-- Gestion des options --##
my ($date, $FichierOne, $FichierTwo, $FichierResultat, $erreur, $encoding) = ();
my ($verbeux, $help, $pretty_print, $locale) = ();
GetOptions( 
  'date|time|t=s'        	    => \$date, # flag de type -date ou --date, ou -time ou --time, ou -t ou --t (=s : string)
  'source|base|in|one|from|i=s' => \$FichierOne, 
  'axi|a=s'        		=> \$FichierTwo,
  'sortie|out|to|o=s'           => \$FichierResultat, 
  'erreur|error|e=s'     	  	=> \$erreur, 
  'encodage|encoding|enc|f=s' 	=> \$encoding, 
  'help|h'                	  	=> \$help, 
  'verbeux|v'             	  	=> \$verbeux, 
  'print|pretty|p=s'       	  	=> \$pretty_print, 
  'locale|locale|l=s'				=> \$locale,
  );
 
if (!(defined $date)) {$date = localtime;};
if (!(defined $FichierOne)) {&help;}; # si le fichier source n'est pas spécifié, affichage de l'aide.
if (!(defined $FichierTwo)) {&help;};
if (!(defined $FichierResultat)) {$FichierResultat = "toto.xml";};
if (!(defined $erreur)) {$erreur = "|ERROR| : problem opening file :";};
if (!(defined $encoding)) {$encoding = "UTF-8";};
if (!(defined $pretty_print)) {$pretty_print = "indented";};
if (!(defined $locale)) {$locale = "km_KH.UTF-8";};
if (defined $help) {&help;};
 
 setlocale( LC_ALL, $locale);

 
# ------------------------------------------------------------------------
# Autres variables :
my $count_one = 0; # pour compter les entrées issues de source1.
setlocale(LC_ALL,$locale); # pour indiquer la locale
 
# ------------------------------------------------------------------------
# Input/ Output
open (FILEONE, "<:encoding($encoding)", $FichierOne) or die ("$erreur $!\n");
open (FILETWO, "<:encoding($encoding)", $FichierTwo) or die ("$erreur $!\n");
#open (STDERR, ">:encoding($encoding)", 'toto.txt') or die ("$erreur $!\n");
 
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
	'name'              => "Motamot_axi",
	'source-language'   => 'axi',
	'creation-date'     => $date,
	'xmlns:d'  	        => 'http://www-clips.imag.fr/geta/services/dml',
	'xmlns'			    => 'http://www-clips.imag.fr/geta/services/dml/motamot',
	'xmlns:m'			=> 'http://www-clips.imag.fr/geta/services/dml/motamot',
	'xmlns:xsi'		    => 'http://www.w3.org/2001/XMLSchema-instance',
	'xsi:schemaLocation'=> 'http://www-clips.imag.fr/geta/services/dml/motamot ' . 
			'http://www-clips.imag.fr/geta/services/dml/motamot_fra.xsd',
	);
 
# =======================================================================================================================================
###--- PREPARATION ---###
my ($twig_one, $twig_axi);
my ($entry_one, $entry_axi);

$twig_one = XML::Twig->new
  (
   output_encoding => $encoding, 
   pretty_print    => $pretty_print, 
   twig_roots      => {'m:entry' => 1}, 
   twig_print_outside_roots => 1,
   no_prolog => 1,
   Twig_handlers   => {'m:entry' => \&entry_one},
  );

$twig_axi = XML::Twig->new
  (
   output_encoding => $encoding, 
   pretty_print    => $pretty_print, 
   twig_roots      => {'m:axie' => 1}, 
   twig_print_outside_roots => 1,
   no_prolog => 1,
  Twig_handlers   => {'m:axie' => \&entry_axi},
  );
 
sub entry_one {
  $entry_one = $_[1];
  return 1;
}
sub entry_axi {
  $entry_axi = $_[1];
  return 1;
}
  
# ------------------------------------------------------------------------
if ( defined $verbeux ) {&info('b');};

# ------------------------------------------------------------------------
# Charge le fichier d'axies en mémoire dans une table de hash
my %AXIES = ();
my $axies = 0;
my $id_axi;

$entry_axi = next_axi($twig_axi, *FILETWO, \$entry_axi); # obtenir la première entrée de la source 1.
$id_axi = $entry_axi ? $entry_axi->id : undef;

while ($entry_axi) {
#while (0) {
	$AXIES{$id_axi} = $entry_axi;
	$axies++;
	$entry_axi = next_axi($twig_axi, *FILETWO, \$entry_axi); # obtenir la première entrée de la source 1.
	$id_axi = $entry_axi ? $entry_axi->id : undef;
	if ($axies % 100 == 0) {
		print $axies, " parsed\n";
	}
}
 
# ------------------------------------------------------------------------
my ($headword_one, $headword_two);

$entry_one = next_entry($twig_one, *FILEONE, \$entry_one); # obtenir la première entrée de la source 1.
$headword_one = $entry_one ? [$entry_one->findnodes ("//m:headword")]->[0]->text : undef;

# ------------------------------------------------------------------------
if ( defined $verbeux ) {&info('c');};
 
 
# =======================================================================================================================================
###--- ALGORITHME DE LA FUSION ---###
 
# Après avoir récupéré la ou les entrées (sub next_entry), on les compare.
# On écrit dans le fichier de sortie selon la comparaison.
#my ($headword_one, $headword_two, $id_one, $id_two);
# Le traitement continuera tant qu'il y a des entrées dans l'une ou l'autre source.
while ($entry_one)
  { 
	my $id_entry = $entry_one ? $entry_one->id : undef;
	my $sense = [$entry_one->findnodes("m:sense")]->[0];
	my $sibling = $sense->next_sibling();
	while ($sibling) {
		my $id_sense = $sibling->id;
		print STDERR "sibling! $id_entry, $id_sense\n";
		# 1 récupérer l'id de l'axie : m:translation idrefaxie="axi.[fra:rayon,khm:kam].10364.2.e" 
		my $translation = [$sibling->findnodes("m:translations/m:translation")]->[0];
		my $id_refaxie = $translation->{'att'}->{'idrefaxie'};
		print 'refaxie_id: ',$id_refaxie, "\n";
		# 2 récupérer l'axie 
		my $axie = $AXIES{$id_refaxie};
		# 3 récupérer le lien vers la lexie
		#my $reflexie = [$axie->findnodes('//m:reflexie')]->[0]; l'utilisation de // ne marche pas ici !
		my $reflexie = [$axie->findnodes('m:reflexies/m:reflexie[@lang="khm"]')]->[0];
		# 4 renuméroter le lien de l'axie avec l'id de l'entry + reflexie s courant
		$reflexie->set_att('idrefentry',$id_entry);
		$reflexie->set_att('idreflexie',$id_sense);		
		$sibling = $sibling->next_sibling();
	} 

	$entry_one = next_entry($twig_one, *FILEONE, \$entry_one); # obtenir la première entrée de la source 1.
	$headword_one = $entry_one ? [$entry_one->findnodes ("//m:headword")]->[0]->text : undef;
}
# ------------------------------------------------------------------------
# Fin de l'écriture :

foreach my $key (sort keys %AXIES) {
	my $axi = $AXIES{$key};
    $writer->startTag($axi->root->name, 'id' => $axi->root->id, 'level' => '');
    $axi->print($output, "indented");
    $writer->endTag($axi->root->name);
}

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
	$xml =~ s/^\s+//m;
	$xml =~ s/\s+$//m;
    $twig->safe_parse($xml);
	}
$twig->purge; 
return $$entry;
}

sub next_axi
{
my ($twig, $file, $entry) = @_;
 
$$entry = undef;
$/ = "</m:axie>";
while (!$$entry && !eof $file) 
	{
	my $xml = <$file>;
	$xml =~ s/^\s+//m;
	$xml =~ s/\s+$//m;
    $twig->safe_parse($xml);
	}
#$twig->purge; 
return $$entry;
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
