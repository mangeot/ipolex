#!/usr/bin/perl
#
# transformation.pl
#

use strict;
use warnings;
use utf8::all;

use XML::DOM::XPath;

my $encoding = "UTF-8";

binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
#open my $FILE, "<:encoding($encoding)","/opt/lampp/htdocs/ipolex/Dicos/Baat_fra-wol/Baat_wol-fra.xml" or die ("$! IN \n");
#open my $FILE, "<:encoding($encoding)","/opt/lampp/htdocs/ipolex/Dicos/Baat_fra-wol/DicoArrivee_fra-wol/DicoArrivee_wol-fra.metadata" or die ("$! IN \n");
open my $FILE, "<:encoding($encoding)","../Donnees/Baat_fra-wol/baat_wol_fra-prep.xml" or die ("$! IN \n");
#open my $OUT, ">:encoding($encoding)","/opt/lampp/htdocs/ipolex/Dicos/Baat_fra-wol/Cisse_wol-fra-transformation.xml" or die ("$! OUT \n");

my $xmlarrivee = '<?xml version="1.0" ?>
<volume>
  <article id="">
    <bloc_forme>
      <mot_vedette/>
      <prononciation/>
    </bloc_forme>
    <catégorie_grammaticale/>
    <classe_nominale/>
    <variant/>
    <bloc_sens>
    <sens id="">
      <définition/>
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
      <dérivé/>
      <lexème_source_expression_dérivée/>
    </bloc_dérivés>
    </article>
</volume>';


my $cdmvolumedepart = '/database';
my $cdmvolumearrivee = '/volume';

my $cdmentrydepart = '/database/lexGroup';
my $cdmentryarrivee = '/volume/article';

my $cdmheadworddepart = '/database/lexGroup/lex/text()';
my $cdmheadwordarrivee = '/volume/article/bloc_forme/mot_vedette/text()';

my $cdmprononciationdepart='/database/lexGroup/uttW/text()';
my $cdmprononciationarrivee='/volume/article/bloc_forme/prononciation/text()';

my $cdmcatdepart='/database/lexGroup/catWGroup/catW/text()';
my $cdmcatarrivee='/volume/article/catégorie_grammaticale/text()';

my $cdmclassWdepart='/database/lexGroup/catWGroup/clasW/text()';
my $cdmclassWarrivee='/volume/article/classe_nominale/text()';

my $cdmvariantdepart='/database/lexGroup/variant/text()';
my $cdmvariantarrivee='/volume/article/variant/text()';

my $cdmsynonymedepart='/database/lexGroup/variante/text()';
my $cdmsynonymearrivee='/volume/article/bloc_sens/sens/synonyme/text()';

my $cdmhomonymedepart='/database/lexGroup/homo/text()';
my $cdmhomonymearrivee='/volume/article/bloc_sens/sens/homonyme/text()';


my $cdmdefinitiondepart='/database/lexGroup/defWGroup/defW/text()';
my $cdmdefinitionarrivee='/volume/article/bloc_sens/sens/définition/text()';

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
	my $prononciation=$docdepart->findvalue($cdmprononciationdepart);
	my $cat=$docdepart->findvalue($cdmcatdepart);
	my $classW=$docdepart->findvalue($cdmclassWdepart);
  my $definition=$docdepart->findvalue($cdmdefinitiondepart);
  my $translation=$docdepart->findvalue($cdmtranslationdepart);
  my $cattrad=$docdepart->findvalue($cdmcattradfrenchdepart);
my $wolexemple=$docdepart->findvalue($cdmwolofexempledepart);
my $frenchexemple=$docdepart->findvalue($cdmfrenchexempledepart);
my $variant=$docdepart->findvalue($cdmvariantdepart);
my $synonyme=$docdepart->findvalue($cdmsynonymedepart);
my $homonyme=$docdepart->findvalue($cdmhomonymedepart);
	$cdmheadwordarrivee =~ s/\/text\(\)$//;
	$cdmprononciationarrivee =~ s/\/text\(\)$//;
	$cdmcatarrivee =~ s/\/text\(\)$//;
	$cdmclassWarrivee =~ s/\/text\(\)$//;
  $cdmdefinitionarrivee=~ s/\/text\(\)$//;
  $cdmtranslationarrivee=~ s/\/text\(\)$//;
    $cdmcattradfrencharrivee=~ s/\/text\(\)$//;
   $cdmwolofexemplearrivee=~ s/\/text\(\)$//;
   $cdmfrenchexemplearrivee=~ s/\/text\(\)$//;
 $cdmvariantarrivee=~ s/\/text\(\)$//;
  $cdmsynonymearrivee=~ s/\/text\(\)$//;
  $cdmhomonymearrivee=~ s/\/text\(\)$//;


	my @nodes = $docarrivee->findnodes($cdmheadwordarrivee);
	my $headwordNode = $nodes[0];

	$headwordNode->addText($headword);

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




my @nodevariant = $docarrivee->findnodes($cdmvariantarrivee);
my $variantNode = $nodevariant[0];

 $variantNode->addText($variant);



my @nodesynonyme = $docarrivee->findnodes($cdmsynonymearrivee);
my $synonymeNode = $nodesynonyme[0];

 $synonymeNode->addText($synonyme);


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