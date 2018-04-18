#!/usr/bin/env perl

# usage : tri.pl infile.xml > infile-sorted.xml
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
# -date "date" 				 	 : pour spécifier la date (par défaut : la date du jour (localtime)
# -encoding "format d'encodage" : pour spécifier le format d'encodage (par défaut UTF-8)
# -help 						 : pour afficher l'aide
# =======================================================================================================================================

use strict;
use warnings;
use utf8::all;
use Getopt::Long; # pour gérer les arguments.
use XML::DOM;
use XML::DOM::XPath;

use locale; # si les variables d'environnement sont correctement positionnées, cela devrait suffire
use POSIX qw(locale_h setlocale); # pour forcer une locale donnée
setlocale(LC_ALL,"fr_FR.UTF-8"); # pour forcer la locale fr_FR
#use Text::StripAccents;
use Unicode::Collate;

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
if ($FichierEntree) {
	open $INFILE, "<:encoding($encoding)",$FichierEntree or die ("$! $FichierEntree \n");
}
else {
	$FichierEntree = 'STDIN';
	$INFILE = *STDOUT;
}
if ($FichierResultat) {
	open $OUTFILE, ">:encoding($unicode)",$FichierResultat or die ("$! $FichierResultat \n");
} # si le fichier sortie n'est pas spécifié, on ouvre la sortie standard
else {
	$FichierResultat = 'STDOUT';
	$OUTFILE = *STDOUT;
}
if (!(defined $locale)) {$locale = "fr_FR.UTF-8";};


my $collator = Unicode::Collate::->new();

# on initialise le parseur XML DOM
my $parser= XML::DOM::Parser->new();
if ( $verbeux ) {print STDERR "Charge les pointeurs CDM des métadonnées\n";}
my %CDMSENTREE=load_cdm($metaEntree);
# =======================================================================================================================================
###--- PROLOGUE ---###
my $cdmvolume = $CDMSENTREE{'cdm-volume'}; # le volume
my $cdmentry = $CDMSENTREE{'cdm-entry'}; # l'élément de référence.
my $cdmheadword = $CDMSENTREE{'cdm-headword'}; # le sous-élément à comparer
my $cdmpos=$CDMSENTREE{'cdm-pos'};#le sous-élément à comparer dans le cas où on trouve 2 entrées de même headword.
# ------------------------------------------------------------------------

# On reconstruit les balises ouvrantes et fermantes du volume 
my $headervolume = xpath2opentags($cdmvolume);
my $footervolume = xpath2closedtags($cdmvolume);
my $closedtagentry = xpath2closedtag($cdmentry);


# ------------------------------------------------------------------------
# Input/ Output
# On va lire le fichier d'entrée article par article 
# donc on coupe après une balise de fin d'article.
$/ = $closedtagentry;

my @lines = <$INFILE>;
my @total = ();
if ( $verbeux ) {print STDERR "Extrait les vedettes et cat avec XPath\n";}
while (my $line = shift (@lines)) {
	my $entry = $headervolume . $line . $footervolume;
	my $doc = $parser->parse($entry);
	my $headword = find_string($doc,$cdmheadword);
	my $pos = find_string($doc,$cdmpos);
	my @array = ($headword, $pos, $line);
	push @total, \@array;
}
if ( $verbeux ) {print STDERR "Trie le tableau résultat\n";}
my @dico = sort { 
	my $cmp = $collator->cmp(${ $a }[0],${ $b }[0]);
	if ($cmp == 0) {
		$cmp = $collator->cmp(${ $a }[1],${ $b }[1]);	
	}
	return $cmp 
	} 
	@total;
if ( $verbeux ) {print STDERR "Affiche le résultat trié\n";}
foreach my $row (@total) {
	print $OUTFILE ${ $row }[2];
}
if ( $verbeux ) {fin();}


# ------------------------------------------------------------------------
# cette fonction permet de récupérer les pointeurs cdm à partir du fichier metada.
 sub load_cdm {
  my ($fichier)=@_;
  open (IN, "<:encoding($unicode)", $fichier);
  my %dico=();
  while(my $ligne=<IN>){
      
      if ($ligne=~/^\s*<(\S+)\s+xpath=\"([^\"]+)(\"\sd:lang=\")?(\w+)?/){
           my $cdm=$1; my $xpath=$2;  my $lang = $4;
           if ($ligne=~/d:lang/)
           {
           $dico{$cdm.$lang}=$xpath;}
           else
           {$dico{$cdm}=$xpath;}
  }
 
}
close(IN);
 return %dico;

 }

# ------------------------------------------------------------------------
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
# Cette fonction extrait une chaîne de caractères avec un pointeur XPath
sub find_string {
	my $entry = $_[0];
	my $cdm = $_[1];
	my $text = '';
	if ($entry) {
		my @strings = $entry->findnodes($cdm);
		if (scalar(@strings>0)) {
			$text = getNodeText($strings[0]);
		}
		else {
			if ($verbeux) {print STDERR "Problème avec find_string : XPath $cdm introuvable !\n"}; 
		}
	}
	else {
		if ($verbeux) {print STDERR "Problème avec find_string : objet XML vide !\n";} 
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

# ------------------------------------------------------------------------
sub fin
{
	print (STDERR "~~~~ $0 : END ~~~~\n");
	my $date = localtime;
	my $time = times ;
	print STDERR
	"==================================================\n",
	"RAPPORT : ~~~~ $0 ~~~~\n",
	"--------------------------------------------------\n",
	"Fichier source : $FichierEntree\n",
	"--------------------------------------------------\n",
	"Fichier final : $FichierResultat\n",
	"--------------------------------------------------\n",
	"Date du traitement : ", $date, "\n",
	"--------------------------------------------------\n",
	"Nombre d'entrées : ",scalar(@total),"\n",
	"--------------------------------------------------\n",
	"Durée du traitement : ", $time, " s\n",
	"==================================================\n";
}

# ------------------------------------------------------------------------
# Cette fonction affiche l'aide
sub help 
{
print (STDERR "================================================================================\n");  
print (STDERR "HELP\n");
print (STDERR "================================================================================\n");
print (STDERR "usage : $0 -i <sourcefile.xml> -m <metadatafile.xml> -o <outfile.xml>\n\n") ;
print (STDERR "options : -h affichage de l'aide\n") ;
print (STDERR "          -f le format d'encodage\n");
print (STDERR "          -v mode verbeux (STDERR et LOG)\n");
print (STDERR "================================================================================\n");
exit 0;
}

1;
