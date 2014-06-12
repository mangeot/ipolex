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
	include(RACINE_SITE.'include/header.php');
?>
<header id="enTete">
	<?php print_lang_menu();?>
	<h1><?php echo gettext('iPoLex : entrepôt de données lexicales');?></h1>
	<h2><?php echo gettext('Ajout/Modification d\'un dictionnaire');?></h3>
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
<form action="?" method="post">
<fieldset name="Gérer un dictionnaire">
<legend><?php echo gettext('Gestion d\'un dictionnaire');?></legend>
<div>
	<p>*<?php echo gettext('Nom complet'); echo gettext(' : ');?><input type="text" required="required" size="50" id="NameC" name="NameC" value="<?php affichep('NameC')?>" /></p>
	<p>*<?php echo gettext('Nom abrégé'); echo gettext(' : ');?><input type="text" required="required"  pattern="[A-Z][a-zA-Z0-9\-]+"  id="Name" name="Name" onfocus="copyifempty(this,'NameC');" value="<?php affichep('Name')?>"/> <?php echo gettext('Caractères ASCII alphanumériques et tiret uniquement !');?></p>
	<p><?php echo gettext('Propriétaire'); echo gettext(' : ');?><input type="text" id="Owner"  onfocus="copyifempty(this,'Name');" name="Owner"  value="<?php affichep('Owner')?>"/></p>
	<p>*<?php echo gettext('Catégorie'); echo gettext(' : ');?><select id="Category"  required="required" name="Category" onchange="this.form.submit()">
		<option value="">choisir...</option>
		<?php afficheo('Category',"monolingual")?><?php echo gettext('monolingue');?></option>
		<?php afficheo('Category',"bilingual")?><?php echo gettext('bilingue');?></option>
		<?php afficheo('Category',"multilingual")?><?php echo gettext('multilingue');?></option>
	</select>
	</p>
	<?php if (!empty($Params['Category'])) {
		echo '
	<p>*Type : <select id="Type" name="Type" onchange="this.form.submit()">';
		afficheo('Type','monodirectional'); echo gettext('monodirectionnel (1 volume)'),'</option>';
		if ($Params['Category'] !== 'monolingual') {
			afficheo('Type','monovolume'); echo gettext('monovolume (1 volume avec traductions alignées)'),'</option>';
			afficheo('Type','bidirectional'); echo gettext('bidirectionnel (2 volumes La->Lb et Lb->La)'),'</option>';
			afficheo('Type','direct'); echo gettext('direct (2 volumes La et Lb reliés)'),'</option>';
			afficheo('Type','pivot'); echo gettext('pivot (x volumes Lx reliés à 1 volume pivot)'),'</option>';
			afficheo('Type','mixed'); echo gettext('mixé'),'</option>';
		}
		echo '
			</select>
			</p>';
	}
	?>
	<p><?php echo gettext('Contenu');?> <input type="text" id="Contents" name="Contents" value="<?php affichep('Contents','vocabulaire général');?>" /></p>	
	<p><?php echo gettext('Domaine');?> <input type="text" id="Domain" name="Domain" value="<?php affichep('Domain','général');?>"/></p>	
	<p><?php echo gettext('Source');?> <input type="text" id="Source" name="Source" value="<?php affichep('Source','GETALP');?>"/></p>	
	<p><?php echo gettext('Auteurs');?> <input type="text" id="Authors" name="Authors" onfocus="copyifempty(this,'Owner');"  value="<?php affichep('Authors');?>"/></p>	
	<p><?php echo gettext('Licence');?> <input type="text"  size="50" id="Legal" name="Legal" value="<?php affichep('Legal','Creative Commons, CC by SA');?>"/></p>
	<p>*<?php echo gettext('Accès'); echo gettext(' : ');?><select id="Access"  required="required" name="Access">
		<option value="">choisir...</option>
		<?php afficheo('Access',"public")?><?php echo gettext('public = web');?></option>
		<?php afficheo('Access',"restricted")?><?php echo gettext('réservé = labo');?></option>
		<?php afficheo('Access',"private")?><?php echo gettext('privé = admin');?></option>
	</select>
	</p>

	<p><?php echo gettext('Commentaires');?> <input type="text"  size="50" id="Comments" name="Comments" value="<?php affichep('Comments');?>"/></p>	
	<p><?php echo gettext('Administrateurs');?> <input type="text" id="Administrators" name="Administrators" value="<?php affichep('Administrators',$user);?>"/></p>	
	<p><?php echo gettext('Volumes');?><?php echo gettext(' : ');?><ol>
		<?php 
			$volumes = max(getNumVolumes($Params),getNumVolumes($_REQUEST));
			$i=1;
			while ($i<=$volumes) {
				ajouteVolume($i++);
			}
			if (empty($Params['Category']) || $Params['Category'] !== 'monolingual') {
				ajouteVolumePlus($i);
			}
		?>
		</ol>
	</p>
	<a href="#" onclick="document.getElementById('moreInfo').style.display='block'"><?php echo gettext('Plus d\'infos')?></a><br/>
	<div id="moreInfo" style="display:none;">
	<?php echo gettext('Répertoire'),gettext(' : ');?>	<input type="text" size="50" name="Dirname" value="<?php affichep('Dirname')?>" /><br/>
	<?php echo gettext('URL des métadonnées'),gettext(' : ');?>
	 <?php echo DICTIONNAIRES_DAV, '/';affichep('Dirname');echo '/',affichep('Name');echo '-metadata.xml';?><br/>
	<?php echo gettext('Date de création'),gettext(' : ');?><input type="text"  size="50" name="CreationDate" value="<?php affichep('CreationDate',date('c'))?>" /><br/>
	<?php echo gettext('Date d\'installation'),gettext(' : ');?><input type="text"  size="50" name="InstallationDate" value="<?php affichep('InstallationDate',date('c'))?>" /><br/>
	ResultFormatter: <input type="text"  size="100" name="ResultFormatter" value="<?php affichep('ResultFormatter',DefaultResultFormatter)?>" /><br/>
	ResultPreprocessor: <input type="text"  size="100" name="ResultPreprocessor" value="<?php affichep('ResultPreprocessor')?>" /><br/>
	ResultPostupdateprocessor: <input type="text"  size="100" name="ResultPostupdateprocessor" value="<?php affichep('ResultPostupdateprocessor',DefaultResultPostUpdateProcessor)?>" /><br/>
	ResultPostsaveprocessor: <input type="text"  size="100" name="ResultPostsaveprocessor" value="<?php affichep('ResultPostsaveprocessor')?>" /><br/>
	<?php
		if (!empty($Params['Links'])) {
		echo 'Links : <textarea name="Links" cols="100" rows="8">',stripslashes($Params['Links']),'</textarea>',"<br/>\n";
		}
		if (!empty($Params['OtherFiles'])) {
		echo 'Other files : <textarea name="OtherFiles" cols="100" rows="8">',stripslashes($Params['OtherFiles']),'</textarea><br/>',"\n";
		}
	?>
	<?php 
			if (!empty($Params['XslStylesheet'])) {
		$xsls = $Params['XslStylesheet'];
		foreach ($xsls as $xsl) {
			echo 'XSL sheet : <input name="XslStylesheet[]" value="',$xsl,'" />
	';}
	}
	?>
	</div>
	<?php
		if ($modif && !empty($Params['Name']) && !empty($Params['Type']) && !empty($Params['Volume1Source'])) {
			echo '<p style="text-align:center;"><input type="submit" name="Enregistrer" value="',gettext('Enregistrer'),'" /></p>';
		}
	?>
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
		$cibles = recupCibles($params);
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
?>
</div>
<?php include(RACINE_SITE.'include/footer.php');?>
