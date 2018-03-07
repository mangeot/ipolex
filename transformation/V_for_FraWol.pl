#!/usr/bin/env perl

# =======================================================================================================================================
######----- V_for_FraKhm.pl -----#####
# =======================================================================================================================================
# Auteur : V.GROS
# Version 1.0 
# Dernières modifications : 11 juin 2010
# Synopsis :  - transformation d'une structure XML type "FraKhm"
#               vers une structure XML type "Mot à Mot".
# Remarques : - Structure plate qui nécessite un travail supplémentaire pour unifier le <sense>
#             - Création d'un journal des exécutions (LOG)
# ---------------------------------------------------------------------------------------------------------------------------------------
# Usage : perl V_for_FraKhm.pl -v -from source.xml -to MAM -src fra -trg khm
#
# -v : affiche les informations du STDERR
#
# Pour les options avancées :
# -date "date" : pour spécifier la date (par défaut : la date du jour (localtime)
# -erreur "message d'erreur" : pour spécifier le message d'erreur (ouverture de fichiers)
# -encodding "format d'encodage" : pour spécifier le format d'encodage (par défaut UTF-8)
# -help : pour afficher l'aide
# -total : pour indiquer le nombre total d'entrées de la source (pour la barre de progression)
# =======================================================================================================================================



# =======================================================================================================================================
###--- METADIRECTIVES ---###

use strict;
use warnings;
use utf8;
use IO::File; 
use Getopt::Long; # pour gérer les arguments.

use XML::Twig; # (non inclus dans le core de Perl), pour le parsing de la source.
use XML::Writer; # (non inclus dans le core de Perl), pour le fichier de sortie.


# =======================================================================================================================================
###--- PROLOGUE ---###

# ------------------------------------------------------------------------
##-- Les balises de la source/de la sortie (MAM) --##

# ------------------------------------------------
# MODIFIEZ CES VARIABLES SELON LE TRAITEMENT VOULU
# ------------------------------------------------

my $name = "FraWol";

#<dictionnaire>
#<article><forme><vedette>a</vedette></forme><sens><glose>1ère lettre de l’alphabet français</glose><traduction><api>-aksɑ̄-</api><khm>អក្សអ</khm></traduction></sens></article>

my  $in_root 		   = 'dictionnaire'; 
my  $in_entry 		   = 'article'; 				 # l'élément dans la source qui correspond à <m:entry> dans MAM.
my	$in_head 	   = 'bloc_forme';
my	$in_headword 	   = 'mot_vedette';
my	$in_pronunciation  = 'prononciation'; 
my	$in_pos 		   = 'catégorie_grammaticale'; 	
my $in_affix_class='classe_nominale';
my $in_src_headword='source_lexeme';
my $in_variant='variante';	    
my  $in_sense		   = 'sens';					# idem pour l'élément <sense> de MAM.
#my	$in_gloss 		   = 'glose';  
my	$in_definition     = 'definition';  
my $in_src_definition='source_définition';	    

my $in_synonyme='synonyme';
my $in_note_usage='note_usage';
my $in_translations='bloc_traduction';
my $in_translation='traduction_française';
my $in_pos_translation_headword='catégorie_grammaticale_traduction_française_mot_vedette';
my $in_example="exemple";
my $in_wol_example='phrase_illustration';
my $in_fra_example="traduction_française_phrase_illustration";
my $in_related_forms='bloc_derivés';
my $in_related_form='derivé';
my $in_src_headword_related='lexème_source_expression_dérivée';
my $in_metadata='bloc-métainformatio';
my $in_author='auteur';
my $in_comment='commentaire';
my $in_autheur_stat_fich='auteur_statut_fiche';
my $in_stat_fiche='statut_fiche';
my $in_last_date_modif='date_dernière_modification';
#my	$in_examples 	   = 'examples';   
#my	$in_example 	   = 'french_sentence'; 
#my	$in_label 		   = 'french_label'; 	   
#my	$in_formula 	   = 'formula'; 	     

#my	$in_trg_script    = 'khm';
#my   $in_trg_pron = 'api';

	   
#my	$in_idioms 	       = 'idioms'; 
#my	$in_idiom	 	   = 'french_phrase';  	  	  
my $xmlnsm="http://www-clips.imag.fr/geta/services/dml/motamot";
my $xmlnsxsi="http://www.w3.org/2001/XMLSchema-instance";
my $xsiSchemaLocation="http://www-clips.imag.fr/geta/services/dml/motamot 
 http://www-clips.imag.fr/geta/services/dml/motamot_fra.xsd";


my  $mam_root 		   = 'dictionnaire'; 
my  $mam_entry 		   = 'article'; 				 # l'élément dans la source qui correspond à <m:entry> dans MAM.
my	$mam_head 	   = 'bloc_forme';
my	$mam_headword 	   = 'mot_vedette';
my	$mam_pronunciation  = 'prononciation'; 
my	$mam_pos 		   = 'catégorie_grammaticale_mot_vedette'; 	
my $mam_affix_class='classe_nominale';
my $mam_src_headword='source_lexeme';
my $mam_variant='variante';	    
my  $mam_sense		   = 'sens';					# idem pour l'élément <sense> de MAM.
#my	$in_gloss 		   = 'glose';  
my	$mam_definition     = 'definition';  
my $mam_src_definition='source_définition';	    

my $mam_synonyme='synonyme';
my $mam_note_usage='note_usage';
my $mam_translation='translation';
my	$mam_translations= 'translations';
my $mam_translation_headword='catégorie_grammaticale_traduction_française_mot_vedette';
my $mam_example="exemple";
my $mam_wol_exemple='phrase_illustration';
my $mam_fra_exemple="traduction_française_phrase_illustration";
my $mam_related_forms='bloc_derivés';
my $mam_related_form='derivé';
my $mam_headword_related='lexème_source_expression_dérivée';
my $mam_metadata='bloc_métainformatio';
my $mam_author='auteur';
my $mam_comment="commentaire";
my $mam_autheur_stat_fich='auteur_statut_fiche>';
my $mam_stat_fiche='statut_fiche';
my $mam_last_date_modif='date_dernière_modification';

my $mam_axi = 'm:axie';
my $mam_reflexies = 'm:reflexies';
my $mam_reflexie = 'm:reflexie';

# ------------------------------------------------------------------------

##-- Gestion des options --##

my ($date, $FichierXML, $FichierResultat, $erreur, $encoding, $src, $trg) = ();
my ($verbeux, $help) = ();
GetOptions( 
  'date|time|d=s'        	  => \$date, # flag de type -date ou --date, ou -time ou --time, ou -t ou --t (=s : string)
  'source|in|from|i=s'        => \$FichierXML, 
  'sortie|out|to|o=s'         => \$FichierResultat, 
  'source_language|src|s=s'         => \$src, 
  'target_language|trg|t=s'         => \$trg, 
  'erreur|error|e=s'     	  => \$erreur, 
  'encodage|encoding|enc|f=s' => \$encoding, 
  'help|h'                	  => \$help, 
  'verbeux|v'             	  => \$verbeux, 
  );

if (!( defined $date ))
	{
	$date = localtime;
	};
if (!( defined $FichierXML ))
	{
	&help ; # si le fichier source n'est pas spécifié, affichage de l'aide.
	};
if (!( defined $FichierResultat ))
	{
	$FichierResultat = "MAM" ;
	};
if (!( defined $src ))
	{
	$src = 'Wol' ;
	};
if (!( defined $trg ))
	{
	$trg = 'Fra' ;
	};
if (!( defined $erreur ))
	{
	$erreur = "|ERROR| : problem opening file :";
	};
if (!( defined $encoding ))
	{
	$encoding = "UTF-8"; 
	};
if ( defined $help )
	{
	&help;
	};
	
# ------------------------------------------------------------------------
##-- Configuration de l'output --##

my $output_src = new IO::File('>'.$FichierResultat.'_'.$src.'.xml');
my $writer_src = new XML::Writer(
  OUTPUT      => $output_src,
  DATA_INDENT => 3,         # indentation, 3 espaces
  DATA_MODE   => 1,         # changement ligne.
  ENCODING    => $encoding,
);
$writer_src->xmlDecl($encoding);

my $output_trg = new IO::File('>'.$FichierResultat.'_'.$trg.'.xml');
my $writer_trg = new XML::Writer(
  OUTPUT      => $output_trg,
  DATA_INDENT => 3,         # indentation, 3 espaces
  DATA_MODE   => 1,         # changement ligne.
  ENCODING    => $encoding,
);
$writer_trg->xmlDecl($encoding);

my $output_axi = new IO::File('>'.$FichierResultat.'_axi.xml');
my $writer_axi = new XML::Writer(
  OUTPUT      => $output_axi,
  DATA_INDENT => 3,         # indentation, 3 espaces
  DATA_MODE   => 1,         # changement ligne.
  ENCODING    => $encoding,
);
$writer_axi->xmlDecl($encoding);

binmode STDERR, ":utf8";

# ------------------------------------------------------------------------

if ( defined $verbeux )
	{
	&info('a'); 
	};
# message dans le STDERR (voir subroutine 'info') indiquant le démarrage du programme.


# =======================================================================================================================================
###--- TWIG ---###

if ( defined $verbeux )
	{
	&info('b'); 
	};

# ------------------------------------------------------------------------

# Début du fichier en sortie :
$writer_src->startTag
	(
  $mam_root,
  'name'          => $name . '_' . $src,
  'source-language'          => $src,
  'creation-date' => $date,
  'xmlns:m' => $xmlnsm,
  'xmlns:xsi' => $xmlnsxsi,
  'xsi:schemaLocation' => $xsiSchemaLocation,
	);
	
$writer_trg->startTag
	(
  $mam_root,
  'name'          => $name . '_' . $trg,
  'source-language'         => $trg,
  'creation-date' => $date,
	);

$writer_axi->startTag
	(
  $mam_root,
  'name'          => $name . '_axi',
  'source-language'         => 'axi',
  'creation-date' => $date,
	);

my $entry_count = 0;

my $twig = XML::Twig->new
(
output_encoding => $encoding, # on reste en utf8
Twig_handlers   => {$in_entry => \&entry,}, 
);
$twig->parsefile($FichierXML);
my $root = $twig->root; 

# ------------------------------------------------------------------------

if ( defined $verbeux )
	{
	&info('c'); 
	};
	
# ------------------------------------------------------------------------	
# Fin des fichiers en sortie :
$writer_src->endTag($mam_root);
$output_src->close();

$writer_trg->endTag($mam_root);
$output_trg->close();

$writer_axi->endTag($mam_root);
$output_axi->close();

# ------------------------------------------------------------------------

if ( defined $verbeux )
	{
	&info('d'); 
	};


# =======================================================================================================================================
###--- SUBROUTINES ---###

sub entry 
{
$entry_count++;
my $count = 0;
my ($twig, $twig_entry) = @_;
my @senses = $twig_entry->children($in_sense);
my $form = $twig_entry->first_child($in_head);
my $headword = $form->first_child_text($in_headword);

my $prononciation = $form->first_child($in_pronunciation);
$prononciation=defined($prononciation)?$prononciation->text():'';
my $variant= $twig_entry->first_child($in_variant);
$variant=defined($variant)?$variant->text:'';
my $source_lexeme=$form->first_child($in_src_headword);
$source_lexeme=defined($source_lexeme)?$source_lexeme->text():'';
my $lexeme_derive=$twig_entry->first_child($in_src_headword_related);
$lexeme_derive=defined($lexeme_derive)?$lexeme_derive->text():'';

my $pos = $twig_entry->first_child($in_pos);
$pos = defined($pos)?$pos->text():'';
my $affix_class = $twig_entry->first_child($in_affix_class);
$affix_class = defined($affix_class)?$affix_class->text():'';
my $id_src = $src . '.' . $headword . '.' . $entry_count . '.e';



$writer_src->startTag( $mam_entry, 'id' => $id_src, 'level' => '');
	$writer_src->startTag($mam_head);
		$writer_src->startTag($mam_headword);
		$writer_src->characters($headword);
		$writer_src->endTag($mam_headword);
		$writer_src->startTag($mam_pronunciation);
		$writer_src->characters($prononciation);
		$writer_src->endTag($mam_pronunciation);
		$writer_src->startTag($mam_src_headword);
		$writer_src->characters($source_lexeme);
		$writer_src->endTag($mam_src_headword);
		$writer_src->startTag($mam_variant);
		$writer_src->characters($variant);
		$writer_src->endTag($mam_variant);
		$writer_src->startTag($mam_headword_related);
		$writer_src->characters($lexeme_derive);
		$writer_src->endTag($mam_headword_related);

		$writer_src->endTag($mam_head);	

	#	$writer->startTag($mam_pronunciation);
	#	$writer->characters($first_pron);
	#	$writer->endTag($mam_pronunciation);

		$writer_src->startTag($mam_pos, 'valeur' => $pos, 'classe_nominale' => $affix_class);
		$writer_src->endTag($mam_pos);
	

foreach my $twig_sense (@senses)
	{
	#my $gloss = $twig_sense->first_child_text($in_gloss);
	my $translations = $twig_sense->first_child($in_translations);
	my $translation = defined($translations)?$translations->first_child_text($in_translation):'';
	 my $in_pos_translation_headword=defined($translations)?$translations->first_child_text($in_pos_translation_headword):'';
	  my $definition=$twig_sense->first_child($in_definition);
	  $definition=defined($definition)?$definition->text:'';
	    my $src_definition=$twig_sense->first_child($in_src_definition);
	  $src_definition=defined($src_definition)?$src_definition->text:'';
	    my $synonyme=$twig_sense->first_child($in_synonyme);
	  $synonyme=defined($synonyme)?$synonyme->text:'';
	    my $note_usage=$twig_sense->first_child($in_note_usage);
	  $note_usage=defined($note_usage)?$note_usage->text:'';
	     my $example=$twig_sense->first_child($in_example);
	     my $wol_example=defined($example)?$example->first_child_text($in_wol_example):'';
	   my $fra_example=defined($example)?$example->first_child_text($in_fra_example):'';




	#my $translation = $translationTag->first_child_text($in_trg_pron);
	
 	my @translations = split(' +\/ +', $translation);

    my $id_sense = $count+1;

	
	$writer_src->startTag($mam_sense, 'id' => 's'.$id_sense, 'level' => '');
	
	$writer_src->startTag($mam_definition);
	$writer_src->characters($definition);
	$writer_src->endTag($mam_definition);
	$writer_src->startTag($mam_src_definition);
	$writer_src->characters($src_definition);
	$writer_src->endTag($mam_src_definition);
	$writer_src->startTag($mam_synonyme);
	$writer_src->characters($synonyme);
	$writer_src->endTag($mam_synonyme);
	$writer_src->startTag($mam_note_usage);
	$writer_src->characters($note_usage);
	$writer_src->endTag($mam_note_usage);


		$writer_src->startTag($mam_translations);
		
		 foreach my $translation (@translations) {
			$count++;
 			my $trg_headword = $translation;
 			$trg_headword =~ s/ *\([^\)]*\) *//g;
			$trg_headword =~ s/^\-//g;
			$trg_headword =~ s/ *[\!\?] *//g;
			$trg_headword =~ s/ *\.\.\.$//g;
			$trg_headword =~ s/^\.\.\.//g;
			$trg_headword =~ s/ʔ//g;
			my $trg_headword_id = $trg_headword;
			if (length ($trg_headword_id) > 100) {
				$trg_headword_id = substr($trg_headword_id,0,100);
				if ( defined $verbeux ) { print STDERR 'truncate id: ', $trg_headword_id,"\n"; }
			}
			my $id_trg = $trg . '.' . $trg_headword_id . '.' . $entry_count . '.' . $count . '.e';
			my $hw_axi = '[' . $src . ':' . $headword . ',' . $trg . ':'. $trg_headword_id . ']';
			my $id_axi = 'axi.' . $hw_axi . '.' . $entry_count . '.' . $count . '.e';   
			if ( defined $verbeux ) { print STDERR 'axi id: ', $hw_axi,"\n"; }
 			$writer_src->startTag($mam_translation, 'idrefaxie' => $id_axi);
			$writer_src->endTag($mam_translation);
 
 	## traitement de la cible
$writer_trg->startTag( $mam_entry, 'id' => $id_trg, 'level' => '');
	$writer_trg->startTag($mam_head);
		$writer_trg->startTag($mam_headword);
		$writer_trg->characters($trg_headword);
		$writer_trg->endTag($mam_headword);

		$writer_trg->startTag('prononciation');
		$writer_trg->characters('');
		$writer_trg->endTag('prononciation');
		$writer_trg->endTag($mam_head);	

		$writer_trg->startTag('$mam_pos');
		$writer_trg->characters($in_pos_translation_headword);
		$writer_trg->endTag('$mam_pos');
	

		#$writer_trg->startTag($mam_pos);
		#$writer_trg->characters($first_pos);
		#$writer_trg->endTag($mam_pos);
	
	$writer_trg->startTag($mam_sense, 'id' => 's1', 'level' => '');


	#	if ($translation =~ /[\(\!\?\.ʔ]/) {
	#		$writer_trg->startTag($mam_gloss);
	#		$writer_trg->characters($translation);
	#		$writer_trg->endTag($mam_gloss);
	#	}
	
		$writer_trg->startTag($mam_translations);
			$writer_trg->startTag($mam_translation, 'idrefaxie' => $id_axi);
			$writer_trg->endTag($mam_translation);
		$writer_trg->endTag($mam_translations);

		$writer_trg->startTag($mam_example);
		$writer_trg->startTag('phrase_illustration');
		$writer_trg->characters('');
		$writer_trg->endTag('phrase_illustration');
		$writer_trg->startTag('source_exemple');
		$writer_trg->characters('');
		$writer_trg->endTag('source_exemple');
		$writer_trg->endTag($mam_example);
		
	$writer_trg->endTag($mam_sense);
$writer_trg->endTag( $mam_entry);


	
	## traitement de l'axi
$writer_axi->startTag( $mam_axi, 'id' => $id_axi, 'level' => '');
		$writer_axi->startTag($mam_headword);
		$writer_axi->characters($hw_axi);
		$writer_axi->endTag($mam_headword);

		$writer_axi->startTag($mam_reflexies);
			$writer_axi->startTag($mam_reflexie,'idrefentry' => $id_src, 'idreflexie' => 's' . $id_sense, 'lang' => $src);
			$writer_axi->endTag($mam_reflexie);
			$writer_axi->startTag($mam_reflexie,'idrefentry' => $id_trg, 'idreflexie' => 's1', 'lang' => $trg);
			$writer_axi->endTag($mam_reflexie);
		$writer_axi->endTag($mam_reflexies);
$writer_axi->endTag($mam_axi);
 }
		$writer_src->endTag($mam_translations);



		$writer_trg->startTag('exemple');
		$writer_trg->startTag('phrase_illustration');
		$writer_trg->characters('');
		$writer_trg->endTag('phrase_illustration');
		$writer_trg->startTag('source_exemple');
		$writer_trg->characters('');
		$writer_trg->endTag('source_exemple');
		$writer_trg->startTag('traduction', 'lang' => 'fra');
		$writer_trg->characters('');
		$writer_trg->endTag('traduction');
		$writer_trg->endTag('exemple');
	$writer_src->endTag($mam_sense);
	}
$writer_src->endTag($mam_entry);
$twig->purge;
return;
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
	print (STDERR "Parsing\n");
	print (STDERR "--------------------------------------------------------------------------------\n");
	}
elsif ($info=~ 'c')
	{
	print (STDERR "Process done : $FichierXML parsed\n");
	print (STDERR "--------------------------------------------------------------------------------\n");
	print (STDERR "Applying changes and write into $FichierResultat \n");
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
	"Fichier source : $FichierXML\n",
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