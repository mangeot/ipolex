#!/usr/bin/perl -w

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

##-- Gestion des options --##
my ($FichierEntree, $metaEntree, $FichierResultat, $encoding) = ();
my ($verbeux, $help, $locale) = ();
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

if ( $verbeux ) {print STDERR "Charge les pointeurs CDM des métadonnées\n";}
# on initialise le parseur XML DOM
my $parser= XML::DOM::Parser->new();
my $metaentreestring = read_file($metaEntree);
my %CDMSENTREE=load_cdm($metaentreestring);

###--- PROLOGUE ---###
my $cdmentry = $CDMSENTREE{'cdm-entry'}; # le volume


my $twig= new XML::Twig( twig_roots    => { $cdmentry => 1},
                                              # handler will be called for
                                              # $field elements
                         twig_handlers => { $cdmentry => \&entry } ); 

# print the result
if ($FichierEntree) {
	$twig->parsefile($FichierEntree);
}
else {
	$twig->parse(\*STDIN);
}                              
                                              
sub entry
  { my( $twig, $entry)= @_;                      
	my $string = $entry->sprint;
	$string =~ s/\R/ /gsm;
	print $string,"\n";
    $twig->purge;                             # delete the twig so far   
 }

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
