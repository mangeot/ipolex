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
# -encoding "format d'encodage" : pour spécifier le format d'encodage (par défaut UTF-8)
# -help : pour afficher l'aide
# -total : pour indiquer le nombre total d'entrées de la source (pour la barre de progression)
# =======================================================================================================================================



# =======================================================================================================================================
###--- METADIRECTIVES ---###

use strict;
use warnings;
use utf8::all;

use XML::DOM;
use XML::DOM::XPath;
use Data::Dumper;
my $encoding = "UTF-8";
my $unicode = "UTF-8";

##-- Gestion des options --##

my ($date, $FichierEntree,$metaEntree,$FichierResultat, $erreur, $encoding, $src, $trg) = ();
my ($verbeux, $help) = ();
GetOptions( 
  'date|time|d=s'        	  => \$date, # flag de type -date ou --date, ou -time ou --time, ou -t ou --t (=s : string)
  'source|in|from|i=s'        => \$FichierEntree, 
  'metaentree|min|m=s' => \$metaEntree, 
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
if (!( defined $FichierEntree ))
	{
	&help ; # si le fichier source n'est pas spécifié, affichage de l'aide.
	};
if (!( defined $metaEntree ))
	{
	&help ; # si le fichier de métadoné source n'est pas spécifié, affichage de l'aide.
	};
	
if (!( defined $FichierResultat ))
	{
	$FichierResultat = "MAM" ;
	};
if (!( defined $src ))
	{
	$src = 'src' ;
	};
if (!( defined $trg ))
	{
	$trg = 'trg' ;
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



#print STDERR "load cdm départ:\n";
my %CDMSDEPART=load_cdm($metaEntree);	
# print STDERR "Récupération de quelques pointeurs CDM utiles pour la suite\n";
my $cdmvolumedepart =$CDMSDEPART{'cdm-volume'};

my $cdmentrydepart = $CDMSDEPART{'cdm-entry'};

my $cdmheadworddepart = $CDMSDEPART{'cdm-headword'};
# =======================================================================================================================================
###--- PROLOGUE ---###

# ------------------------------------------------------------------------
##-- Les balises de la source/de la sortie (MAM) --##

# ------------------------------------------------
# MODIFIEZ CES VARIABLES SELON LE TRAITEMENT VOULU
# ------------------------------------------------

my $name = "FraKhm";

my  $in_root 		   = 'dictionnaire'; 
my  $in_entry 		   = 'article'; 				 # l'élément dans la source qui correspond à <m:entry> dans MAM.
my	$in_head 	   = 'forme';
my	$in_headword 	   = 'vedette';
#my	$in_pronunciation  = 'french_pron'; 
my	$in_pos 		   = 'gram'; 		    
my  $in_sense		   = 'sens';					# idem pour l'élément <sense> de MAM.

#my	$in_definition     = 'definition';    
#my	$in_label 		   = 'french_label'; 	   
#my	$in_formula 	   = 'formula'; 	     
my	$in_gloss 		   = 'glose';  	    
my	$in_translation    = 'traduction';
my	$in_trg_script    = 'khm';
my   $in_trg_pron = 'api';

#my	$in_examples 	   = 'examples';   
#my	$in_example 	   = 'french_sentence'; 	   
#my	$in_idioms 	       = 'idioms'; 
#my	$in_idiom	 	   = 'french_phrase';  	  	  

my $xmlnsm="http://www-clips.imag.fr/geta/services/dml/motamot";
my $xmlnsxsi="http://www.w3.org/2001/XMLSchema-instance";
my $xsiSchemaLocation="http://www-clips.imag.fr/geta/services/dml/motamot 
 http://www-clips.imag.fr/geta/services/dml/motamot_fra.xsd";


my $mam_root = 'm:dictionary'; # la racine du volume cible MAM (par exemple : <volume> ou <dictionary>).
my $mam_entry = 'm:entry'; 
my $mam_headword = 'm:headword';
my $mam_pos = 'm:pos';
my $mam_pron = 'm:pronunciation';
my $mam_sense = 'm:sense';
my $mam_head = 'm:head';
my $mam_gloss = 'm:gloss';
my $mam_translations = 'm:translations';
my $mam_translation = 'm:translation';

my $mam_axi = 'm:axie';
my $mam_reflexies = 'm:reflexies';
my $mam_reflexie = 'm:reflexie';
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

# cette fonction permet de récupérer les pointeurs cdm à partir du fichier metada.
sub load_cdm {
  my ($fichier)=@_;
  open (IN, "<:encoding($unicode)", $fichier);
  my %dico=();
  while(my $ligne=<IN>){
      
      if($ligne=~/^\s*<(\S+)\s+xpath=\"([^\"]+)(\"\sd:lang=\")?(\w+)?/){
           my $cdm=$1; my $xpath=$2;  my $lang = $4;
           if ($ligne=~/d:lang/)
           {
           $dico{$cdm.$lang}=$xpath;}
           else
           {$dico{$cdm}=$xpath;}
  }
 
}
close(IN);
 return %dico;

 }


sub entry 
{
$entry_count++;
my $count = 0;
my ($twig, $twig_entry) = @_;
my @senses = $twig_entry->children($in_sense);
my $form = $twig_entry->first_child($in_head);
my $headword = $form->first_child_text($in_headword);
my $pos = $form->first_child($in_pos);
$pos = defined($pos)?$pos->text():'';
my $id_src = $src . '.' . $headword . '.' . $entry_count . '.e';

$writer_src->startTag( $mam_entry, 'id' => $id_src, 'level' => '');
	$writer_src->startTag($mam_head);
		$writer_src->startTag($mam_headword);
		$writer_src->characters($headword);
		$writer_src->endTag($mam_headword);

	#	$writer->startTag($mam_pronunciation);
	#	$writer->characters($first_pron);
	#	$writer->endTag($mam_pronunciation);

		$writer_src->startTag($mam_pos);
		$writer_src->characters($pos);
		$writer_src->endTag($mam_pos);
	$writer_src->endTag($mam_head);	

foreach my $twig_sense (@senses)
	{
	my $gloss = $twig_sense->first_child_text($in_gloss);
	my $translationTag = $twig_sense->first_child($in_translation);
	my $translation = $translationTag->first_child_text($in_trg_pron);
	
	my @translations = split(' +\/ +', $translation);

    my $id_sense = $count+1;

	
	$writer_src->startTag($mam_sense, 'id' => 's'.$id_sense, 'level' => '');
	
	$writer_src->startTag($mam_gloss);
	$writer_src->characters($gloss);
	$writer_src->endTag($mam_gloss);

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

		$writer_trg->startTag($mam_pron);
		$writer_trg->characters($trg_headword);
		$writer_trg->endTag($mam_pron);

		#$writer_trg->startTag($mam_pos);
		#$writer_tr$g->characters($first_pos);
		#$writer_trg->endTag($mam_pos);
	$writer_trg->endTag($mam_head);	
	$writer_trg->startTag($mam_sense, 'id' => 's1', 'level' => '');
		if ($translation =~ /[\(\!\?\.ʔ]/) {
			$writer_trg->startTag($mam_gloss);
			$writer_trg->characters($translation);
			$writer_trg->endTag($mam_gloss);
		}
	
		$writer_trg->startTag($mam_translations);
			$writer_trg->startTag($mam_translation, 'idrefaxie' => $id_axi);
			$writer_trg->endTag($mam_translation);
		$writer_trg->endTag($mam_translations);
	
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