<?php
	require_once('../init.php');
	include(RACINE_SITE.'include/header.php');
?>
<header id="enTete">
	<?php print_lang_menu();?>
    <h1><?php echo gettext('iPoLex : entrepôt de données lexicales');?></h1>
	<h2><?php echo gettext('Accueil');?></h2>
	<hr />
</header>
<section id="partieCentrale">
<?php
	$tri = !empty($_REQUEST['tri'])?$_REQUEST['tri']:'Nom';
	$user = !empty($_SERVER['PHP_AUTH_USER'])?$_SERVER['PHP_AUTH_USER']:'';
	$dicts = array();
	$srcs = array();
	$langs = array();
// Open a known directory, and proceed to read its contents*ça ouvre le répertoire contenant les dictionaires et lit leur contenu.
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
?>
	<table>
		<thead>
			<?php if ($tri == 'Source') {
				 	echo '<tr><th>&nbsp;</th><th>Source</th><th><a href="?tri=Nom">',gettext('Nom'),
				 	'</a></th><th>',gettext('Catégorie'),'</th><th>Type</th><th>',gettext('Administrateur'),
				 	'</th><th>',gettext('Format'),'</th><th>',gettext('Cibles'),' <a style="font-size:smaller;" href="?tri=Langues">',gettext('toutes'),
				 	' </a></th><th>',gettext('Entrées'),'</th><th colspan="3"></th></tr>';
				}
				else if ($tri == 'Langues') {
				 	echo '<tr><th>&nbsp;</th><th>',gettext('Langue'),'</th><th><a href="?tri=Nom">',gettext('Nom'),'</a></th><th>',gettext('Catégorie'),
				 	'</th><th>Type</th><th>',gettext('Administrateur'),'</th><th>',gettext('Format'),'</th><th><a href="?tri=Langues">',gettext('Langues'),
				 	'</a> <a style="font-size:smaller;" href="?tri=Source">',gettext('Source'),'</a></th><th>',gettext('Entrées'),'</th></tr>';
				}
				else echo '<tr><th>&nbsp;</th><th>',gettext('Nom'),'</th><th>',gettext('Catégorie'),'</th><th>',gettext('Type'),
				'</th><th>',gettext('Administrateur'),'</th><th>',gettext('Format'),'</th><th><a href="?tri=Source">',gettext('Source'),
				'</a></th><th>',gettext('Cibles'),' <a style="font-size:smaller;" href="?tri=Langues">',gettext('toutes'),'</a></th><th>',gettext('Entrées'),'</th></tr>';
				?>
		</thead>
		<tbody>
			<?php
	$entrees = 0;
	$style='odd';
	$i=1;
	if ($tri == 'Langues') {
		$srcs = $langs;
	}
	if ($tri == 'Source' || $tri == 'Langues') {
		foreach ($srcs as $source => $dicts) {
		$j=0;
		ksort($dicts,SORT_LOCALE_STRING);
		foreach ($dicts as $nom => $dict) {
			echo '<tr class="'; echo $i%2==0?'even':'odd'; echo '">';
			if ($j==0) {
				echo '<td rowspan="',count($dicts),'">',$i,'</td>';
				echo '<td rowspan="',count($dicts),'"><abbr title="',$LANGUES[$source],'">',$source,'</abbr></td>';
			}
			echo '<td><acronym title="',$dict['NameC'],'">',$nom,'</acronym> </td>';
				echo '<td>',$dict['Category'],'</td>';
				echo '<td>',$dict['Type'],'</td>';
				echo '<td>',implode(',',$dict['Administrators']),'</td>';
				
				echo '<td>',$dict['Volumes'][key($dict['Volumes'])]['Format'],'</td>';
			if ($tri == 'Source') {
				$trgs = $dict['Volumes'][$source]['Targets'];
			}
			else {
				$trgs = toutesLangues($dict['Volumes']);
			}
			echo '<td>';
			foreach ($trgs as $trg) {
				echo '<abbr title="',$LANGUES[$trg],'">',$trg,'</abbr>, ';
			}
			echo '</td>';
			$articles = $dict['Volumes'][key($dict['Volumes'])]['HwNumber'];
			echo '<td style="text-align:right">',$articles,'</td>';
				$entrees += intval($articles);
				echo '<td>';
				if (in_array($user, $dict['Administrators'])) {
					echo '<a title="Éditer" href="modifDictionnaire.php?Modifier=on&Dirname=',$dict['Dirname'],'&Name=',$dict['Name'],'"><img style="border:none;" src="',RACINE_WEB,'images/assets/b_edit.png" alt="Éditer"/></a>';
				}
				else {
					echo '<a title="Consulter" href="modifDictionnaire.php?Consulter=on&Dirname=',$dict['Dirname'],'&Name=',$dict['Name'],'"><img  style="border:none;" width="20" src="',RACINE_WEB,'images/assets/b_update.png" alt="Consulter"/></a>';
				}
				echo '</td>';
				echo '<td><a title="Ouvrir" href="',DICTIONNAIRES_DAV,'/',$dict['Dirname'],'"><img style="border:none;" width="20" src="',RACINE_WEB,'images/assets/b_send.png" alt="Ouvrir"/></a></td>';
			echo '</tr>';
			$j++;
		}
		$i++;
	}
	}
	else {
	foreach ($dicts as $nom => $dict) {
		$j=0;
		$volumes = $dict['Volumes'];
		if (empty($dict['Volumes'])) {echo 'Volumes vides : ',$dict['Dirname'];}
		foreach ($volumes as $src => $volume) {
			echo '<tr class="'; echo $i%2==0?'even':'odd'; echo '">';
			if ($j==0) {
				echo '<td rowspan="',count($volumes),'">',$i,'</td>';
				echo '<td rowspan="',count($volumes),'"><acronym title="',$dict['NameC'],'">',$nom,'</acronym> </td>';
				echo '<td rowspan="',count($volumes),'">',$dict['Category'],'</td>';
				echo '<td rowspan="',count($volumes),'">',$dict['Type'],'</td>';
				echo '<td rowspan="',count($volumes),'">',implode(',',$dict['Administrators']),'</td>';
				$format= !empty($volume['Format'])?$volume['Format']:'?';
				echo '<td rowspan="',count($volumes),'">',$format,'</td>';
			}
			echo '<td><abbr title="',$LANGUES[$src],'">',$src,'</abbr></td>';
			$trgs = !empty($volume['Targets'])?$volume['Targets']:array();
			echo '<td>';
			foreach ($trgs as $trg) {
				echo '<abbr title="',$LANGUES[$trg],'">',$trg,'</abbr>, ';
			}
			echo '</td>';
			$HwNumber= !empty($volume['HwNumber'])?$volume['HwNumber']:'?';
			echo '<td style="text-align:right">',$HwNumber,'</td>';
			$entrees += intval($HwNumber);
			if ($j++==0) {
				echo '<td rowspan="',count($volumes),'">';
				if (in_array($user, $dict['Administrators'])) {
					echo '<a title="Éditer" href="modifDictionnaire.php?Modifier=on&Dirname=',$dict['Dirname'],'&Name=',$dict['Name'],'"><img style="border:none;" src="',RACINE_WEB,'images/assets/b_edit.png" alt="Éditer"/></a>';
				}
				else {
					echo '<a title="Consulter" href="modifDictionnaire.php?Consulter=on&Dirname=',$dict['Dirname'],'&Name=',$dict['Name'],'"><img  style="border:none;" width="20" src="',RACINE_WEB,'images/assets/b_update.png" alt="Consulter"/></a>';
				}
				echo '</td>';
				echo '<td rowspan="',count($volumes),'"><a title="Ouvrir" href="',DICTIONNAIRES_DAV,'/',$dict['Dirname'],'"><img style="border:none;" width="20" src="',RACINE_WEB,'images/assets/b_send.png" alt="Ouvrir"/></a></td>';
			}
			echo '</tr>';
		}
		$i++;
	}
	}
	echo '<tr><th>&nbsp;</th><th>Total</th><td colspan="7" style="text-align:right">',$entrees,'</td><td>&nbsp;</td><td>&nbsp;</td></tr>';
			?>
		</tbody>
	</table>
	
	<p style="text-align:center;"><a href="modifDictionnaire.php"><img src="<?php echo RACINE_WEB;?>images/assets/b_new.png"/>
	<?php echo gettext('Ajout d\'un dictionnaire');?></a></p>
	<p style="text-align:center;"><a href="manipDico.php"><img src="<?php echo RACINE_WEB;?>images/assets/b_new.png"/>
	<?php echo gettext('Manipulation d\'un dictionnaire');?></a></p>
 	<p><?php echo gettext('Vous pouvez accéder directement aux dictionnaires en montant le site sur votre bureau comme un répertoire distant avec le protocole <a href="http://fr.wikipedia.org/wiki/WebDAV">WebDav</a>.'); 
 	echo ' ',gettext('Pour monter un dictionnaire spécifique, copiez l\'adresse URL de la flèche droite verte.');
 	echo ' ',gettext('Pour monter le répertoire contenant tous les dictionnaires, utilisez l\'adresse URL suivante'); echo gettext(' : ');?><a href="<?php echo DICTIONNAIRES_DAV;?>">
 	<?php echo DICTIONNAIRES_DAV;?></a>.</p>
 
 </section>
<?php
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
<?php include(RACINE_SITE.'include/footer.php');?>

