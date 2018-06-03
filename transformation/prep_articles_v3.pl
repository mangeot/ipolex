#!/usr/bin/perl -w

use XML::Twig;
use utf8::all;


my $xml = '<volume><article id="">      <bloc_forme>        <mot_vedette>a</mot_vedette>        <prononciation/>      </bloc_forme>      <catégorie_grammaticale>gr</catégorie_grammaticale>      <bloc_sens>        <sens id="">          <définition/>          <bloc_traduction>          <traduction_française>/a/ peut servir de voyelle de liaison entre le verbe et son complément</traduction_française>          <catégorie_grammaticale_traduction_française_mot_vedette/>            <lien_traduction id="" lang="" type="" volume=""/>          </bloc_traduction>          <exemples>            <exemple>              <exemple-srr/>               <exemple-fra/>            </exemple>          </exemples>        </sens>      </bloc_sens>      <sources>        <entree-source provenance="CrétoisDDL"><article>     <mot_vedette>a</mot_vedette>     <traductions_françaises><traduction>/a/ peut servir de voyelle de liaison entre le verbe et son complément</traduction></traductions_françaises>     <catégorie_grammaticale>gr</catégorie_grammaticale>    </article>
</entree-source>      </sources>    </article>
  <article id="">      <bloc_forme>        <mot_vedette>d</mot_vedette>        <prononciation/>      </bloc_forme>      <catégorie_grammaticale/>      <bloc_sens>        <sens id="">          <définition/>          <bloc_traduction>          <traduction_française>Dans les verbes à radical redoublé, /a/ est euphonique</traduction_française>          <catégorie_grammaticale_traduction_française_mot_vedette/>            <lien_traduction id="" lang="" type="" volume=""/>          </bloc_traduction>          <exemples>            <exemple>              <exemple-srr/>               <exemple-fra/>            </exemple>          </exemples>        </sens>      </bloc_sens>      <sources>        <entree-source provenance="CrétoisDDL"><article>     <mot_vedette>a</mot_vedette>     <traductions_françaises><traduction>Dans les verbes à radical redoublé, /a/ est euphonique</traduction></traductions_françaises>    </article>
</entree-source>      </sources>    </article>
  <article id="">      <bloc_forme>        <mot_vedette>b</mot_vedette>        <prononciation/>      </bloc_forme>      <catégorie_grammaticale>gr</catégorie_grammaticale>      <bloc_sens>        <sens id="">          <définition/>          <bloc_traduction>          <traduction_française>Les adverbes français en /ment/ se forment avec l\'adjectif qualificatif précédé de /a/</traduction_française>          <catégorie_grammaticale_traduction_française_mot_vedette/>            <lien_traduction id="" lang="" type="" volume=""/>          </bloc_traduction>          <exemples>            <exemple>              <exemple-srr/>               <exemple-fra/>            </exemple>          </exemples>        </sens>      </bloc_sens>      <sources>        <entree-source provenance="CrétoisDDL"><article>     <mot_vedette>a</mot_vedette>     <traductions_françaises><traduction>Les adverbes français en /ment/ se forment avec l\'adjectif qualificatif précédé de /a/</traduction></traductions_françaises>     <catégorie_grammaticale>gr</catégorie_grammaticale>    </article>
</entree-source>      </sources>    </article>
  <article id="">      <bloc_forme>        <mot_vedette>c</mot_vedette>        <prononciation/>      </bloc_forme>      <catégorie_grammaticale>det</catégorie_grammaticale>      <bloc_sens>        <sens id="">          <définition/>          <bloc_traduction>          <traduction_française>Joint au pronom subséquent de classe, indique que l\'objet est éloigné [alors que sa position peut être connue] ou qu\'il est indéterminé, par rapport à la personne qui parle</traduction_française>          <catégorie_grammaticale_traduction_française_mot_vedette/>            <lien_traduction id="" lang="" type="" volume=""/>          </bloc_traduction>          <exemples>            <exemple>              <exemple-srr/>               <exemple-fra/>            </exemple>          </exemples>        </sens>      </bloc_sens>      <sources>        <entree-source provenance="CrétoisDDL"><article>     <mot_vedette>a</mot_vedette>     <traductions_françaises><traduction>Joint au pronom subséquent de classe, indique que l\'objet est éloigné [alors que sa position peut être connue] ou qu\'il est indéterminé, par rapport à la personne qui parle</traduction></traductions_françaises>     <catégorie_grammaticale>det</catégorie_grammaticale>    </article>
</entree-source>      </sources>    </article>
  <article id="">      <bloc_forme>        <mot_vedette>a</mot_vedette>        <prononciation/>      </bloc_forme>      <catégorie_grammaticale>gr</catégorie_grammaticale>      <bloc_sens>        <sens id="">          <définition/>          <bloc_traduction>          <traduction_française>/a/ indique, également, que l\'action est passée</traduction_française>          <catégorie_grammaticale_traduction_française_mot_vedette/>            <lien_traduction id="" lang="" type="" volume=""/>          </bloc_traduction>          <exemples>            <exemple>              <exemple-srr/>               <exemple-fra/>            </exemple>          </exemples>        </sens>      </bloc_sens>      <sources>        <entree-source provenance="CrétoisDDL"><article>     <mot_vedette>a</mot_vedette>     <traductions_françaises><traduction>/a/ indique, également, que l\'action est passée</traduction></traductions_françaises>     <catégorie_grammaticale>gr</catégorie_grammaticale>    </article>
</entree-source>      </sources>    </article></volume>';


my $twig= new XML::Twig( twig_roots    => { $ARGV[1] => 1},
                                              # handler will be called for
                                              # $field elements
                         twig_handlers => { $ARGV[1] => \&entry } ); 

                                              # print the result
#$twig->parse($xml);
$twig->parsefile($ARGV[0]);
                                              
sub entry
  { my( $twig, $entry)= @_;                      
	my $string = $entry->sprint;
	$string =~ s/\R/ /gsm;
	print $string,"\n";
    $twig->purge;                             # delete the twig so far   
 }
