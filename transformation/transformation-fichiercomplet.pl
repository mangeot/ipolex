#!/usr/bin/perl
#
# transformation.pl
#

use strict;
use warnings;
use utf8::all;

use XML::DOM;
use XML::DOM::XPath;
use Data::Dumper;

my $encoding = "UTF-8";

binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
#open my $FILE, "<:encoding($encoding)","/opt/lampp/htdocs/ipolex/Dicos/Baat_fra-wol/Baat_wol-fra.xml" or die ("$! IN \n");
#open my $FILE, "<:encoding($encoding)","/opt/lampp/htdocs/ipolex/Dicos/Baat_fra-wol/DicoArrivee_fra-wol/DicoArrivee_wol-fra.metadata" or die ("$! IN \n");
# open (IN,$ARGV[0]);
open my $FILE, "<:encoding($encoding)",$ARGV[0] or die ("$! $ARGV[0] \n");
#open my $OUT, ">:encoding($encoding)","/opt/lampp/htdocs/ipolex/Dicos/Baat_fra-wol/Cisse_wol-fra-transformation.xml" or die ("$! OUT \n");

my $xmlarrivee = '<?xml version="1.0" ?>
<volume>
  <article id="">
    <bloc_forme>
      <mot_vedette/>
      <source_mot_vedette/>
      <lexème_source/>
	  <variante/>
	  <prononciation/>
    </bloc_forme>
    <catégorie_grammaticale/>
    <classe_nominale/>
    <bloc_sens>
    <sens id="">
      <définition/>
      <source_définition/>
      <bloc_traduction>
        <traduction_française/>
        <catégorie_grammaticale_traduction_française_mot_vedette/>
      </bloc_traduction>
      <exemples>
      <exemple>
        <wol/>
        <fra/>
      </exemple>
      </exemples>
      <synonyme/>
      <homonyme/>
      <note_usage/>
    </sens>
    </bloc_sens>
    <bloc_métainformation>
      <auteur/>
      <date_dernière_modification/>
      <commentaire/>
      <auteur_statut_fiche/>
      <statut_fiche/>
    </bloc_métainformation>
    <bloc_dérivés>
      <expression_dérivée/>
    </bloc_dérivés>
    </article>
</volume>';


my $cdmvolumedepart = '/database';
my $cdmvolumearrivee = '/volume';

my $cdmentrydepart = '/database/lexGroup';
my $cdmentryarrivee = '/volume/article';

my $cdmheadworddepart = '/database/lexGroup/lex/text()';
my $cdmheadwordarrivee = '/volume/article/bloc_forme/mot_vedette/text()';

my $cdmsourceheadworddepart = '/database/lexGroup/srcLW/text()';
my $cdmsourceheadwordarrivee = '/volume/article/bloc_forme/source_mot_vedette/text()';


my $cdmlexemesourcedepart = '/database/lexGroup/lexSrcW/text()';
my $cdmlexemesourcearrivee = '/volume/article/bloc_forme/lexème_source/text()';



my $cdmprononciationdepart='/database/lexGroup/uttW/text()';
my $cdmprononciationarrivee='/volume/article/bloc_forme/prononciation/text()';

my $cdmcatdepart='/database/lexGroup/catWGroup/catW/text()';
my $cdmcatarrivee='/volume/article/catégorie_grammaticale/text()';

my $cdmclassWdepart='/database/lexGroup/catWGroup/clasW/text()';
my $cdmclassWarrivee='/volume/article/classe_nominale/text()';

my $cdmvariantdepart='/database/lexGroup/varW/text()';
my $cdmvariantarrivee='/volume/article/bloc_forme/variante/text()';

my $cdmderivedepart='/database/lexGroup/exDerW/text()';
my $cdmvderivearrivee='/volume/article/bloc_dérivés/expression_dérivée/text()';


my $cdmsynonymedepart='/database/lexGroup/synW/text()';
my $cdmsynonymearrivee='/volume/article/bloc_sens/sens/synonyme/text()';

my $cdmhomonymedepart='/database/lexGroup/homW/text()';
my $cdmhomonymearrivee='/volume/article/bloc_sens/sens/homonyme/text()';


my $cdmdefinitiondepart='/database/lexGroup/defWGroup/defW/text()';
my $cdmdefinitionarrivee='/volume/article/bloc_sens/sens/définition/text()';

my $cdmsourcedefinitiondepart='/database/lexGroup/defWGroup/srcDW/text()';
my $cdmsourcedefinitionarrivee='/volume/article/bloc_sens/sens/définition/source_defintion/text()';

my $cdmtranslationdepart='/database/lexGroup/tradFlexGroup/tradFlex/text()';
my $cdmtranslationarrivee='/volume/article/bloc_sens/sens/bloc_traduction/traduction_française/text()';

my $cdmcattradfrenchdepart='/database/lexGroup/tradFlexGroup/catF/text()';
my $cdmcattradfrencharrivee='/volume/article/bloc_sens/sens/bloc_traduction/catégorie_grammaticale_traduction_française_mot_vedette/text()';

my $cdmwolofexempledepart='/database/lexGroup/phrWGroup/phrW/text()';
my $cdmwolofexemplearrivee='/volume/article/bloc_sens/sens/exemples/exemple/wol/text()';

my $cdmfrenchexempledepart='/database/lexGroup/phrWGroup/tradPhrW/text()';
my $cdmfrenchexemplearrivee='/volume/article/bloc_sens/sens/exemples/exemple/fra/text()';

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
my $opentagvolumearrivee = xpath2opentag($cdmvolumearrivee);
my $closedtagvolumearrivee = xpath2closedtag($cdmvolumearrivee);

$/ = $closedtagentryarrivee;

my $parser= XML::DOM::Parser->new();

print STDOUT '<?xml version="1.0" encoding="UTF-8" ?>
';
print $opentagvolumearrivee,"\n";

while( my $line = <$FILE>)  {   

	#my $doc = $parser->parsefile ("file.xml");
	$line = $headerdepart . $line . $footerdepart;
	print STDERR "Entrée : ",$line;

	my $docdepart = $parser->parse ($line);
	my $docarrivee = $parser->parse ($xmlarrivee);


	my $headword = $docdepart->findvalue($cdmheadworddepart);
	my $sourceheadword= $docdepart->findvalue($cdmsourceheadworddepart);
	my $lexemesource= $docdepart->findvalue($cdmlexemesourcedepart);
	my $prononciation=$docdepart->findvalue($cdmprononciationdepart);
	my $cat=$docdepart->findvalue($cdmcatdepart);
	my $classW=$docdepart->findvalue($cdmclassWdepart);
  my $definition=$docdepart->findvalue($cdmdefinitiondepart);
   my $sourcedefinition=$docdepart->findvalue($cdmsourcedefinitiondepart);
  my $translation=$docdepart->findvalue($cdmtranslationdepart);
  my $cattrad=$docdepart->findvalue($cdmcattradfrenchdepart);
my $wolexemple=$docdepart->findvalue($cdmwolofexempledepart);
my $frenchexemple=$docdepart->findvalue($cdmfrenchexempledepart);
my @variantes = $docdepart->findnodes($cdmvariantdepart);
my @derivees = $docdepart->findnodes($cdmderivedepart);
my @synonymes=$docdepart->findnodes($cdmsynonymedepart);
my $homonyme=$docdepart->findvalue($cdmhomonymedepart);
	$cdmheadwordarrivee =~ s/\/text\(\)$//;
	$cdmsourceheadwordarrivee =~ s/\/text\(\)$//;
	$cdmlexemesourcearrivee =~ s/\/text\(\)$//;
	$cdmprononciationarrivee =~ s/\/text\(\)$//;
	$cdmcatarrivee =~ s/\/text\(\)$//;
	$cdmclassWarrivee =~ s/\/text\(\)$//;
  $cdmdefinitionarrivee=~ s/\/text\(\)$//;
   $cdmsourcedefinitionarrivee=~ s/\/text\(\)$//;
  $cdmtranslationarrivee=~ s/\/text\(\)$//;
    $cdmcattradfrencharrivee=~ s/\/text\(\)$//;
   $cdmwolofexemplearrivee=~ s/\/text\(\)$//;
   $cdmfrenchexemplearrivee=~ s/\/text\(\)$//;
 $cdmvariantarrivee=~ s/\/text\(\)$//;
  $cdmvderivearrivee=~ s/\/text\(\)$//;
  $cdmsynonymearrivee=~ s/\/text\(\)$//;
  $cdmhomonymearrivee=~ s/\/text\(\)$//;


	my @nodes = $docarrivee->findnodes($cdmheadwordarrivee);
	my $headwordNode = $nodes[0];
     $headwordNode->addText($headword);

     my @sourceheadwordnodes = $docarrivee->findnodes($cdmsourceheadwordarrivee);
	my $sourceheadwordNode = $sourceheadwordnodes[0];
     $sourceheadwordNode->addText($sourceheadword);


    my @lexemesourcenodes = $docarrivee->findnodes($cdmlexemesourcearrivee);
	my $lexemesourceNode = $lexemesourcenodes[0];
     $lexemesourceNode->addText($lexemesource);

	my @nodesbis = $docarrivee->findnodes($cdmprononciationarrivee);
	my $prononciationNode = $nodesbis[0];

	$prononciationNode->addText($prononciation);

	my @nodecat = $docarrivee->findnodes($cdmcatarrivee);
	my $catNode = $nodecat[0];

	$catNode->addText($cat);



	my @nodeclassW = $docarrivee->findnodes($cdmclassWarrivee);
	my $classWnode = $nodeclassW[0];

	$classWnode->addText($classW);

  my @nodedef = $docarrivee->findnodes($cdmdefinitionarrivee);
  my $defNode = $nodedef[0];

  $defNode->addText($definition);

  my @sourcedefinitionnode = $docarrivee->findnodes($cdmsourcedefinitionarrivee);
  my $sourcedefinitionNode = $nodedef[0];

  $sourcedefinitionNode->addText($sourcedefinition);

  my @nodetranslation = $docarrivee->findnodes($cdmtranslationarrivee);
  my $translationNode = $nodetranslation[0];

  $translationNode->addText($translation);

  my @nodecattrad = $docarrivee->findnodes($cdmcattradfrencharrivee);
  my $cattradNode = $nodecattrad[0];

  $cattradNode->addText($cattrad);


my @nodewolexemple = $docarrivee->findnodes($cdmwolofexemplearrivee);
 my $wolexempleNode = $nodewolexemple[0];

 $wolexempleNode->addText($wolexemple);


my @nodefrenchexemple = $docarrivee->findnodes($cdmfrenchexemplearrivee);
my $frenchexempleNode = $nodefrenchexemple[0];

 $frenchexempleNode->addText($frenchexemple);





my @nodevariante = $docarrivee->findnodes($cdmvariantarrivee);
my $varianteNode = $nodevariante[0];

	my $parentVariante = $varianteNode->getParentNode();
	my $noeudSuivantVariante = $varianteNode->getNextSibling();
	if (scalar(@variantes)>0) 	{$parentVariante->removeChild($varianteNode);}
	foreach my $variante (@variantes) {
		my $noeudClone = $varianteNode->cloneNode(1);
		$noeudClone->setOwnerDocument($docarrivee);
		my $varianteText = getNodeText($variante);
		$noeudClone->addText($varianteText);
		# si la variante a un noeud suivant
		if ($noeudSuivantVariante) {
			$parentVariante->insertBefore($noeudClone,$noeudSuivantVariante);
		}
		else {
		# sinon
		$parentVariante->appendChild($noeudClone);
		}
	}



my @nodesynonyme = $docarrivee->findnodes($cdmsynonymearrivee);
my $synonymeNode = $nodesynonyme[0];

	my $parentSynonyme = $synonymeNode->getParentNode();
	my $noeudSuivantSynonyme = $synonymeNode->getNextSibling();
	if (scalar(@synonymes)>0) 	{$parentSynonyme->removeChild($synonymeNode);}
	foreach my $synonyme (@synonymes) {
		my $noeudCloneSyn = $synonymeNode->cloneNode(1);
		$noeudCloneSyn->setOwnerDocument($docarrivee);
		my $synonymeText = getNodeText($synonyme);
		$noeudCloneSyn->addText($synonymeText);
		# si la variante a un noeud suivant
		if ($noeudSuivantSynonyme) {
			$parentSynonyme->insertBefore($noeudCloneSyn,$noeudSuivantSynonyme);
		}
		else {
		# sinon
		$parentSynonyme->appendChild($noeudCloneSyn);
		}
	}


my @nodesderive = $docarrivee->findnodes($cdmvderivearrivee);
my $deriveNode = $nodesderive[0];

	my $parentDerive = $deriveNode->getParentNode();
	my $noeudSuivantDerive = $deriveNode->getNextSibling();
	if (scalar(@derivees)>0) 	{$parentDerive->removeChild($deriveNode);}
	foreach my $derivee (@derivees) {
		my $noeudCloneDer = $deriveNode->cloneNode(1);
		$noeudCloneDer->setOwnerDocument($docarrivee);
		my $deriveText = getNodeText($derivee);
		$noeudCloneDer->addText($deriveText);
		# si la variante a un noeud suivant
		if ($noeudSuivantDerive) {
			$parentDerive>insertBefore($noeudCloneDer,$noeudSuivantDerive);
		}
		else {
		# sinon
		$parentDerive->appendChild($noeudCloneDer);
		}
	}
#my @nodesynonyme = $docarrivee->findnodes($cdmsynonymearrivee);
#my $synonymeNode = $nodesynonyme[0];

 #$synonymeNode->addText($synonyme);


 my @nodehomonyme = $docarrivee->findnodes($cdmhomonymearrivee);
my $homonymeNode = $nodehomonyme[0];

 $homonymeNode->addText($homonyme);

my @entryarrivee = $docarrivee->findnodes($cdmentryarrivee);

my $entryarrivee = $entryarrivee[0];
	# pour imprimer dans un fichier, remplacer STDOUT par $OUT
	#print $OUT $docarrivee->toString;
	print STDOUT $entryarrivee->toString,"\n";
}

print STDOUT $closedtagvolumearrivee;


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
	$xpath =~ s/\/$//;
	$xpath =~ s/\//></g;
	$xpath =~ s/^>//;
	$xpath .= '>';
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