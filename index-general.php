<?php
$lang = (!empty($_GET['lang']))?$_GET['lang']:'fr_FR.UTF-8'; // Pretend this came from the Accept-Language header
$filename = 'default';
putenv("LANGUAGE=$lang");
//setlocale(LANGUAGE,$lang);
//putenv("LC_ALL=$lang");
//setlocale(LC_ALL, $lang);
bindtextdomain($filename, './locale');
bind_textdomain_codeset($filename, "UTF-8");
textdomain($filename);
?>
<!DOCTYPE html>
<html xml:lang="<?php echo $lang;?>" lang="<?php echo $lang;?>">
<head>
	<meta charset="utf-8" />
	<meta name="author" content="Mathieu MANGEOT" />
	<meta name="keywords" content="<?php echo gettext("Entrepôts de données linguistiques");?>" />
	<meta name="description" content="<?php echo gettext("Entrepôts de données linguistiques");?>" />
	<title><?php echo gettext("Entrepôts de données linguistiques");?></title>
	<link rel="stylesheet" href="dictliste/style/site.css" type="text/css" />
	<script type="text/javascript">
	<!--
		function copyifempty(input, orig) {
			if (input.value=='') {
				input.value=document.getElementById(orig).value;
			}
		}
	// -->
	</script>
</head>
<body>
<header id="enTete">
    <h1><?php echo gettext("Entrepôts de données linguistiques du GETALP");?></h1>
	<h2><?php echo gettext("Accueil");?></h2>
	<hr />
	<?php echo 'locale: ',$lang;?>
</header>
<section id="partieCentrale">
	<?php echo gettext("Partie centrale");?>
<ul>
<li><a href="dictliste/">iPoLex</a><?php echo gettext(" : "); echo gettext("Entrepôt de données lexicales (dictionnaires, lexiques, terminologies)");?></li>
<li><a href="corpliste/">iPoCorp</a><?php echo gettext(" : "); echo gettext("Entrepôt de données corporales (corpus textuels)");?></li>
</ul>
</section>
<?php include('dictliste/include/footer.php');?>
