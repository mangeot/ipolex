#!/usr/bin/perl

# =======================================================================================================================================
######----- V_Morphalou.pl -----#####
# =======================================================================================================================================
# Auteur : V.GROS
# Version 1.1 
# Dernières modifications : 14 juin 2010
# Synopsis :  - transformation d'une structure XML type Morphalou
#               vers une structure XML type "Mot à Mot".
# Remarques : - Il s'agit de la version complète de Morphalou 2.0
#             - Création d'un journal des exécutions (LOG)
# ---------------------------------------------------------------------------------------------------------------------------------------
# Usage : perl V_Morphalou.pl -v -from source.xml -to MAM.xml 
#
# -v : affiche les informations du STDERR
#
# Pour les options avancées :
#
# -date "date" 				 	 : pour spécifier la date (par défaut : la date du jour (localtime)
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
use XML::Writer; # (non inclus dans le core de Perl), pour l'écriture dans le fichier de sortie.


# =======================================================================================================================================
###--- PROLOGUE ---###
# ------------------------------------------------------------------------
##-- Les balises de la source/de la sortie (MAM) --##

# ------------------------------------------------
# MODIFIEZ CES VARIABLES SELON LE TRAITEMENT VOULU
# ------------------------------------------------
# S'il n'y a pas de correspondance, laisser 'notag' comme valeur.

my $ref_root = 'volume'; # la racine (par exemple : <volume> ou <dictionary>).
my $ref_entry = 'lexicalEntry'; # l'élément dans la source qui correspond avec <m:entry> dans MAM.
my $ref_headword = 'orthography'; # l'élément dans la source qui correspond avec <m:headword> dans MAM.
my $ref_pos = 'grammaticalCategory'; # l'élément dans la source qui correspond avec <m:pos> dans MAM.
my $ref_genre = 'grammaticalGender'; # informations complémentaires
my $ref_nombre = 'grammaticalNumber'; # informations complémentaires

my $ref_parent = 'lemmatizedForm'; # élément qui contient les informations

# ------------------------------------------------------------------------
##-- Gestion des options --##
my ($date, $FichierXML, $FichierResultat, $erreur, $encoding) = ();
my ($verbeux, $help) = ();
my $count_entry = 7779000000; # 7779 = MO (pour Morphalou).
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
if ( defined $verbeux )	{&info('a');};
# message dans le STDERR (voir subroutine 'info') indiquant le démarrage du programme.
	
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


# =======================================================================================================================================
###--- TRAITEMENT ---###
if ( defined $verbeux ) {&info('b');};
	
# ------------------------------------------------------------------------
# Writer et Twig
$writer->startTag
	(
	"m:$ref_root",
	'name'           => "Morphalou2",
	'source-langage' => "fra",
	'creation-date'  => $date,
	);

my $twig = XML::Twig->new
	(
	output_encoding => $encoding, # on reste en utf8
	Twig_handlers   => {$ref_entry => \&entry,}, 
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

 my %eq_cat = ( # table de hachage permettant l'équivalence entre les catégories syntaxiques de Morphalou et de Mot à Mot.
 "" => "",
 "commonNoun" => "n.",
 "adjective" => "a.",
 "adverb" => "adv.",
 "verb" => "v.",
 "interjection" => "intj.",
 "functionWord" => "",
 "onomatopoeia" => "(ono.)" 
 );
  my %eq_gn = ( # table de hachage concernant d'autres précisions des catégories, notamment le genre et le nombre.
 "" => "",
 "masculine" => "m.",
 "feminine" => "f.",
 "singular" => "",
 "plural" => "pl.",
 "functionWord" => "undef",
 "onomatopoeia" => "(ono.)" 
 );
 
 foreach my $set ($twig_entry->findnodes('formSet'))
	{
	foreach my $head ($set->findnodes($ref_parent))
	{
	$writer->startTag(
	"m:entry", 
	'id' => 'fra.' . $head->field($ref_headword) . '.' . $count_entry, 
	'level' => "*"
	);
	my $pos = $head->field($ref_pos);
	my $g = $head->field($ref_genre);
	my $n = $head->field($ref_nombre);
	$writer->startTag("m:head");
		$writer->startTag("m:headword");
		$writer->characters($head->field($ref_headword));
		$writer->endTag("m:headword");

		$writer->startTag("m:pronunciation");
		$writer->endTag("m:pronunciation");

		$writer->startTag("m:pos");
		$writer->characters(($eq_cat{$pos}).($eq_gn{$g}).($eq_gn{$n}));
		$writer->endTag("m:pos");
	$writer->endTag("m:head");	
	
	&sense;
	$writer->endTag("m:entry");
	}
	}
$twig->purge;
return;
}

sub sense 
{
$writer->startTag(
	"m:sense", 
	'id'=>"", 
	'level'=>"");
	$writer->startTag("m:definition");
	$writer->endTag("m:definition");
	
	$writer->startTag("m:gloss");
	$writer->endTag("m:gloss");
	
	$writer->startTag("m:translations");
		$writer->emptyTag(
			"m:translation", 
			'idrefaxie'=>"", 
			'idreflexie'=>"", 
			'lang'=>""
			);
	$writer->endTag("m:translations");
	
	$writer->startTag("m:examples");
	$writer->endTag("m:examples");
	
	$writer->startTag("m:idioms");
	$writer->endTag("m:idioms");
$writer->endTag("m:sense");
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
print (STDERR "          -d spécifie la date (par défaut : date du jour)\n");
print (STDERR "================================================================================\n");
}

# =======================================================================================================================================
1 ;