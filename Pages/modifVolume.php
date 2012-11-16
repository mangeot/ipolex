<?php
	require_once('../init.php');
	require_once(RACINE_SITE.'include/langues.php');
	require_once(RACINE_SITE.'include/fonctions.php');

	$Params = array();
	
	if (empty($_REQUEST['Dirname']) || empty($_REQUEST['Dictname']) || empty($_REQUEST['Source'])) {
		header('Location:index.php');
	}
	$source = $_REQUEST['Source'];
	$targets = array_filter(explode(' ',$_REQUEST['Targets']));
	$name = makeName($_REQUEST['Dictname'],$source,$targets);
	$doc = new DOMDocument();
	$metadataFile = DICTIONNAIRES_SITE.'/'.$_REQUEST['Dirname']."/".$name.'-metadata.xml';
	if (empty($_REQUEST['Editer']) || !file_exists($metadataFile)) {creerVolume($_REQUEST);}
	$doc->load($metadataFile);
	$dicts = $doc->getElementsByTagName("volume-metadata");
	$dict = $dicts->item(0);
	$Params['Dirname'] = $_REQUEST['Dirname'];
	$Params['Dictname'] = $_REQUEST['Dictname'];
	$Params['Name'] = $dict->getAttribute('name');
	$Params['Source'] = $dict->getAttribute('source-language');
	$Params['Targets'] = $dict->getAttribute('target-languages');
	$Params['Encoding'] = $dict->getAttribute('encoding');
	$Params['CreationDate'] = $dict->getAttribute('creation-date');
	$Params['InstallationDate'] = $dict->getAttribute('installation-date');
	$Params['Format'] = $dict->getAttribute('format');
	$Params['HwNumber'] = $dict->getAttribute('hw-number'); 
	$Params['Authors'] = $dict->getElementsByTagName('authors')->item(0)->nodeValue;
	$Params['Comments'] = $dict->getElementsByTagName('comments')->item(0)->nodeValue;
	$Params['Administrators'] = $dict->getElementsByTagName('user-ref')->item(0)->getAttribute('name');
	$cdmElements = $dict->getElementsByTagName('cdm-elements')->item(0)->childNodes;
	foreach ($cdmElements as $node) {
		if ($node->nodeType == XML_ELEMENT_NODE) {
			$nom = $node->nodeName;
			if (!empty($CDMElements[$nom])) {
				if ($nom == 'cdm-translation' || $nom == 'cdm-translation-ref'
					|| $nom == 'cdm-example' || $nom == 'cdm-idiom') {
					$lang = $node->getAttributeNS(DML_PREFIX,'lang');
					$nom .= '_'.$lang; 
				}
				$Params[$nom] =  $node->getAttribute('xpath');
			}
			else {
				if (empty($Params['CDMFreeElementsName'])) {$Params['CDMFreeElementsName']=array();}
				if (empty($Params['CDMFreeElementsValue'])) {$Params['CDMFreeElementsValue']=array();}
				array_push($Params['CDMFreeElementsName'],$nom);
				array_push($Params['CDMFreeElementsValue'],$node->getAttribute('xpath'));
			}
		}
  	}

	if ($Params['Format']=='xml') {
		$myFile = DICTIONNAIRES_SITE.'/'.$_REQUEST['Dirname']."/".strtolower($name).'-template.xml';
		if (file_exists($myFile)) {
			$Params['Template'] = file_get_contents($myFile);
		}
                $xslsheets = $dict->getElementsByTagName('xsl-stylesheet');
                $sheets = array();
                foreach ($xslsheets as $xslsheet) {
                        array_push($sheets,$xslsheet->getAttribute('name'));
                }
                $Params['XslStylesheet'] = $sheets;

	}
	$modif = !empty($Params['Template']);
	include(RACINE_SITE.'include/header.php');
?>
<div id="enTete">
	<h1>Site des dictionnaires</h1>
	<h2>Ajout/modification d'un volume</h2>
	<hr />
</div>
<div id="partieCentrale">
<?php
	if (!empty($_REQUEST['Enregistrer'])) {
		enregistrerVolume($Params);
	}
?>
<form action="?" method="post">
<fieldset name="Gérer un volume">
<legend>Gestion d'un volume</legend>
<div>
	<p>Nom du dictionnaire : <?php affichep('Dictname')?>; 
	langue source : <?php echo $LANGUES[$source]?>; 
	langues cible : <?php foreach ($targets as $cible) {echo $LANGUES[$cible],', ';}?></p>
	<p>Nombre d'entrées : <input type="text" id="HwNumber" name="HwNumber"  value="<?php affichep('HwNumber')?>"/></p>
	<p>*Format : <select id="Format" name="Format" onchange="this.form.submit()">
		<option value="">choisir...</option>
		<?php afficheo('Format',"xml")?>xml</option>
		<?php afficheo('Format',"txt")?>texte</option>
		<?php afficheo('Format',"csv")?>csv (excel)</option>
		<?php afficheo('Format',"ao")?>ariane</option>
		<?php afficheo('Format',"unl")?>unl</option>
		<?php afficheo('Format',"rtf")?>RTF</option>
		<?php afficheo('Format',"odt")?>ODT (OpenDocument)</option>
		<?php afficheo('Format',"other")?>autre</option>
	</select>
	</p>
	<p>Encodage : <input type="text" id="Encoding" name="Encoding"  value="<?php affichep('Encoding','UTF-8')?>"/></p>
	<?php if (!empty($Params['Format']) && $Params['Format']=='xml') {
		$langs = $targets;
		array_push($langs,$source);
		sort($langs,SORT_LOCALE_STRING);
		echo '<p>*Pointeurs CDM <a href="http://fr.wikipedia.org/wiki/XPath">XPath</a> :<br/>
		Attention, n\'oubliez pas de vider
		la description d\'un pointeur s\'il ne correspond à rien dans votre structure !</p>
		  <ul>',"\n";
		  foreach ($CDMElements as $nom => $element) {
		  	if ($nom=='cdm-translation'||$nom=='cdm-translation-ref') {$langs= $targets;}
		  	if ($nom=='cdm-example'||$nom=='cdm-idiom'||$nom=='cdm-translation'||$nom=='cdm-translation-ref') {
				foreach ($langs as $cible) {
					echo '<li>',$element[0],$LANGUES[$cible], ' : <input type="text" size="70" id="',$nom,'_',$cible,'" name="',$nom,'_',$cible,'"  value="', affichep($nom.'_'.$cible,$element[1]),'"/> ',$element[2],"\n";
				}
		  	}
		  	else {
				echo '<li>',$element[0], ' : <input type="text" size="70" id="',$nom,'" name="',$nom,'"  value="', affichep($nom,$element[1]),'"/> ',$element[2],"\n";
		  	}
		  }
		  if (!empty($Params['CDMFreeElementsName'])) {
			echo '<li style="list-style-type:none;">Éléments CDM spécifiques à un volume :</li>';
			$Valeurs = $Params['CDMFreeElementsValue'];
			$i=0;			
			foreach ($Params['CDMFreeElementsName'] as $nom) {
				$valeur = $Valeurs[$i++];
				echo '<li><input type="text" size="30" name="CDMFreeElementsName[]" value="', $nom,'"/> : ',"\n";
				echo '<input type="text"  size="80" name="CDMFreeElementsValue[]" value="', $valeur,'"/></li>',"\n";
			}
		  }
			echo '		  </ul>';
		echo '<p>*Article XML modèle (vide) :
			<textarea name="Template" id="Template" cols="40" rows="10">';
		if (!empty($Params['Template'])) {
			echo stripslashes($Params['Template']);
		}
		else {
			echo '&lt;?xml version="1.0"?>
&lt;volume>
	&lt;entry id="">
		&lt;headword>&lt;/headword>
	&lt;/entry>
&lt;/volume>
';
		}
		echo '</textarea>
		</p>';
	}
	?>
	<a href="#" onclick="document.getElementById('moreInfo').style.display='block'">Plus d'infos</a><br/>
	<div id="moreInfo" style="display:none;">
	Répertoire : <input type="text" size="50" name="Dirname" value="<?php affichep('Dirname')?>" /><br/>
	Nom : <input type="text" size="50" name="Name" value="<?php affichep('Name')?>" /><br/>
 URL des métadonnées :
 <?php echo 'file://',DICTIONNAIRES_SITE, '/';affichep('Dirname');echo '/',affichep('Name');echo '-metadata.xml';?><br/>
	Date de création : <input type="text"  size="50" name="CreationDate" value="<?php affichep('CreationDate',date('c'))?>" /><br/>
	Date d'installation :<input type="text"  size="50" name="InstallationDate" value="<?php affichep('InstallationDate',date('c'))?>" /><br/>
	Auteurs : <input type="text"  size="100" name="Authors" value="<?php affichep('Authors')?>" /><br/>
	Administrateurs : <input type="text" size="100" id="Administrators" name="Administrators" value="<?php $u=!empty($_SERVER['PHP_AUTH_USER'])?$_SERVER['PHP_AUTH_USER']:'';affichep('Administrators',$u);?>"/><br/>	
	XmlschemaRef : <input type="text"  size="100" name="XmlschemaRef" value="<?php affichep('XmlschemaRef')?>" /><br/>
	TemplateInterfaceRef : <input type="text"  size="100" name="TemplateInterfaceRef" value="<?php affichep('TemplateInterfaceRef')?>" /><br/>
	<input name="Dictname" type="hidden" id="Dictname"  value="<?php affichep('Dictname')?>" />
	<input name="Source" type="hidden" id="Source"  value="<?php affichep('Source')?>"/>
	<input name="Targets" type="hidden" id="Targets"  value="<?php affichep('Targets')?>"/>
	<?php $xsls = $Params['XslStylesheet'];
		foreach ($xsls as $xsl) {
			echo 'Stylesheet : <input type="text" name="XslStylesheet[]" value="',$xsl,'" /><br/>
	';}?>
	Commentaires : 	<input type="text" size="100" name="Comments" value="<?php affichep('Comments')?>" /><br/>
	</div>
	<?php
		if (!empty($Params['Dictname']) && !empty($Params['Format']) && !empty($Params['Source'])) {
			echo '<p style="text-align:center;"><input type="submit" name="Enregistrer" value="Enregistrer" /></p>';
		}
	?>

</fieldset>
</form>
<?php
	
	//require_once(RACINE_SITE . 'include/connexion.php');
	
	function affichep ($param,$default='') {
		global $Params;
		global $modif;
		$default = $modif?'':$default;
		echo !empty($Params[$param])?$Params[$param]:$default;
	}
	function afficheo ($param, $option) {
		global $Params;
		echo '<option value="',$option,'"';
		if (!empty($Params[$param]) && $Params[$param]==$option) echo ' selected="selected" ';
		echo '>';
	}
	
	function afficheLangues($option,$default='') {
		if (empty($option)) {
			$option= $default;
		}
		global $LANGUES;
		global $langs;
		foreach ($langs as $val) {
    		echo "<option value='" . $val . "'";
    		if ($val==$option) {echo ' selected="selected" ';}
    		echo ">" . $LANGUES[$val] . "</option>\n";
		}
	}
		
	function creerVolume($params) {
		$cibles = array_filter(explode(' ',$params['Targets']));
		$name = makeName($params['Dictname'],$params['Source'],$cibles);
		$volumeMetadata = creerVolumeMetadata($params,$name,$cibles);
		$myFile = DICTIONNAIRES_SITE.'/'.$params['Dirname']."/".$name.'-metadata.xml';
		$fh = fopen($myFile, 'w') or die("impossible d'ouvrir le fichier ".$myFile);
		fwrite($fh, $volumeMetadata);
		fclose($fh);
		$dataFileName = strtolower($name);
		$templateFileName = $dataFileName . '-template.xml';
		if (!empty($params['Format']) && $params['Format']=='xml' && !empty($params['Template'])) {
			$myFile = DICTIONNAIRES_SITE.'/'.$params['Dirname']."/".$templateFileName;
			$fh = fopen($myFile, 'w') or die("impossible d'ouvrir le fichier ".$myFile);
			fwrite($fh, stripslashes($params['Template']));
			fclose($fh);
		}
	}
	
	function enregistrerVolume($params) {
		if ($params['Format']=='xml' && (empty($params['cdm-volume'])
											|| empty($params['cdm-entry'])
											|| empty($params['cdm-entry-id'])
											|| empty($params['cdm-headword']))) {
			echo '<p style="color:red;">Attention, vous devez impérativement remplir les pointeurs
			CDM précédés d\'un astérisque *</p>';
		}
		else {
			$cibles = array_filter(explode(' ',$params['Targets']));
			$name = makeName($params['Dictname'],$params['Source'],$cibles);
			if ($params['Format']=='xml' && empty($params['XslStylesheet'])) {
				$filepath = DICTIONNAIRES_SITE.'/' . $params['Dirname'] . '/' . $name;
				$pron = !empty($params['cdm-pronunciation'])?$params['cdm-pronunciation']:'';
				$pos = !empty($params['cdm-pos'])?$params['cdm-pos']:'';
				$example = !empty($params['cdm-example'])?$params['cdm-example']:'';
				$idiom = !empty($params['cdm-idiom'])?$params['cdm-idiom']:'';
				createXslStylesheet($filepath,$params['cdm-entry'],$params['cdm-entry-id'],$params['cdm-headword'],
					$pron,$pos,$example,$idiom);
				$sheets = array();
				array_push($sheets,$name);
				$params['XslStylesheet'] = $sheets;
				creerVolume($params);
			}
			
			$dataFileName = strtolower($name);
			$dataFileName .= '.'.$params['Format'];			
			
			echo '<p>Le fichier de métadonnées du volume est créé. Vous pouvez maintenant 
			ouvrir le dossier du volume sur votre bureau en <a href="http://fr.wikipedia.org/wiki/WebDAV">WebDav</a> avec l\'adresse URL suivante : 
			<a href="',DICTIONNAIRES_DAV,'/',$params['Dirname'],'/">',DICTIONNAIRES_DAV,'/',$params['Dirname'],'/</a>
			 (vous seul avez les droits d\'écriture sur ce dossier).</p>
			<p>Téléversez ensuite le fichier de données du volume en le renommant 
			avec le nom suivant : <code><strong>',$dataFileName,'</strong></code>.</p>
			<p>Une fois que vous avez terminé, retournez sur la page de 
			<a href="modifDictionnaire.php?Modifier=on&Dirname=',$params['Dirname'],'&Name=',$params['Dictname'],'">modification du dictionnaire</a>.</p>';
		}
	}
?>
</div>
<?php include(RACINE_SITE.'include/footer.php');?>
