#!/usr/bin/perl


# ./creation-liens-traduction.pl -v -m Donnees/Baat_fra-wol/DicoArrivee_wol_fra-metadata.xml -s Donnees/Baat_fra-wol/DicoArrivee_fra-metadata.xml -n Donnees/Baat_fra-wol/dicoarrivee_wol_fra-template.xml -u Donnees/Baat_fra-wol/dicoarrivee_fra-template.xml -from Donnees/fusion.xml -g target.xml -o out.xml
#
# =======================================================================================================================================
######----- creation-liens-traduction.pl -----#####
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
my ($date, $FichierEntree, $modeleEntree, $modeleCible, $metaEntree, $metaSortie, $FichierResultat, $FichierCible, $encoding) = ();
my ($verbeux, $help, $pretty_print) = ();
my ($OUTFILE, $TARGETFILE);

GetOptions( 
  'date|time|t=s'             => \$date, # flag de type -date ou --date, ou -time ou --time, ou -t ou --t (=s : string)
  'source|in|from|i=s' => \$FichierEntree, 
  'metaentree|min|m=s' => \$metaEntree, 
  'metasortie|mout|s=s'           => \$metaSortie, 
  'modeleentree|tin|n=s'           => \$modeleEntree, 
  'modelecible|tout|u=s'           => \$modeleCible, 
  'sortie|out|to|o=s'           => \$FichierResultat, 
  'cible|target|g=s'           => \$FichierCible, 
  'encodage|encoding|enc|f=s'   => \$encoding, 
  'aide|help|h'                      => \$help, 
  'verbeux|verbose|v'                   => \$verbeux, 
  'print|pretty|p=s'            => \$pretty_print, 
  );
 

if (!(defined $date)) {$date = localtime;};
if (!$FichierEntree) {&help;}; # si le fichier source n'est pas spécifié, affichage de l'aide.
if (!$metaEntree || !$metaSortie || !$modeleEntree || !$modeleCible || !$FichierCible) {help();} # si les fichiers ne sont pas spécifiés, affichage de l'aide.
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
 

# =======================================================================================================================================
###--- PROLOGUE ---###

open $TARGETFILE, ">:encoding($unicode)",$FichierCible or die ("$! $FichierCible \n");

my $collator = Unicode::Collate::->new();

# on initialise le parseur XML DOM
my $parser= XML::DOM::Parser->new();

if ( $verbeux ) {print STDERR "load cdm FichierMeta:\n";}
my $metaentreestring = read_file($metaEntree);
my %CDMSENTREE = load_cdm($metaentreestring);
my %LINKSENTREE = load_links($metaentreestring);

# ATTENTION, il faudra spécifier comment trouver le bon link dans des métadonnées !!!
my $keyentree = (keys %LINKSENTREE)[0];
my $cdmtranslationlinkinfoentree = $LINKSENTREE{$keyentree};

my $metasortiestring = read_file($metaSortie);
my %CDMSARRIVEE = load_cdm($metasortiestring);
my %LINKSARRIVEE = load_links($metasortiestring);
# ATTENTION, il faudra spécifier comment trouver le bon link dans des métadonnées !!!
my $keysortie = (keys %LINKSARRIVEE)[0];
my $cdmtranslationlinkinfosortie = $LINKSARRIVEE{$keysortie};

my $modeleentree = read_file($modeleEntree);
my $modelesortie = read_file($modeleCible);

my $srclang = load_source_language($metaentreestring);
my $trglang = load_source_language($metasortiestring);
my $volumedepart = load_volume_name($metaentreestring);
my $volumearrivee = load_volume_name($metasortiestring);

my $cdmvolumedepart = $CDMSENTREE{'cdm-volume'}; # le volume
my $cdmentrydepart = $CDMSENTREE{'cdm-entry'}; # l'article
my $cdmentryiddepart = $CDMSENTREE{'cdm-entry-id'}; # l'id de l'article
my $cdmtranslationblockdepart = $CDMSENTREE{'cdm-translation-block'.':'.$trglang}; # l'id de l'article
my $cdmtranslationposdepart = $CDMSENTREE{'cdm-translation-pos'.':'.$trglang}; # l'id de l'article
my $cdmtranslationdepart = $CDMSENTREE{'cdm-translation'.':'.$trglang}; # l'id de l'article

my $cdmvolumearrivee = $CDMSARRIVEE{'cdm-volume'}; # le mot-vedette
my $cdmentryarrivee = $CDMSARRIVEE{'cdm-entry'}; # l'article
my $cdmentryidarrivee = $CDMSARRIVEE{'cdm-entry-id'}; # l'id de l'article
my $cdmheadwordarrivee = $CDMSARRIVEE{'cdm-headword'}; # le mot-vedette
my $cdmposarrivee = $CDMSARRIVEE{'cdm-pos'}; # le mot-vedette

$cdmheadwordarrivee =~ s/\/$//;
$cdmheadwordarrivee =~ s/\/text\(\)$//;
$cdmposarrivee =~ s/\/$//;
$cdmposarrivee =~ s/\/text\(\)$//;

my $docentree = $parser->parse($modeleentree);
my $linknodedepart = create_link_node($cdmtranslationlinkinfoentree,$docentree);


#print STDERR Dumper(\%CDMSENTREE);
#print STDERR Dumper(\%LINKSARRIVEE);

# ------------------------------------------------------------------------

# On reconstruit les balises ouvrantes et fermantes du volume 
my $headervolumedepart = xpath2opentags($cdmvolumedepart);
my $footervolumedepart = xpath2closedtags($cdmvolumedepart);
my $closedtagentrydepart = xpath2closedtag($cdmentrydepart);
my $opentagvolumedepart = xpath2opentags($cdmvolumedepart, 'creation-date="' . $date . '"');
my $closedtagvolumedepart = xpath2closedtags($cdmvolumedepart);

my $opentagvolumearrivee = xpath2opentags($cdmvolumearrivee, 'creation-date="' . $date . '"');
my $closedtagvolumearrivee = xpath2closedtags($cdmvolumearrivee);


# ------------------------------------------------------------------------
# Input/ Output
open (INFILE, "<:encoding($encoding)",$FichierEntree) or die ("$! $FichierEntree\n");
# On va lire le fichier d'entrée article par article 
# donc on coupe après une balise de fin d'article.
$/ = $closedtagentrydepart;

# ------------------------------------------------------------------------
if ( defined $verbeux ) {&info('a');};
# message dans le STDERR (voir subroutine 'info') indiquant le démarrage du programme.
 
# ------------------------------------------------------------------------
##-- Début de l'écriture : en-tête XML--##
print $OUTFILE '<?xml version="1.0" encoding="UTF-8" ?>
';
print $OUTFILE $opentagvolumedepart,"\n";

print $TARGETFILE '<?xml version="1.0" encoding="UTF-8" ?>
';
print $TARGETFILE $opentagvolumearrivee,"\n";


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
$cdmtranslationdepart =~ s/\/$//;
$cdmtranslationdepart =~ s/\/text\(\)$//;
$cdmtranslationposdepart =~ s/\/$//;
$cdmtranslationposdepart =~ s/\/text\(\)$//;
if ($cdmtranslationblockdepart && $cdmtranslationposdepart) {
	$cdmtranslationdepart =~ s/^\Q$cdmtranslationblockdepart\E/\./;
	$cdmtranslationposdepart =~ s/^\Q$cdmtranslationblockdepart\E/\./;
}

while (my $entry = next_entry(*INFILE)) {
	my $entryid = find_string($entry,$cdmentryiddepart,1);
	if ($entryid && $cdmtranslationdepart) {	
		if ($cdmtranslationblockdepart) {
			my @tblocks = $entry->findnodes($cdmtranslationblockdepart);
			foreach my $tblock (@tblocks) {
				my @translations = $tblock->findnodes($cdmtranslationdepart);
				my $translation = $translations[0];
				if ($translation) {
					my $transtring = getNodeText($translation);
					if ($transtring) {
						my $tpos = '';
						my @poss = $tblock->findnodes($cdmtranslationposdepart);
						if (scalar(@poss>0)) {
							$tpos = getNodeText($poss[0]);
							my $parent = $poss[0]->getParentNode();
							$parent->removeChild($poss[0]);
						}
						my $targetid = create_and_print_entry($modelesortie, $transtring, $tpos, $cdmtranslationlinkinfosortie, $volumedepart, $entryid, $srclang);
						my $locallinknode = $linknodedepart->cloneNode(1);
						$locallinknode->setOwnerDocument($entry->getOwnerDocument());
						replace_translation_by_link($cdmtranslationlinkinfoentree, $translation, $locallinknode, $volumearrivee, $targetid, $trglang);
					}
				}
			}
		}
		elsif ($cdmtranslationposdepart) {
			my @translations = $entry->findnodes($cdmtranslationdepart);
			my $translation = $translations[0];
			my $transstring = find_string($entry,$cdmtranslationdepart);
			if ($transstring) {
				my $tpos = '';
				my @poss = $entry->findnodes($cdmtranslationposdepart);
				if (scalar(@poss>0)) {
					$tpos = getNodeText($poss[0]);
					my $parent = $poss[0]->getParentNode();
					$parent->removeChild($poss[0]);
				}
				my $targetid = create_and_print_entry($modelesortie, $transstring, $tpos, $volumedepart, $entryid, $srclang);
				my $locallinknode = $linknodedepart->cloneNode(1);
				$locallinknode->setOwnerDocument($entry->getOwnerDocument());
				replace_translation_by_link($cdmtranslationlinkinfoentree, $translation, $locallinknode, $volumearrivee, $targetid, $trglang);
			}
		}
		else {
			my @translations = $entry->findnodes($cdmtranslationdepart);
			foreach my $translation (@translations) {
				my $transtring = getNodeText($translation);
				if ($transtring) {
					my $targetid = create_and_print_entry($modelesortie, $transtring, '', $volumedepart, $entryid, $srclang);
					my $locallinknode = $linknodedepart->cloneNode(1);
					$locallinknode->setOwnerDocument($entry->getOwnerDocument());
					replace_translation_by_link($cdmtranslationlinkinfoentree, $translation, $locallinknode, $volumearrivee, $targetid, $trglang);
				}
			}
		}	
	}
	else {
		if ($verbeux) {print STDERR "un vide : $entryid ou $cdmtranslationdepart\n";}
	}
	my @entrydepart = $entry->findnodes($cdmentrydepart);
	my $entrydepart = $entrydepart[0];
 	print $OUTFILE $entrydepart->toString,"\n";
} 

 
# ------------------------------------------------------------------------
# Fin de l'écriture :
print $TARGETFILE $closedtagvolumearrivee;
close $TARGETFILE;
print $OUTFILE $closedtagvolumedepart;
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
	$/ = $closedtagentrydepart;
	my $line = <$file>;
	if ($line) {
		$line = $headervolumedepart . $line . $footervolumedepart;
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
	my $lang = find_string($cdmelement,'@d:lang');
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
			$type->addText('direct');
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
sub create_and_print_entry {
	my $newentry = $_[0];
	my $newheadword = $_[1];
	my $newpos = $_[2];
	my $linkinfo = $_[3];
	my $sourcevolume  = $_[4];
	my $targetid = $_[5];
	my $targetlang = $_[6];
	
	if ($verbeux) {print STDERR "create_and_print_entry: $newheadword [$newpos] -> $targetid\n";}
				
	my $docarrivee = $parser->parse($newentry);
	$entreesresultat++;
	my $newentryid = $trglang . '.' . $newheadword . '.' .$entreesresultat . '.e';	
	
	if ($cdmentryidarrivee =~ /@[^\/]+$/) {
		$cdmentryidarrivee =~ s/\/@([^\/]+)$//;
		my $attributename = $1;
		my @entryidnodes = $docarrivee->findnodes($cdmentryidarrivee);
		my $entryidnode = $entryidnodes[0];
		$entryidnode->setAttribute($attributename,$newentryid);
	}
	else {
		my @entryidnodes = $docarrivee->findnodes($cdmentryidarrivee);
		my $entryidnode = $entryidnodes[0];
		$entryidnode->addText($newentryid);
	}
	my @headwordarrivee = $docarrivee->findnodes($cdmheadwordarrivee);
	my $headwordarrivee = $headwordarrivee[0];
	$headwordarrivee->addText($newheadword);
	my @posarrivee = $docarrivee->findnodes($cdmposarrivee);
	if (scalar(@posarrivee)>0) {
		my $posarrivee = $posarrivee[0];
		$posarrivee->addText($newpos);
	}
		
	if ($linkinfo) {
		my $linknode = create_link_node($linkinfo,$docarrivee);
		fill_link($linkinfo, $linknode, $volumedepart, $targetid, $targetlang);
	}
	else {
		if ($verbeux) {print STDERR "Erreur : Pas de lien trouvé!\n"}
	}
	my @entryarrivee = $docarrivee->findnodes($cdmentryarrivee);
	my $entryarrivee = $entryarrivee[0];
 	print $TARGETFILE $entryarrivee->toString,"\n";
 	return $newentryid;
} 
 
# ------------------------------------------------------------------------
sub replace_translation_by_link {
	my $linkinfo = $_[0];
	my $transnode = $_[1];
	my $linkelement = $_[2];
	my $targetvolume = $_[3];
	my $targetid = $_[4];
	my $targetlang = $_[5];
	
	$linkelement->setOwnerDocument($transnode->getOwnerDocument());
	my $parent = $transnode->getParentNode();
	$parent->replaceChild($linkelement, $transnode);
	fill_link($linkinfo, $linkelement, $targetvolume, $targetid, $targetlang);
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
