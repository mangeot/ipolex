#!/usr/bin/perl
#
# ./transformation-fichiercomplet.pl -i Donnees/anaan.xml -t Donnees/Baat_fra-wol/dicoarrivee_wol_fra-template.xml > out.xml
# ./transformation-fichiercomplet.pl -i Donnees/Baat_fra-wol/baat_wol_fra-prep.xml -t Donnees/Baat_fra-wol/dicoarrivee_wol_fra-template.xml > out.xml
#
#

use strict;
use warnings;
use utf8::all;

use XML::DOM;
use XML::DOM::XPath;
use Data::Dumper;
use Getopt::Long; # pour gérer les arguments.

my $encoding = "UTF-8";
my $unicode = "UTF-8";

my ($metaEntree, $metaSortie,  $entreeModele, $fichierEntree, $fichierSortie, $help, $verbeux) = ();

GetOptions( 
  'entree|in|from|i=s' => \$fichierEntree, 
  'sortie|out|to|o=s'           => \$fichierSortie, 
  'modele|template|t=s'           => \$entreeModele, 
  'encodage|encoding|enc|c=s' 	=> \$encoding, 
  'help|h'                	  	=> \$help, 
  'verbeux|v'             	  	=> \$verbeux, 
  );
 
my $date = localtime;
my $OUTFILE;
if (!(defined $fichierEntree)) {
	$fichierEntree  = *STDIN;
} # si le fichier entree n'est pas spécifié, on ouvre l'entrée standard
if (!(defined $fichierSortie)) {
	$OUTFILE = *STDOUT;
} # si le fichier sortie n'est pas spécifié, on ouvre la sortie standard
else {
	open $OUTFILE, ">:encoding($unicode)",$fichierSortie or die ("$! $fichierSortie \n");
}
if (!defined $entreeModele) {&help;};
if (!(defined $encoding)) {
	$encoding  = "UTF-8";
} # si le fichier entree n'est pas spécifié, on ouvre l'entrée standard
if (defined $help) {&help;};

binmode(STDERR, ":utf8");

sub help {
	print STDERR "Message d'aide, voir V_for_fusionInterne.pl pour exemple\n";
}

open my $INFILE, "<:encoding($encoding)",$fichierEntree or die ("$! $fichierEntree \n");

open my $MODELEFILE, "<:encoding($unicode)", $entreeModele or die "error opening $entreeModele: $!";
open my $METAENTREFILE, "<:encoding($unicode)", $metaEntree or die "error opening $metaEntree: $!";
open my $METASORTIEFILE, "<:encoding($unicode)", $metaEntree or die "error opening $metaSortie: $!";

my %CDMSDEPART=load_cdm($metaEntree);
my %CDMSARRIVE=load_cdm($metaSortie);



my $xmlarrivee = do { local $/; <$MODELEFILE> };

#print STDERR "XMLarrivée : [",$xmlarrivee,"]",$entreeModele;

  <cdm-volume xpath="/database"/>
<cdm-entry xpath="/database/lexGroup"/>
<cdm-entry-id xpath="/database/lexGroup/@id"/>
<cdm-headword xpath="/database/lexGroup/lex/text()"/>
<cdm-headword-variant xpath="/database/lexGroup/variante/text()"/>
<cdm-pronunciation xpath="/database/lexGroup/uttW/text()"/>
<cdm-pos xpath="/database/lexGroup/catWGroup/catW/text()"/>
<cdm-definition xpath="/database/lexGroup/defWGroup/defW/text()"/>
<cdm-translation xpath="/database/lexGroup/tradFlexGroup/tradFlex/text()" d:lang="fra" />
  <cdm-example-block xpath="/database/lexGroup/phrWGroup"/>
<cdm-example xpath="/database/lexGroup/phrWGroup/tradPhrW/text()" d:lang="fra" />
  <cdm-example xpath="/database/lexGroup/phrWGroup/phrW/text()" d:lang="wol" />
  <cdm-classe-nominale xpath="/database/lexGroup/catWGroup/clasW/text()" index="true"  />	
  		<cdm-source-mot-vedette xpath="/database/lexGroup/SrcLW/text()" index="true"  />	
  		<cdm-lexeme-source xpath="/database/lexGroup/lexSrcW/text()" index="true"  />	
  		<cdm-pos-translation xpath="/database/lexGroup/tradFlexGroup/catF/text()" index="true"  />	
  		<cdm-synonyme xpath="/database/lexGroup/synW/text()" index="true"  />	
  		<cdm-homonyme xpath="/database/lexGroup/homW/text()" index="true"  />	
  		<cdm-note-usage xpath="/database/lexGroup/nusW/text()" index="true"  />	
  		<cdm-derive-bloc xpath="/database/lexGroup/exDerWGroup" index="true"  />	
  		<cdm-expression-derive xpath="/database/lexGroup/exDerW/text" index="true"  />	
  		<cdm-source-definition xpath="/database/lexGroup/defWGroup/srcDW/text()" index="true"  />	

my $nomDicoDepart = 'Thierno';

my $cdmvolumedepart = $CDMSDEPART[cdm-voume];
my $cdmvolumearrivee = $CDMSARRIVE[cdm-voume];

my $cdmentrydepart = $CDMSDEPART[cdm-entry]
my $cdmentryarrivee = $CDMSARRIVE[cdm-entry];

my $cdmheadworddepart = $CDMSDEPART[cdm-headword];
my $cdmheadwordarrivee = $CDMSARRIVE[cdm-headword];

my $cdmsourceheadworddepart = $CDMSDEPART[cdm-source-mot-vedette];
my $cdmsourceheadwordarrivee = $CDMSARRIVE[cdm-source-mot-vedette];


my $cdmlexemesourcedepart = $CDMSDEPART[cdm-lexeme-source];
my $cdmlexemesourcearrivee = $CDMSARRIVE[cdm-lexeme-source];



my $cdmprononciationdepart=$CDMSDEPART[cdm-pronunciation];
my $cdmprononciationarrivee=$CDMSARRIVE[cdm-pronunciation];

my $cdmcatdepart=$CDMSDEPART[cdm-pos];
my $cdmcatarrivee=$CDMSARRIVE[cdm-pos];

my $cdmclassWdepart=$CDMSDEPART[cdm-classe-nominale];
my $cdmclassWarrivee=$CDMSARRIVE[cdm-classe-nominale];

my $cdmvariantdepart=$CDMSDEPART[cdm-headword-variant];
my $cdmvariantarrivee=$CDMSARRIVE[cdm-headword-variant]

my $cdmderivedepart=$CDMSDEPART[cdm-expression-derive];
my $cdmderivearrivee=$CDMSARRIVE[cdm-expression-derive];

my $cdmblocderivedepart=$CDMSDEPART[cdm-derive-bloc;
my $cdmblocderivearrivee=$CDMSARRIVE[cdm-derive-bloc];

my $cdmderivedepart=$CDMSDEPART[cdm-expression-derive];
my $cdmderivearrivee=$CDMSARRIVE[cdm-expression-derive];



my $cdmsynonymedepart=$CDMSDEPART[cdm-synonyme]
my $cdmsynonymearrivee=$CDMSARRIVE[cdm-synonyme];

my $cdmhomonymedepart=$CDMSDEPART[cdm-homonyme;
my $cdmhomonymearrivee=$CDMSARRIVE[cdm-homonyme];


my $cdmdefinitiondepart=$CDMSDEPART[cdm-definition];
my $cdmdefinitionarrivee=$CDMSARRIVE[cdm-definition];

my $cdmsourcedefinitiondepart=$CDMSDEPART[cdm-source-definition];
my $cdmsourcedefinitionarrivee=$CDMSARRIVE[cdm-source-definition];

my $cdmtranslationdepart=$CDMSDEPART[cdm-translation];
my $cdmtranslationarrivee=$CDMSARRIVE[cdm-translation];

my $cdmcattradfrenchdepart=$CDMSDEPART[cdm-pos-translation];
my $cdmcattradfrencharrivee=$CDMSARRIVE[cdm-pos-translation];

my $cdmwolofexempledepart='/database/lexGroup/phrWGroup/phrW/text()';
my $cdmwolofexemplearrivee='/volume/article/bloc_sens/sens/exemples/exemple/exemple-wol/text()';

my $cdmfrenchexempledepart='/database/lexGroup/phrWGroup/tradPhrW/text()';
my $cdmfrenchexemplearrivee='/volume/article/bloc_sens/sens/exemples/exemple/exemple-fra/text()';

my $headerdepart = xpath2opentag($cdmvolumedepart);
my $footerdepart = xpath2closedtag($cdmvolumedepart);


#my $cdmvolumearrivee='/volume';
#my $cdmentryaarivee='/volume/article';
#my $cdmentrid='/volume/article/@id';
#my $cdmvariantarrivee='/volume/article/variante/text()';
#my $cdmgrammaticalearrivee='/volume/article/catégorie_grammaticale/text()';
#my $cdmnomminalearrivee='/volume/article/classe_nominale/text()';
#my $cdm_sens_bloc='/volume/article/bloc_sens';
#my $cdmsens='/volume/article/sens';
#my $cdmsensid='/volume/article/bloc_sens/sens/@id';
#my $cdmdefinition='/volume/article/bloc_sens/sens/définition/text()';
#my $cdmtranslation='/volume/article/bloc_sens/sens/bloc_traduction/tranduction_française/text()';
#my $cdm_exemple_bloc='/volume/article/bloc_sens/sens/exemples';
#my $cdmwolofexemple='/volume/article/sens/exemples/exemple/wol/text()';
#my $cdmfrenchexemple='/volume/article/sens/exemples/exemple/fra/text()';


my $closedtagentryarrivee = xpath2closedtag(xpathdifference($cdmentrydepart,$cdmvolumedepart));
my $opentagvolumearrivee = xpath2opentag($cdmvolumearrivee, 'creation-date="' . $date . '"');
my $closedtagvolumearrivee = xpath2closedtag($cdmvolumearrivee);

$/ = $closedtagentryarrivee;

my $parser= XML::DOM::Parser->new();

print $OUTFILE '<?xml version="1.0" encoding="UTF-8" ?>
';
print $OUTFILE $opentagvolumearrivee,"\n";

while( my $line = <$INFILE>)  {   

	$line = $headerdepart . $line . $footerdepart;
	print STDERR "Entrée : ",$line;

	my $docdepart = $parser->parse ($line);
	print STDERR "xmlarrivee : ",$xmlarrivee;
	my $docarrivee = $parser->parse ($xmlarrivee);

&copiePointeurs($cdmheadworddepart, $cdmheadwordarrivee, $docdepart, $docarrivee);

&copiePointeurs($cdmsourceheadworddepart, $cdmsourceheadwordarrivee, $docdepart, $docarrivee);

&copiePointeurs($cdmlexemesourcedepart, $cdmlexemesourcearrivee, $docdepart, $docarrivee);

&copiePointeurs($cdmprononciationdepart, $cdmprononciationarrivee, $docdepart, $docarrivee);

&copiePointeurs($cdmcatdepart, $cdmcatarrivee, $docdepart, $docarrivee);

&copiePointeurs($cdmclassWdepart, $cdmclassWarrivee, $docdepart, $docarrivee);

&copiePointeurs($cdmdefinitiondepart, $cdmdefinitionarrivee, $docdepart, $docarrivee);

&copiePointeurs($cdmsourcedefinitiondepart, $cdmsourcedefinitionarrivee, $docdepart, $docarrivee);
  
&copiePointeurs($cdmtranslationdepart, $cdmtranslationarrivee, $docdepart, $docarrivee);

&copiePointeurs($cdmcattradfrenchdepart, $cdmcattradfrencharrivee, $docdepart, $docarrivee);

&copiePointeurs($cdmwolofexempledepart, $cdmwolofexemplearrivee, $docdepart, $docarrivee);

&copiePointeurs($cdmfrenchexempledepart, $cdmfrenchexemplearrivee, $docdepart, $docarrivee);

&copiePointeurs($cdmvariantdepart, $cdmvariantarrivee, $docdepart, $docarrivee);

&copiePointeurs($cdmsynonymedepart, $cdmsynonymearrivee, $docdepart, $docarrivee);

&copiePointeurs($cdmderivedepart, $cdmderivearrivee, $docdepart, $docarrivee);

&copiePointeurs($cdmhomonymedepart, $cdmhomonymearrivee, $docdepart, $docarrivee);


my @entryarrivee = $docarrivee->findnodes($cdmentryarrivee);
my $entryarrivee = $entryarrivee[0];

# copie de l'entrée source dans l'entrée arrivée

my @entrydepart = $docdepart->findnodes($cdmentrydepart);
my $entrydepart = $entrydepart[0];

my $elementsource = $docarrivee->createElement('entree-source');
$elementsource->setAttribute('provenance',$nomDicoDepart);
my $cloneEntrydepart = $entrydepart->cloneNode(1);
$cloneEntrydepart->setOwnerDocument($docarrivee);
$elementsource->appendChild($cloneEntrydepart);
	$entryarrivee->appendChild($elementsource);
	print $OUTFILE $entryarrivee->toString,"\n";
}

print $OUTFILE $closedtagvolumearrivee;


sub xpathdifference{
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

sub xpath2opentag {
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

sub xpath2closedtag {
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

sub getNodeText {
	my $node = $_[0];
	my $text = '';
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
	return $text;
}


#cette fonction permet de récupérer les pointeurs cdm à partir du fichier metada.


sub load_cdm {
    my ($fichier)=@_;
  open (IN,$fichier);
  my %dico=();
  while(my $ligne=<IN>){
      
      if($ligne=~/^\s*<(\S+)\s+xpath=\"([^\"]+[(\sd:lang=\"w+\"\")]?)/gi){
           my $cdm=$1; my $xpath=$2; 
           $dico{$cdm}=$xpath;
      }
  }
  return %dico;
}

sub copiePointeurs {
	my $pointeurDepart = $_[0];
	my $pointeurArrivee = $_[1];
	my $docDepart = $_[2];
	my $docArrivee = $_[3];
	
	my @valeurs = $docDepart->findnodes($pointeurDepart);
	$pointeurArrivee =~ s/\/text\(\)$//;

	my @noeudsArrivee = $docArrivee->findnodes($pointeurArrivee);
	my $noeudArrivee = $noeudsArrivee[0];

	if (!$noeudArrivee) {
		print STDERR "$pointeurArrivee gives null value\n";
	}
	else {
		my $noeudParent = $noeudArrivee->getParentNode();
		my $noeudSuivant = $noeudArrivee->getNextSibling();
		if (scalar(@valeurs)>0) 	{$noeudParent->removeChild($noeudArrivee);}
		foreach my $valeur (@valeurs) {
			my $noeudClone = $noeudArrivee->cloneNode(1);
			$noeudClone->setOwnerDocument($docArrivee);
			my $noeudTexte = getNodeText($valeur);
			$noeudClone->addText($noeudTexte);
			# si la variante a un noeud suivant
			if ($noeudSuivant) {
				$noeudParent->insertBefore($noeudClone,$noeudSuivant);
			}
			else {
			# sinon
			$noeudParent->appendChild($noeudClone);
			}
		}
	}
}