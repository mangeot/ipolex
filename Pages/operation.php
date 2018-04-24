<?php
require_once('../init.php');
require_once(RACINE_SITE.'include/lang_'.$LANG.'.php');
require_once(RACINE_SITE.'include/fonctions.php');

echo $_POST['nomvolume'];
$dico = $_POST['nomdico'];
$nomDicoArrivee='DicoArrivee_fra-wol';
echo $dico;
$chemin = DICTIONNAIRES_SITE.$dico.'/';
$cheminArrivee = DICTIONNAIRES_SITE.$nomDicoArrivee.'/';



//// Opération de  transformation :
// récupérer metadonnes depart, donnes depart, metadonnes arrivee, tempalte arrivee d
// fabriaquer le nom du fichier donnees arrivee

// appeler le perl de préparation
// entrée : donnes depart 
// sortie : donnes depart prep

// appeler le perl de tri
// entrees donnes depart prep
// sortie donnes depart tri

// appeler le perl de transformation
// entree : donnes depart tri + meta depart , meta arrivee, template arrivee
// sortie : donnes arrivee



//// Opération de fusion 
// récupérer metadonnes A, donnes A, metadonnes B, donnees B

// créer un nouveau dico avec metadonnes de volume A

// appeler le script de préparation sur donnes A et B

// concatener les 2 fichiers de donnees A et B
// `cat fichierA.xml fichierB.xml > fichierC.xml`;

// appeler le script de tri

// appeler le perl de fusion



///// Opération de réification

// récupérer metadonnes depart, donnes depart, 

// appeler le script d'ajout des identifiants 

// appeler le script de réification

#$metadataFile = $chemin.$_POST['nomvolume'].'-metadata.xml';
$metadataEntree = $chemin.$_POST['nomvolume'].'-metadata.xml';
$metadataArrivee =$cheminArrivee.'DicoArrivee_wol_fra-metadata.xml';
$modelArrivee = $cheminArrivee.'dicoarrivee_wol_fra-template.xml';
$dataEntree = $chemin.strtolower($_POST['nomvolume']).'.xml';



  $doc = new DOMDocument();
  $doc->load($metadataEntree);
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

foreach($cdmheadword as $pos)
  {
   
    if ($pos->hasAttribute("xpath")) {
        $xpathpos=$pos->getAttribute("xpath");
       $cdmh=preg_replace('#.+/([^/]+)/([^/]+)$#','$2',$xpathpos);
       if ($cdmh=="text()"){
      $cdmhead=preg_replace('#.+/([^/]+)/([^/]+)$#','$1',$xpathpos);
  }
      else $cdmhead=$cdm;

       echo 'cdm-headword:'.$cdmhead;
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

  

    if ($_POST['op']=='transformation')
    {
      
      $resultat_prep = $chemin.strtolower($_POST['nomvolume']).'-prep.xml';
      $resultat_tri=$chemin.strtolower($_POST['nomvolume'])."-tri.xml";
      $resultat_transformation=$chemin.strtolower($_POST['nomvolume'])."-transfo.xml";
      exec("perl /opt/lampp/htdocs/ipolex-transformation/transformation/prep_articles.pl $dataEntree $resultat_prep $cdment");
      exec("perl /opt/lampp/htdocs/ipolex-transformation/transformation/tri.pl -v -m  $metadataEntree -from $resultat_prep > $resultat_tri");
     exec ("perl /opt/lampp/htdocs/ipolex-transformation/transformation-fichiercomplet.pl -i $resultat_tri -n 'thierno' -m $metadataEntree -s metadataArrivee -t modelArrivee -o $resultat_transformation");
       echo "opération de transformation réussie";




      #}else
      # {echo "/projets/iBaatukaay/Scripts/W_for_Sort_wol.pl $XML_FILE $cdment $cdm_head $cdmpos $VOLUME_NAME"."<br>probléme exec PERL  !!!!!!!!!!<br>";}
      }



    elseif ($_POST['op']=='prep')
    {
      $datafile_prep = $chemin.strtolower($_POST['nomvolume']).'.xml';
    $resultat_prep=$chemin . strtolower($_POST['nomvolume'])."-prep.xml";
    echo "<br>perl /projets/iBaatukaay/Scripts/prep_articles.pl $dataEntree $resultat_prep $cdment<br>";
    exec("perl /projets/iBaatukaay/Scripts/prep_articles.pl $dataEntree $resultat_prep $cdment");
    echo "opération de préparation réussie";

    }


    elseif ($_POST['op']=='tri')
    {
      $datafile_tri = $chemin.strtolower($_POST['nomvolume']).'-prep.xml';
       $resultat_tri=$chemin . strtolower($_POST['nomvolume'])."-tri.xml";
    //  exec("/projets/iBaatukaay/Scripts/W_for_Sort_wol.pl $_POST['ressource'] $cdment $cdm_head $cdmpos $_POST['nomvolume']_tri.xml");
      echo "perl /projets/iBaatukaay/Scripts/W_for_Sort_wol.pl $datafile_tri '$cdment' '$cdmhead' '$cdmpos' $resultat_tri";
      exec("perl /projets/iBaatukaay/Scripts/W_for_Sort_wol.pl $datafile_tri $cdment $cdmhead $cdmpos $resultat_tri");
      exec("perl tri.pl -v -m  $metadataFile -from $resultat_prep > $resultat_tri");
      echo "opération de tri réussie";
      #}else
      # {echo "/projets/iBaatukaay/Scripts/W_for_Sort_wol.pl $XML_FILE $cdment $cdm_head $cdmpos $VOLUME_NAME"."<br>probléme exec PERL  !!!!!!!!!!<br>";}
      }


    elseif ($_POST['op']=='transformation')
    {
      $datafile_tri = $chemin.strtolower($_POST['nomvolume']).'-prep.xml';
       $resultat_tri=$chemin . strtolower($_POST['nomvolume'])."-tri.xml";
    //  exec("/projets/iBaatukaay/Scripts/W_for_Sort_wol.pl $_POST['ressource'] $cdment $cdm_head $cdmpos $_POST['nomvolume']_tri.xml");
      echo "perl /projets/iBaatukaay/Scripts/W_for_Sort_wol.pl $datafile_tri '$cdment' '$cdmhead' '$cdmpos' $resultat_tri";
      exec("perl /projets/iBaatukaay/Scripts/W_for_Sort_wol.pl $datafile_tri $cdment $cdmhead $cdmpos $resultat_tri");
      exec("perl tri.pl -v -m  $metadataFile -from $resultat_prep > $resultat_tri");
      echo "opération de tri réussie";
      #}else
      # {echo "/projets/iBaatukaay/Scripts/W_for_Sort_wol.pl $XML_FILE $cdment $cdm_head $cdmpos $VOLUME_NAME"."<br>probléme exec PERL  !!!!!!!!!!<br>";}
      }





?>
