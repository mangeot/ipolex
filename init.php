<?php 
	error_reporting(E_ALL);
	

	define ('RACINE_SITE',realpath(dirname(__FILE__)).'/');
	define ('RACINE_WEB',substr($_SERVER['SCRIPT_NAME'],0,
		strpos($_SERVER['SCRIPT_NAME'],substr($_SERVER['SCRIPT_FILENAME'],
		strlen(RACINE_SITE)))));

	define('LANG_COOKIE','LANG_COOKIE');
	define('SEP_NOM',"#");
//	define('DICTIONNAIRES_SITE','/opt/www/html-ssl/dictionnaires');
	define('DICTIONNAIRES_SITE','/Data/ipolex');
	define('DICTIONNAIRES_DAV','https://papillon.imag.fr/DAV/dictionnaires');
	require_once(RACINE_SITE.'include/language_negociation.php');
	$locale = negotiate_language();
	$filename = 'default';
	putenv("LANGUAGE=$locale");
	setlocale(LC_COLLATE, $locale);
	setlocale(LC_ALL, $locale);

	bindtextdomain($filename, RACINE_SITE . 'locale');
	bind_textdomain_codeset($filename, "UTF-8");
	textdomain($filename);
	require_once(RACINE_SITE.'include/lang_'.$LANG.'.php');
	require_once(RACINE_SITE.'include/fonctions.php');

?>