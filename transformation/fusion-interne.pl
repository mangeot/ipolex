#!/usr/bin/perl


# ./fusion-interne.pl -v -m Donnees/Baat_fra-wol/DicoArrivee_wol_fra-metadata.xml -from Donnees/fusion.xml > out.xml
# ./fusion-interne.pl -v -m Donnees/Baat_fra-wol/DicoArrivee_wol_fra-metadata.xml -from Donnees/outcheriftpreptrie.xml > out.xml
#
# =======================================================================================================================================
######----- V_for_FusionInterne.pl -----#####
# =======================================================================================================================================
# Auteur : M.MANGEOT
# Version 1.1 
# Dernières modifications : 27 juillet 2012
# Synopsis :  - Fusion interne d'un fichier XML de même structure. 
# Les entrées ayant le même mot-vedette sont fusionnées et les identifiants de sens sont recalculés
# Remarques : ATTENTION : lfe fichier source d'origine doit commencer par <entry. Il faut effacer l'en-tête XML et l'élément racine !
#             - Le fichier d'origine doit être préalablement trié (./V_for_Sort.pl)
#             - Il faut ensuite renuméroter les axies
#             - La fusion ne modifie pas le fichier source
#             - Création d'un journal des exécutions (LOG)
# ---------------------------------------------------------------------------------------------------------------------------------------
# Usage : perl V_for_FusionInterne.pl -v -metadata fichier-metadata.xml -from source1.xml -to out.xml 
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

use Unicode::Collate;


use POSIX qw(locale_h setlocale);
my $unicode = "UTF-8";

##-- Gestion des options --##
my ($date, $FichierEntree, $metaArrivee, $FichierResultat, $encoding) = ();
my ($verbeux, $help, $pretty_print) = ();
my $OUTFILE;

GetOptions( 
  'date|time|t=s'             => \$date, # flag de type -date ou --date, ou -time ou --time, ou -t ou --t (=s : string)
  'source|base|in|one|from|i=s' => \$FichierEntree, 
  'metadonnees|metadata|m=s'           => \$metaArrivee,
  'sortie|out|to|o=s'           => \$FichierResultat, 
  'encodage|encoding|enc|f=s'   => \$encoding, 
  'help|h'                      => \$help, 
  'verbeux|v'                   => \$verbeux, 
  'print|pretty|p=s'            => \$pretty_print, 
  );
 

if (!(defined $date)) {$date = localtime;};
if (!(defined $FichierEntree)) {&help;}; # si le fichier source n'est pas spécifié, affichage de l'aide.
if (! ($metaArrivee)) {&help;}; # si le fichier metaArrivee n'est pas spécifié, affichage de l'aide.;
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
if ( $verbeux ) {print STDERR "load cdm métaArrivée:\n";}
my %CDMSARRIVEE=load_cdm($metaArrivee);
# =======================================================================================================================================
###--- PROLOGUE ---###
my $cdmvolume = $CDMSARRIVEE{'cdm-volume'}; # le volume
my $cdmentry = $CDMSARRIVEE{'cdm-entry'}; # l'élément de référence pour la fusion (pour MAM : 'entry' par exemple).
my $cdmheadword = $CDMSARRIVEE{'cdm-headword'}; # le sous-élément à comparer pour la fusion
my $cdmsense = $CDMSARRIVEE{'cdm-sense'}; # le sous-élément qui sera récupéré puis inséré.
my $cdmcat=$CDMSARRIVEE{'cdm-pos'};#le sous-élément à comparer dans le cas où on trouve 2 entrées de même headword.
my $cdmsourceblock=$CDMSARRIVEE{'cdm-source-block'};# pour recopier les entrées source
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
my ($entry_one, $entry_two);
my ($headword_one, $headword_two);
my ($cat_one, $cat_two);

#print STDERR 'next_entry:';

my $nbentries = 0;
$entry_one = next_entry(*INFILE); # obtenir la première entrée
$headword_one = find_string($entry_one,$cdmheadword);
$cat_one = find_string($entry_one,$cdmcat);
#print STDERR "h1: $headword_one cat1: $cat_one\n";

$entry_two = next_entry(*INFILE); # obtenir la deuxième entrée
$headword_two = find_string($entry_two,$cdmheadword);
$cat_two = find_string($entry_two,$cdmcat);

#print STDERR "h2: $headword_two cat2: $cat_two\n";
# ------------------------------------------------------------------------
if ( defined $verbeux ) {&info('c');};
 
 
# =======================================================================================================================================
###--- ALGORITHME DE LA FUSION ---###
 
# Après avoir récupéré la ou les entrées (sub next_entry), on les compare.
# On écrit dans le fichier de sortie selon la comparaison.
#my ($headword_one, $headword_two, $id_one, $id_two);
# Le traitement continuera tant qu'il y a des entrées dans l'une ou l'autre source.
my $egaux = 0;
my $egaunotcat=0;
my $entreesresultat = 0;
    while ($entry_one && $entry_two)
  { 
    # on compare les deux headword 'lexicographiquement'
   # my $compare = (defined $headword_two) - (defined $headword_one) || ($headword_one => stripaccents ($headword_one)) cmp ($headword_two => stripaccents ($headword_two));
    my $compare = $collator->cmp($headword_one,$headword_two);
    my $cmparecat=$collator->cmp($cat_one,$cat_two);

# si =0  comparer les cat si manque une cat = message d erreur , si 2 cat diff cas compare < 0 si 2 cat = cas fusion

     if ( defined $verbeux ){
      print STDERR "compare $headword_one cmp $headword_two = $compare; cpmcat $cat_one cmp $cat_two = $cmparecat\n";
      if ($compare==0 && $cmparecat==0){
        $egaux++;
#      print STDERR 'compare ', $headword_one , ' cmp ', $headword_two, ' = ', $compare, "\n";
      }
    };
    # 1) si l'entrée 1 est inférieure à l'entrée 2 (ou s'il n'y a plus d'entrée 2):
    # On écrit l'entrée 1 dans le fichier de sortie.
    # On avance d'une entrée dans le fichier 1
    if ($compare < 0 || ($compare==0 && $cmparecat!=0)) {
  		my @entries = $entry_one->findnodes($cdmentry);
		my $entry = $entries[0];
 		print $OUTFILE $entry->toString,"\n";
 		$entreesresultat++;
 		
      if ($compare==0 && $cmparecat!=0){
      	$egaunotcat++;

      }
      # pour avoir l'entrée suivante dans le fichier 1.
      $entry_one = $entry_two;
	  $headword_one = find_string($entry_one,$cdmheadword);
	  $cat_one = find_string($entry_one,$cdmcat);
    

    $entry_two = next_entry(*INFILE);
	$headword_two = find_string($entry_two,$cdmheadword);
	$cat_two = find_string($entry_two,$cdmcat);

    }
    # 2) si l'entrée 1 est supérieure à l'entrée 2 (ou s'il n'y a plus d'entrée 1):
    # ce cas ne devrait pas se présenter
    # On écrit l'entrée 2 dans le fichier de sortie.
    # On avanc d'une entrée dans le fichier 2.
    elsif ($compare > 0) {
      print STDERR "Erreur: fichier non trié $headword_one > $headword_two\n";
      exit 1;
      # pour avoir l'entrée suivante dans le fichier 2.
  	  my @entries = $entry_two->findnodes($cdmentry);
	  my $entry = $entries[0];
 	  print $OUTFILE $entry->toString,"\n";
      $entry_two = next_entry(*INFILE);
	  $headword_two = find_string($entry_two,$cdmheadword);
	  $cat_two = find_string($entry_two,$cdmcat);
    }
    # 3) le dernier cas : entrée 1 = entrée 2 et cat1 = cat2 :
    # On ajoute les éléments de entrée 2 dans entrée 1, qu'on écrit dans le fichier de sortie.
    # On avance d'une entrée dans le fichier 1 et dans le fichier 2.
    else
      {
        fusion ($entry_one, $entry_two);
        $entry_two = next_entry(*INFILE);
        if ($entry_two) {
			$headword_two = find_string($entry_two,$cdmheadword);
			$cat_two = find_string($entry_two,$cdmcat);
        }
      }
  }
 	my @entries = $entry_one->findnodes($cdmentry);
	my $entry= $entries[0];
 	print $OUTFILE $entry->toString,"\n";
 	$entreesresultat++;
 
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
sub fusion
{
my $entry_one = shift @_;
my $entry_two = shift @_;
my $i = 0;
# La fusion consiste à ajouter à la suite les éléments <sense> du second fichier source.
# Il ne faut pas oublier pour cela la gestion de la numérotation des sense.
# Pour les éléments <sense> du premier fichier, rien ne change.
# Pour ceux du second fichier, il existera un décalage selon Sn sense (n = le nombre de <sense> dans le premier fichier).
my $last_sense = '';
foreach my $sense_one ($entry_one->findnodes($cdmsense)) {
	$i++;
	$last_sense = $sense_one;
  	$sense_one->setAttribute('id','s'.$i);
}
my $doc = $last_sense->getOwnerDocument();
my $noeudParent = $last_sense->getParentNode();
my $noeudSuivant = $last_sense->getNextSibling();
foreach my $sense_two ($entry_two->findnodes($cdmsense))
  {
  $i++;
  $sense_two->setAttribute('id','s'.$i);
 # foreach my $translations ($sense_two->findnodes('m:translations'))
#	{
#	foreach my $translation ($translations->findnodes('m:translation'))
#		{
#		$translation->set_att('idreflexie' => "s$i");
#		}
#	}
	$sense_two->setOwnerDocument($doc);
	if ($noeudSuivant) {
		$noeudParent->insertBefore($sense_two,$noeudSuivant);
	}
	else {
		$noeudParent->appendChild($sense_two);
	}
	$last_sense = $sense_two;
  }
  my @sourceblocks_one = $entry_one->findnodes($cdmsourceblock);
  my @sourceblocks_two = $entry_two->findnodes($cdmsourceblock);
  if (scalar(@sourceblocks_one)>0 && scalar(@sourceblocks_two)>0) {
  	  my $sourceblockone = $sourceblocks_one[0];
  	  my $sourceblocktwo = $sourceblocks_two[0];
  	  foreach my $child ($sourceblocktwo->getChildNodes()) {
  	  	$child->setOwnerDocument($doc);
  	  	$sourceblockone->appendChild($child);
  	  }
  }
  return ($entry_one);
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
	"Nombre d'entrées fusionnées : ", $egaux, "\n",
	"--------------------------------------------------\n",
	"Nombre d'entrées affichées : ", $entreesresultat, "\n",
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
