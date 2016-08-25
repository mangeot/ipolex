#!/usr/bin/perl
#
# transformation.pl
#

use strict;
use warnings;
use utf8::all;

use XML::DOM::XPath;

my $xmldepart = '<?xml version="1.0" ?>
<database toolboxdatabasetype="Dic_Wol" wrap="400" toolboxversion="1.6.1 Jun 2013" toolboxwrite="export">
<lexGroup>
<lex>aada</lex>
<uttW>a:dɐ</uttW>
<catWGroup>
<catW>turu bokkaale</catW>
<clasW>j-</clasW>
</catWGroup>
<defWGroup>
<defW>li aw xeet cosaanoo di ko def</defW>
</defWGroup>
<tradFlexGroup>
<tradFlex>coutumes</tradFlex>
<catF>nom</catF>
</tradFlexGroup>
<phrWGroup>
<phrW>Sunu aada day bañ foot àllarba</phrW>
<tradPhrW>Nos coutumes nous interdisent de faire le linge le mercredi</tradPhrW>
</phrWGroup>
<aut>MTC</aut>
<dat>02/Sep/2007</dat>
</lexGroup>
</database>';

my $xmlarrivee = '<?xml version="1.0" ?>
<volume>
  <article id="">
    <bloc_forme>
      <mot_vedette/>
      <prononciation/>
    </bloc_forme>
    <catégorie_grammaticale/>
    <classe_nominale/>
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
      <exemple>
      </exemples>
      <synonyme/>
      <homonyme/>
      <note_usage/>
    </sens>
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

my $cdmheadworddepart = '/database/lexGroup/lex/text()';
my $cdmheadwordarrivee = '/volume/article/bloc_forme/mot_vedette/text()';
my $cdmprononciationarrivee='/volume/article/bloc_forme/prononciation/text()';
my $cdmvolumearrivee='/volume';
my $cdmentryaarivee='/volume/article';
my $cdmentrid='/volume/article/@id';
my $cdmvariantarrivee='/volume/article/variante/text()';
my $cdmgrammaticalearrivee='/volume/article/catégorie_grammaticale/text()';
my $cdmnomminalearrivee='/volume/article/classe_nominale/text()';
my $cdmsens='/database/article/sens';
my $cdmsensid='/database/article/sens/@id'
my $cdmdefinition='/database/article/sens/définition/text()';
my $cdmtranslation='/volume/article/sens/bloc_traduction/tranduction_française/text()';
my $cdmwolofexemple='/volume/article/sens/exemples/exemple/wol/text()';
my $cdmfrenchexemple='/volume/article/sens/exemples/exemple/fra/text()';



my $parser= XML::DOM::Parser->new();
#my $doc = $parser->parsefile ("file.xml");
my $docdepart = $parser->parse ($xmldepart);
my $docarrivee = $parser->parse ($xmlarrivee);

my $headword = $docdepart->findvalue($cdmheadworddepart);

$cdmheadwordarrivee =~ s/\/text\(\)$//;

my @nodes = $docarrivee->findnodes($cdmheadwordarrivee);
my $headwordNode = $nodes[0];

$headwordNode->addText($headword);

print $docarrivee->toString;

#my @nodes = $doc->findnodes( '/database/lexGroup/lex');
#print $_->getValue, "\n" foreach (@nodes);


#foreach my $node (@nodes) {
#	print $node->firstChild->data,"\n";
#	foreach my $text ($node) {
#		print $text,"\n";
#	}
#}
