<?php
    require_once '../init.php';

    if (empty($_SESSION['User'])) {
        header('Location:login.php');
    }
    $dicoReference = get_dictionnaire('Lexinnova');

    $TITLE = 'Création d\'un article - LexInnovons';
    
    function startsWith($haystack, $needle) {
     	$length = strlen($needle);
     	return (substr($haystack, 0, $length) === $needle);
     }
     
     function paste($element, $elementDOM) {
		$elementParent = $element->xpath("parent::*")[0];
		$elementParentDOM = dom_import_simplexml($elementParent);
		$newElementDOM = $elementDOM->cloneNode(true);
		$elementParentDOM->appendChild($newElementDOM);
		$newElement = simplexml_import_dom($newElementDOM);
     	return $newElement;
      }
     
     $articleString = '<volume
  xmlns:d="http://www-clips.imag.fr/geta/services/dml"
  xmlns:xml="http://www.w3.org/XML/1998/namespace"    langue-source="esp"    nom="Lexinnova_esp">
  <d:contribution    d:contribid=""    d:originalcontribid="">
    <d:metadata>
      <d:author></d:author>
      <d:groups></d:groups>
      <d:creation-date></d:creation-date>
      <d:finition-date></d:finition-date>
      <d:review-date></d:review-date>
      <d:reviewer></d:reviewer>
      <d:validation-date></d:validation-date>
      <d:validator></d:validator>
      <d:status></d:status>
      <d:history>
        <d:modification>
          <d:author/>
          <d:date/>
          <d:comment/>
        </d:modification>
      </d:history>
      <d:previous-contribution/>
      <d:previous-classified-finished-contribution/>
    </d:metadata>
    <d:data>
    <article id="">
		<forme>
			<vedette></vedette>
			<classe-gram></classe-gram>
		</forme>
		<sémantique>
			<sens>
				<séance></séance>
				<définition></définition>
				<traduction lang="fra">
					<texte-traduction></texte-traduction>
					<gram-traduction></gram-traduction>
				</traduction>
				<exemples>
					<exemple>
						<texte-exemple lang="esp"></texte-exemple>
						<traduction-exemple lang="fra"></traduction-exemple>
						<source></source>
					</exemple>
				</exemples>
			</sens>
			<expressions>
			</expressions>
		</sémantique>
		<remarques></remarques>
	</article>
    </d:data>
  </d:contribution>
</volume>';

?>

<?php


	if (!empty($_REQUEST['CreerArticle'])) {
		
		$articleXML = simplexml_load_string($articleString);
		$articleXML->registerXPathNamespace('d', 'http://www-clips.imag.fr/geta/services/dml');
		
		$auteur = $articleXML->xpath('//d:author');
		$auteur[0][0] = $_SESSION['User']->login;
		$creationDate = $articleXML->xpath('//d:creation-date');
		$creationDate[0][0] = date('c');

		$article = $articleXML->xpath('//article');
		$article[0]['id'] = 'esp.'.$_REQUEST['vedette'].'.1';
		
		$vedette = $articleXML->xpath('//vedette');
		$vedette[0][0] = $_REQUEST['vedette'];
		
		$pos = $articleXML->xpath('//classe-gram');
		$pos[0][0] = $_REQUEST['classe-gram'];
		
		$remarques = $articleXML->xpath('//remarques');
		$remarques[0][0] = $_REQUEST['remarques'];
		
		$sens = $articleXML->xpath('//sens')[0];
		$sensDOM =  dom_import_simplexml($sens);
		$newSensDOM = $sensDOM->cloneNode(true);

		$exemple = $articleXML->xpath('//exemple')[0];
		$exempleDOM =  dom_import_simplexml($exemple);
		$newExempleDOM = $exempleDOM->cloneNode(true);

		
		foreach($_REQUEST as $nom => $valeur) {
			//echo 'req:',$nom,' valeur:',$valeur;
			if (startsWith($nom,'seance_')) {
				$nb = substr($nom, strlen('seance_'));
//				echo 'def:',$nom,' nb:',$nb,' valeur:',$valeur;
				if ($nb == '0') {
					$def = $articleXML->xpath('//séance');
					$def[0][0] = $valeur;
				}
				else {
					$sens = $articleXML->xpath('//sens');
					$sens = $sens[$nb-1];
					$newSens = paste($sens,$newSensDOM);
					$def = $newSens->xpath('.//séance');
					$def[0][0] = $valeur;
				}
			}
			if (startsWith($nom,'definition_')) {
				$nb = substr($nom, strlen('definition_'));
				$def = $articleXML->xpath('//définition');
				$def[$nb][0] = $valeur;
			}
			if (startsWith($nom,'texte-traduction_')) {
				$nb = substr($nom, strlen('texte-traduction_'));
				$trad = $articleXML->xpath('//texte-traduction');
				$trad[$nb][0] = $valeur;
			}
			if (startsWith($nom,'gram-traduction_')) {
				$nb = substr($nom, strlen('gram-traduction_'));
				$trad = $articleXML->xpath('//gram-traduction');
				$trad[$nb][0] = $valeur;
			}
			if (startsWith($nom,'texte-exemple_')) {
				preg_match_all('/_([0-9]+)/',$nom,$matches);
				$nbs = $matches[1][0];
				$nbe = $matches[1][1];
				$sens = $articleXML->xpath('//sens');
				$sens = $sens[$nbs];
				if ($nbe>0) {
					$exemple = $articleXML->xpath('//sens['.($nbs+1).']//exemple')[0];
					paste($exemple,$newExempleDOM);
				}
				$texteExemple = $sens->xpath('.//texte-exemple');
				$texteExemple[$nbe][0] = $valeur;
			}
			if (startsWith($nom,'traduction-exemple_')) {
				preg_match_all('/_([0-9]+)/',$nom,$matches);
				$nbs = $matches[1][0];
				$nbe = $matches[1][1];
				$sens = $articleXML->xpath('//sens');
				$sens = $sens[$nbs];
				$exemple = $articleXML->xpath('//sens['.($nbs+1).']//exemple['.($nbe+1).']')[0];
				$traductionExemple = $exemple->xpath('.//traduction-exemple');
				$traductionExemple[0][0] = $valeur;
			}
			if (startsWith($nom,'source_')) {
				preg_match_all('/_([0-9]+)/',$nom,$matches);
				$nbs = $matches[1][0];
				$nbe = $matches[1][1];
				$sens = $articleXML->xpath('//sens');
				$sens = $sens[$nbs];
				$exemple = $articleXML->xpath('//sens['.($nbs+1).']//exemple['.($nbe+1).']')[0];
				$sourceExemple = $exemple->xpath('.//source');
				$sourceExemple[0][0] = $valeur;
			}
		}
	
		//echo 'XML:',$articleXML->asXML();
        $id = $articleXML->xpath('.//article/@id')[0];
		$articleXML = post_article($dicoReference->name, 'esp', $id, $articleXML->asXML(), $_SESSION['Login'], $_SESSION['Passe']);
        if (!empty($articleXML)) {
                $id = $articleXML->xpath('.//article/@id')[0];
                 echo '<p class="notice">Article id: ',$id,' importé !</p>';
         }
	}
?>

	<?php include RACINE_SITE.'/Includes/entete.php'; ?>
	<script type="text/javascript">
	<!--
	function dupliqueExemple(plus) {
		var parent = plus.parent();
		var countSens = parent.closest('.sens').prevAll('.sens').size();
		var countExemples = parent.find('li.exemple').size();
		var noeud = $('#sens').find('li.exemple').clone();
		noeud.find('input.texte-exemple').attr('name','texte-exemple_'+countSens + '_' + countExemples);
		noeud.find('input.traduction-exemple').attr('name','traduction-exemple_'+countSens +'_'+countExemples);
		noeud.appendTo(parent.children('.exemples'));
	}
	function dupliqueSens(plus) {
		var noeud = $('#sens').clone().removeAttr('id');
		var countSens = plus.nextAll('.sens').size();
		noeud.find('select.seance').attr('name','seance_'+countSens);
		noeud.find('input.inputdefinition').attr('name','definition_'+countSens);
		noeud.find('input.inputtraduction').attr('name','traduction_'+countSens);
		noeud.find('input.texte-exemple').attr('name','texte-exemple_'+countSens + '_0');
		noeud.find('input.traduction-exemple').attr('name','traduction-exemple_'+countSens +'_0');
		//noeud.insertBefore('#plus');
		noeud.appendTo('.semantique');
		//$('#exemple').clone().attr('id', '').attr('name',count).insertBefore('#plus');
	}
	// -->
	</script>
		<section id="CreationArticle">
			<header>
				<h2 style="text-align:center">Création d'un article</h2>
			</header>
			<form action="?" method="post"  style="margin:auto;">
				<div class="entry">
				<div class="entrybody">
					<div style="display:none" class="templateentry">
					<blockquote id="sens" class="sens" style="border-left: 0px;border: 1px solid grey; border-radius: 5px;">
					<p>Séance <select name="seance" class="seance">
						<option value="Semaine 1">Semaine 1</option>
						<option value="Semaine 2">Semaine 2</option>
						<option value="Semaine 3">Semaine 3</option>
						<option value="Semaine 4">Semaine 4</option>
						<option value="Semaine 5">Semaine 5</option>
						<option value="Semaine 6">Semaine 6</option>
						<option value="Semaine 7">Semaine 7</option>
						<option value="Semaine 8">Semaine 8</option>
						<option value="Semaine 9">Semaine 9</option>
						<option value="Semaine 10">Semaine 10</option>
					</select></p>
					<p><span class="fra">Traduction : <input type="text" class="inputtraduction" name="texte-traduction_0"  size="50"  placeholder="Saisir une traduction du mot-vedette en français"/></span> <pan class="pos">Catégorie [<select name="gram-traduction">
						<option value="adv.">adjectif</option>
						<option value="adv.">adverbe</option>
						<option value="n.m.">nom masculin</option>
						<option value="n.f.">nom féminin</option>
						<option value="v.i.">verbe intransitif</option>
						<option value="v.t.">verbe transitif</option>
					</select>]</span></p>
					<p>Définition : <input class="inputdefinition" type="text" name="definition_0" size="100"  placeholder="Saisir une définition du mot-vedette en espagnol"/></p>
					<div>Exemples : <input type="button" onclick="dupliqueExemple($(this))" value="+" />
					 <ul class="exemples">
					 	<li class="exemple"><span class="esp">Exemple : <input type="text" class="texte-exemple" name="texte-exemple"  size="93"  placeholder="Saisir un exemple en espagnol"/></span><br />
					 	<span class="fra">Traduction : <input type="text" class="traduction-exemple" name="traduction-exemple"   size="91" placeholder="Saisir une traduction en français de l'exemple"/></span><br/>
					 	<span class="source">Source : <input type="text" class="source" name="source_0_0"  placeholder="Noter la source de l'exemple "  size="91"/></span>
					 	</li>
					 </ul>
					 </div>
					</blockquote>	
					</div>
					<p><span class="headword">Mot-vedette <input type="text" name="vedette" required="required" placeholder="Saisir un mot-vedette"/></span> <pan class="pos">Catégorie [<select name="classe-gram">
						<option value="adv.">adjectif</option>
						<option value="adv.">adverbe</option>
						<option value="n.m.">nom masculin</option>
						<option value="n.f.">nom féminin</option>
						<option value="v.i.">verbe intransitif</option>
						<option value="v.t.">verbe transitif</option>
					</select>]</span></p>
					<div class="semantique">Sens : <input type="button" onclick="dupliqueSens($(this))" value="+" />
					<blockquote class="sens" style="border-left: 0px;border: 1px solid grey; border-radius: 5px;">
					<p>Séance <select class="seance" name="seance_0">
						<option value="Semaine 1">Semaine 1</option>
						<option value="Semaine 2">Semaine 2</option>
						<option value="Semaine 3">Semaine 3</option>
						<option value="Semaine 4">Semaine 4</option>
						<option value="Semaine 5">Semaine 5</option>
						<option value="Semaine 6">Semaine 6</option>
						<option value="Semaine 7">Semaine 7</option>
						<option value="Semaine 8">Semaine 8</option>
						<option value="Semaine 9">Semaine 9</option>
						<option value="Semaine 10">Semaine 10</option>
					</select></p>
					<p><span class="fra">Traduction : <input type="text" class="inputtraduction" name="texte-traduction_0"  size="50"  placeholder="Saisir une traduction du mot-vedette en français"/></span> <pan class="pos">Catégorie [<select name="gram-traduction">
						<option value="adv.">adjectif</option>
						<option value="adv.">adverbe</option>
						<option value="n.m.">nom masculin</option>
						<option value="n.f.">nom féminin</option>
						<option value="v.i.">verbe intransitif</option>
						<option value="v.t.">verbe transitif</option>
					</select>]</span></p>
					<p>Définition : <input class="inputdefinition" type="text" name="definition_0" size="100"  placeholder="Saisir une définition du mot-vedette en espagnol"/></p>
					<div>Exemples : <input type="button" onclick="dupliqueExemple($(this))" value="+" />
					 <ul class="exemples">
					 	<li class="exemple"><span class="esp">Exemple : <input type="text" class="texte-exemple" name="texte-exemple_0_0"  size="93" placeholder="Saisir un exemple en espagnol"/></span><br />
					 	<span class="fra">Traduction : <input type="text" class="traduction-exemple" name="traduction-exemple_0_0"  placeholder="Saisir une traduction en français de l'exemple "  size="91"/></span><br />
					 	<span class="source">Source : <input type="text" class="source" name="source_0_0"  placeholder="Noter la source de l'exemple "  size="91"/></span>
					 	</li>
					 </ul>
					 </div>
					</blockquote>	
					<p>Remarques : <textarea class="remarques" name="remarques" rows="2" cols="70" style="width: auto;" >aa</textarea></p>					
					</div>			
				</div>
				</div>
				<p style="text-align: center;"><input type="submit" name="CreerArticle" value="Créer" /></p>
			</form>
		</section>
	<?php include RACINE_SITE.'/Includes/pieddepage.php'; ?>
	
	<!--
	<article id="esp.reloj.1">
		<forme>
			<vedette>reloj</vedette>
			<classe-gram>n.m.</classe-gram>
		</forme><sémantique><sens><définition>Indica la hora, los minutos, los segundos.</définition><traduction lang="fra">horloge</traduction><exemples><exemple><texte-exemple lang="esp">Allí se encuentra el reloj del antiguo edificio de Correos.</texte-exemple><traduction-exemple lang="fra">On y trouve l'horloge de l'ancien bâtiment de la poste.</traduction-exemple></exemple></exemples></sens><expressions>
			</expressions></sémantique></article>
			-->
