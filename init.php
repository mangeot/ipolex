<?php 
	error_reporting(E_ALL);

	setlocale(LC_COLLATE,'fr_FR','fr_FR.UTF-8');
	setlocale(LC_ALL, 'fr_FR', 'fr_FR.UTF-8');

	define ('RACINE_SITE',realpath(dirname(__FILE__)).'/');
	define ('RACINE_WEB',substr($_SERVER['SCRIPT_NAME'],0,
		strpos($_SERVER['SCRIPT_NAME'],substr($_SERVER['SCRIPT_FILENAME'],
		strlen(RACINE_SITE)))));

	define('SEP_NOM',"#");
	define('DICTIONNAIRES_SITE','/opt/www/html-ssl/dictionnaires');
//	define('DICTIONNAIRES_SITE','/Data/papillon-data/Purgatory');
	define('DICTIONNAIRES_DAV','https://papillon.imag.fr/DAV/dictionnaires');
?>
