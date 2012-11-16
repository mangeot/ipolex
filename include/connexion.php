<?php
	require(RACINE_SITE.'connect.php');
	
	$connexion = mysql_connect (SERVEUR_BD, LOGIN_BD, PASS_BD);
	if (!$connexion) {
		echo 'Désolé, connexion au serveur ' . SERVEUR_BD . " impossible\n";
		exit();
	}
	else {
		if (!mysql_select_db(NOM_BD)) {
			echo "Désolé, accès à la base" . NOM_BD . " impossible\n";
			exit();
		}
		// Spécifie l'encodage UTF-8 pour dialoguer avec la BD
		mysql_query('SET NAMES utf8');
	}
?>