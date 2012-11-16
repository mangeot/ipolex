<?php
	require_once('../init.php');
	require_once(RACINE_SITE.'include/langues.php');
	require_once(RACINE_SITE.'include/fonctions.php');
	$Params = array();

	$modif = false;	
	if (!empty($_REQUEST['Dirname']) && !empty($_REQUEST['Name'])) {
		$myFile = DICTIONNAIRES_SITE.'/'.$_REQUEST['Dirname']."/".$_REQUEST['Name'].'-metadata.xml';
		$modif = empty($_REQUEST['Consulter']) && file_exists($myFile);
	}
	if ((!empty($_REQUEST['Modifier']) || !empty($_REQUEST['Consulter'])) && $modif) {
		$doc = new DOMDocument();
  		$doc->load($myFile);
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
  		$Params['NameC'] = $dict->getAttribute('fullname');
  		$Params['Contents'] = $dict->getElementsByTagName('contents')->item(0)->nodeValue;
  		$Params['Domain'] = $dict->getElementsByTagName('domain')->item(0)->nodeValue;
  		$Params['Source'] = $dict->getElementsByTagName('source')->item(0)->nodeValue;
  		$Params['Authors'] = $dict->getElementsByTagName('authors')->item(0)->nodeValue;
  		$Params['Legal'] = $dict->getElementsByTagName('legal')->item(0)->nodeValue;
  		$Params['Comments'] = $dict->getElementsByTagName('comments')->item(0)->nodeValue;
  		$Params['Administrators'] = $dict->getElementsByTagName('user-ref')->item(0)->getAttribute('name');

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
		header('Location:modifVolume.php?Editer=on&Dirname='.$Params['Dirname'].'&Dictname='.$Params['Name'].'&Source='.$source.'&Targets='.$targets.'&Authors='.$Params['Authors'].'&Administrators='.$Params['Administrators']);
	}
	include(RACINE_SITE.'include/header.php');
?>
<div id="enTete">
	<h1>Site des dictionnaires</h1>
	<h2>Ajout/Modification d'un dictionnaire</h3>
	<hr />
</div>
<div id="partieCentrale">
<?php
	if (!empty($_REQUEST['Enregistrer']) && !empty($_REQUEST['Name'])) {
		$Params['Dirname'] = creerDictionnaire($Params);
	}
?>
<form action="?" method="post">
<fieldset name="Gérer un dictionnaire">
<legend>Gestion d'un dictionnaire</legend>
<div>
	<p>*Nom complet : <input type="text" size="50" id="NameC" name="NameC" value="<?php affichep('NameC')?>" /></p>
	<p>*Nom abrégé : <input type="text" id="Name" name="Name" onfocus="copyifempty(this,'NameC');" value="<?php affichep('Name')?>"/></p>
	<p>Propriétaire : <input type="text" id="Owner"  onfocus="copyifempty(this,'Name');" name="Owner"  value="<?php affichep('Owner')?>"/></p>
	<p>*Catégorie : <select id="Category" name="Category" onchange="this.form.submit()">
		<option value="">choisir...</option>
		<?php afficheo('Category',"monolingual")?>monolingue</option>
		<?php afficheo('Category',"bilingual")?>bilingue</option>
		<?php afficheo('Category',"multilingual")?>multilingue</option>
	</select>
	</p>
	<?php if (!empty($Params['Category'])) {
		echo '
	<p>*Type : <select id="Type" name="Type" onchange="this.form.submit()">';
		afficheo('Type','monodirectional'); echo 'monodirectionnel (1 volume)</option>';
		if ($Params['Category'] !== 'monolingual') {
			afficheo('Type','monovolume'); echo 'monovolume (1 volume avec traductions alignées)</option>';
			afficheo('Type','bidirectional'); echo 'bidirectionnel (2 volumes La->Lb et Lb->La)</option>';
			afficheo('Type','direct'); echo 'direct (2 volumes La et Lb reliés)</option>';
			afficheo('Type','pivot'); echo 'pivot (x volumes Lx reliés à 1 volume pivot)</option>';
			afficheo('Type','mixed'); echo 'mixé</option>';
		}
		echo '
			</select>
			</p>';
	}
	?>
	<p>Contenu <input type="text" id="Contents" name="Contents" value="<?php affichep('Contents','vocabulaire général');?>" /></p>	
	<p>Domaine <input type="text" id="Domain" name="Domain" value="<?php affichep('Domain','général');?>"/></p>	
	<p>Source <input type="text" id="Source" name="Source" value="<?php affichep('Source','GETALP');?>"/></p>	
	<p>Auteurs <input type="text" id="Authors" name="Authors" onfocus="copyifempty(this,'Owner');"  value="<?php affichep('Authors');?>"/></p>	
	<p>Licence <input type="text"  size="50" id="Legal" name="Legal" value="<?php affichep('Legal','Creative Commons, certains droits réservés');?>"/></p>	
	<p>Commentaires <input type="text"  size="50" id="Comments" name="Comments" value="<?php affichep('Comments');?>"/></p>	
	<p>Administrateur <input type="text" id="Administrators" name="Administrators" value="<?php $u=!empty($_SERVER['PHP_AUTH_USER'])?$_SERVER['PHP_AUTH_USER']:'';affichep('Administrators',$u);?>"/></p>	
	<p>Volumes :<ol>
		<?php $volumes = getNumVolumes($Params);
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
	<a href="#" onclick="document.getElementById('moreInfo').style.display='block'">Plus d'infos</a><br/>
	<div id="moreInfo" style="display:none;">
	Répertoire : 	<input type="text" size="50" name="Dirname" value="<?php affichep('Dirname')?>" /><br/>
	URL des métadonnées :
 <?php echo 'file://',DICTIONNAIRES_SITE, '/';affichep('Dirname');echo '/',affichep('Name');echo '-metadata.xml';?><br/>
	Date de création : <input type="text"  size="50" name="CreationDate" value="<?php affichep('CreationDate',date('c'))?>" /><br/>
	Date d'installation :<input type="text"  size="50" name="InstallationDate" value="<?php affichep('InstallationDate',date('c'))?>" /><br/>
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
	<?php $xsls = $Params['XslStylesheet'];
		foreach ($xsls as $xsl) {
			echo 'XSL sheet : <input name="XslStylesheet[]" value="',$xsl,'" />
	';}?>
	</div>
	<?php
		if (empty($Params['Consulter']) || (!empty($Params['Name']) && !empty($Params['Type']) && !empty($Params['Volume1Source']))) {
			echo '<p style="text-align:center;"><input type="submit" name="Enregistrer" value="Enregistrer" /></p>';
		}
	?>
</div>
</fieldset>
</form>
<?php

	function affichep ($param, $default='') {
		global $modif;
		global $Params;
		$default = $modif?'':$default;
		echo !empty($Params[$param])?stripslashes($Params[$param]):$default;
	}
	function afficheo ($param, $option) {
		global $Params;
		echo '<option value="',$option,'"';
		if (!empty($Params[$param]) && $Params[$param]==$option) echo ' selected="selected" ';
		echo '>';
	}
	
	function ajouteVolume($num) {
		global $Params;
		echo '<li>Langue source : <select id="Volume'.$num.'Source" name="Volume'.$num.'Source" onchange="this.form.submit()">';
		echo '<option value="">Choisir...</option>';
		$source='';
		if (!empty($Params['Volume'.$num.'Source'])) {
			$source = $Params['Volume'.$num.'Source'];
		}
		afficheLanguesOptions($source);
		echo '</select>';
		echo 'Langues cibles : ';
		$targets = getNumCibles($Params,$num);
		$t=1;
		while ($t<=$targets) {
			echo $t, ' : ',ajouteCible($num,$t);
			$t++;
		}
		ajouteCiblePlus($num,$t);
		if (!empty($Params['Name']) && !empty($Params['Type']) && !empty($source) && !empty($Params['Dirname'])) {
			echo '<input type="submit" id="ManageVolume'.$num.'" name="ManageVolume" value="Gérer le volume '.$num.'" />';
		}
		echo '</li>';
	}
	function ajouteCible($vol,$cible) {
		global $Params;
		echo '<select id="Volume'.$vol.'Target'.$cible.'" name="Volume'.$vol.'Target'.$cible.'"  onchange="this.form.submit()">';
		echo '<option value="">Choisir...</option>';
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
		$name = $params['Name'];
		$sources = recupSources($params);
		$cibles = recupCibles($params);
		$langs=array_unique(array_merge($sources,$cibles));
		sort($langs,SORT_LOCALE_STRING);
		$dirname = makeDictName($name,$langs);
		if (!empty($params['Dirname'])) {
			$olddirname = $params['Dirname'];
			if ($dirname !== $olddirname) {
				rename(DICTIONNAIRES_SITE.'/'.$olddirname,DICTIONNAIRES_SITE.'/'.$dirname);
			}
		}
		else {
			@mkdir(DICTIONNAIRES_SITE.'/'.$dirname);
		}
		$dictmetadata = creerDictMetadata($params,$sources,$cibles);
		$myFile = DICTIONNAIRES_SITE.'/'.$dirname."/".$name.'-metadata.xml';
		$fh = fopen($myFile, 'w') or die("impossible d'ouvrir le fichier ".$myFile);
		fwrite($fh, $dictmetadata);
		fclose($fh);
		$admins = array();
		// le jour où je veux mettre plusieurs admins
		array_push($admins,$params['Administrators']);
		restrictAccess($dirname,$admins);
		
		echo '<p>Le fichier de métadonnées du dictionnaire a été enregistré.
		Vous pouvez maintenant gérer les volumes.</p>';
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
		$cibles = array_unique($cibles);
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
