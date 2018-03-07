#!/usr/bin/perl

# =======================================================================================================================================
######----- W_for_Export.pl -----#####
# =======================================================================================================================================
# Auteur : M. MANGEOT
# Version 1.0 
# Dernières modifications : 27 nov 2012
# Synopsis :  - transformation de toutes les balises du fichier XML
# Remarques : - La structure est obligatoirement de type "Mot à Mot";
#             - Les variables doivent être changées au sein du programme (début).
# ---------------------------------------------------------------------------------------------------------------------------------------
# Usage : perl W_for_Export.pl -v -source source.xml -out out.xml -export export.xml
#
# -v : affiche les informations du STDERR
#
# Pour les options avancées :
# -source "out.xml"					 : pour spécifier un fichier de sortie (par défaut il s'agit du fichier source)
# -date "date" 					 : pour spécifier la date (par défaut : la date du jour (localtime)
# -erreur "message d'erreur" 	 : pour spécifier le message d'erreur (ouverture de fichiers)
# -encodding "format d'encodage" : pour spécifier le format d'encodage (par défaut UTF-8)
# -pretty "pretty_print" 		 : pour spécifier l'indentation du twig
# -parse 'numeric'				 : le parsing se fait sur plusieurs niveaux :
#									- 0 : la racine
#									- 1 : l'entrée 
#									- 2 : le 'head' et les 'sense'
#									- 3 : les fils du 'head' et du 'sense'
#									- 4 : les petits-fils du 'sense'
# -help 				 		 : pour afficher l'aide
# =======================================================================================================================================



# =======================================================================================================================================
###--- METADIRECTIVES ---###
use strict;
use warnings;
use utf8;
use IO::File;
use Getopt::Long; # pour gérer les arguments.

use XML::Twig; # (non inclus dans le core de Perl), pour le parsing de la source.


# =======================================================================================================================================
###--- PROLOGUE ---###
# ------------------------------------------------------------------------
##-- Les balises de la source/de la sortie (MAM) --##

# ------------------------------------------------
# éléments de la source :
# ------------------------------------------------
my $in_entry 		   = 'article'; 		
my $in_match 		   = 'vedette';

my %list = ('aadam','est.aadam.9061872.e',
'aamorpost','est.aamoripost.3759920.e',
'ah-ah-haa','est.ahahaa.9396726.e',
'ah-ah-ah','est.ahahaa.9396726.e',
'aroomteraapia','est.aroomiteraapia.11475890.e',
'bambustihnik','est.bambusetihnik.9346997.e',
'emake','est.emakene.3845867.e',
'haigustekitaja','est.haigusetekitaja.3877010.e',
'hajuskiirgus','est.hajukiirgus.11473693.e',           
'interregnum','est.interreegnum.3922132.e',
'käeke','est.käekene.4085317.e',
'kannatuskarikas','est.kannatusekarikas.3972655.e',
'karpauh','est.karpauhti.3978774.e',
'karvake','est.karvakene.3980419.e',
'karvaväärt','est.karvaväärtki.3980673.e',
'kõhnake','est.kõhnakene.4076842.e',
'kõhuke','est.kõhukene.4077169.e',
'konservitult','est.konserveeritult.4037598.e',
'kõõrsilmaline','est.kõõrdsilmaline.4084865.e',
'kõrreke','est.kõrrekene.4082359.e',
'korvike','est.korvikene.4049432.e',
'krauh','est.krauhti.4052858.e',
'kruvike','est.kruvikene.4058177.e',
'kuradike','est.kuradikene.4068005.e',
'küüneväärt','est.küüneväärtki.4099966.e',
'küünevõrra','est.küünevõrragi.4099952.e',
'lamepealisus','est.lamedapealisus.4108622.e',
'laserkiir','est.laserikiir.15184447.e',
'leeliskindel','est.leelisekindel.4116382.e',
'lihake','est.lihakene.4124339.e',
'loodusarmastus','est.loodusearmastus.11351434.e',
'mammake','est.mammakene.4167386.e',
'marjuke','est.marjukene.4170448.e',
'masskese','est.masskese.31185852.e',
'meheke','est.mehekene.4177895.e',
'memmeke','est.memmekene.4179974.e',
'merisk','est.meriski.4182403.e',
'mh','est.mhh.4187086.e',
'mh-mh','est.mh-mhh.4187102.e',
'mihuke','est.mihukene.4187380.e',
'misuke','est.misukene.4191776.e',
'momentvõte','est.momentülesvõte.4194946.e',
'möödapääsmatult','est.möödapääsematult.4217821.e',
'möödapääsmatus','est.möödapääsematus.4217836.e',
'mullkamber','est.mullkamber.31186012.e',
'mullike','est.mullikene.4202185.e',
'mürgituma','est.mürgistuma.4219303.e',
'mustuke','est.mustukene.4206149.e',
'müt-müt','est.müt-müt-müt.4220137.e',
'nakkuskandja','est.nakkuskandja.13411886.e',
'näoke','est.näokene.4252357.e',
'nihuke','est.nihukene.4232573.e',
'niidike','est.niidikene.4232809.e',
'niisuke','est.niisukene.4233715.e',
'ninake','est.ninakene.4235597.e',
'nisuke','est.nisukene.4236690.e',
'nitinatike','est.nitinatikene.4236781.e',
'nõh','est.nõhh.4246888.e',
'nõksuke','est.nõksukene.4247487.e',
'nõndaps','est.nõndapsi.4247916.e',
'nooleke','est.noolekene.4239224.e',
'nõrgake','est.nõrgakene.4248235.e',
'nuhtlusalune','est.nuhtlusealune.4242594.e',
'nukuke','est.nukukene.4243107.e',
'õenatuke','est.õenatukene.27944404.e',
'õeraasuke','est.õeraasukene.27944441.e',
'õhkõhuke','est.õhkõhukene.27945224.e',
'oh-oh-oo','est.oh-oh-hoo.4258020.e',
'õhvake','est.õhvakene.27946845.e',
'öökannike','est.öökannikene.27956376.e',
'ööpääsuke','est.ööpääsukene.27956572.e',
'overlokmasin','est.overlokõmblusmasin.4274294.e',
'päevake','est.päevakene.4373838.e',
'pah','est.pahh.4279026.e',
'paljuke','est.paljukene.4284601.e',
'paluke','est.palukene.4285555.e',
'pärjake','est.pärjakene.4377710.e',
'patsike','est.patsikene.4295579.e',
'patuke','est.patukene.4295817.e',
'peake','est.peakene.4296989.e',
'peeglike','est.peeglikene.4300520.e',
'peremamsel','est.peremampsel.4305555.e',
'perenaisuke','est.perenaisukene.4305755.e',
'piigat','est.piigart.4312494.e',
'piisake','est.piisakene.4314868.e',
'pilguke','est.pilgukene.4317883.e',
'pilveke','est.pilvekene.4319450.e',
'pinnuke','est.pinnukene.4321907.e',
'põieke','est.põiekene.4367685.e',
'poolusking','est.pooluseking.4337733.e',
'põõsake','est.põõsakene.4373439.e',
'põrmuke','est.põrmukene.4372418.e',
'prometeuslik','est.prometheuslik.4347526.e',
'prouake','est.prouakene.4349945.e',
'pst','est.psst.4351743.e',
'puuke','est.puukene.4363623.e',
'raamatuke','est.raamatukene.22853295.e',
'radeernõel','est.radeerimisnõel.22854956.e',
'rahake','est.rahakene.22856254.e',
'rajake','est.rajakene.22859883.e',
'rakverlane','est.rakverelane.22861045.e',
'raoke','est.raokene.22862469.e',
'reisimajake','est.reisimajakene.22871003.e',
'ribake','est.ribakene.22876183.e',
'ristike','est.ristikene.22882461.e',
'sädemeke','est.sädemekene.22958655.e',
'salguke','est.salgukene.22904832.e',
'salmike','est.salmikene.22905150.e',
'särgike','est.särgikene.22959570.e',
'sarveke','est.sarvekene.22909390.e',
'seisuskohaselt','est.seisusekohaselt.22916216.e',
'seisusvääriline','est.seisusevääriline.23014553.e',
'seitsmeteistaastaselt','est.seitsmeteistkümneaastaselt.22916777.e',
'setuke','est.setukene.22923615.e',
'siiluke','est.siilukene.22927114.e',
'sikuke','est.sikukene.22928360.e',
'sildike','est.sildikene.22928635.e',
'sillake','est.sillakene.22929270.e',
'sirbike','est.sirbikene.22932853.e',
'sõbrake','est.sõbrakene.23015735.e',
'sokuke','est.sokukene.22939671.e',
'sõlmeke','est.sõlmekene.22955380.e',
'sõnake','est.sõnakene.22956035.e',
'sooneke','est.soonekene.22942890.e',
'sõrmeke','est.sõrmekene.22957414.e',
'sortsuke','est.sortsukene.22944974.e',
'sõsarake','est.sõsarakene.22957886.e',
'sõuke','est.sõukene.22958142.e',
'stenografeermasin','est.stenografeerimismasin.23006094.e',
'südameke','est.südamekene.22996372.e',
'sutike','est.sutikene.23011232.e',
'suuruke','est.suurukene.23013237.e',
'tabuleermasin','est.tabuleerimismasin.22963586.e',
'täheke','est.tähekene.27861008.e',
'taimeke','est.taimekene.22968200.e',
'talleke','est.tallekene.22970913.e',
'tassike','est.tassikene.22977154.e',
'telemehaanika','est.telemehhaanika.22984865.e',
'telemehaaniline','est.telemehhaaniline.22984879.e',
'tiben-tobens','est.tibens-tobens.22990778.e',
'tiben-toben','est.tibens-tobens.22990778.e',
'tippmamsel','est.tippmampsel.22994812.e',
'tobuke','est.tobukene.27827869.e',
'toitainerikas','est.toitaineterikas.27829314.e',
'toitainevaene','est.toitainetevaene.27829328.e',
'tornipääsuke','est.tornipääsukene.27834662.e',
'tössike','est.tössikene.27865737.e',
'tsutike','est.tsutikene.27844763.e',
'tutki','est.tutkit.27854294.e',
'tuuleke','est.tuulekene.27854960.e',
'tuumake','est.tuumakene.27855559.e',
'üheksateistaastaselt','est.üheksateistkümneaastaselt.27957461.e',
'üheteistaastaselt','est.üheteistkümneaastaselt.27958167.e',
'vaeneke','est.vaenekene.27885203.e',
'vahepaluke','est.vahepalukene.27887964.e',
'vanainimeslik','est.vanainimeselik.27895372.e',
'vanainimeslikult','est.vanainimeselikult.27895388.e',
'vanaisaaegne','est.vanaisadeaegne.27895417.e',
'vaoke','est.vaokene.27897541.e',
'vihmake','est.vihmakene.27912668.e',
'viilpink','est.viilimispink.27914569.e',
'viletsake','est.viletsakene.27918008.e',
'viletsushunnik','est.viletsusehunnik.27918140.e',
'viletsuspäevad','est.viletsusepäevad.27918153.e',
'virvatuluke','est.virvatulukene.27923015.e',
'voonake','est.voonakene.27926773.e',
'vorstike','est.vorstikene.27927837.e',
'võruke','est.võrukene.27934400.e',
'zombi','est.zombie.23008686.e');		

# ------------------------------------------------------------------------
##-- Gestion des options --##
my ($date, $FichierXML, $FichierResultat, $FichierExport, $erreur, $encoding) = ();
my ($verbeux, $help, $pretty_print, $parse) = ();
GetOptions( 
  'date|time|t=s'        	  => \$date, # flag de type -date ou --date, ou -time ou --time, ou -t ou --t (=s : string)
  'source|in|from|i=s'        => \$FichierXML, 
  'sortie|out|to|o=s'         => \$FichierResultat, 
  'export|export|x=s'         => \$FichierExport, 
  'erreur|error|e=s'     	  => \$erreur, 
  'encodage|encoding|enc|f=s' => \$encoding, 
  'help|h'                	  => \$help, 
  'verbeux|v'             	  => \$verbeux, 
  'prettyprint|pretty|p=s'	  => \$pretty_print,
  );

if (!(defined $date))	{$date = localtime;};
if (!(defined $FichierXML)) {&help;};
	# si le fichier source n'est pas spécifié, affichage de l'aide.
if (!(defined $FichierResultat)) {$FichierResultat = $FichierXML.'.out';};
if (!(defined $FichierExport)) {$FichierExport = $FichierXML.'.export';};
if (!(defined $erreur)) {$erreur = "|ERROR| : problem opening file :";};
if (!(defined $encoding)) {$encoding = "UTF-8";};
if (!(defined $pretty_print)) {$pretty_print = 'indented';};
if (defined $help) {&help;};

# ------------------------------------------------------------------------
if ( defined $verbeux )	{&info('a');};
# message dans le STDERR (voir subroutine 'info') indiquant le démarrage du programme.

my $output = new IO::File(">$FichierResultat");
my $export = new IO::File(">$FichierExport");

# =======================================================================================================================================
###--- TWIG ---###

my $twig = XML::Twig->new
(
output_encoding => $encoding, # on reste en utf8
Twig_handlers   => {$in_entry => \&entry,}, 
);
$twig->parsefile($FichierXML);
my $root = $twig->root; 


sub entry 
{
my ($twig, $twig_entry) = @_;

my $headword = $twig_entry->findvalue('//'.$in_match);
my $printed = 0;
foreach my $word (keys %list) {
	if ($word eq $headword) {
		$twig->print($export);
		print $export $list{$word};
		$printed = 1;
		last;
	}
}
if (!$printed) {
	$twig->print($output);
}

$twig->purge();
return;
}

# ------------------------------------------------------------------------
if ( defined $verbeux ) {&info('d');};


# =======================================================================================================================================
###--- SUBROUTINES ---###
sub info
{
my $info = shift @_;
if ($info =~ 'a')
	{
	print (STDERR "================================================================================\n");
	print (STDERR "\t~~~~ $0 : START ~~~~\n");
	print (STDERR "================================================================================\n");
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