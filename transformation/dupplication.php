<?php 


function paste($element, $elementDOM) {
		$elementParent = $element->xpath("parent::*")[0];
		$elementParentDOM = dom_import_simplexml($elementParent);
		$newElementDOM = $elementDOM->cloneNode(true);
		$elementParentDOM->appendChild($newElementDOM);
		$newElement = simplexml_import_dom($newElementDOM);
     	return $newElement;
      }

					$sens = $articleXML->xpath('//sens');
					$sens = $sens[$nb-1];
					$newSens = paste($sens,$newSensDOM);
					$def = $newSens->xpath('.//séance');
					$def[0][0] = $valeur;

?>