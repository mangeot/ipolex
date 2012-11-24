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

	$LANG = (!empty($_COOKIE[LANG_COOKIE]))?$_COOKIE[LANG_COOKIE]:'';
	echo 'lang0;',$LANG;

	if (!empty($_REQUEST['lang'])) {
		$LANG = $_REQUEST['lang'];
		echo 'lang1;',$LANG;
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
		echo 'lang2;',$LANG;
    } 

    /* One last desperate try: check for a valid language code in the 
     * top-level domain of the client's source address. 
     */ 
    else if (preg_match('/\\.[^\\.]+$/', $_SERVER['REMOTE_HOST'], $arr)) { 
        $LANG = strtolower($arr[1]); 
		echo 'lang3;',$LANG;
    } 

	$LANG = (!empty($supported_languages[$LANG]))?$LANG:$default_language;
	echo 'supl:',$supported_languages[$LANG];
	echo 'nesupl:',!empty($supported_languages[$LANG]);
	echo 'lang4;',$LANG;
	if (!empty($_REQUEST['lang'])) {
		setcookie(LANG_COOKIE, $LANG, time()+3600*24*365*5);  /* expire dans 5 ans */
		echo 'setcookie;',$LANG;
	}
    return $supported_languages[$LANG]; 
} 

function print_lang_menu() {
echo '   
	<form id="LangForm" action="?">
        <img src="',RACINE_WEB,'images/multilingual_logo.png" alt="lang/语言/言語/لُغة/..." height="20px" style="vertical-align: middle;"/>
         <select name="lang" id="lang" onchange="this.form.submit()">
          <option label="lang go" selected="selected" value="">lang/语言/لُغة/...</option>
          <!--option value="ara">عربية</option>
          <option  value="cat">Català</option>
          <option value="deu">Deutsch</option-->
          <option value="eng">English</option>
          <!--option value="esp">español</option-->
          <option value="fra">français</option>
          <!--option value="jpn">日本語</option>
          <option value="msa">Melayu</option>
          <option value="rus">Русский</option>
          <option value="zho">简体中文</option-->
        </select>
        <noscript><input type="submit" value="Go" /></noscript>
      </form>';
}

?>