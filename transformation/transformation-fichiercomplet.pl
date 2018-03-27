#!/usr/bin/perl
#
# ./transformation-fichiercomplet.pl -i Donnees/anaan.xml -o 'Thierno' -m Donnees/Baat_fra-wol/Baat_wol_fra-metadata.xml -s Donnees/Baat_fra-wol/DicoArrivee_wol_fra-metadata.xml -t Donnees/Baat_fra-wol/dicoarrivee_wol_fra-template.xml > out.xml
# ./transformation-fichiercomplet.pl -i Donnees/Baat_fra-wol/baat_wol_fra-prep.xml  -m Donnees/Baat_fra-wol/Baat_wol_fra-metadata.xml -n Donnees/Baat_fra-wol/DicoArrivee_wol_fra-metadata.xml -t Donnees/Baat_fra-wol/dicoarrivee_wol_fra-template.xml > out.xml
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
my $nomDicoDepart = '';
my ($metaEntree, $metaSortie, $entreeModele, $fichierEntree, $fichierSortie, $help, $verbeux) = ();

GetOptions( 
  'entree|in|from|i=s' => \$fichierEntree, 
  'sortie|out|to|o=s'           => \$fichierSortie, 
  'metaentree|min|m=s' => \$metaEntree, 
  'metasortie|mout|s=s'           => \$metaSortie, 
  'modele|template|t=s'           => \$entreeModele, 
  'nom|name|n=s' 	=> \$nomDicoDepart, 
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
if (! ($entreeModele && $metaEntree && $metaSortie)) {&help;};
if (defined $help) {&help;};

binmode(STDERR, ":utf8");

sub help {
	print STDERR "Message d'aide, voir V_for_fusionInterne.pl pour exemple\n";
	exit 0;
}

open my $INFILE, "<:encoding($encoding)",$fichierEntree or die ("$! $fichierEntree \n");

open my $MODELEFILE, "<:encoding($unicode)", $entreeModele or die "error opening $entreeModele: $!";

#print STDERR "load cdm depart:\n";
my %CDMSDEPART=load_cdm($metaEntree);
#print STDERR "load cdm arrivee:\n";
my %CDMSARRIVEE=load_cdm($metaSortie);



my $xmlarrivee = do { local $/; <$MODELEFILE> };

#print STDERR "XMLarrivée : [",$xmlarrivee,"]",$entreeModele;

my $cdmvolumedepart = delete($CDMSDEPART{'cdm-volume'});
my $cdmvolumearrivee = delete($CDMSARRIVEE{'cdm-volume'});

my $cdmentrydepart = delete($CDMSDEPART{'cdm-entry'});
my $cdmentryarrivee = delete($CDMSARRIVEE{'cdm-entry'});

my $cdmheadworddepart = $CDMSDEPART{'cdm-headword'};
print STDERR "cdm : $cdmheadworddepart\n";

my $headerdepart = xpath2opentag($cdmvolumedepart);
my $footerdepart = xpath2closedtag($cdmvolumedepart);


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

	my $docdepart = $parser->parse ($line);
	my $docarrivee = $parser->parse ($xmlarrivee);
	
	my @headwords = $docdepart->findnodes($cdmheadworddepart);
	my $headword = getNodeText($headwords[0]);
	print STDERR "Transformation article : $headword\n";

	
	foreach my $pointeur (keys %CDMSDEPART) {
    	my $cdmdepart = $CDMSDEPART{$pointeur};
    	my $cdmarrivee = $CDMSARRIVEE{$pointeur};
    	if ($cdmarrivee) {
			&copiePointeurs($cdmdepart, $cdmarrivee, $docdepart, $docarrivee);
    	}
	}

#	print STDERR "fin des copiePointeurs\n";

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
#	print STDERR "Fin transformation article\n";
}
#print STDERR "Fin transformation fichier\n";
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
  open (IN, "<:encoding($unicode)", $fichier);
  my %dico=();
  while(my $ligne=<IN>){
      # attention, il faut prendre tout ce qui n'est pas " et '
      if ($ligne=~/^\s*<(\S+)\s+xpath=["']([^"]+)["']/){
           my $cdm=$1; my $xpath=$2; 
#           print STDERR 'cdm: ',$cdm,' xpath:',$xpath,"\n";
           $dico{$cdm}=$xpath;
      }
  }
  close(IN);
  return %dico;
}

sub copiePointeurs {
	my $pointeurDepart = $_[0];
	my $pointeurArrivee = $_[1];
	my $docDepart = $_[2];
	my $docArrivee = $_[3];
	
	# ATTENTION : supprimer le / final sinon le module xpath bugue !
	$pointeurDepart =~ s/\/$//;
	$pointeurArrivee =~ s/\/$//;
	$pointeurArrivee =~ s/\/text\(\)$//;
	print STDERR 'cdmd: ', $pointeurDepart, ' cdma: ', $pointeurArrivee,"\n";
	my @valeurs = $docDepart->findnodes($pointeurDepart);

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
			my $noeudTexte = getNodeText($valeur);
			my $noeudClone = $noeudArrivee->cloneNode(1);
			$noeudClone->setOwnerDocument($docArrivee);
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