<?php
	$supported_languages = array( 
    'fr' => 'fr_FR.UTF-8',    /* français */ 
    'en' => 'en_US.UTF-8',     /* English */ 
); 

$LANG= '';
$default_language = 'fr'; 

/* Try to figure out which language to use. 
*/ 
function negotiate_language() { 
	GLOBAL $LANG;
    global $default_language;
    global $supported_languages;

	$LANG = '';

	if (!empty($_REQUEST['lang'])) {
		$LANG = $_REQUEST['lang'];
	}
        else if (!empty($_COOKIE[LANG_COOKIE])) {
                $LANG= $_COOKIE[LANG_COOKIE];
        }

    /* If the client has sent an Accept-Language: header, 
     * see if it is for a language we support. 
     */ 
    else if (!empty($_SERVER['HTTP_ACCEPT_LANGUAGE'])) { 
        $accepted = explode( ",", $_SERVER['HTTP_ACCEPT_LANGUAGE']); 
        for ($i = 0; $i < count($accepted); $i++) { 
    		$LANG = $accepted[$i];
    		$LANG = substr($LANG,0,2);
        } 
    } 

    /* One last desperate try: check for a valid language code in the 
     * top-level domain of the client's source address. 
     */ 
    else if (preg_match('/\\.[^\\.]+$/', $_SERVER['REMOTE_HOST'], $arr)) { 
        $LANG = strtolower($arr[1]); 
    } 

	$LANG = (!empty($supported_languages[$LANG]))?$LANG:$default_language;
	if (!empty($_REQUEST['lang']) || empty($_COOKIE[LANG_COOKIE])) {
		setcookie(LANG_COOKIE, $LANG, time()+3600*24*365*5);  /* expire dans 5 ans */
	}
    return $supported_languages[$LANG]; 
} 

function print_lang_menu() {
echo '   
	<form id="LangForm" action="?">
        <img src="',RACINE_WEB,'images/multilingual_logo.png" alt="lang/语言/言語/لُغة/..." height="20px" style="vertical-align: middle;"/>
         <select name="lang" id="lang" onchange="this.form.submit()">
          <option label="lang go" selected="selected" value="">lang/语言/لُغة/...</option>
          <!--option value="ar">عربية</option>
          <option  value="ct">Català</option>
          <option value="de">Deutsch</option-->
          <option value="en">English</option>
          <!--option value="es">español</option-->
          <option value="fr">français</option>
          <!--option value="jp">日本語</option>
          <option value="ms">Melayu</option>
          <option value="ru">Русский</option>
          <option value="zh">简体中文</option-->
        </select>
        <noscript><input type="submit" value="Go" /></noscript>
      </form>';
}

?>