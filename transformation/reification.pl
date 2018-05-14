#!/usr/bin/perl


# ./reification.pl -v -a Donnees/volumewol.xml -b Donnees/Baat_fra-wol/DicoArrivee_wol_fra-metadata.xml -c Donnees/Baat_fra-wol/dicoarrivee_wol_fra-template.xml -d outwol.xml -i Donnees/volumefra.xml -j Donnees/Baat_fra-wol/DicoArrivee_fra-metadata.xml -k Donnees/Baat_fra-wol/dicoarrivee_wol_fra-template.xml -l outfra.xml -m Donnees/Baat_fra-wol/DicoArrivee_axi-metadata.xml -n Donnees/Baat_fra-wol/dicoarrivee_axi-template.xml -o outaxi.xml
#
# =======================================================================================================================================
######----- reification.pl -----#####
# =======================================================================================================================================
# Auteur : M.MANGEOT
# Version 1.1 
# Dernières modifications : 28 avril 2018
# Synopsis :  - ajout d'identifiants pour les articles
# ---------------------------------------------------------------------------------------------------------------------------------------
# Usage : perl reification.pl -v -metadata fichier-metadata.xml -from source1.xml -to out.xml 
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
my ($FichierSource, $metaSource, $modeleSource, $sortieSource, $FichierCible, $metaCible, $modeleCible, $sortieCible, $metaPivot, $modelePivot, $FichierResultat) = ();
my ($date, $encoding, $verbeux, $help) = ();
my ($OUTSOURCE, $OUTPIVOT, $OUTTARGET);

GetOptions( 
  'source|a=s' => \$FichierSource, 
  'metasource|msource|b=s'     => \$metaSource, 
  'modelesource|tsource|c=s'   => \$modeleSource, 
  'sortiesource|osource|d=s'   => \$sortieSource, 
  'cible|target|i=s'           => \$FichierCible, 
  'metacible|mtarget|j=s'      => \$metaCible, 
  'modelecible|ttarget|k=s'    => \$modeleCible, 
  'sortiecible|otarget|l=s'    => \$sortieCible, 
  'metapivot|mpivot|m=s'       => \$metaPivot, 
  'modelepivot|tpivot|n=s'     => \$modelePivot, 
  'sortiepivot|out|to|o=s'     => \$FichierResultat, 
  'aide|help|h'                => \$help, 
  'verbeux|verbose|v'          => \$verbeux, 
  );


if (!$FichierSource || !$metaSource || !$modeleSource || !$sortieSource || !$FichierCible || !$metaCible || !$modeleCible || !$sortieCible || !$metaPivot || !$modelePivot) {help();} # si les fichiers ne sont pas spécifiés, affichage de l'aide.

if ($FichierResultat) {
	open $OUTPIVOT, ">:encoding($unicode)",$FichierResultat or die ("$! $FichierResultat \n");
} # si le fichier sortie n'est pas spécifié, on ouvre la sortie standard
else {
	$FichierResultat = 'STDOUT';
	$OUTPIVOT = *STDOUT;
}

if (!(defined $encoding)) {$encoding = "UTF-8";};
if (!(defined $date)) {$date = localtime;};
if (defined $help) {&help;};

# =======================================================================================================================================
###--- PROLOGUE ---###

open $OUTSOURCE, ">:encoding($unicode)",$sortieSource or die ("$! $sortieSource \n");
open $OUTTARGET, ">:encoding($unicode)",$sortieCible or die ("$! $sortieCible \n");

my $collator = Unicode::Collate::->new();

# on initialise le parseur XML DOM
my $parser= XML::DOM::Parser->new();

if ( $verbeux ) {print STDERR "load cdm fichiers meta et modèle source:\n";}
# ------------------------------------------------------------------------
# données source
my $metasourcestring = read_file($metaSource);
my %CDMSSOURCE = load_cdm($metasourcestring);
my %LINKSSOURCE = load_links($metasourcestring);
#print STDERR Dumper(\%CDMSSOURCE);
#print STDERR Dumper(\%LINKSSOURCE);
my $modelesourcestring = read_file($modeleSource);
my $docsource = $parser->parse($modelesourcestring);
my $srclang = load_source_language($metasourcestring);
my $volumesource = load_volume_name($metasourcestring);
# ATTENTION, il faudra spécifier comment trouver le bon link dans des métadonnées !!!
my $keysource = (keys %LINKSSOURCE)[0];
my $cdmfirsttranslationlinkinfosource = $LINKSSOURCE{$keysource};
my $linknodesource = create_link_node($cdmfirsttranslationlinkinfosource,$docsource);
my $cdmvolumesource = $CDMSSOURCE{'cdm-volume'}; # le volume
my $cdmentrysource = $CDMSSOURCE{'cdm-entry'}; # l'article
my $cdmentryidsource = $CDMSSOURCE{'cdm-entry-id'}; # l'id de l'article
# On reconstruit les balises ouvrantes et fermantes du volume 
my $headervolumesource = xpath2opentags($cdmvolumesource);
my $footervolumesource = xpath2closedtags($cdmvolumesource);
my $closedtagentrysource = xpath2closedtag($cdmentrysource);
my $opentagvolumesource = xpath2opentags($cdmvolumesource, 'creation-date="' . $date . '"');
my $closedtagvolumesource = xpath2closedtags($cdmvolumesource);


if ( $verbeux ) {print STDERR "load cdm fichiers meta et modèle cible:\n";}
# ------------------------------------------------------------------------
# données cible
my $metaciblestring = read_file($metaCible);
my %CDMSCIBLE = load_cdm($metaciblestring);
my %LINKSCIBLE = load_links($metaciblestring);
my $modeleciblestring = read_file($modeleCible);
my $doccible = $parser->parse($modeleciblestring);
my $trglang = load_source_language($metaciblestring);
my $volumecible = load_volume_name($metaciblestring);
# ATTENTION, il faudra spécifier comment trouver le bon link dans des métadonnées !!!
my $keycible = (keys %LINKSCIBLE)[0];
my $cdmfirsttranslationlinkinfocible = $LINKSSOURCE{$keycible};
my $linknodecible = create_link_node($cdmfirsttranslationlinkinfocible,$doccible);
my $cdmvolumecible = $CDMSCIBLE{'cdm-volume'}; # le volume
my $cdmentrycible = $CDMSCIBLE{'cdm-entry'}; # l'article
my $cdmentryidcible = $CDMSCIBLE{'cdm-entry-id'}; # l'id de l'article
# On reconstruit les balises ouvrantes et fermantes du volume 
my $headervolumecible = xpath2opentags($cdmvolumecible);
my $footervolumecible = xpath2closedtags($cdmvolumecible);
my $closedtagentrycible = xpath2closedtag($cdmentrycible);
my $opentagvolumecible = xpath2opentags($cdmvolumecible, 'creation-date="' . $date . '"');
my $closedtagvolumecible = xpath2closedtags($cdmvolumecible);


if ( $verbeux ) {print STDERR "load cdm fichiers meta et modèle pivot:\n";}
# ------------------------------------------------------------------------
# données pivot
my $metapivotstring = read_file($metaPivot);
my %CDMSPIVOT = load_cdm($metapivotstring);
my %LINKSPIVOT = load_links($metapivotstring);
my $modelepivotstring = read_file($modelePivot);
my $docpivot = $parser->parse($modelepivotstring);
my $pivotlang = load_source_language($metapivotstring);
my $volumepivot = load_volume_name($metapivotstring);
# ATTENTION, il faudra spécifier comment trouver le bon link dans des métadonnées !!!
my $keypivot = (keys %LINKSPIVOT)[0];
my $cdmfirsttranslationlinkinfopivot = $LINKSPIVOT{$keypivot};
my $linknodepivot = create_link_node($cdmfirsttranslationlinkinfopivot,$docpivot);
my $cdmvolumepivot = $CDMSPIVOT{'cdm-volume'}; # le volume
my $cdmentrypivot = $CDMSPIVOT{'cdm-entry'}; # l'article
my $cdmentryidpivot = $CDMSPIVOT{'cdm-entry-id'}; # l'id de l'article
my $cdmheadwordpivot = $CDMSPIVOT{'cdm-headword'}; # le mot-vedette
$cdmheadwordpivot =~ s/\/$//;
$cdmheadwordpivot =~ s/\/text\(\)$//;
my $opentagvolumepivot = xpath2opentags($cdmvolumepivot, 'creation-date="' . $date . '"');
my $closedtagvolumepivot = xpath2closedtags($cdmvolumepivot);


# ------------------------------------------------------------------------
# Input/ Output
open (SOURCEFILE, "<:encoding($encoding)",$FichierSource) or die ("$! $FichierSource\n");
# On va lire le fichier d'entrée article par article 
# donc on coupe après une balise de fin d'article.
$/ = $closedtagentrysource;

# ------------------------------------------------------------------------
if ( defined $verbeux ) {&info('a');};
# message dans le STDERR (voir subroutine 'info') indiquant le démarrage du programme.
 
# ------------------------------------------------------------------------
##-- Début de l'écriture : en-tête XML--##
print $OUTSOURCE '<?xml version="1.0" encoding="UTF-8" ?>
',$opentagvolumesource,"\n";

print $OUTPIVOT '<?xml version="1.0" encoding="UTF-8" ?>
',$opentagvolumepivot,"\n";


# =======================================================================================================================================
###--- PREPARATION ---###
  
# ------------------------------------------------------------------------
if ($verbeux) {&info('b');};
 
# ------------------------------------------------------------------------

my $nbentries = 0;
my $entreesresultat = 0;

# ------------------------------------------------------------------------
if ($verbeux) {&info('c');};
 
 
# =======================================================================================================================================
###--- ALGORITHME DE CRÉATION DE LIENS ---###

my %lienscible = ();
while (my $entry = next_entry_source(*SOURCEFILE)) {
	my $entryid = find_string($entry,$cdmentryidsource,1);

	if ($entryid) {
# ATTENTION, il faudra spécifier comment trouver le bon link dans des métadonnées !!!
	foreach my $clelien (keys %LINKSSOURCE) {
		my $cdmtranslationlinkinfosource = $LINKSSOURCE{$clelien};
		my @links = $entry->findnodes($cdmtranslationlinkinfosource->{'xpath'});
		foreach my $link (@links) {
			my $type = find_string($link,$cdmtranslationlinkinfosource->{'type'});
			my $volume = find_string($link,$cdmtranslationlinkinfosource->{'volume'});
			my $value = find_string($link,$cdmtranslationlinkinfosource->{'value'});
			if ($type eq 'direct' && $volume eq $volumecible && $value ne '') {
				$entreesresultat++;
				my $pivotid = create_pivot_id($pivotlang,$srclang,$trglang,$entryid,$value,$entreesresultat);
				my $locallinknode = $linknodesource->cloneNode(1);
				$locallinknode->setOwnerDocument($entry->getOwnerDocument());
				replace_direct_by_pivot_link($cdmtranslationlinkinfosource, $link, $locallinknode, $volumepivot, $pivotid, $pivotlang);
				
				create_and_print_pivot_entry($modelepivotstring, $pivotid, $cdmentrypivot, $cdmentryidpivot, $cdmheadwordpivot, 
				$cdmfirsttranslationlinkinfopivot, $volumesource, $entryid, $srclang, $volumecible, $value, $trglang);
				$lienscible{$entryid} = $pivotid;
			}
		}
	}
	}
	my @entrysource = $entry->findnodes($cdmentrysource);
	if (scalar(@entrysource)>0) {
		my $entrysource = $entrysource[0];
 		print $OUTSOURCE $entrysource->toString,"\n";
	}
} 

 
# ------------------------------------------------------------------------
# Fin de l'écriture :
print $OUTPIVOT $closedtagvolumepivot;
close $OUTPIVOT;
print $OUTSOURCE $closedtagvolumesource;
close $OUTSOURCE;
 

print $OUTTARGET '<?xml version="1.0" encoding="UTF-8" ?>
',$opentagvolumecible,"\n";

# ------------------------------------------------------------------------
# Input/ Output
open (TARGETFILE, "<:encoding($encoding)",$FichierCible) or die ("$! $FichierCible\n");
# On va lire le fichier d'entrée article par article 
# donc on coupe après une balise de fin d'article.
$/ = $closedtagentrycible;

while (my $entry = next_entry_cible(*TARGETFILE)) {
	my $entryid = find_string($entry,$cdmentryidcible,1);
	if ($entryid) {
# ATTENTION, il faudra spécifier comment trouver le bon link dans des métadonnées !!!
	foreach my $clelien (keys %LINKSCIBLE) {
		my $cdmtranslationlinkinfocible = $LINKSCIBLE{$clelien};
		my @links = $entry->findnodes($cdmtranslationlinkinfocible->{'xpath'});
		foreach my $link (@links) {
			my $type = find_string($link,$cdmtranslationlinkinfocible->{'type'});
			my $volume = find_string($link,$cdmtranslationlinkinfocible->{'volume'});
			my $value = find_string($link,$cdmtranslationlinkinfocible->{'value'});
			if ($type eq 'direct' && $volume eq $volumesource && $value ne '') {
				if (defined($lienscible{$value})) {
					my $pivotid = $lienscible{$value};
					if ($verbeux) {print STDERR 'liencible : ',$value, ' => ', $pivotid,"\n";}
					my $locallinknode = $linknodecible->cloneNode(1);
					$locallinknode->setOwnerDocument($entry->getOwnerDocument());
					replace_direct_by_pivot_link($cdmtranslationlinkinfocible, $link, $locallinknode, $volumepivot, $pivotid, $pivotlang);
				}
			}
		}
	}
	}
	my @entrycible = $entry->findnodes($cdmentrycible);
	if (scalar(@entrycible)>0) {
		my $entrycible = $entrycible[0];
 		print $OUTTARGET $entrycible->toString,"\n";
	}
} 

 
# ------------------------------------------------------------------------
# Fin de l'écriture :
print $OUTTARGET $closedtagvolumecible;
close $OUTTARGET;


# ------------------------------------------------------------------------
if ( defined $verbeux ) {
  &info('d');
};


# =======================================================================================================================================
###--- SUBROUTINES ---###
sub next_entry
{
	my $file = $_[0];
	my $stop = $_[1];
	my $header = $_[2];
	my $footer = $_[3];
	my $doc = '';
	$/ = $stop;
	my $line = <$file>;
	if ($line) {
		$line = $header . $line . $footer;
		eval {
			$doc = $parser->parse($line);
    		1;
		} or do {
    		my $e = $@;
    		print STDERR "Error parsing XML: [$line] $e\n";
		};
		$nbentries++;
	}
	return $doc;
}

sub next_entry_source {
	my $file = $_[0];
	return next_entry($file,$closedtagentrysource, $headervolumesource, $footervolumesource);	
}

sub next_entry_cible {
	my $file = $_[0];
	return next_entry($file,$closedtagentrycible, $headervolumecible, $footervolumecible);	
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

# cette fonction permet de récupérer les links pointeurs cdm à partir du fichier metada.
 sub load_links {
  my $fichier = $_[0];
  my $doc = $parser->parse($fichier);
  my %dico=();
  my @cdmelements = $doc->findnodes('/volume-metadata/cdm-elements/links/link');
  foreach my $cdmelement (@cdmelements) {
  	my %link = ();
	my $name = find_string($cdmelement,'@name');
	if (!$name) {$name='#empty';}
	my $xpath = find_string($cdmelement,'@xpath');
	my $lang = find_string($cdmelement,'@d:lang',1);
	if ($lang) {
		$name .= ':' . $lang; 
	}
	$link{'xpath'} = $xpath;
	my @children = $cdmelement->findnodes('./*');
	foreach my $child (@children) {
		my $nameattr = $child->getNodeName();
		$xpath = $child->getAttribute('xpath');
		$link{$nameattr} = $xpath;
	}	
	$dico{$name} = \%link;
  }
  return %dico;
}


# cette fonction permet de récupérer les pointeurs cdm à partir du fichier metada.
 sub load_source_language {
  my $fichier = $_[0];
  my $doc = $parser->parse($fichier);
  return find_string($doc, '/volume-metadata/@source-language');
}
# cette fonction permet de récupérer le nom du volume
 sub load_volume_name {
  my $fichier = $_[0];
  my $doc = $parser->parse($fichier);
  return find_string($doc, '/volume-metadata/@name');
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
 
 
#------------------------------------------------------------------------
sub create_link_node {
	my $translationlinkinfo = $_[0];
	my $doc = $_[1];
	my $cdmlinkxpath = $translationlinkinfo->{'xpath'};
	my @linknodes = $doc->findnodes($cdmlinkxpath);
	return $linknodes[0];
}
 
#------------------------------------------------------------------------
sub fill_link {
	my $translationlinkinfo = $_[0];
	my $linknode = $_[1];
	my $targetvolume = $_[2];
	my $targetid = $_[3];
	my $targetlang = $_[4];
	my $typestring = $_[5];
		
	if ($translationlinkinfo) {
		my $langpath = $translationlinkinfo->{'lang'};
		if ($langpath) {
			my @langs = $linknode->findnodes($langpath);
			my $lang = $langs[0];
			$lang->addText($targetlang);
		}
		my $typepath = $translationlinkinfo->{'type'};
		if ($typepath) {
			my @types = $linknode->findnodes($typepath);
			my $type = $types[0];
			$type->addText($typestring);
		}
		my $volumepath = $translationlinkinfo->{'volume'};
		if ($volumepath) {
			my @volumes = $linknode->findnodes($volumepath);
			my $volume = $volumes[0];
			$volume->addText($targetvolume);
		}
		my $valuepath = $translationlinkinfo->{'value'};
		if ($valuepath) {
			my @values = $linknode->findnodes($valuepath);
			my $value = $values[0];
			$value->addText($targetid);
		}
	}
	else {
		if ($verbeux) {print STDERR "Erreur : Pas de lien trouvé!\n"}
	}
	return $linknode;
}
	

# ------------------------------------------------------------------------
sub create_and_print_pivot_entry {
	my $pivotentry = $_[0];
	my $pivotentryid = $_[1];
	my $cdmpivotentry = $_[2];
	my $cdmpivotentryid = $_[3];
	my $cdmpivotheadword = $_[4];
	my $linkinfo = $_[5];
	my $srcvolume  = $_[6];
	my $sourceid  = $_[7];
	my $sourcelang  = $_[8];
	my $trgvolume  = $_[9];
	my $targetid = $_[10];
	my $targetlang = $_[11];
	
	if ($verbeux) {print STDERR "create_and_print_entry: $pivotentryid\n";}
				
	my $docpivot = $parser->parse($pivotentry);

	
	if ($cdmpivotentryid =~ /\/@[^\/]+$/) {
		$cdmpivotentryid =~ s/\/@([^\/]+)$//;
		my $attributename = $1;
		my @entryidnodes = $docpivot->findnodes($cdmpivotentryid);
		my $entryidnode = $entryidnodes[0];
		$entryidnode->setAttribute($attributename,$pivotentryid);
	}
	else {
		my @entryidnodes = $docpivot->findnodes($cdmpivotentryid);
		my $entryidnode = $entryidnodes[0];
		$entryidnode->addText($pivotentryid);
	}
	my @headwordpivot = $docpivot->findnodes($cdmpivotheadword);
	my $headwordpivot = $headwordpivot[0];
	my $newheadword = $pivotentryid;
	$newheadword =~ s/^.*\[/\[/;
	$newheadword =~ s/\].*$/\]/;
	$headwordpivot->addText($newheadword);
		
	if ($linkinfo) {
		my $linknodetemplate = create_link_node($linkinfo,$docpivot);
		my $papa = $linknodetemplate->getParentNode();
		my $locallinknode = $linknodepivot->cloneNode(1);
		$locallinknode->setOwnerDocument($docpivot);
		fill_link($linkinfo, $locallinknode, $srcvolume, $sourceid, $sourcelang,'final');
		$papa->appendChild($locallinknode);
		$locallinknode = $linknodepivot->cloneNode(1);
		$locallinknode->setOwnerDocument($docpivot);
		fill_link($linkinfo, $locallinknode, $trgvolume, $targetid, $targetlang,'final');
		$papa->appendChild($locallinknode);
	}
	else {
		if ($verbeux) {print STDERR "Erreur : Pas de lien trouvé!\n"}
	}
	my @entrypivot = $docpivot->findnodes($cdmpivotentry);
	my $entrypivot = $entrypivot[0];
 	print $OUTPIVOT $entrypivot->toString,"\n";
} 
 
# ------------------------------------------------------------------------
sub replace_direct_by_pivot_link {
	my $linkinfo = $_[0];
	my $transnode = $_[1];
	my $linkelement = $_[2];
	my $trgvolume = $_[3];
	my $targetid = $_[4];
	my $targetlang = $_[5];
	
	$linkelement->setOwnerDocument($transnode->getOwnerDocument());
	my $parent = $transnode->getParentNode();
	$parent->replaceChild($linkelement, $transnode);
	fill_link($linkinfo, $linkelement, $trgvolume, $targetid, $targetlang,'pivot');
}	

 
# ------------------------------------------------------------------------
sub create_pivot_id {
	my $axi = $_[0];
	my $src = $_[1];
	my $trg = $_[2];
	my $srcid = $_[3];
	my $trgid = $_[4];
	my $uniqueid = $_[5];
	
	$srcid =~ s/^[^\.]+\.//;
	$trgid =~ s/^[^\.]+\.//;
	$srcid =~ s/^([^\.]+).*$/$1/;
	$trgid =~ s/^([^\.]+).*$/$1/;

# axi.[fra:Ancêtres,khm:bopeak-borɔh].418.1.e"	
	return $axi . '.[' . $src . ':' . $srcid . ',' . $trg . ':' . $trgid . '].' . $uniqueid . '.e';
	
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
	print (STDERR "en-tete du fichier de sortie effective\n");
	print (STDERR "--------------------------------------------------------------------------------\n");
	}
elsif ($info=~ 'c')
	{
	print (STDERR "================================================================================\n");
	print (STDERR "lancement du processus de réification\n");
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
	"Fichier source : $FichierSource\n",
	"Fichier cible : $FichierCible\n",
	"--------------------------------------------------\n",
	"Fichiers finaux : $FichierResultat\n",
	"                  $sortieSource\n",
	"                  $sortieCible\n",
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
