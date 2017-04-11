<?php
	session_start();
	require_once('../init.php');
	
	if (empty($_REQUEST['Dirname']) || empty($_REQUEST['Dictname']) || empty($_REQUEST['Source'])) {
		header('Location:index.php');
	}
	$source = $_REQUEST['Source'];
	$targets = array_filter(explode(' ',$_REQUEST['Targets']));
	$name = makeName($_REQUEST['Dictname'],$source,$targets);
	$folder = DICTIONNAIRES_SITE.'/'.$_REQUEST['Dirname']."/";
	$metadataFile = $folder.$name.'-metadata.xml';	
	$analysisFile = $folder.$name.'-analysis.html';	
	$logFile = $folder.$name.'-analysis-log.txt';	
	$lowerName = strtolower($name);
	$extension = !empty($_REQUEST['Format'])?$_REQUEST['Format']:'';
	$dataFileName = $lowerName;
	$dataFile = $folder.$dataFileName;	
	$templateFileName = $lowerName . '-template.xml';
	$templateFile = $folder.$templateFileName;	
	$analysisLink = DICTIONNAIRES_WEB.'/'.$_REQUEST['Dirname']."/".$name.'-analysis.html';	

// http://2bits.com/articles/installing-php-apc-gnulinux-centos-5.html
//get unique id
$up_id = uniqid();
$ongoing_analysis = !empty($_REQUEST['ongoing_analysis'])?1:0;
$file_uploaded = 0;

//specify redirect URL
$redirect = basename($_SERVER['SCRIPT_FILENAME'])."?success";

//process the forms and upload the files
if (!empty($_REQUEST['Send']) && !empty($_FILES["file"]["name"])) {
	$uploaded_file_name = $folder.$_FILES["file"]["name"];
	//upload the file
	move_uploaded_file($_FILES["file"]["tmp_name"], $uploaded_file_name);

	$extension = pathinfo($_FILES["file"]["name"], PATHINFO_EXTENSION);
	if ($extension == 'zip') {
		exec("unzip $uploaded_file_name -d $folder -x '__MACOSX/*'");
		unlink($uploaded_file_name);
		$uploaded_file_name = pathinfo($uploaded_file_name, PATHINFO_DIRNAME) . '/'. pathinfo_filename($uploaded_file_name);
		$extension = pathinfo($uploaded_file_name, PATHINFO_EXTENSION);
		$dataFileName .='.'.$extension;
		$dataFile .='.'.$extension;
		rename($uploaded_file_name,$dataFile);
	}
	else if ($extension == 'gz') {

		exec("gunzip $uploaded_file_name");
		$uploaded_file_name = pathinfo($uploaded_file_name, PATHINFO_DIRNAME) . '/'. pathinfo_filename($uploaded_file_name);
		$extension = pathinfo($uploaded_file_name, PATHINFO_EXTENSION);
		$dataFileName .='.'.$extension;
		$dataFile .='.'.$extension;
		rename($uploaded_file_name,$dataFile);
	}
	else if ($extension == 'rar') {
		$temp_file_name = pathinfo($uploaded_file_name, PATHINFO_DIRNAME) . '/'. pathinfo_filename($uploaded_file_name);
		$extension = pathinfo($temp_file_name, PATHINFO_EXTENSION);
		$dataFileName .='.'.$extension;
		$dataFile .='.'.$extension;
		exec("unrar p $uploaded_file_name > $dataFile");
		unlink($uploaded_file_name);
	}
	else {
		$dataFileName .='.'.$extension;
		$dataFile .='.'.$extension;
		rename($uploaded_file_name,$dataFile);
	}
	$file_uploaded = 1;
}
else if (!empty($_REQUEST['Format'])) {
	$extension = $_REQUEST['Format'];
	$dataFileName .='.'.$extension;
	$dataFile .='.'.$extension;
}
else if (file_exists($dataFile.'.xml')) {
	$extension = 'xml';
	$dataFileName .='.'.$extension;
	$dataFile .='.'.$extension;
}

if (!empty($_REQUEST['Analyze'])) {
	exec(RACINE_SITE . "pl/dictionary_analysis.pl $dataFile > $analysisFile 2> $logFile &");
	$ongoing_analysis = 1;
}
if (!empty($_REQUEST['BuildMetadata'])) {
    $Encoding = '';
    $HwNumber = '';
    $CDMElements = '';
    $TemplateEntry = '';
	extractInfoFromAnalysis($analysisFile);
	$TemplateEntry = "<?xml version=\"1.0\" ?>\n".$TemplateEntry;
	$vmd = creerVolumeMetadata($extension, $Encoding, $HwNumber, $source, $_REQUEST['Targets'], $name, $_REQUEST['Authors'], $_REQUEST['Administrators'], $CDMElements);
	file_put_contents($metadataFile,$vmd);
	file_put_contents($templateFile,$TemplateEntry);
	$parameters = 'Dirname='.$_REQUEST['Dirname'].'&Dictname='.$_REQUEST['Dictname'].'&Source='.$_REQUEST['Source'];
	$parameters .= '&Targets='.$_REQUEST['Targets'].'&Authors='.$_REQUEST['Authors'].'&Administrators='.$_REQUEST['Administrators'];
	$parameters .= '&Format='.$extension;
	header('Location:modifVolume.php?'.$parameters);
}

?>
<!DOCTYPE html>
<html xml:lang="<?php echo $LANG?>" lang="<?php echo $LANG?>">
<head>
	<meta charset="utf-8" />
	<meta name="author" content="Mathieu MANGEOT" />
	<meta name="keywords" content="<?php echo gettext('iPoLex : entrepôt de données lexicales');?>" />
	<meta name="description" content="<?php echo gettext('iPoLex : entrepôt de données lexicales');?>" />
	<title><?php echo gettext('iPoLex : entrepôt de données lexicales');?></title>
	<link rel="stylesheet" href="<?php echo RACINE_WEB;?>style/site.css" type="text/css" />
	<!--Progress Bar and iframe Styling-->
	<link href="<?php echo RACINE_WEB;?>style/style_progress.css" rel="stylesheet" type="text/css" />
	<script type="text/javascript">
	<!--
		function copyifempty(input, orig) {
			if (input.value=='') {
				input.value=document.getElementById(orig).value;
			}
		}
	// -->
	</script>
<!--Get jQuery-->
<script src="<?php echo RACINE_WEB;?>js/jquery-1.4.0.js" type="text/javascript"></script>
<!--display bar only if file is chosen-->
<script type="text/javascript">
$(document).ready(function() { 

//show the progress bar only if a file field was clicked
	var show_bar = 0;
	var show_analizelog = 0;
    $('input[type="file"]').click(function(){
		show_bar = 1;
    });

//show iframe on form submit
    $("#form1").submit(function(){

		if (show_bar === 1) { 
			$('#upload_frame').show();
			function set () {
				$('#upload_frame').attr('src','<?php echo RACINE_WEB;?>include/upload_frame.php?up_id=<?php echo $up_id; ?>');
			}
			setTimeout(set);
		}
    });
});
</script>
</head>
<body>
<header id="enTete">
	<?php print_lang_menu();?>
	<h1><?php echo gettext('iPoLex : entrepôt de données lexicales');?></h1>
	<h2><?php echo gettext('Ajout d\'un volume');?></h3>
	<hr />
</header>
<section id="partieCentrale">
<?php if ($file_uploaded) {
 	echo '<p><span class="notice">',gettext('Votre fichier de données a été téléversé.'),'</span></p>';
  } ?>
 	<?php
 		echo '<p><img src="',RACINE_WEB,'images/assets/b_back.png" alt="back"/><a href="modifDictionnaire.php?Dirname=',$_REQUEST['Dirname'],'&Name=',$_REQUEST['Dictname'],'">',gettext('Gestion du dictionnaire'),'</a></p>';
	?>
 <form action="" method="post" enctype="multipart/form-data" name="form1" id="form1">
  	<fieldset>
  	 	<h3><?php echo gettext('Téléversement du fichier de données');?></h3>
  <?php 
  		if ($extension == '') {
  			$dataFileName.='[.extension]';
  		}
  		echo '<p>',gettext('Téléversez le fichier de données du volume soit en vous connectant en WebDAV au serveur, soit en utilisant le formulaire ci-dessous.');
  		echo '<br/>',gettext('Vous pouvez compresser le fichier en zip ou gzip avant de l\'envoyer.'),'</p>';
  		echo '<p>',gettext('Adresse WebDAV'),gettext(' : '),'<a href="',DICTIONNAIRES_DAV,'/',$_REQUEST['Dirname'],'">',DICTIONNAIRES_DAV,'/',$_REQUEST['Dirname'],'</a></p>';
  		echo '<p class="note">',gettext('Attention, si vous téléversez votre fichier en WebDAV, renommez-le avec le nom suivant'),gettext(' : ');
  		echo '<strong><code>',$dataFileName,'</code></strong></p>';
  	?>
   <?php echo gettext('Sélectionner le fichier de données à téléverser');?><br />

<!--APC hidden field-->
    <input type="hidden" name="APC_UPLOAD_PROGRESS" id="progress_key" value="<?php echo $up_id; ?>"/>
 	<input type="hidden" name="<?php echo ini_get('session.upload_progress.name'); ?>" value="form1" />

 	<input type="hidden" name="ongoing_analysis" value="<?php echo $ongoing_analysis; ?>" />
 	<input type="hidden" name="Format" value="<?php echo $extension; ?>" />
 	<input type="hidden" name="Dirname" value="<?php echo $_REQUEST['Dirname']; ?>" />
 	<input type="hidden" name="Dictname" value="<?php echo $_REQUEST['Dictname']; ?>" />
 	<input type="hidden" name="Source" value="<?php echo $_REQUEST['Source']; ?>" />
 	<input type="hidden" name="Targets" value="<?php echo $_REQUEST['Targets']; ?>" />
 	<input type="hidden" name="Authors" value="<?php echo $_REQUEST['Authors']; ?>" />
 	<input type="hidden" name="Administrators" value="<?php echo $_REQUEST['Administrators']; ?>" />
<!---->

    <input name="file" type="file" id="file" size="30" />

<!--Include the iframe-->
    <br />
    <iframe id="upload_frame" name="upload_frame" frameborder="0" border="0" src="" scrolling="no" scrollbar="no" > </iframe>
    <br />
<!---->

    <input name="Send" type="submit" id="submit" value="<?php echo gettext('Envoyer');?>" /><br/>
   <?php    if (file_exists($dataFile)) {
       			$file_creation_time = filemtime($dataFile);
       			$file_size = filesize($dataFile);
       			echo '<p>',gettext('Fichier de données actuel'),gettext(' : '),number_format($file_size,0,FORMAT_NOMBRE_DECIMAL,FORMAT_NOMBRE_MILLE), ' ',gettext('octets'), gettext(','),' ',gettext('versé le'),gettext(' : '),date (FORMAT_DATE,$file_creation_time),'</p>';
  		}
  		?>

    </fieldset><br/>
    <?php
    	if (file_exists($dataFile)) {
    		if ($extension == 'xml') {
    		echo ' <fieldset>';
    	 	echo '<h3>',gettext('Analyse du fichier de données'),'</h3>';
    	 	echo '<p>',gettext('Le serveur va analyser le fichier de données pour générer une première version du fichier de métadonnées.'),'</p>';
	 echo '
    <br />
   	<input name="Analyze" type="submit" id="submit" value="', gettext('Analyser'),'" />
   	';
   				if ($ongoing_analysis) {
   				echo '<br/>
   	<iframe id="analyze_frame" src="',RACINE_WEB,'include/analyze_frame.php?filename=',$logFile,'" name="analyze_frame" frameborder="0" border="0" src="" scrolling="no" scrollbar="no" > </iframe>';
    			}
   		 	if (file_exists($analysisFile)) {
	 			echo '
   				<p><a href="',$analysisLink,'" target="_blank">', gettext('Résultat de l\'analyse'),'</a></p>';
   				}
   				echo '</fieldset><br/>';
    		}
   			if ($extension !== 'xml' || file_exists($analysisFile)) {
     		echo ' <fieldset>';
   	 		echo '<h3>',gettext('Génération du fichier de métadonnées'),'</h3>';
    	 	echo '<p>',gettext('Vous pourrez ensuite modifier ce fichier en ligne.'),'</p>';
   			echo '<p><input name="BuildMetadata" type="submit" id="submit" value="', gettext('Générer'),'" /></p>';
   			echo '</fieldset>';
   			}
   		}
     ?>
</form>
</section>
    <?php
    	function extractInfoFromAnalysis($analysis_file) {
    		global $Encoding;
    		global $HwNumber;
    		global $CDMElements;
    		global $TemplateEntry;
    		$doc = new DOMDocument();
			$doc->load($analysis_file);
			$dicts = $doc->getElementsByTagName("volume-metadata");
			$dict = $dicts->item(0);
			$Encoding = $dict->getAttribute('encoding');
			$HwNumber = $dict->getAttribute('hwnumber'); 
			$CDMElements = $dict->getElementsByTagName('cdm-elements');
			$CDMElements = $CDMElements->item(0);
			$TemplateEntry = $doc->getElementsByTagName("template-entry")->item(0);
			$children = $TemplateEntry->childNodes; 
 			for($i = 0; $i < $children->length; $i++) { 
        		$child = $children->item($i); 
	    	    if ($child->nodeType == XML_ELEMENT_NODE) { 
	    	    	$TemplateEntry = $child;
				}
			}
			$TemplateEntry = $doc->saveXML($TemplateEntry);
			$CDMElements = $doc->saveXML($CDMElements);
    	}
    
    	function creerVolumeMetadata($format, $encoding, $hwnumber, $source, $targetstring, $name, $authors, $admins, $cdmElts) {
		$targets = array_filter(explode(' ',$targetstring));
		$langs = $targets;
		array_push($langs,$source);
		sort($langs,SORT_LOCALE_STRING);
		$dbname = preg_replace('/[_\-]/','',strtolower($name));
		$dataFileName = strtolower($name);
		$templateFileName = $dataFileName . '-template.xml';
		$dataFileName .= '.'.$format;
		$res = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<volume-metadata
   xmlns="http://www-clips.imag.fr/geta/services/dml" 
   xmlns:d="http://www-clips.imag.fr/geta/services/dml"
   xmlns:xlink="http://www.w3.org/1999/xlink"
   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
   xsi:schemaLocation="http://www-clips.imag.fr/geta/services/dml
   http://www-clips.imag.fr/geta/services/dml/dml.xsd"
   location="local"
   creation-date="'.date('c').'" 
   installation-date="'.date('c').'" 
   last-modification-date="'.date('c').'" 
   hw-number="'.$hwnumber.'" 
   encoding="'.$encoding.'" 
   format="'.$format.'" 
   name="'.$name.'"
   dbname="'.$dbname.'" 
   version="1"
   source-language="'.$source.'"
   target-languages="'.$targetstring.'"
   reverse-lookup="false">
 <authors>'.$authors.'</authors>
 <comments></comments>
 ';
  $res .= $cdmElts;
  $res .= '
	';  
 
 $res .= '<administrators>
		  <user-ref name="'.$admins.'"/>';
 $res .= '
 </administrators>
 <volume-ref xlink:href="'.$dataFileName.'" source-language="'.$source.'"/>
 ';
 if ($format=='xml') {
 	$res .= '<template-entry-ref xlink:href="'.$templateFileName.'"/>
';}

 $res .= '</volume-metadata>
';
		return $res;
	}

    
    ?>
  <?php include(RACINE_SITE.'include/footer.php');?>
