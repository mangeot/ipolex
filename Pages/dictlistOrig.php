<?php
	require_once('../init.php');
	require_once(RACINE_SITE.'include/langues.php');
	include(RACINE_SITE.'include/header.php');
?>
<div id="enTete">
    <h1>Site des dictionnaires</h1>
	<h2>Accueil</h2>
	<hr />
</div>
<div id="partieCentrale">
<?php
	$dicts = array();
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
			$dictlangstring = substr($file,$souligne+1);
			$dictlangs = explode('-',$dictlangstring); 	
			$dicts[$nom]=$file;
			foreach ($dictlangs as $lang) {
				if (!empty($langs[$lang])) {
					$tableau = $langs[$lang];
				}
				else {
					$tableau = array();
				}
				array_push($tableau,$nom);
				$langs[$lang] = $tableau;
			}
		}
        }
        closedir($dh);
    }
	asort($dicts);
	asort($langs);
	foreach ($dicts as $nom => $dict) {
		echo $nom,' : ',$dict,'<br/>';
	}
	foreach ($langs as $lang => $dicts) {
		echo $lang,' : ';
		sort($dicts);
		foreach ($dicts as $dict) {
			echo $dict,', ';
		}
		echo '<br/>';
	}
}
?>
	<ul>
		<li><a href="modifDictionnaire.php">Gestion</a> d'un dictionnaire</li>
	</ul>
 
 </div>
<?php include(RACINE_SITE.'include/footer.php');?>

