#!/usr/bin/perl

## pb : comparaison de bɑɲcoh et bɑŋkāɘt // vérifier les tris et locales
# =======================================================================================================================================
######----- V_for_FusionInterne.pl -----#####
# =======================================================================================================================================
# Auteur : M.MANGEOT
# Version 1.1 
# Dernières modifications : 27 juillet 2012
# Synopsis :  - Fusion interne d'un fichier XML de même structure (type "Mot à Mot"). 
# Les entrées ayant le même mot-vedette sont fusionnées et les identifiants de sens sont recalculés
# Remarques : ATTENTION : le fichier source d'origine doit commencer par <m:entry. Il faut effacer l'en-tête XML et l'élément racine !
#             - Le fichier d'origine doit être préalablement trié (./V_for_Sort.pl)
#             - Il faut ensuite renuméroter les axies
#             - pb : comparaison de bɑɲcoh et bɑŋkāɘt // vérifier les tris et locales
#             - La fusion ne modifie pas les deux fichiers sources
#             - Création d'un journal des exécutions (LOG)
# ---------------------------------------------------------------------------------------------------------------------------------------
# Usage : perl V_for_FusionInterne.pl -v -from source1.xml -to out.xml 
#
# -v : affiche les informations du STDERR
#
# Pour les options avancées :
#
# -date "date" 				 	 : pour spécifier la date (par défaut : la date du jour (localtime)
# -erreur "message d'erreur" 	 : pour spécifier le message d'erreur (ouverture de fichiers)
# -encoding "format d'encodage" : pour spécifier le format d'encodage (par défaut UTF-8)
# -pretty "indentation" 		 : pour spécifier l'indentation XML ('none' ou 'indented', par exemple)
# -locale "locale"				 : pour spécifier la locale (langue source) des ressources qui seront fusionnées
# -help 						 : pour afficher l'aide
# =======================================================================================================================================



# =======================================================================================================================================
###--- METADIRECTIVES ---###
use strict;
use warnings;
use utf8;
use locale;
use IO::File; 
use Getopt::Long; # pour gérer les arguments.

#use Text::StripAccents; # non inclus dans le core de Perl
use XML::Twig; # (non inclus dans le core de Perl), pour le parsing de la source.
#use XML::Twig::XPath;
use XML::Writer; # (non inclus dans le core de Perl), pour le fichier de sortie.

use Unicode::Collate;


binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

use POSIX qw(locale_h setlocale);

# =======================================================================================================================================
###--- PROLOGUE ---###
my $ref_root = 'database'; # la racine (par exemple : <volume> ou <dictionary>).
my $ref_entry = 'article'; # l'élément de référence pour la fusion (pour MAM : 'entry' par exemple).
my $ref_head = 'bloc_forme';
my $ref_headword = 'mot_vedette'; # le sous-élément à comparer pour la fusion
my $ref_sense = 'sens'; # le sous-élément qui sera récupéré puis inséré.
my $ref_cat='catégorie_grammaticale';#le sous-élément à comparer dans le cas où ontrouve 2 entées de même headword.
# ------------------------------------------------------------------------
##-- Gestion des options --##
my ($date, $FichierOne, $FichierTwo, $FichierResultat, $erreur, $encoding) = ();
my ($verbeux, $help, $pretty_print, $locale) = ();
GetOptions( 
  'date|time|t=s'        	    => \$date, # flag de type -date ou --date, ou -time ou --time, ou -t ou --t (=s : string)
  'source|base|in|one|from|i=s' => \$FichierOne, 
  'sortie|out|to|o=s'           => \$FichierResultat, 
  'erreur|error|e=s'     	  	=> \$erreur, 
  'encodage|encoding|enc|f=s' 	=> \$encoding, 
  'help|h'                	  	=> \$help, 
  'verbeux|v'             	  	=> \$verbeux, 
  'print|pretty|p=s'       	  	=> \$pretty_print, 
  'locale|locale|l=s'				=> \$locale,
  );
 
if (!(defined $date)) {$date = localtime;};
if (!(defined $FichierOne)) {&help;}; # si le fichier source n'est pas spécifié, affichage de l'aide.
if (!(defined $FichierResultat)) {$FichierResultat = "/home/khoule/Documents/dico_v118_fusion.XML";};
if (!(defined $erreur)) {$erreur = "|ERROR| : problem opening file :";};
if (!(defined $encoding)) {$encoding = "UTF-8";};
if (!(defined $pretty_print)) {$pretty_print = "indented";};
if (!(defined $locale)) {$locale = "fr_FR.UTF-8";};
#if (!(defined $locale)) {$locale = "km_KH.UTF-8";};
if (defined $help) {&help;};
 
 setlocale( LC_ALL, $locale);

my $collator = Unicode::Collate::->new();

# ------------------------------------------------------------------------
# Autres variables :
my $count_one = 0; # pour compter les entrées issues de source1.
my $count_two = 0; # idem pour source2.
setlocale(LC_ALL,$locale); # pour indiquer la locale
 

# ------------------------------------------------------------------------
# Input/ Output
open (FILEONE, "<:encoding($encoding)",$FichierOne) or die ("$erreur $!\n");
#open (STDERR, ">:encoding($encoding)", 'toto.txt') or die ("$erreur $!\n");
  
# ------------------------------------------------------------------------
if ( defined $verbeux ) {&info('a');};
# message dans le STDERR (voir subroutine 'info') indiquant le démarrage du programme.
 
# ------------------------------------------------------------------------
##-- Début de l'écriture : en-tête XML--##
my $output = new IO::File(">$FichierResultat");
my $writer = new XML::Writer(
  OUTPUT      => $output,
  DATA_INDENT => 3,         # indentation, 3 espaces
  DATA_MODE   => 1,         # changement ligne.
  ENCODING    => $encoding,
);
$writer->xmlDecl($encoding);
 
$writer->startTag
	(
	"volume",
	'name'              => "dico_wol_fr_" . $locale,
	'source-language'   => $locale,
	'creation-date'     => $date,
	'xmlns:d'  	        => 'http://www-clips.imag.fr/geta/services/dml',
	'xmlns'			    => 'http://www-clips.imag.fr/geta/services/dml/motamot',
	'xmlns:m'			=> 'http://www-clips.imag.fr/geta/services/dml/motamot',
	'xmlns:xsi'		    => 'http://www.w3.org/2001/XMLSchema-instance',
	'xsi:schemaLocation'=> 'http://www-clips.imag.fr/geta/services/dml/motamot ' . 
			'http://www-clips.imag.fr/geta/services/dml/motamot_fra.xsd',
	);
 
# =======================================================================================================================================
###--- PREPARATION ---###
my ($twig_base, $twig_one, $twig_two, $twig_axi);
my ($entry_base, $entry_one, $entry_two, $entry_axi);
$twig_base = XML::Twig->new
  (
   output_encoding => $encoding, 
   pretty_print    => $pretty_print, 
   twig_print_outside_roots => 1,
   twig_roots      => {$ref_entry => 1}, 
   no_prolog => 1,
   Twig_handlers   => {$ref_entry => \&entry_base},
  );

$twig_one = XML::Twig->new
#$twig_one = XML::Twig::XPath->new
  (
   output_encoding => $encoding, 
   pretty_print    => $pretty_print, 
   twig_roots      => {$ref_entry => 1}, 
   twig_print_outside_roots => 1,
   no_prolog => 1,
   Twig_handlers   => {$ref_entry => \&entry_one},
  );

$twig_two = XML::Twig->new
  (
   output_encoding => $encoding, 
   pretty_print    => $pretty_print, 
   twig_roots      => {$ref_entry => 1}, 
   twig_print_outside_roots => 1,
   no_prolog => 1,
  Twig_handlers   => {$ref_entry => \&entry_two},
  );
 
sub entry_base {
  $entry_base = $_[1];
  return 1;
}
sub entry_one {
  $entry_one = $_[1];
  return 1;
}
sub entry_two {
  $entry_two = $_[1];
  return 1;
}
 
# ------------------------------------------------------------------------
if ( defined $verbeux ) {&info('b');};
 
# ------------------------------------------------------------------------
my ($headword_one, $headword_two);
my ($forme_one, $forme_two);
my ($cat_one, $cat_two);

$entry_one = next_entry($twig_one, *FILEONE, \$entry_one); # obtenir la première entrée de la source 1.
$forme_one = [$entry_one->findnodes ($ref_head)]->[0];
$headword_one = $forme_one ? [$forme_one->findnodes ($ref_headword)]->[0]->text : undef;
#$headword_one = $entry_one ? [$forme_one->findnodes ($ref_headword)]->[0]->text : undef;
$entry_two = next_entry($twig_two, *FILEONE, \$entry_two); # obtenir la deuxième entrée de la source 1.
$forme_two = [$entry_two->findnodes ($ref_head)]->[0];
$headword_two = $forme_two ? [$forme_two->findnodes ($ref_headword)]->[0]->text : undef;
$cat_one= $entry_one ? [$entry_one->findnodes ($ref_cat)]->[0]->text : undef;
$cat_two = $entry_one ?[$entry_two->findnodes ($ref_cat)]->[0]->text : undef;
print STDERR  'h1:',$headword_one;
print  STDERR 'h2:',$headword_two;

# ------------------------------------------------------------------------
if ( defined $verbeux ) {&info('c');};
 
 
# =======================================================================================================================================
###--- ALGORITHME DE LA FUSION ---###
 
# Après avoir récupéré la ou les entrées (sub next_entry), on les compare.
# On écrit dans le fichier de sortie selon la comparaison.
#my ($headword_one, $headword_two, $id_one, $id_two);
# Le traitement continuera tant qu'il y a des entrées dans l'une ou l'autre source.
my    $egaux = 0;
my $egaunotcat=0;
    while ($entry_one && $entry_two)
  { 
    # on compare les deux headword 'lexicographiquement'
   # my $compare = (defined $headword_two) - (defined $headword_one) || ($headword_one => stripaccents ($headword_one)) cmp ($headword_two => stripaccents ($headword_two));
    my $compare = $collator->cmp($headword_one,$headword_two);
    my $cmparecat=$collator->cmp($cat_one,$cat_two);

# si =0  comparer les cat si manque une cat = messqge d erreur , si 2 cat diff cas compare < 0 si 2 cat = cas fusion

     if ( defined $verbeux ){
      if ($compare==0 && $cmparecat==0){
        $egaux++;
      print STDERR 'compare ', $headword_one , ' cmp ', $headword_two, ' = ', $compare, "\n";
      }
    };
    # 1) si l'entrée 1 est inférieure à l'entrée 2 (ou s'il n'y a plus d'entrée 2):
    # On écrit l'entrée 1 dans le fichier de sortie.
    # On avance d'une entrée dans le fichier 1
    if ($compare < 0 || ($compare==0 && $cmparecat<0)) {
    	$writer->startTag($entry_one->root->name, 'id' => $entry_one->root->id, 'level' => '');
        $entry_one->print($output, "indented");
    	$writer->endTag($entry_one->root->name);
      if ($compare==0 && $cmparecat<0){
      print "$headword_one.$headword_two.$egaunotcat";
      $egaunotcat++;

    }
      # pour avoir l'entrée suivante dans le fichier 1.
      $entry_one = $entry_two;
	  $forme_one = $entry_one ? [$entry_one->findnodes ($ref_head)]->[0] : undef;
	  $headword_one = $forme_one ? [$forme_one->findnodes ($ref_headword)]->[0]->text : undef;

    my $cat_one_node00 = $entry_one ? [$entry_one->findnodes ($ref_cat)]->[0] : undef;
        $cat_one = (ref($cat_one_node00)) ? $cat_one_node00->text : undef;
      #  if (!(defined $cat_one)){
       #   print"Erreur catégorie"; print "$headword_one";
        #}

   # $cat_one = $entry_one ?[$entry_one->findnodes ($ref_cat)]->[0]->text : undef;
    

    $entry_two = next_entry($twig_two, *FILEONE, \$entry_two);
	  $forme_two = $entry_two ? [$entry_two->findnodes ($ref_head)]->[0] : undef;
	  $headword_two = $forme_two ? [$forme_two->findnodes ($ref_headword)]->[0]->text : undef;
    my $cat_two_node0 = $entry_two ? [$entry_two->findnodes ($ref_cat)]->[0] : undef;
   # $cat_two = ref([$cat_two_nodes]->[0])  &&  UNIVERSAL::can($r,'can') ? [$cat_two_nodes]->[0]->text : undef;
    $cat_two = (ref($cat_two_node0)) ? $cat_two_node0->text : undef;

    


    }
    # 2) si l'entrée 1 est supérieure à l'entrée 2 (ou s'il n'y a plus d'entrée 1):
    # ce cas ne devrait pas se présenter
    # On écrit l'entrée 2 dans le fichier de sortie.
    # On avanc d'une entrée dans le fichier 2.
    elsif ($compare > 0) {
      #$entry_two->print($output, "indented");
      #$entry_two->flush($output);
      # pour avoir l'entrée suivante dans le fichier 2.
      $entry_two = next_entry($twig_two, *FILEONE, \$entry_two);
    }
    # 3) le dernier cas : entrée 1 = entrée 2 :
    # On ajoute les éléments de entrée 2 dans entrée 1, qu'on écrit dans le fichier de sortie.
    # On avance d'une entrée dans le fichier 1 et dans le fichier 2.
    else
      {
        print "$headword_one";
       fusion ($entry_one, $entry_two);
        $entry_two = next_entry($twig_two, *FILEONE, \$entry_two);
		$forme_two = [$entry_two->findnodes ($ref_head)]->[0];
		$headword_two = $entry_two ? [$forme_two->findnodes ($ref_headword)]->[0]->text : undef;
    my $cat_two_node000 = $entry_two ? [$entry_two->findnodes ($ref_cat)]->[0] : undef;
   # $cat_two = ref([$cat_two_nodes]->[0])  &&  UNIVERSAL::can($r,'can') ? [$cat_two_nodes]->[0]->text : undef;
    $cat_two = (ref($cat_two_node000)) ? $cat_two_node000->text : undef;
    
      }
  }
 
    $writer->startTag($entry_one->root->name, 'id' => $entry_one->root->id, 'level' => '');
    $entry_one->print($output, "indented");
    $writer->endTag($entry_one->root->name);
 
# ------------------------------------------------------------------------
# Fin de l'écriture :
$writer->endTag('volume');
$output->close();
 

# ------------------------------------------------------------------------
if ( defined $verbeux ) {
  print STDERR "egaux; ",$egaux;
  &info('d');
};


# =======================================================================================================================================
###--- SUBROUTINES ---###
sub next_entry 
{
my ($twig, $file, $entry) = @_;
$$entry = undef;
$/ = '</'.$ref_entry.'>';
while (!$$entry && !eof $file) 
	{
	my $xml = <$file>;
#	print STDERR 'xml:[',$xml,']';
    $twig->safe_parse($xml);
	}
$twig->purge; 
return $$entry;
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
foreach my $sense_one ($entry_one->findnodes($ref_sense))
  {$i++;}
foreach my $sense_two ($entry_two->findnodes($ref_sense))
  {
  $i++;
  $sense_two->set_id("s" . $i); 
 # foreach my $translations ($sense_two->findnodes('m:translations'))
#	{
#	foreach my $translation ($translations->findnodes('m:translation'))
#		{
#		$translation->set_att('idreflexie' => "s$i");
#		}
#	}
  $sense_two->cut;
  my $last_elt = $entry_one->last_child($ref_sense);
  $last_elt = $entry_one->last_child($ref_head) if !defined $last_elt;
  $sense_two->paste('after' => $last_elt);
  }
return ($entry_one);
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
	my $FichierLog = 'LOG.txt';
	open(my $FiLo, ">>:encoding($encoding)", $FichierLog) or die ("$erreur $!\n");
	print {$FiLo}
	"==================================================\n",
	"RAPPORT : ~~~~ $0 ~~~~\n",
	"--------------------------------------------------\n",
	"Fichier source : $FichierOne\n",
	"--------------------------------------------------\n",
	"Fichier final : $FichierResultat\n",
	"--------------------------------------------------\n",
	"Date du traitement : ", $date, "\n",
	"--------------------------------------------------\n",
	"Lapsed time : ", $time, " s\n",
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
}
 
# =======================================================================================================================================
1 ;
