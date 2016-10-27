<?php
	require_once('../init.php');

	$Params = array();
	
	if (empty($_REQUEST['Dirname']) || empty($_REQUEST['Dictname']) || empty($_REQUEST['Source'])) {
		header('Location:index.php');
	}
	
	$source = $_REQUEST['Source'];
	$targets = array_filter(explode(' ',$_REQUEST['Targets']));
	$name = makeName($_REQUEST['Dictname'],$source,$targets);
	$metadataFile = DICTIONNAIRES_SITE.'/'.$_REQUEST['Dirname']."/".$name.'-metadata.xml';	
	$analysisFile = DICTIONNAIRES_SITE.'/'.$_REQUEST['Dirname']."/".$name.'-analysis.html';	
	$analysisLink = DICTIONNAIRES_WEB.'/'.$_REQUEST['Dirname']."/".$name.'-analysis.html';	

	$parameters = 'Dirname='.$_REQUEST['Dirname'].'&Dictname='.$_REQUEST['Dictname'].'&Source='.$_REQUEST['Source'];
	$parameters .= '&Targets='.$_REQUEST['Targets'].'&Authors='.$_REQUEST['Authors'].'&Administrators='.$_REQUEST['Administrators'];

	if (!file_exists($metadataFile)) {
		header('Location:creerVolume.php?'.$parameters);
	}
	
	$modif = false;
	if (!empty($_REQUEST['Administrators'])) {
		$user=!empty($_SERVER['PHP_AUTH_USER'])?$_SERVER['PHP_AUTH_USER']:DEFAULT_TEST_USER;
		$admins = preg_split("/[\s,;]+/", $_REQUEST['Administrators']);
		$modif = in_array($user, $admins);
		if ($modif && (!empty($_REQUEST['Enregistrer']) || !empty($_REQUEST['AjoutLien']) || !empty($_REQUEST['AjoutCDMFreeElement']))) {
			$Params = $_REQUEST;
			$Params['Name'] = $name;
			if (!empty($_REQUEST['AjoutLien'])) {
				$LinkCopy = $CDMLink;
				if (empty($Params['CDMLinks'])) {
					$Params['CDMLinks'] = array();
				}
				array_push($Params['CDMLinks'],$LinkCopy);
			}
			if (!empty($_REQUEST['AjoutCDMFreeElement'])) {
				if (empty($Params['CDMFreeElementsName'])) {$Params['CDMFreeElementsName']=array();}
				if (empty($Params['CDMFreeElementsValue'])) {$Params['CDMFreeElementsValue']=array();}
				array_push($Params['CDMFreeElementsName'],'nom');
				array_push($Params['CDMFreeElementsValue'],'valeur');
			}
			enregistrerVolume($Params);
		}
		if ($modif && !empty($_REQUEST['CompterEntrees'])) {
			$Params = $_REQUEST;
			$Params['Name'] = $name;
			$Params['HwNumber'] = compterEntrees($Params);
			enregistrerVolume($Params);
		}
	}
	
	$Params = array();


	$doc = new DOMDocument();
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
	$administrators = $dict->getElementsByTagName('user-ref');
	$adminString = '';
	foreach ($administrators as $user) {
		$adminString .= $user->getAttribute('name') . ',';
	}
	$Params['Administrators'] = trim($adminString,',');
	$cdmElements = $dict->getElementsByTagName('cdm-elements')->item(0)->childNodes;
	foreach ($cdmElements as $node) {
		if ($node->nodeType == XML_ELEMENT_NODE) {
			$nom = $node->nodeName;
			if (!empty($CDMElements[$nom])) {
				if ($nom == 'cdm-translation' || $nom == 'cdm-translation-ref'
					|| $nom == 'cdm-example' || $nom == 'cdm-idiom') {
					$lang = $node->getAttributeNS(DML_PREFIX,'lang');
					if ($lang == 'qaa' && empty($Params[$nom.'_'.$source])) {
						$nom .= '_'.$source; 
						echo 'lang qaa:',$nom;
					}
					else {
						$nom .= '_'.$lang; 
					}
				}
				$Params[$nom] =  $node->getAttribute('xpath');
			}
			else if ($nom == 'links') {
				foreach ($node->childNodes as $linkNode) {
					if ($linkNode->nodeType == XML_ELEMENT_NODE && $linkNode->nodeName == 'link') {
						$newLink = array();
						$newLink['name'] = $linkNode->getAttribute('name');
						$newLink['xpath'] = $linkNode->getAttribute('xpath');
						foreach ($linkNode->childNodes as $linkValue) {
							if ($linkValue->nodeType == XML_ELEMENT_NODE) {
								$nom = $linkValue->nodeName;
								$newLink[$nom] = $linkValue->getAttribute('xpath');
							}
						}
						if (empty($Params['CDMLinks'])) {$Params['CDMLinks']=array();}
						array_push($Params['CDMLinks'],$newLink);
					}
				}
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
        $schema = $dict->getElementsByTagName('xmlschema-ref');
        if ($schema->length>0) {
        	$Params['XmlschemaRef']=$schema->item(0)->getAttribute('xlink:href');
        }
        $itf = $dict->getElementsByTagName('template-interface-ref');
        if ($itf->length>0) {
        	$Params['TemplateInterfaceRef']=$itf->item(0)->getAttribute('xlink:href');
        }
	}
	include(RACINE_SITE.'include/header.php');
?>
<header id="enTete">
	<?php print_lang_menu();?>
	<h1><?php echo gettext('iPoLex : entrepôt de données lexicales');?></h1>
	<h2><?php echo gettext('Modification des métadonnées du volume');?> <?php affichep('Name')?></h3>
	<hr />
</header>
<div id="partieCentrale">
<?php
	
	$adresseDonnees = $modif?gettext('Adresse WebDAV pour mise à jour des données'):gettext('Adresse WebDAV pour accès aux données');
	echo '<p>',$adresseDonnees,gettext(' : '),'<a href="',DICTIONNAIRES_DAV,'/',$Params['Dirname'],'">',DICTIONNAIRES_DAV,'/',$Params['Dirname'],'</a></p>';
	if ($modif) {
		echo '<p><img src="',RACINE_WEB,'images/assets/b_back.png" alt="back"/><a href="creerVolume.php?',$parameters,'">',gettext('Mise à jour des données par formulaire'),'</a>.</p>';
	}
	echo '<p><img src="',RACINE_WEB,'images/assets/b_back.png" alt="back"/><a href="modifDictionnaire.php?Dirname=',$Params['Dirname'],'&Name=',$Params['Dictname'],'">',gettext('Gestion du dictionnaire'),'</a>.</p>';

?>
<form action="?" method="post">
<fieldset name="Gérer un volume">
<legend><?php echo gettext('Gestion d\'un volume');?></legend>
<div>
	<p><?php echo gettext('Nom du dictionnaire'), gettext(' : ');?><?php affichep('Dictname')?>; 
	<?php echo gettext('langue source'), gettext(' : ');?><?php echo $LANGUES[$source]?>; 
	<?php echo gettext('langues cible'), gettext(' : ');?><?php foreach ($targets as $cible) {echo $LANGUES[$cible],', ';}?></p>
	<p><?php echo gettext('Nom du volume'), gettext(' : ');?><?php affichep('Name')?></p>
	<p><?php echo gettext('Nombre d\'entrées'), gettext(' : ');?><input type="text" id="HwNumber" name="HwNumber"  value="<?php affichep('HwNumber')?>"/>
	<?php if ($Params['Format']=='xml') {echo ' <input type="submit" name="CompterEntrees" value="',gettext('Recompter'),'"/>';};?></p>
	<p>*<?php echo gettext('Format'), gettext(' : ');?><select id="Format" name="Format" onchange="this.form.submit()">
		<option value=""><?php echo gettext('Choisir...');?></option>
		<?php afficheo('Format',"xml")?>xml</option>
		<?php afficheo('Format',"txt")?><?php echo gettext('texte');?></option>
		<?php afficheo('Format',"csv")?>csv (excel)</option>
		<?php afficheo('Format',"ao")?>ariane</option>
		<?php afficheo('Format',"unl")?>unl</option>
		<?php afficheo('Format',"rtf")?>RTF</option>
		<?php afficheo('Format',"odt")?>ODT (OpenDocument)</option>
		<?php afficheo('Format',"other")?><?php echo gettext('autre');?></option>
	</select>
	</p>
	<p><?php echo gettext('Encodage'), gettext(' : ');?><input type="text" id="Encoding" name="Encoding"  value="<?php affichep('Encoding','UTF-8')?>"/></p>
	<?php if (!empty($Params['Format']) && $Params['Format']=='xml') {
		$langs = $targets;
		array_push($langs,$source);
		sort($langs,SORT_LOCALE_STRING);
		echo '<p>*',gettext('Pointeurs CDM <a href="http://fr.wikipedia.org/wiki/XPath">XPath</a>'),gettext(' : '),'<br/>';
		echo gettext('Attention, n\'oubliez pas de vider la description d\'un pointeur s\'il ne correspond à rien dans votre structure !'),'</p>
		  <ul>',"\n";
		  foreach ($CDMElements as $nom => $element) {
		  	if ($nom=='cdm-translation'||$nom=='cdm-translation-ref') {$langs= $targets;}
		  	if ($nom=='cdm-example'||$nom=='cdm-idiom'||$nom=='cdm-translation'||$nom=='cdm-translation-ref') {
		  		if ($nom=='cdm-example'||$nom=='cdm-idiom') {
					echo '<li>',$element[0],' ',$LANGUES[$source], gettext(' : '),'<input type="text" size="70" id="',$nom,'_',$source,'" name="',$nom,'_',$source,'"  value="', affichep($nom.'_'.$source,$element[1]),'"/> ',$element[2],"\n";
				}
				foreach ($langs as $cible) {
					echo '<li>',$element[0],' ',$LANGUES[$cible], gettext(' : '),'<input type="text" size="70" id="',$nom,'_',$cible,'" name="',$nom,'_',$cible,'"  value="', affichep($nom.'_'.$cible,$element[1]),'"/> ',$element[2],"\n";
				}
		  	}
		  	else {
				echo '<li>',$element[0], ' : <input type="text" size="70" id="',$nom,'" name="',$nom,'"  value="', affichep($nom,$element[1]),'"/> ',$element[2],"\n";
		  	}
		  }
		echo '		  </ul>';		  
		echo '<p>',gettext('Éléments CDM spécifiques à un volume'), gettext(' : '),' <input type="submit" name="AjoutCDMFreeElement" id="AjoutCDMFreeElement" value="+" /></p>';
		  if (!empty($Params['CDMFreeElementsName'])) {
			echo '<ul>';
			$Valeurs = $Params['CDMFreeElementsValue'];
			$i=0;			
			foreach ($Params['CDMFreeElementsName'] as $nom) {
				$valeur = $Valeurs[$i++];
				echo '<li><input type="text" size="30" name="CDMFreeElementsName[]" value="', $nom,'"/> : ',"\n";
				echo '<input type="text"  size="80" name="CDMFreeElementsValue[]" value="', $valeur,'"/></li>',"\n";
			}
		  }
			echo '		  </ul>';
			
		echo '<p>',gettext('Liens vers d\'autres entrées'), gettext(' : '),' <input type="submit" name="AjoutLien" id="AjoutLien" value="+" /></p>';
		if (empty($Params['CDMLinks'] )) {
			$Params['CDMLinks']  = array();
		}
		$i = 0;
		foreach ($Params['CDMLinks'] as $cdmlink) {
			echo '<p>',gettext('Lien'),gettext(' : '),$i,'</p><ul> ';
			foreach ($cdmlink as $nom => $valeur) {
				echo '<li>',$CDMLinkInfo[$nom][0], ' : <input type="text" size="70" id="CDMLinks[',$i,'][',$nom,']" name="CDMLinks[',$i,'][',$nom,']"  value="', $valeur,'"/> ',$CDMLinkInfo[$nom][1],"\n";
			}
			$i++;
			echo '</ul>';
		}
		echo '<p>*',gettext('Article XML modèle (vide)'), gettext(' : '),'
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
	<a href="#" onclick="document.getElementById('moreInfo').style.display='block'"><?php echo gettext('Plus d\'infos');?></a><br/>
	<div id="moreInfo" style="display:none;">
	<?php echo gettext('Répertoire'), gettext(' : ');?><input type="text" size="50" name="Dirname" value="<?php affichep('Dirname')?>" /><br/>
	<?php echo gettext('Nom'), gettext(' : ');?><input type="text" size="50" name="Name" value="<?php affichep('Name')?>" /><br/>
 <?php echo gettext('URL des métadonnées'), gettext(' : ');?>
 <?php echo 'file://',DICTIONNAIRES_SITE, '/';affichep('Dirname');echo '/',affichep('Name');echo '-metadata.xml';?><br/>
	 <?php echo gettext('Date de création'), gettext(' : ');?><input type="text"  size="50" name="CreationDate" value="<?php affichep('CreationDate',date('c'))?>" /><br/>
	<?php echo gettext('Date d\'installation'), gettext(' : ');?><input type="text"  size="50" name="InstallationDate" value="<?php affichep('InstallationDate',date('c'))?>" /><br/>
	<?php echo gettext('Auteurs'), gettext(' : ');?><input type="text"  size="100" name="Authors" value="<?php affichep('Authors')?>" /><br/>
	<?php echo gettext('Administrateurs'), gettext(' : ');?><input type="text" size="100" id="Administrators" name="Administrators" value="<?php $u=!empty($_SERVER['PHP_AUTH_USER'])?$_SERVER['PHP_AUTH_USER']:'';affichep('Administrators',$u);?>"/><br/>	
	XmlschemaRef : <input type="text"  size="100" name="XmlschemaRef" value="<?php affichep('XmlschemaRef')?>" /><br/>
	TemplateInterfaceRef : <input type="text"  size="100" name="TemplateInterfaceRef" value="<?php affichep('TemplateInterfaceRef')?>" /><br/>
	<input name="Dictname" type="hidden" id="Dictname"  value="<?php affichep('Dictname')?>" />
	<input name="Source" type="hidden" id="Source"  value="<?php affichep('Source')?>"/>
	<input name="Targets" type="hidden" id="Targets"  value="<?php affichep('Targets')?>"/>
	<?php 
		$xsls = (!empty($Params['XslStylesheet']))?$Params['XslStylesheet']:array();
		foreach ($xsls as $xsl) {
			echo 'Stylesheet : <input type="text" name="XslStylesheet[]" value="',$xsl,'" /><br/>
	';}?>
	<?php echo gettext('Commentaires'), gettext(' : ');?><input type="text" size="100" name="Comments" value="<?php affichep('Comments')?>" /><br/>
	</div>
	<?php
		if (!empty($Params['Dictname']) && !empty($Params['Format']) && !empty($Params['Source']) && $modif) {
			echo '<p style="text-align:center;"><input type="submit" name="Enregistrer" value="',gettext('Enregistrer'),'" /></p>';
		}
	?>

</fieldset>
</form>
<?php
   		 	if (file_exists($analysisFile)) {
	 			echo '
   				<p><a href="',$analysisLink,'">', gettext('Résultat de l\'analyse'),'</a></p>';
   				}
?>

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
		$name = $params['Name'];
		$volumeMetadata = enregistrerVolumeMetadata($params);
		$myFile = DICTIONNAIRES_SITE.'/'.$params['Dirname']."/".$name.'-metadata.xml';
		file_put_contents($myFile,$volumeMetadata);
		$dataFileName = strtolower($name);
		$templateFileName = $dataFileName . '-template.xml';
		if (!empty($params['Format']) && $params['Format']=='xml' && !empty($params['Template'])) {
			$myFile = DICTIONNAIRES_SITE.'/'.$params['Dirname']."/".$templateFileName;
			file_put_contents($myFile,stripslashes($params['Template']));
		}
	}
	
	function enregistrerVolume($params) {
		if ($params['Format']=='xml' && (empty($params['cdm-volume'])
											|| empty($params['cdm-entry'])
											|| empty($params['cdm-headword']))) {
			echo '<p style="color:red;">',gettext('Attention, vous devez impérativement remplir les pointeurs CDM précédés d\'un astérisque *'),'</p>';
		}
		else {
			$name = $params['Name'];
			$metadataFile = DICTIONNAIRES_SITE.'/'.$_REQUEST['Dirname']."/".$name.'-metadata.xml';	
			if ($params['Format']=='xml' && empty($params['XslStylesheet'])) {
				$filepath = DICTIONNAIRES_SITE.'/' . $params['Dirname'] . '/' . $name;
				$pron = !empty($params['cdm-pronunciation'])?$params['cdm-pronunciation']:'';
				$pos = !empty($params['cdm-pos'])?$params['cdm-pos']:'';
				$example = !empty($params['cdm-example'])?$params['cdm-example']:'';
				$idiom = !empty($params['cdm-idiom'])?$params['cdm-idiom']:'';
				$sense = !empty($params['cdm-sense'])?$params['cdm-sense']:'';
				createXslStylesheet($filepath,$params['cdm-entry'],$params['cdm-entry-id'],$params['cdm-headword'],
					$pron,$pos,$example,$idiom, $sense, $params['Template']);
				$params['XslStylesheet'] = array();
				array_push($params['XslStylesheet'],$name);				
			}
			if ($params['Format']=='xml' && (empty($params['XmlschemaRef']) || !file_exists($params['XmlschemaRef']))  && !empty($params['Template'])) {
				$filepath = DICTIONNAIRES_SITE.'/' . $params['Dirname'] . '/' . strtolower($name);
				$volume = $filepath.'.xml';
				$filepath .= '.xsd';
				creerXmlschema($filepath,$volume);
				$params['XmlschemaRef'] = pathinfo($filepath, PATHINFO_BASENAME);
			}
			creerVolume($params);
			$dataFileName = strtolower($name). '.'.$params['Format'];			
			}
	}
	
	function creerXmlschema($schema, $xmlFile) {
		$bugMAMP = "export DYLD_LIBRARY_PATH=\"\"; ";
		$commande = 'java -jar ' . RACINE_SITE . 'jar/trang.jar ' .  $xmlFile . ' ' . $schema . ' 2>&1';
		//echo 'commande: ',$bugMAMP,$commande;
		$output = exec($bugMAMP.$commande);
		if (!empty($output)) {
			echo '<p style="color:red; font-size:1.2em; font-weight: bold;">Error with jar/trang.jar when generating the XSL schema: <br/><code style="color:black;">',$output,'</code></p>';
		}
	}
	
	function compterEntrees($params) {
		$dataFileName = strtolower($params['Name']). '.'.$params['Format'];
		$filepath = DICTIONNAIRES_SITE.'/' . $params['Dirname'] . '/' . $dataFileName;
		$pointeurCDMEntree = $params['cdm-entry'];
		$baliseEntree = substr($pointeurCDMEntree,strrpos($pointeurCDMEntree,'/')+1);
		$baliseEntree = '</'.$baliseEntree.'>';
		$result = `grep -c '$baliseEntree' $filepath`;
		return $result;			
	}
?>
</div>
<?php include(RACINE_SITE.'include/footer.php');?>
