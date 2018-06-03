#!/usr/bin/perl

# ./tri.pl -m Donnees/Baat_fra-wol/DicoArrivee_wol_fra-metadata.xml  -i Donnees/Baat_fra-wol/dicoThiernoTransformePrep.xml -v > out.xml
# ./tri.pl -v -m Donnees/Baat_fra-wol/DicoArrivee_wol_fra-metadata.xml -from outcheriftpreptrie.xml > out.xml
#
#
# =======================================================================================================================================
######----- tri.pl -----#####
# =======================================================================================================================================
# Auteur : M.MANGEOT
# Version 1.0
# Dernières modifications : 18 avril 2018
# Synopsis :  - tri unicode d'un dictionnaire. 
# ---------------------------------------------------------------------------------------------------------------------------------------
# Usage : perl tri.pl -v -metadata fichier-metadata.xml -from source.xml -to out.xml 
#
# -v : affiche les informations du STDERR
#
# Pour les options avancées :
#
# -encoding "format d'encodage" : pour spécifier le format d'encodage (par défaut UTF-8)
# -help 						 : pour afficher l'aide
# =======================================================================================================================================

use strict;
use warnings;
use utf8::all;
use Getopt::Long; # pour gérer les arguments.
use XML::Twig;

use XML::DOM;
use XML::DOM::XPath;

use Unicode::Collate;


##-- Gestion des options --##
my ($FichierEntree, $metaEntree, $FichierResultat, $encoding) = ();
my ($date, $verbeux, $help, $locale) = ();
my ($INFILE, $OUTFILE) = ();
my $unicode = 'UTF-8';

GetOptions( 
  'source|base|in|one|from|i=s' => \$FichierEntree, 
  'metadonnees|metadata|m=s'           => \$metaEntree,
  'sortie|out|to|o=s'           => \$FichierResultat, 
  'encodage|encoding|enc|f=s'   => \$encoding, 
  'help|h'                      => \$help, 
  'verbeux|verbose|v'                   => \$verbeux, 
  );

if (!(defined $date)) {$date = localtime;};
if (!(defined $encoding)) {$encoding = "UTF-8";};
if (defined $help) {&help;};
if (!$metaEntree) {&help;}; # si le fichier de metadonnées n'est pas spécifié, affichage de l'aide.;
if ($FichierResultat) {
	open $OUTFILE, ">:encoding($unicode)",$FichierResultat or die ("$! $FichierResultat \n");
} # si le fichier sortie n'est pas spécifié, on ouvre la sortie standard
else {
	$FichierResultat = 'STDOUT';
	$OUTFILE = *STDOUT;
}

my $collator = Unicode::Collate::->new();

if ( $verbeux ) {print STDERR "Charge les pointeurs CDM des métadonnées\n";}
# on initialise le parseur XML DOM
my $parser= XML::DOM::Parser->new();
my $metaentreestring = read_file($metaEntree);
my %CDMSENTREE=load_cdm($metaentreestring);

###--- PROLOGUE ---###
my $cdmvolume = $CDMSENTREE{'cdm-volume'}; # le volume
my $cdmentry = $CDMSENTREE{'cdm-entry'}; # l'élément de référence.
my $cdmheadword = $CDMSENTREE{'cdm-headword'}; # le sous-élément à comparer
my $cdmpos=$CDMSENTREE{'cdm-pos'};#le sous-élément à comparer dans le cas où on trouve 2 entrées de même headword.

if ($verbeux) {print STDERR "Tri avec cdmheadword: $cdmheadword, cdmpos: $cdmpos\n";}

$cdmheadword = '.' . xpathdifference($cdmheadword,$cdmentry);
$cdmpos = '.' . xpathdifference($cdmpos,$cdmentry);

$cdmheadword =~ s/\/$//;
$cdmheadword =~ s/\/text\(\)$//;
$cdmpos =~ s/\/$//;
$cdmpos =~ s/\/text\(\)$//;

$cdmheadword .= '[1]';
$cdmpos .= '[1]';

if ($verbeux) {print STDERR "XPath avec cdmheadword: $cdmheadword, cdmpos: $cdmpos\n";}

my $nbentries = 0;
sub sort_children {
    my $parent = $_;
    my @children = sort {
    
    	my $cmp = $collator->cmp($a->findvalue($cdmheadword),$b->findvalue($cdmheadword));
		if ($cmp == 0) {
			$cmp = $collator->cmp($a->findvalue($cdmpos),$b->findvalue($cdmpos));	
		}
		return $cmp;
	} $parent->cut_children;
	$nbentries = scalar(@children);
    $_->paste(last_child => $parent) for @children;
}

my $twig = 'XML::Twig'->new(twig_handlers => { $cdmvolume => \&sort_children });
if ($FichierEntree) {
	$twig->parsefile($FichierEntree);
}
else {
	$twig->parse( \*STDIN);
}
$twig->print;

# ------------------------------------------------------------------------
# cette fonction permet de récupérer les pointeurs cdm à partir du fichier metada.
 sub load_cdm {
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

# ------------------------------------------------------------------------
# Cette fonction permet de lire un fichier dans une variable textuelle
sub read_file {
  	my $fichier = $_[0];
	open my $FILE, "<:encoding($unicode)", $fichier or die "error opening $fichier: $!";
	my $string = do { local $/; <$FILE> };
	close $FILE;
	return $string;
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

1;