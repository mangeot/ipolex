<?php

	$CDMElements = array(
	'cdm-volume' => array('*'.gettext('Volume'),'/volume',''),
	'cdm-entry' => array('*'.gettext('Article'),'/volume/entry',''),
	'cdm-entry-id' => array('*'.gettext('Identifiant unique de l\'article'),'/volume/entry/@id',gettext('valeur éventuellement vide')),
	'cdm-headword' => array('*'.gettext('Mot-vedette'),'/volume/entry/headword/text()',''),
	'cdm-homograph-number' => array(gettext('Numéro d\'homographe'),'/volume/entry/headword/@hn',''),
	'cdm-headword-variant' => array(gettext('Variante'),'/volume/entry/variant/text()',''),
	'cdm-writing' => array(gettext('Transcription'),'/volume/entry/transcription/text()',gettext('ex : romaji, pinyin')),
	'cdm-reading' => array(gettext('Lecture'),'/volume/entry/reading/text()',gettext('ex : yomigana')),
	'cdm-pronunciation' => array(gettext('Prononciation'),'/volume/entry/pron/text()',gettext('en API si possible')),
	'cdm-pos' => array(gettext('Classe grammaticale'),'/volume/entry/pos/text()',''),
	'cdm-domain' => array(gettext('Domaine'),'/volume/entry/domain/text()',''),
	'cdm-definition' => array(gettext('Définition'),'/volume/entry/definition/text()',gettext('non indexé')),
	'cdm-sense-block' => array(gettext('Bloc de sens'),'/volume/entry/senses',gettext('non indexé')),
	'cdm-sense' => array(gettext('Sens'),'/volume/entry/senses/sense',gettext('non indexé')),
	'cdm-translation' => array(gettext('Traduction en '),'/volume/entry/translation/text()',''),
	'cdm-example-block' => array(gettext('Bloc d\'exemples'),'/volume/entry/examples',''),
	'cdm-example' => array(gettext('Exemple en '),'/volume/entry/examples/example/text()',''),
	'cdm-idiom' => array(gettext('Expression idiomatique en '),'/volume/entry/idioms/idiom/text()','')
	);
	
	$CDMLinkInfo = array(
		'name' => array('*'.gettext('Nom'),''),
		'volume' => array('*'.gettext('Volume cible'),''),
		'xpath' => array('*'.gettext('XPath du lien'),gettext('XPath de l\'élément')),
		'value' => array('*'.gettext('XPath de la valeur du lien'),gettext('Chemin relatif à l\'élément')),
		'type' => array('*'.gettext('XPath du type du lien'),gettext('Valeur "final" vers une entrée, et "axi" vers une axie')),
		'lang' => array('*'.gettext('XPath de la langue de la cible'),''),
		'label' => array(gettext('XPath de l\'étiquette du lien'),gettext('Valeur libre')),
		'weight' => array(gettext('XPath du poids du lien'),gettext('Entier ou réel'))
	);

	$CDMLink = array(
		'name' => 'translation',
		'volume' => 'target-volume-name',
		'xpath' => '/volume/entry/translation-ref',
		'value' => '@id',
		'type' => '@type',
		'lang' => '@lang',
		'label' => '@label',
		'weight' => '@weight'
	);

	
	define ('DML_PREFIX','http://www-clips.imag.fr/geta/services/dml');
	define ('XLINK_PREFIX','http://www.w3.org/1999/xlink');
	define ('DefaultResultFormatter','');
	define ('DefaultResultPostUpdateProcessor','');
	//define ('DefaultResultFormatter','fr.imag.clips.papillon.business.motamot.MotamotFormatter');
	//define ('DefaultResultPostUpdateProcessor','fr.imag.clips.papillon.business.motamot.MotamotPostUpdateProcessor');
	
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
 <access>'.$params['Access'].'</access>
 <comments>'.htmlspecialchars($params['Comments']).'</comments>
 <administrators>';
	$admins = preg_split("/[\s,;]+/", $params['Administrators']);
	foreach ($admins as $admin) {
		  $res .= '
		  <user-ref name="'.$admin.'"/>';
	}
 $res .= '
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
  if (!empty($params['ResultFormatter'])) {
  	$res .= '<result-formatter class-name="'.$params['ResultFormatter'].'"/>
  ';
  }
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
		
	
	function enregistrerVolumeMetadata($params) {
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
		$name = $params['Name'];
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
  		$valeur = preg_replace('/\/$/','',$params[$nom]);
  		$res .= '<'.$nom.' xpath="'.$valeur.'"/>'."\n";
  	}
  	else if (preg_match('/|'.$nom.'_[a-z][a-z][a-z]|/',$keys)) {
	  foreach($langs as $lang) {
		if (!empty($params[$nom.'_'.$lang])) {
  			$valeur = preg_replace('/\/$/','',$params[$nom.'_'.$lang]);
  			$valeur = preg_replace('/"/','\'',$valeur);
			$res .= '<'.$nom.' xpath="'.$valeur.'"';
			$res .= ' d:lang="'.$lang.'" />'."\n  ";
		  }
      }
    }
  }
  if (!empty($params['CDMFreeElementsName'])) {
  	$i=0;
  	foreach ($params['CDMFreeElementsName'] as $nom) {
  		$valeur = $params['CDMFreeElementsValue'][$i++];
  		$valeur = preg_replace('/\/$/','',$valeur);
  		if (!empty($nom) && !empty($valeur)) {
  	  		$res .= '<'.$nom.' xpath="'.$valeur.'" index="true"  />	
  		';} 
  	}
  }
  $res .= '<links>
  ';
  if (!empty($params['CDMLinks'])) {
  	foreach ($params['CDMLinks'] as $link) {
  		if (!empty($link['name']) && !empty($link['xpath'])) {
  		$valeur = preg_replace('/\/$/','',$link['xpath']);
  		$res .= '<link name="'.$link['name'].'" xpath="'.$link['xpath'].'">
  		';
  		 foreach ($link as $name => $value) {
  		 	if ($name != 'name' && $name != 'xpath') {
  		 		if (!empty($link[$name])) {
				$res .='<'.$name.' xpath="'.$link[$name].'"/>
  ';  		 	
  		 		}
  			}
  		}
  		  $res .= '</link>
  		';
  		}
	}
  }
  $res .= '</links>
	';  
 
 $res .= '</cdm-elements>
<administrators>';
	$admins = preg_split("/[\s,;]+/", $params['Administrators']);
	foreach ($admins as $admin) {
		  $res .= '
		  <user-ref name="'.$admin.'"/>';
	}
 $res .= '
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

	function createXslStylesheet($name, $entry, $id, $headword, $pron, $pos, $example, $idiom, $sense, $template) {
		$entry = substr($entry,strrpos($entry,'/')+1);
		$id = empty($id)?'':substr($id,strrpos($id,'/')+1);
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

		$sense = empty($sense)?'':substr($sense,strrpos($sense,'/')+1);
		
		$templatexml = simplexml_load_string($template);
		$templatenamespaces = $templatexml->getDocNamespaces();
		
		$stylesheet = file_get_contents(RACINE_SITE.'include/default-view.xsl');

		$stylesheetxml = simplexml_load_string($stylesheet);
		$stylesheetnamespaces = $stylesheetxml->getDocNamespaces();
		$namespacesdiff = array_diff_assoc($templatenamespaces, $stylesheetnamespaces);
		
		if (count($namespacesdiff) >0) {
			foreach ($namespacesdiff as $nsprefix => $namespace) {
				$stylesheetxml->addAttribute("xmlns:xmlns:".$nsprefix, $namespace);
			}
			$stylesheet =$stylesheetxml->asXML();
		}

		$stylesheet = preg_replace('/##entry_xpath##/','//'.$entry,$stylesheet);
		$stylesheet = preg_replace('/##entry_element##/',$entry,$stylesheet);
		if ($id) {$stylesheet = preg_replace('/##entry_id##/',$id,$stylesheet);}
		if ($headword) {$stylesheet = preg_replace('/##headword_element##/',$headword,$stylesheet);}
		if ($pron) {$stylesheet = preg_replace('/##pronunciation_element##/',$pron,$stylesheet);}
		if ($pos) {$stylesheet = preg_replace('/##pos_element##/',$pos,$stylesheet);}
		if ($example) {$stylesheet = preg_replace('/##example_element##/',$example,$stylesheet);}
		if ($idiom) {$stylesheet = preg_replace('/##idiom_element##/',$idiom,$stylesheet);}
		if ($sense) {$stylesheet = preg_replace('/##sense_element##/',$sense,$stylesheet);}
		
		$myFile = $name . '-view.xsl';
		file_put_contents($myFile,$stylesheet);
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

  if (!function_exists('pathinfo_filename')) {
      if (version_compare(phpversion(), "5.2.0", "<")) {
       function pathinfo_filename($path) {
         $temp = pathinfo($path);
         if ($temp['extension']) {
           $temp['filename'] = substr($temp['basename'], 0, strlen($temp['basename']) -strlen($temp['extension']) -1);
         }
         else {
           $temp['filename'] = $temp['basename'];
         }
         return $temp['filename'];
       }
     }
     else {
       function pathinfo_filename($path) {
         return pathinfo($path,PATHINFO_FILENAME);
       }
     }
   }
?>
