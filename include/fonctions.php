<?php

	$CDMElements = array(
	'cdm-volume' => array('*Volume','/volume',''),
	'cdm-entry' => array('*Article','/volume/entry',''),
	'cdm-entry-id' => array('*Identifiant unique de l\'article','/volume/entry/@id','valeur éventuellement vide'),
	'cdm-headword' => array('*Mot-vedette','/volume/entry/headword/text()',''),
	'cdm-homograph-number' => array('Numéro d\'homographe','/volume/entry/headword/@hn',''),
	'cdm-headword-variant' => array('Variante','/volume/entry/variant/text()',''),
	'cdm-writing' => array('Transcription','/volume/entry/transcription/text()','ex : romaji, pinyin'),
	'cdm-reading' => array('Lecture','/volume/entry/reading/text()','ex : yomigana'),
	'cdm-pronunciation' => array('Prononciation','/volume/entry/pron/text()','en API si possible'),
	'cdm-pos' => array('Classe grammaticale','/volume/entry/pos/text()',''),
	'cdm-definition' => array('Définition','/volume/entry/definition/text()','non indexé'),
	'cdm-translation' => array('Traduction en ','/volume/entry/translation/text()',''),
	'cdm-translation-ref' => array('Lien vers la traduction en ','/volume/entry/translation-ref/text()',''),
	'cdm-example' => array('Exemple en ','/volume/entry/examples/example/text()',''),
	'cdm-idiom' => array('Expression idiomatique en ','/volume/entry/idioms/idiom/text()','')
	);

	define ('DML_PREFIX','http://www-clips.imag.fr/geta/services/dml');
	define ('XLINK_PREFIX','http://www.w3.org/1999/xlink');
	define ('DefaultResultFormatter','fr.imag.clips.papillon.business.motamot.MotamotFormatter');
	define ('DefaultResultPostUpdateProcessor','fr.imag.clips.papillon.business.motamot.MotamotPostUpdateProcessor');
	
	function creerDictMetadata($params,$sources,$cibles) {
		$res = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<dictionary-metadata
   xmlns="http://www-clips.imag.fr/geta/services/dml"
   xmlns:d="http://www-clips.imag.fr/geta/services/dml" 
   xmlns:xlink="http://www.w3.org/1999/xlink" 
   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
   xsi:schemaLocation="http://www-clips.imag.fr/geta/services/dml
   http://www-clips.imag.fr/geta/services/dml/dml.xsd"
   category="'.$params['Category'].'" 
   creation-date="'.$params['CreationDate'].'" 
   installation-date="'.$params['InstallationDate'].'" 
   last-modification-date="'.date('c').'" 
   fullname="'.htmlspecialchars($params['NameC']).'"
   name="'.$params['Name'].'" 
   owner="'.$params['Owner'].'" 
   type="'.$params['Type'].'"> 
 <languages>
';
 		foreach ($sources as $source) {
 			$res .= ' <source-language d:lang="'.$source.'"/>'."\n";
 		}
 		foreach ($cibles as $cible) {
 			$res .= ' <target-language d:lang="'.$cible.'"/>'."\n";
 		}
 		$res .=' </languages>
 <contents>'.htmlspecialchars($params['Contents']).'</contents>
 <domain>'.htmlspecialchars($params['Domain']).'</domain> 
 <source>'.htmlspecialchars($params['Source']).'</source>
 <authors>'.$params['Authors'].'</authors>
 <legal>'.$params['Legal'].'</legal>
 <comments>'.htmlspecialchars($params['Comments']).'</comments>
 <administrators>
  <user-ref name="'.$params['Administrators'].'"/>
 </administrators>
 <volumes>
';
		$nbvolumes = getNumVolumes($params);
  		for ($i=1;$i<=$nbvolumes;$i++) {
  			$source = $params['Volume'.$i.'Source'];
			$targets = recupCiblesVolume($params, $i);
			$cibles = array_unique(array_filter(explode(' ',$targets)));
  			$volumeName = makeName($params['Name'],$source, $cibles);
  			$res .= '  <volume-metadata-ref name="'.$volumeName.'" xlink:href="'.$volumeName.'-metadata.xml" source-language="'.$source.'" ';
  			if ($targets !== '') {
  				$res .= 'target-languages="'.$targets.'" ';
  			}
  			$res .= "/>\n";
 		}
		$res .= ' </volumes>
  ';
  
  $res .=  (!empty($params['Links']))?stripslashes($params['Links'])."\n  ":'';
  $res .=  (!empty($params['OtherFiles']))?stripslashes($params['OtherFiles'])."\n  ":'';

  if (!empty($params['ResultPreprocessor'])) {
  	$res .= '<result-postupdateprocessor class-name="'.$params['ResultPostupdateprocessor'].'"/>
  ';
  }
  $res .= '<result-formatter class-name="'.$params['ResultFormatter'].'"/>
  ';
  if (!empty($params['ResultPreprocessor'])) {
  	$res .= '<result-postupdateprocessor class-name="'.$params['ResultPostupdateprocessor'].'"/>
  ';
  }
  if (!empty($params['ResultPostupdateprocessor'])) {
  	$res .= '<result-postupdateprocessor class-name="'.$params['ResultPostupdateprocessor'].'"/>
  ';
  }
  if (!empty($params['ResultPostsaveprocessor'])) {
  	$res .= '<result-postsaveprocessor class-name="'.$params['ResultPostsaveprocessor'].'"/>
  ';
  }
  if (!empty($params['XslStylesheet'])) {
	foreach ($params['XslStylesheet'] as $xsl) {
		$default = $xsl==$params['Name']?' default="true"':'';
 		$res.='<xsl-stylesheet name="'.$xsl.'"'.$default.' xlink:href="'.$xsl.'-view.xsl"/>
 	';}
  }
 $res.='
</dictionary-metadata>
';
		return $res;
	}
	
	function creerVolumeMetadata($params, $name) {
		if (empty($params['Format'])) {
			$params['Format'] = '';
		}
		if (empty($params['HwNumber'])) {
			$params['HwNumber'] = '';
		}
		if (empty($params['Encoding'])) {
			$params['Encoding'] = '';
		}
		if (empty($params['CreationDate'])) {
			$params['CreationDate'] = date('c');
		}
		if (empty($params['InstallationDate'])) {
			$params['InstallationDate'] = date('c');
		}
		$source = $params['Source'];
		$targets = $params['Targets'];
		$targets = array_filter(explode(' ',$targets));
		$langs = $targets;
		array_push($langs,$source);
		sort($langs,SORT_LOCALE_STRING);
		$dbname = preg_replace('/[_\-]/','',strtolower($name));
		$dataFileName = strtolower($name);
		$templateFileName = $dataFileName . '-template.xml';
		$dataFileName .= '.'.$params['Format'];
		if (empty($params['Comments'])) {$params['Comments']='';}
		$res = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<volume-metadata
   xmlns="http://www-clips.imag.fr/geta/services/dml" 
   xmlns:d="http://www-clips.imag.fr/geta/services/dml"
   xmlns:xlink="http://www.w3.org/1999/xlink"
   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
   xsi:schemaLocation="http://www-clips.imag.fr/geta/services/dml
   http://www-clips.imag.fr/geta/services/dml/dml.xsd"
   location="local"
   creation-date="'.$params['CreationDate'].'" 
   installation-date="'.$params['InstallationDate'].'" 
   last-modification-date="'.date('c').'" 
   hw-number="'.$params['HwNumber'].'" 
   encoding="'.$params['Encoding'].'" 
   format="'.$params['Format'].'" 
   name="'.$name.'"
   dbname="'.$dbname.'" 
   version="1"
   source-language="'.$source.'"
   target-languages="'.$params['Targets'].'"
   reverse-lookup="false">
 <authors>'.$params['Authors'].'</authors>
 <comments>'.htmlspecialchars($params['Comments']).'</comments>
 <cdm-elements>
  ';
  global $CDMElements;
  $keys=  '|'.join("|", array_keys($params)).'|';
  foreach ($CDMElements as $nom => $element) {
  	if (!empty($params[$nom])) {
  		$res .= '<'.$nom.' xpath="'.$params[$nom].'"/>'."\n";
  	}
  	else if (preg_match('/|'.$nom.'_[a-z][a-z][a-z]|/',$keys)) {
	  foreach($langs as $lang) {
		if (!empty($params[$nom.'_'.$lang])) {
			$res .= '<'.$nom.' xpath="'.$params[$nom.'_'.$lang].'"';
			$res .= ' d:lang="'.$lang.'" />'."\n  ";
		  }
      }
    }
  }
  if (!empty($params['CDMFreeElementsName'])) {
  	$i=0;
  	foreach ($params['CDMFreeElementsName'] as $nom) {
  		$valeur = $params['CDMFreeElementsValue'][$i++];
  	  	$res .= '<'.$nom.' xpath="'.$valeur.'" index="true"  />	
  ';}
  }
 $res .= '</cdm-elements>
 <administrators>
  <user-ref name="'.$params['Administrators'].'"/>
 </administrators>
 <volume-ref xlink:href="'.$dataFileName.'" source-language="'.$source.'"/>
 ';
 if (!empty($params['XmlschemaRef'])) {
 	$res .= '<xmlschema-ref xlink:href="'.$params['XmlschemaRef'].'"/>
';}
 if ($params['Format']=='xml') {
 	$res .= '<template-entry-ref xlink:href="'.$templateFileName.'"/>
';}
 if (!empty($params['TemplateInterfaceRef'])) {
 	$res .= '<template-interface-ref xlink:href="'.$params['TemplateInterfaceRef'].'"/>
';}
  if (!empty($params['XslStylesheet'])) {
 	foreach ($params['XslStylesheet'] as $xsl) {
		$default = $xsl==$params['Name']?' default="true"':'';
 		$res.='<xsl-stylesheet name="'.$xsl.'"'.$default.' xlink:href="'.$xsl.'-view.xsl"/>
 	';}
 }

 $res .= '</volume-metadata>
';
		return $res;
	}
	
	function getNumVolumes($params) {
		$res = 1;
		foreach($params as $key=>$val) { 
   			if(substr($key,0,6) == 'Volume') { 
   				$tmp = intval(substr($key,6));
   				if ($tmp > $res) {
   					$res = $tmp;
   				}
   			}
		}
		return $res;
	}
	
	function getNumCibles($params, $vol) {
		$res = 0;
		$match = 'Volume'.$vol.'Target';
		foreach($params as $key=>$val) { 
   			if(substr($key,0,strlen($match)) == $match) { 
   				$tmp = intval(substr($key,strlen($match)));
   				if ($tmp > $res) {
   					$res = $tmp;
   				}
   			}
		}
		return $res;
	}
	
	function recupCiblesVolume($params, $vol) {
	  	$nbcibles = getNumCibles($params,$vol);
  		$targets = '';
  		for ($j=1;$j<=$nbcibles;$j++) {
  			$target = $params['Volume'.$vol.'Target'.$j];
  			$targets .= $target . ' ';
  		}
  		$targets = substr($targets,0,strlen($targets)-1);
		return $targets;
	}

	function createXslStylesheet($name, $entry, $id, $headword, $pron, $pos, $example, $idiom) {
		$entry = substr($entry,strrpos($entry,'/')+1);
		$id = substr($id,strrpos($id,'/')+1);
		if (preg_match('/text\(\)$/',$headword)) {
			$headword = substr($headword,0,strrpos($headword,'/'));
		}
		$headword = substr($headword,strrpos($headword,'/')+1);
		if (preg_match('/text\(\)$/',$pron)) {
			$pron = substr($pron,0,strrpos($pron,'/'));
		}
		$pron = empty($pron)?'':substr($pron,strrpos($pron,'/')+1);
		if (preg_match('/text\(\)$/',$pos)) {
			$pos = substr($pos,0,strrpos($pos,'/'));
		}
		$pos = empty($pos)?'':substr($pos,strrpos($pos,'/')+1);
		if (preg_match('/text\(\)$/',$example)) {
			$example = substr($example,0,strrpos($example,'/'));
		}
		$example = empty($example)?'':substr($example,strrpos($example,'/')+1);
		if (preg_match('/text\(\)$/',$idiom)) {
			$idiom = substr($idiom,0,strrpos($idiom,'/'));
		}
		$idiom = empty($idiom)?'':substr($idiom,strrpos($idiom,'/')+1);

		$stylesheet = file_get_contents(RACINE_SITE.'include/default-view.xsl');
		$stylesheet = preg_replace('/##entry_xpath##/','//'.$entry,$stylesheet);
		$stylesheet = preg_replace('/##entry_element##/',$entry,$stylesheet);
		$stylesheet = preg_replace('/##entry_id##/',$id,$stylesheet);
		$stylesheet = preg_replace('/##headword_element##/',$headword,$stylesheet);
		$stylesheet = preg_replace('/##pronunciation_element##/',$pron,$stylesheet);
		$stylesheet = preg_replace('/##pos_element##/',$pos,$stylesheet);
		$stylesheet = preg_replace('/##example_element##/',$example,$stylesheet);
		$stylesheet = preg_replace('/##idiom_element##/',$idiom,$stylesheet);
		
		$myFile = $name . '-view.xsl';
		$fh = fopen($myFile, 'w') or die("impossible d'ouvrir le fichier ".$myFile);
		fwrite($fh, $stylesheet);
		fclose($fh);
	}
	
	function makeName($dictname, $source, $cibles) {
		$name = $dictname . '_' . $source;
		if (count($cibles)>0) { $name .= '_';}
		foreach ($cibles as $cible) {
			$name .= $cible . '-';
		}
		if (count($cibles)>0) { $name = substr($name,0,strlen($name)-1);}
		return $name;
	}
	
	function restrictAccess($dirname, $users) {
		$filename = DICTIONNAIRES_SITE.'/'.$dirname.'/.htaccess';
		
		$htaccess = '<LimitExcept GET HEAD OPTIONS POST PROPFIND>
        Require user ';
        foreach ($users as $user) {
        	$htaccess .= $user.' ';
        }
        $htaccess .= '
</LimitExcept>
';
		$fh = fopen($filename, 'w') or die("impossible d'ouvrir le fichier ".$myFile);
		fwrite($fh, $htaccess);
		fclose($fh);
		
	}

?>
