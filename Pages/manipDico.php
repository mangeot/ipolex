<?php
	require_once('../init.php');
	require_once(RACINE_SITE.'include/lang_'.$LANG.'.php');
	require_once(RACINE_SITE.'include/fonctions.php');
	$Params = array();
	$metadataFile = '';
	if (!empty($_REQUEST['Dirname']) && !empty($_REQUEST['Name'])) {
		$metadataFile = DICTIONNAIRES_SITE.'/'.$_REQUEST['Dirname']."/".$_REQUEST['Name'].'-metadata.xml';
	}
	if (empty($_REQUEST['Enregistrer']) && file_exists($metadataFile)) {
		$doc = new DOMDocument();
  		$doc->load($metadataFile);
  		$dicts = $doc->getElementsByTagName("dictionary-metadata");
  		$dict = $dicts->item(0);
  		$Params['Dirname'] = $_REQUEST['Dirname'];
  		$Params['NameC'] = $dict->getAttribute('fullname');
  		$Params['Name'] = $dict->getAttribute('name');
  		$Params['Owner'] = $dict->getAttribute('owner');
  		$Params['Category'] = $dict->getAttribute('category');
  		$Params['Type'] = $dict->getAttribute('type');
  		$Params['CreationDate'] = $dict->getAttribute('creation-date');
  		$Params['InstallationDate'] = $dict->getAttribute('installation-date');
  		$Params['Contents'] = $dict->getElementsByTagName('contents')->item(0)->nodeValue;
  		$Params['Domain'] = $dict->getElementsByTagName('domain')->item(0)->nodeValue;
  		$Params['Source'] = $dict->getElementsByTagName('source')->item(0)->nodeValue;
  		$Params['Authors'] = $dict->getElementsByTagName('authors')->item(0)->nodeValue;
  		$Params['Legal'] = $dict->getElementsByTagName('legal')->item(0)->nodeValue;
  		$Params['Access'] = ($dict->getElementsByTagName('access')->item(0))?$dict->getElementsByTagName('access')->item(0)->nodeValue:'restricted';
  		$Params['Comments'] = $dict->getElementsByTagName('comments')->item(0)->nodeValue;
		$administrators = $dict->getElementsByTagName('user-ref');
		$adminString = '';
		foreach ($administrators as $user) {
			$adminString .= $user->getAttribute('name') . ',';
		}
		$Params['Administrators'] = trim($adminString,',');

		$nodeList = $dict->getElementsByTagName('links');
  		$Params['Links'] = $nodeList->length==1?$doc->saveXML($nodeList->item(0)):'';

		$nodeList = $dict->getElementsByTagName('other-files');
  		$Params['OtherFiles'] = $nodeList->length==1?$doc->saveXML($nodeList->item(0)):'';

		$nodeList = $dict->getElementsByTagName('result-formatter');
  		$Params['ResultFormatter'] = $nodeList->length==1?$nodeList->item(0)->getAttribute('class-name'):'';

		$nodeList = $dict->getElementsByTagName('result-preprocessor');
  		$Params['ResultPreprocessor'] = $nodeList->length==1?$nodeList->item(0)->getAttribute('class-name'):'';

		$nodeList = $dict->getElementsByTagName('result-postupdateprocessor');
  		$Params['ResultPostupdateprocessor'] = $nodeList->length==1?$nodeList->item(0)->getAttribute('class-name'):'';

		$nodeList = $dict->getElementsByTagName('result-postsaveprocessor');
  		$Params['ResultPostsaveprocessor'] = $nodeList->length==1?$nodeList->item(0)->getAttribute('class-name'):'';
  		
  		$volumes = $dict->getElementsByTagName('volume-metadata-ref');
  		$i=1;
  		foreach ($volumes as $volume) {
  			$Params['Volume' . $i . 'Source'] = $volume->getAttribute('source-language');
  			$cibles = $volume->getAttribute('target-languages');
  			$cibles = array_filter(explode(' ',$cibles));
  			$j=1;
  			foreach($cibles as $cible) {
  				$Params['Volume' . $i . 'Target' . $j++] = $cible;
  			}
			$i++;
  		}
  		$nbvol = getNumVolumes($_REQUEST);
  		if ($nbvol>=$i) {
  			$Params['Volume' . $i] = '+';
  			if (!empty($_REQUEST['Volume' . $i . 'Source'])) {
  				$Params['Volume' . $i . 'Source']  = $_REQUEST['Volume' . $i . 'Source'];
  				$j=1;
  				while (!empty($_REQUEST['Volume' . $i . 'Target'. $j])) {
  					$Params['Volume' . $i . 'Target' . $j] = $_REQUEST['Volume' . $i . 'Target'. $j];
  					$j++;
  				}
  			}
  		}

  		$xslsheets = $dict->getElementsByTagName('xsl-stylesheet');
		$sheets = array();
  		foreach ($xslsheets as $xslsheet) {
			array_push($sheets,$xslsheet->getAttribute('name'));	
  		}
  		$Params['XslStylesheet'] = $sheets;
	}
	else {
		$Params = $_REQUEST;
	}
	if (!empty($_REQUEST['ManageVolume'])) {
		$volume = $_REQUEST['ManageVolume'];
		preg_match('/ ([0-9]+)$/',$volume,$matches);
		$volume = intval($matches[0]);
		$source = $Params['Volume'.$volume.'Source'];
		$targets = recupciblesVolume($Params,$volume);		
		header('Location:modifVolume.php?Dirname='.$Params['Dirname'].'&Dictname='.$Params['Name'].'&Source='.$source.'&Targets='.$targets.'&Authors='.$Params['Authors'].'&Administrators='.$Params['Administrators']);
	}

	$dicts = array();
	$srcs = array();
	$langs = array();

// Open a known directory, and proceed to read its contents
if (is_dir(DICTIONNAIRES_SITE)) {
    if ($dh = opendir(DICTIONNAIRES_SITE)) {
        while (($file = readdir($dh)) !== false) {
			if (filetype(DICTIONNAIRES_SITE . '/'.$file)=='dir' 
				&& substr($file,0,1)!== '.'
				&& strpos($file,'_')>0) {
				$souligne = strpos($file,'_');
				$nom = substr($file,0,$souligne);
				$dico = DICTIONNAIRES_SITE . '/'. $file . '/' . $nom . '-metadata.xml';
				if (file_exists($dico)) $infos = parseDict($dico);
				$infos['Dirname']= $file;
				$dicts[$infos['Name']] = $infos;
				foreach ($infos['Volumes'] as $key => $volume) {
					$src = empty($srcs[$key])?array():$srcs[$key];
					$lang = empty($langs[$key])?array():$langs[$key];
					if (empty($src[$infos['Name']])) {
						$src[$infos['Name']] = $infos;
						$srcs[$key] = $src;
					}
					if (empty($lang[$infos['Name']])) {
						$lang[$infos['Name']] = $infos;
						$langs[$key] = $lang;
					}
					if (!empty($volume['Targets'])) {
					foreach ($volume['Targets'] as $key) {
						$lang = empty($langs[$key])?array():$langs[$key];
						if (empty($lang[$infos['Name']])) {
							$lang[$infos['Name']] = $infos;
							$langs[$key] = $lang;
						}
					}
					}
				}
			}
        }
        closedir($dh);
    }
	ksort($dicts,SORT_LOCALE_STRING);
	ksort($srcs,SORT_LOCALE_STRING);
	ksort($langs,SORT_LOCALE_STRING);
}

	include(RACINE_SITE.'include/header.php');
?>
<header id="enTete">
	<?php print_lang_menu();?>
	<h1><?php echo gettext('iPoLex : entrepôt de données lexicales');?></h1>
	<h2><?php echo gettext('Manipulation d\'un dictionnaire');?></h3>
	<hr />
</header>
<div id="partieCentrale">
<?php
	$modif = false;
	$user=!empty($_SERVER['PHP_AUTH_USER'])?$_SERVER['PHP_AUTH_USER']:DEFAULT_TEST_USER;
	if (!empty($Params['Administrators'])) {
		$admins = preg_split("/[\s,;]+/", $Params['Administrators']);
		$modif = in_array($user, $admins);
		if ($modif && !empty($_REQUEST['Enregistrer']) && !empty($Params['Name'])) {
			$Params['Dirname'] = creerDictionnaire($Params);
		}
	}
	
	if (file_exists($metadataFile)) {
		$adresseDonnees = $modif?gettext('Adresse WebDAV pour modification des données'):gettext('Adresse WebDAV pour accès aux données');
		echo '<p>',$adresseDonnees,gettext(' : '),'<a href="',DICTIONNAIRES_DAV,'/',$Params['Dirname'],'">',DICTIONNAIRES_DAV,'/',$Params['Dirname'],'</a></p>';
		if (!empty($Params['Access']) && $Params['Access'] == 'public' && file_exists(DICTIONNAIRES_SITE_PUBLIC.'/'.$Params['Dirname'])) {
			echo '<p>',gettext('Adresse Web pour accès public aux données'),gettext(' : '),'<a href="',DICTIONNAIRES_WEB_PUBLIC,'/',$Params['Dirname'],'">',DICTIONNAIRES_WEB_PUBLIC,'/',$Params['Dirname'],'</a></p>';
		}
	}
?>


<form method="POST" enctype="multipart/form-data" action="operation.php" >
<fieldset name="Manipulation d'un dictionnaire">
<legend><?php echo gettext('Effectuer des opérations sur un dictionnaire');?></legend>
<div>
<p>*<?php echo gettext('Dictionnaire à traiter'); echo gettext(' : ');?>
	<select name="nomdico">
	<option value="choisir" >choisir...</option>
	<?php
	foreach ($dicts as $nom => $dict) {
//	echo $nom, ':', $dict['NameC'];
	afficheo('nomdico',$dict['Dirname']); echo $dict['Name'];?></option>
	<?php

}
	?>
</select>
</p>
	<p>*<?php echo gettext('Volume à traiter'); echo gettext(' : ');?>
	<select name="nomvolume">
	<option value="choisir" >choisir...</option>
	<?php
	foreach ($dicts as $nom => $dict) {
//	echo $nom, ':', $dict['NameC'];
$volumes = $dict['Volumes'];
	//var_dump($dict['Volumes']);
	foreach ($volumes as $src => $volume) {
//	var_dump($volumes[$src])
	afficheo('nomvolume',$volumes[$src]['Name']);echo $volumes[$src]['Name'];?></option>
	<?php



}

}
	?>
</select>
</p>

	<p>*<?php echo gettext(' Choisir l \'opération à effectuer'); echo gettext(' : ');?><br/>
	<input type="radio" value="prep" id="prep" name="op" /><label for="prep"> Préparation</label><br/>
	<input type="radio" value="tri" id="tri" name="op" /><label for="tri"> Tri</label><br/>
	<input type="radio" value="transformation" id="transfo" name="op" /><label for="transfo"> transformation</label><br/>
	</p>
	<p style="text-align:center;">

		<input type="submit" value="Envoyer" id="envoyer"/>
	</p>



</div>

</fieldset>

</form>
<?php

	function affichep ($param, $default='') {
		global $Params;
		echo !empty($Params[$param])?stripslashes($Params[$param]):$default;
	}
	function afficheo ($param, $option) {
		global $Params;
		echo '<option value="',$option,'"';
		if (!empty($Params[$param]) && $Params[$param]==$option) echo ' selected="selected" ';
		echo '>';
	}
	
	function ajouteVolume($num) {
		global $Params, $modif;
		echo '<li>',gettext('Langue source'),gettext(' : '),'<select id="Volume'.$num.'Source" name="Volume'.$num.'Source" onchange="this.form.submit()">';
		echo '<option value="">',gettext('Choisir...'),'</option>';
		$source='';
		if (!empty($Params['Volume'.$num.'Source'])) {
			$source = $Params['Volume'.$num.'Source'];
		}
		afficheLanguesOptions($source);
		echo '</select>';
		echo gettext('Langues cibles'),gettext(' : ');
		$targets = getNumCibles($Params,$num);
		$t=1;
		while ($t<=$targets) {
			echo $t, ' : ',ajouteCible($num,$t);
			$t++;
		}
		ajouteCiblePlus($num,$t);
		if (!empty($Params['Name']) && !empty($Params['Type']) && !empty($source) && !empty($Params['Dirname'])) {
			$manageVolumeString = $modif?gettext('Gérer le volume'):gettext('Voir le volume');
			echo '<input type="submit" id="ManageVolume',$num,'" name="ManageVolume" value="',$manageVolumeString,' ',$num,'" />';
		}
		echo '</li>';
	}
	function ajouteCible($vol,$cible) {
		global $Params;
		echo '<select id="Volume'.$vol.'Target'.$cible.'" name="Volume'.$vol.'Target'.$cible.'"  onchange="this.form.submit()">';
		echo '<option value="">',gettext('Choisir...'),'</option>';
		$option='';
		if (!empty($Params['Volume'.$vol.'Target'.$cible])) {
			$option = $Params['Volume'.$vol.'Target'.$cible];
		}
		afficheLanguesOptions($option);
		echo '</select>';
	}
	
	function ajouteVolumePlus($num) {
		echo '<li><input type="submit" name="Volume'.$num.'" value="+" /></li>';
	}
	function ajouteCiblePlus($vol,$cible) {
		echo '<input type="submit" name="Volume'.$vol.'Target'.$cible.'" value="+"/>';
	}
		
	function afficheLanguesOptions($option) {
		global $LANGUES;
		asort($LANGUES,SORT_LOCALE_STRING);
		foreach ($LANGUES as $key => $val) {
    		echo "<option value='" . $key . "'";
    		if ($key==$option) {echo ' selected="selected" ';}
    		echo ">" . $val . "</option>\n";
		}
	}
	
	function creerDictionnaire($params) {
		$admins = preg_split("/[\s,;]+/", $params['Administrators']);		
		$name = $params['Name'];
		if (!preg_match('/^[a-zA-Z0-9\-]+$/',$name)) {
			echo '<p class="erreur">',gettext('Le nom abrégé du dictionnaire contient des caractères non autorisés !'),'</p>';
			return '';
		}
		$sources = recupSources($params);
		$sources2 = recupSources($_REQUEST);
		$cibles = recupCibles($params);
		$cibles2 = recupCibles($_REQUEST);
		if (count($sources)<count($sources2)) {$sources = $sources2;}
		if (count($cibles)<count($cibles2)) {$cibles = $cibles2;}
		$langs=array_filter(array_unique(array_merge($sources,$cibles)));
		sort($langs,SORT_LOCALE_STRING);
		$dirname = makeDictName($name,$langs);
		if (!empty($params['Dirname'])) {
			$olddirname = $params['Dirname'];
			if ($dirname !== $olddirname) {
				rename(DICTIONNAIRES_SITE.'/'.$olddirname,DICTIONNAIRES_SITE.'/'.$dirname);
				@unlink(DICTIONNAIRES_SITE_PUBLIC.'/'.$olddirname);
			}
		}
		else {
			@mkdir(DICTIONNAIRES_SITE.'/'.$dirname);
		}
		if (!empty($params['Access'])) {
			if ($params['Access'] == 'public') {
				symlink(DICTIONNAIRES_SITE.'/'.$dirname,DICTIONNAIRES_SITE_PUBLIC.'/'.$dirname);
			}
			else {
				@unlink(DICTIONNAIRES_SITE_PUBLIC.'/'.$dirname);
			}
		}
		$dictmetadata = creerDictMetadata($params,$sources,$cibles);
		$myFile = DICTIONNAIRES_SITE.'/'.$dirname."/".$name.'-metadata.xml';
		$fh = fopen($myFile, 'w') or die("impossible d'ouvrir le fichier ".$myFile);
		fwrite($fh, $dictmetadata);
		fclose($fh);
		restrictAccess($dirname,$admins);
		
		echo '<p>',gettext('Le fichier de métadonnées du dictionnaire a été enregistré.
		Vous pouvez maintenant gérer les volumes.'),'</p>';
		return $dirname;
	}
		
	function recupSources($params) {
		$sources = array();
		foreach ($params as $key => $value) {
			if (preg_match('/^Volume[0-9]+Source$/',$key)) {
				array_push($sources,$value);
			}
		}
		sort($sources,SORT_LOCALE_STRING);
		return $sources;
	}
	
	function recupCibles($params) {
		$cibles = array();
		foreach ($params as $key => $value) {
			if (preg_match('/^Volume[0-9]+Target[0-9]+$/',$key)) {
				array_push($cibles,$value);
			}
		}
		$cibles = array_filter(array_unique($cibles));
		sort($cibles,SORT_LOCALE_STRING);
		return $cibles;
	}
	
	function makeDictName($name, $sources) {
		$name .= '_';
		foreach ($sources as $source) {
			$name .= $source . '-';
		}
		$name = substr($name,0,strlen($name)-1);
		return $name;
	}	

		function parseDict($dico) {
		$infos = array();
		$doc = new DOMDocument();
		$doc->load($dico);
		$dicts = $doc->getElementsByTagName("dictionary-metadata");
		$dict = $dicts->item(0);
  		$infos['NameC'] = $dict->getAttribute('fullname');
  		$infos['Name'] = $dict->getAttribute('name');
  		$infos['Owner'] = $dict->getAttribute('owner');
  		$infos['Category'] = $dict->getAttribute('category');
  		$infos['Type'] = $dict->getAttribute('type');
  		$infos['CreationDate'] = $dict->getAttribute('creation-date');
  		$infos['InstallationDate'] = $dict->getAttribute('installation-date');
  		$infos['Category'] = $dict->getAttribute('category');
  		$infos['Type'] = $dict->getAttribute('type');
  		$infos['Contents'] = $dict->getElementsByTagName('contents')->item(0)->nodeValue;
  		$infos['Domain'] = $dict->getElementsByTagName('domain')->item(0)->nodeValue;
  		if (empty($infos['Domain'])) {echo 'domaine vide : ',$dico;}
  		$infos['Source'] = $dict->getElementsByTagName('source')->item(0)->nodeValue;
  		$infos['Authors'] = $dict->getElementsByTagName('authors')->item(0)->nodeValue;
  		//if (empty($infos['Authors'])) {echo 'auteurs vides : ',$dico;}
  		$infos['Legal'] = $dict->getElementsByTagName('legal')->item(0)->nodeValue;
  		$tmp = $dict->getElementsByTagName('comments');
  		if ($tmp->length>0) {$infos['Comments'] = $tmp->item(0)->nodeValue;}
  		$adminNodes = $dict->getElementsByTagName('user-ref');
  		$admins = array();
  		foreach ($adminNodes as $admin) {
  			array_push($admins,$admin->getAttribute('name'));
  		}
		$infos['Administrators'] = $admins; 
  		$volumes = $dict->getElementsByTagName('volume-metadata-ref');
		$infos['Volumes'] = array();
  		foreach ($volumes as $volume) {
  			$source = $volume->getAttribute('source-language');
			$volumeRef = $volume->getAttributeNS(XLINK_PREFIX,'href');
			$volumeRef = dirname($dico) . '/'.$volumeRef;
			$infosVolume = parseVolume($volumeRef);
			$infos['Volumes'][$source] = $infosVolume;
  		}
		return($infos);
	}
	
	function parseVolume($volume) {
		$infos = array();
		if (file_exists($volume)) {
		$doc = new DOMDocument();
		$doc->load($volume);
		$volumes = $doc->getElementsByTagName("volume-metadata");
		$dict = $volumes->item(0);
		$infos['Name'] = $dict->getAttribute('name');
		$infos['Source'] = $dict->getAttribute('source-language');
		$infos['Targets'] = $dict->getAttribute('target-languages');
		$infos['Targets'] = array_filter(explode(' ',$infos['Targets']));
		$infos['Encoding'] = $dict->getAttribute('encoding');
		$infos['CreationDate'] = $dict->getAttribute('creation-date');
		$infos['Format'] = $dict->getAttribute('format');
		$infos['HwNumber'] = $dict->getAttribute('hw-number'); 
		$infos['Authors'] = $dict->getElementsByTagName('authors')->item(0)->nodeValue;
  		//if (empty($infos['Authors'])) {echo 'auteurs vides : ',$volume;}
  		$adminNodes = $dict->getElementsByTagName('user-ref');
  		$admins = array();
  		foreach ($adminNodes as $admin) {
  			array_push($admins,$admin->getAttribute('name'));
  		}
		$infos['Administrators'] = $admins; 
  		$tmp = $dict->getElementsByTagName('comments');
  		if ($tmp->length>0) {$infos['Comments'] = $tmp->item(0)->nodeValue;}
		}
		else {echo 'Erreur : le fichier ',$volume,' n\'existe pas !';}
		return($infos);
	}
	
	function cibles($volumes) {
		$cibles = array();
		foreach ($volumes as $volume) {
			$cibles = array_merge($volume['Targets'],$cibles);
		}
		$cibles = array_unique($cibles);
		sort($cibles,SORT_LOCALE_STRING);
		return $cibles;
	}
	
	function toutesLangues($volumes) {
		$cibles = array();
		foreach ($volumes as $volume) {
			$cibles = array_merge($volume['Targets'],$cibles);
			array_push($cibles,$volume['Source']);
		}
		$cibles = array_unique($cibles);
		sort($cibles,SORT_LOCALE_STRING);
		return $cibles;
	}

?>
</div>
<?php include(RACINE_SITE.'include/footer.php');?>