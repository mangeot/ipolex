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
</defWGroup>,
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

my $xmlarriveeavecmetadata = '<?xml version="1.0" ?>
<volume>
  <d:contribution
    xmlns:d="http://www-clips.imag.fr/geta/services/dml"    d:contribid="jpn.??.3736834.c"    d:originalcontribid="jpn.??.3736834.c">
    <d:metadata>
      <d:author></d:author>
      <d:groups/>
      <d:creation-date></d:creation-date>
      <d:finition-date/>
      <d:review-date/>
      <d:reviewer/>
      <d:validation-date/>
      <d:validator/>
      <d:status></d:status>
      <d:history>
        <d:modification>
          <d:author/>
          <d:date/>
          <d:comment/>
        </d:modification>
      </d:history>
      <d:previous-contribution/>
      <d:previous-classified-finished-contribution/>
    </d:metadata>
    <d:data>
   <article id="">
    <bloc_forme>
      <mot_vedette/>
      <prononciation/>
    </bloc_forme>
    <catégorie_grammaticale/>
    <classe_nominale/>
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
    </d:data>
  </d:contribution>
</volume>';
  

my $cdmheadworddepart = '/database/lexGroup/lex/text()';
my $cdmheadwordarrivee = '/volume/article/bloc_forme/mot_vedette/text()';

my $cdmprononciationdepart='/database/lexGroup/uttW/text()';
my $cdmprononciationarrivee='/volume/article/bloc_forme/prononciation/text()';

my $cdmcatdepart='/database/lexGroup/catWGroup/catW/text()';
my $cdmcatarrivee='/volume/article/catégorie_grammaticale/text()';

my $cdmclassWdepart='/database/lexGroup/catWGroup/clasW/text()';
my $cdmclassWarrivee='/volume/article/classe_nominale/text()';




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



my $parser= XML::DOM::Parser->new();
#my $doc = $parser->parsefile ("file.xml");
my $docdepart = $parser->parse ($xmldepart);
my $docarrivee = $parser->parse ($xmlarrivee);


my $headword = $docdepart->findvalue($cdmheadworddepart);
my $prononciation=$docdepart->findvalue($cdmprononciationdepart);
my $cat=$docdepart->findvalue($cdmcatdepart);
my $classW=$docdepart->findvalue($cdmclassWdepart);



$cdmheadwordarrivee =~ s/\/text\(\)$//;
$cdmprononciationarrivee =~ s/\/text\(\)$//;
$cdmcatarrivee =~ s/\/text\(\)$//;
$cdmclassWarrivee =~ s/\/text\(\)$//;

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


print $docarrivee->toString;

#my @nodes = $doc->findnodes( '/database/lexGroup/lex');
#print $_->getValue, "\n" foreach (@nodes);


#foreach my $node (@nodes) {
#	print $node->firstChild->data,"\n";
#	foreach my $text ($node) {
#		print $text,"\n";
#	}
#}
