#!/usr/bin/perl


# ./ajout-identifiants.pl -v -m Donnees/Baat_fra-wol/DicoArrivee_wol_fra-metadata.xml -from Donnees/fusion.xml > out.xml
# ./ajout-identifiants.pl -v -m Donnees/Baat_fra-wol/DicoArrivee_wol_fra-metadata.xml -from Donnees/outcheriftpreptrie.xml > out.xml
#
# =======================================================================================================================================
######----- ajout-identifiants.pl -----#####
# =======================================================================================================================================
# Auteur : M.MANGEOT
# Version 1.1 
# Dernières modifications : 28 avril 2018
# Synopsis :  - ajout d'identifiants pour les articles
# ---------------------------------------------------------------------------------------------------------------------------------------
# Usage : perl ajout-identifiants.pl -v -metadata fichier-metadata.xml -from source1.xml -to out.xml 
#
# -v : affiche les informations du STDERR
#
# Pour les options avancées :
#
# -date "date" 				 	 : pour spécifier la date (par défaut : la date du jour (localtime)
# -encoding "format d'encodage" : pour spécifier le format d'encodage (par défaut UTF-8)
# -pretty "indentation" 		 : pour spécifier l'indentation XML ('none' ou 'indented', par exemple)
# -locale "locale"				 : pour spécifier la locale (langue source) des ressources qui seront fusionnées
# -help 						 : pour afficher l'aide
# =======================================================================================================================================



# =======================================================================================================================================
###--- METADIRECTIVES ---###
use strict;
use warnings;
use utf8::all;
use locale;
use Getopt::Long; # pour gérer les arguments.
use XML::DOM;
use XML::DOM::XPath;

use Data::Dumper;

use POSIX qw(locale_h setlocale);
use Unicode::Collate;

my $unicode = "UTF-8";

##-- Gestion des options --##
my ($date, $FichierEntree, $FichierMeta, $FichierResultat, $encoding) = ();
my ($verbeux, $help, $pretty_print) = ();
my $OUTFILE;

GetOptions( 
  'date|time|t=s'             => \$date, # flag de type -date ou --date, ou -time ou --time, ou -t ou --t (=s : string)
  'source|base|in|one|from|i=s' => \$FichierEntree, 
  'metadonnees|metadata|m=s'           => \$FichierMeta,
  'sortie|out|to|o=s'           => \$FichierResultat, 
  'encodage|encoding|enc|f=s'   => \$encoding, 
  'help|h'                      => \$help, 
  'verbeux|v'                   => \$verbeux, 
  'print|pretty|p=s'            => \$pretty_print, 
  );
 

if (!(defined $date)) {$date = localtime;};
if (!$FichierEntree) {&help;}; # si le fichier source n'est pas spécifié, affichage de l'aide.
if (!$FichierMeta) {&help;}; # si le fichier metaArrivee n'est pas spécifié, affichage de l'aide.;
if (defined $help) {&help;};

if ($FichierResultat) {
	open $OUTFILE, ">:encoding($unicode)",$FichierResultat or die ("$! $FichierResultat \n");
} # si le fichier sortie n'est pas spécifié, on ouvre la sortie standard
else {
	$FichierResultat = 'STDOUT';
	$OUTFILE = *STDOUT;
}

if (!(defined $encoding)) {$encoding = "UTF-8";};
if (!(defined $pretty_print)) {$pretty_print = "indented";};
if (defined $help) {&help;};
 
my $collator = Unicode::Collate::->new();

# on initialise le parseur XML DOM
my $parser= XML::DOM::Parser->new();
if ( $verbeux ) {print STDERR "load cdm FichierMeta:\n";}
my $metastring = read_file($FichierMeta);
my %CDMSARRIVEE = load_cdm_from_string($metastring);

# =======================================================================================================================================
###--- PROLOGUE ---###
my $cdmvolume = $CDMSARRIVEE{'cdm-volume'}; # le volume
my $cdmentry = $CDMSARRIVEE{'cdm-entry'}; # l'article
my $cdmentryid = $CDMSARRIVEE{'cdm-entry-id'}; # l'id de l'article
my $cdmheadword = $CDMSARRIVEE{'cdm-headword'}; # le mot-vedette

my $srclang = load_source_language($metastring);

# ------------------------------------------------------------------------

# On reconstruit les balises ouvrantes et fermantes du volume 
my $headervolume = xpath2opentags($cdmvolume);
my $footervolume = xpath2closedtags($cdmvolume);
my $closedtagentry = xpath2closedtag($cdmentry);
my $opentagvolume = xpath2opentags($cdmvolume, 'creation-date="' . $date . '"');
my $closedtagvolume = xpath2closedtags($cdmvolume);


# ------------------------------------------------------------------------
# Input/ Output
open (INFILE, "<:encoding($encoding)",$FichierEntree) or die ("$! $FichierEntree\n");
# On va lire le fichier d'entrée article par article 
# donc on coupe après une balise de fin d'article.
$/ = $closedtagentry;

# ------------------------------------------------------------------------
if ( defined $verbeux ) {&info('a');};
# message dans le STDERR (voir subroutine 'info') indiquant le démarrage du programme.
 
# ------------------------------------------------------------------------
##-- Début de l'écriture : en-tête XML--##
print $OUTFILE '<?xml version="1.0" encoding="UTF-8" ?>
';
print $OUTFILE $opentagvolume,"\n";


# =======================================================================================================================================
###--- PREPARATION ---###
  
# ------------------------------------------------------------------------
if ( defined $verbeux ) {&info('b');};
 
# ------------------------------------------------------------------------

my $nbentries = 0;
my $entreesresultat = 0;

# ------------------------------------------------------------------------
if ( defined $verbeux ) {&info('c');};
 
 
# =======================================================================================================================================
###--- ALGORITHME D'AJOUT d'IDS ---###
 
while (my $entry = next_entry(*INFILE)) {
	my $entryid = find_string($entry,$cdmentryid,1);
	if (!$entryid) {
		my $headword = find_string($entry,$cdmheadword);
		$headword =~ s/['" ]/_/g;
		my $newentryid = $srclang . '.' . $headword . '.' . $nbentries .'.e';

		$cdmentryid =~ s/\/$//;
		$cdmentryid =~ s/\/text\(\)$//;
		if ($cdmentryid =~ /@[^\/]+$/) {
			$cdmentryid =~ s/\/@([^\/]+)$//;
			my $attributename = $1;
			my @entryidnodes = $entry->findnodes($cdmentryid);
			my $entryidnode = $entryidnodes[0];
			$entryidnode->setAttribute($attributename,$newentryid);
		}
		else {
			my @entryidnodes = $entry->findnodes($cdmentryid);
			my $entryidnode = $entryidnodes[0];
			$entryidnode->addText($newentryid);
		}
	}
 	print $OUTFILE $entry->toString,"\n";
 	$entreesresultat++;
} 

 
# ------------------------------------------------------------------------
# Fin de l'écriture :
print $OUTFILE $closedtagvolume;
close $OUTFILE;
 

# ------------------------------------------------------------------------
if ( defined $verbeux ) {
  &info('d');
};


# =======================================================================================================================================
###--- SUBROUTINES ---###
sub next_entry 
{
	my $file = $_[0];
	my $doc = '';
	$/ = $closedtagentry;
	my $line = <$file>;
	if ($line) {
		$line = $headervolume . $line . $footervolume;
		$doc = $parser->parse($line);
		$nbentries++;
	}
	return $doc;
}
 
# ------------------------------------------------------------------------
# Cette fonction extrait une chaîne de caractères avec un pointeur XPath
sub find_string {
	my $entry = $_[0];
	my $cdm = $_[1];
	my $verbose = !$_[2] && $verbeux;
	my $text = '';
	if ($entry) {
		my @strings = $entry->findnodes($cdm);
		if (scalar(@strings>0)) {
			$text = getNodeText($strings[0]);
		}
		else {
			if ($verbose) {print STDERR "Problème avec find_string : XPath $cdm introuvable !\n"}; 
		}
	}
	else {
		if ($verbose) {print STDERR "Problème avec find_string : objet XML vide !\n";} 
	}
	return $text;
}
 
 
# ------------------------------------------------------------------------
# Cette fonction permet de récupérer le texte dans un nœud DOM quel que soit le type de nœud
sub getNodeText {
	my $node = $_[0];
	my $text = '';
	if ($node) {
		if ($node->getNodeType == DOCUMENT_NODE) {
			$node = $node->getDocumentElement();
		}
		if ($node->getNodeType == TEXT_NODE || $node->getNodeType == CDATA_SECTION_NODE) {
			  $text = $node->getData();
		}
		elsif ($node->getNodeType == ATTRIBUTE_NODE) {
			  $text = $node->getValue();
		}
		elsif ($node->getNodeType == ELEMENT_NODE || $node->getNodeType == ENTITY_REFERENCE_NODE || $node->getNodeType == DOCUMENT_FRAGMENT_NODE) {
			foreach my $child ($node->getChildNodes()) {
			  $text .= getNodeText($child);
			}
		}
		elsif ($node->getNodeType == COMMENT_NODE || $node->getNodeType == ENTITY_NODE || $node->getNodeType == PROCESSING_INSTRUCTION_NODE || $node->getNodeType == DOCUMENT_TYPE_NODE) {
			;
		}
		else {
			  $text = $node->toString();
		}
    }
    else {
    	if ($verbeux) {print STDERR "Problème avec getNodeText: nœud vide !\n";}
    }
	return $text;
}

sub read_file {
  	my $fichier = $_[0];
	open my $FILE, "<:encoding($unicode)", $fichier or die "error opening $fichier: $!";
	my $string = do { local $/; <$FILE> };
	close $FILE;
	return $string;
}


# cette fonction permet de récupérer les pointeurs cdm à partir du fichier metada.
 sub load_cdm_from_string {
  my $fichier = $_[0];
  my $doc = $parser->parse($fichier);
  my %dico=();
  my @cdmelements = $doc->findnodes('/volume-metadata/cdm-elements/*');
  foreach my $cdmelement (@cdmelements) {
  	my $name = $cdmelement->getNodeName();
  	if ($name ne 'links') {
		my $xpath = find_string($cdmelement,'@xpath');
		my $lang = find_string($cdmelement,'@d:lang',1);
		if ($lang) {
			$dico{$name.':'.$lang}=$xpath;}
		else
    	{$dico{$name}=$xpath;}
  	}
  }
  return %dico;
}

# cette fonction permet de récupérer les pointeurs cdm à partir du fichier metada.
 sub load_source_language {
  my $fichier = $_[0];
  my $doc = $parser->parse($fichier);
  return find_string($doc, '/volume-metadata/@source-language');
}


# Cette fonction convertit un XPath en balises ouvrantes
sub xpath2opentags {
	my $xpath = $_[0];
	my $attribut = $_[1] || '';
	if ($attribut ne '') {
		$attribut = ' ' . $attribut;
	}
	$xpath =~ s/\/$//;
	$xpath =~ s/\//></g;
	$xpath =~ s/^>//;
	$xpath .= $attribut . '>';
}

# Cette fonction convertit un XPath en balises fermantes
sub xpath2closedtags {
	my $xpath = $_[0];
	my $tags = '';
	my @xpath = reverse split(/\//,$xpath);
	foreach my $tag (@xpath) {
		if ($tag ne '') {
			$tags .= '</' . $tag . '>';	
		}
	}
	return $tags;
}

# Cette fonction convertit un XPath en une balise fermante
sub xpath2closedtag {
	my $xpath = $_[0];
	my $tag = xpath2closedtags($xpath);
	$tag =~ s/>.*$/>/;
	return $tag;
}

# ------------------------------------------------------------------------
# Cette fonction permet de calculer la différence entre deux XPath
sub xpathdifference {
	my $xpath = $_[0];
	my $xpathcourt = $_[1];
	$xpath =~ s/\/$//;
	$xpathcourt =~ s/\/$//;
	
	my $len = length $xpathcourt;	
	my $xpathcourt2 = substr($xpath,0,$len);
	if ($xpathcourt eq $xpathcourt2) {
		$xpath = substr($xpath,$len);
	}
	return $xpath;
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
	print STDERR
	"==================================================\n",
	"RAPPORT : ~~~~ $0 ~~~~\n",
	"--------------------------------------------------\n",
	"Fichier source : $FichierEntree\n",
	"--------------------------------------------------\n",
	"Fichier final : $FichierResultat\n",
	"--------------------------------------------------\n",
	"Nombre d'entrées analysées : ", $nbentries, "\n",
	"--------------------------------------------------\n",
	"Nombre d'entrées modifiées : ", $entreesresultat, "\n",
	"--------------------------------------------------\n",
	"Date du traitement : ", $date, "\n",
	"--------------------------------------------------\n",
	"Durée du traitement : ", $time, " s\n",
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
exit 0;
}
 
# =======================================================================================================================================
1 ;
