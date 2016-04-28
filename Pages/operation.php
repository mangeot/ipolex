<?php
require_once('../init.php');
require_once(RACINE_SITE.'include/lang_'.$LANG.'.php');
require_once(RACINE_SITE.'include/fonctions.php');

echo $_POST['nomvolume'];
$dico = $_POST['nomdico'];
echo $dico;
$chemin = DICTIONNAIRES_SITE.$dico.'/';
$metadataFile = $chemin.$_POST['nomvolume'].'-metadata.xml';
	$doc = new DOMDocument();
	$doc->load($metadataFile);
	$cdmvolume=$doc->getElementsByTagName("cdm-volume");
	$cdmentry=$doc->getElementsByTagName("cdm-entry");
	$cdmpos=$doc->getElementsByTagName("cdm-pos");
	$cdmheadword=$doc->getElementsByTagName("cdm-headword");


  foreach($cdmvolume as $volume)
  {

    if ($volume->hasAttribute("xpath")) {
        $xpathvolume=$volume->getAttribute("xpath");
        echo $xpathvolume;
       $cdmvol=preg_replace('#^/([a-z]+)$#','$1',$xpathvolume);
       echo "cdm-volume:".$cdmvol;

    }
    }	

  foreach($cdmentry as $entry)
  {
   
    if ($entry->hasAttribute("xpath")) {
        $xpathentry=$entry->getAttribute("xpath");
       $cdment=preg_replace('#.+/([^/]+)$#','$1',$xpathentry);
       echo 'cdm-entry:'.$cdment;

    }

  }


foreach($cdmheadword as $headword)
  {
   
    if ($headword->hasAttribute("xpath")) {
        $xpathheadword=$headword->getAttribute("xpath");
       $cdm_head=preg_replace('#/([a-z_]+/)+([a-z_]+)/(text\(\))$#','$2',$xpathheadword);
       echo 'cdm-headword:'.$cdm_head;

    }

  }

foreach($cdmpos as $pos)
  {
   
    if ($pos->hasAttribute("xpath")) {
        $xpathpos=$pos->getAttribute("xpath");
       $cdm=preg_replace('#.+/([^/]+)/([^/]+)$#','$2',$xpathpos);
       if ($cdm=="text()"){
      $cdmpos=preg_replace('#.+/([^/]+)/([^/]+)$#','$1',$xpathpos);
  }
      else $cdmpos=$cdm;

       echo 'cdm-pos:'.$cdmpos;
    }
}

  



    if ($_POST['op']=='prep')
    {
    	$datafile_prep = $chemin.strtolower($_POST['nomvolume']).'.xml';
    $resultat_prep=$chemin . strtolower($_POST['nomvolume'])."-prep.xml";
    echo "<br>perl /projets/iBaatukaay/Scripts/prep_articles.pl $datafile_prep $resultat_prep $cdment<br>";
    exec("perl /projets/iBaatukaay/Scripts/prep_articles.pl $datafile_prep $resultat_prep $cdment");
    echo "opération de préparation réussie";

    }


    elseif ($_POST['op']=='tri')
    {
    	$datafile_tri = $chemin.strtolower($_POST['nomvolume']).'-prep.xml';
    	 $resultat_tri=$chemin . strtolower($_POST['nomvolume'])."-tri.xml";
    //	exec("/projets/iBaatukaay/Scripts/W_for_Sort_wol.pl $_POST['ressource'] $cdment $cdm_head $cdmpos $_POST['nomvolume']_tri.xml");
    	echo "perl /projets/iBaatukaay/Scripts/W_for_Sort_wol.pl $datafile_tri '$cdment' '$cdm_head' '$cdmpos' $resultat_tri";
    	exec("perl /projets/iBaatukaay/Scripts/W_for_Sort_wol.pl $datafile_tri $cdment $cdm_head $cdmpos $resultat_tri");
    	echo "opération de tri réussie";
    	#}else
    	#	{echo "/projets/iBaatukaay/Scripts/W_for_Sort_wol.pl $XML_FILE $cdment $cdm_head $cdmpos $VOLUME_NAME"."<br>probléme exec PERL  !!!!!!!!!!<br>";}
    	}







?>