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
	$LANG = (!empty($_COOKIE[LANG_COOKIE]))?$_COOKIE[LANG_COOKIE]:'';

	if (empty($LANG) && !empty($_REQUEST['lang'])) {
		$LANG = $_REQUEST['lang'];
		if (!empty($LANG)) {
			setcookie(LANG_COOKIE, $LANG, time()+3600*24*365*5);  /* expire dans 5 ans */
		}
	}

    global $supported_languages; 

    if (isset($supported_languages[$LANG])) { 
        return $supported_languages[$LANG]; 
    } 

    /* If the client has sent an Accept-Language: header, 
     * see if it is for a language we support. 
     */ 
    if (!empty($_SERVER['HTTP_ACCEPT_LANGUAGE'])) { 
        $accepted = explode( ",", $_SERVER['HTTP_ACCEPT_LANGUAGE']); 
        for ($i = 0; $i < count($accepted); $i++) { 
    		$LANG = $accepted[$i];
    		$LANG = substr($LANG,0,2);
            if (!empty($supported_languages[$LANG])) { 
                return $supported_languages[$LANG]; 
            } 
        } 
    } 

    /* One last desperate try: check for a valid language code in the 
     * top-level domain of the client's source address. 
     */ 
    if (preg_match('/\\.[^\\.]+$/', $_SERVER['REMOTE_HOST'], &$arr)) { 
        $LANG = strtolower($arr[1]); 
        if (!empty($supported_languages[$LANG])) { 
           return $supported_languages[$LANG]; 
        } 
    } 

    $LANG = $default_language;
    return $supported_languages[$LANG]; 
} 

function print_lang_menu() {
echo '   
	<form id="LangForm" action="?">
        <div>
        <img src="',RACINE_WEB,'images/multilingual_logo.png" alt="lang/语言/言語/لُغة/..." height="20px" style="vertical-align: middle;"/>
         <select name="lang" id="lang" onchange="this.form.submit()">
          <option label="lang go" selected="selected" value="">lang/语言/لُغة/...</option>
          <!--option label="arabiya" value="ara">عربية</option>
          <option label="Catala" value="cat">Català</option>
          <option label="Deutsch" value="deu">Deutsch</option-->
          <option label="English" value="eng">English</option>
          <!--option label="espanol" value="esp">español</option-->
          <option label="francais" value="fra">français</option>
          <!--option label="nihongo" value="jpn">日本語</option>
          <option label="Melayu" value="msa">Melayu</option>
          <option label="Russian" value="rus">Русский</option>
          <option label="jiantizhongwen" value="zho">简体中文</option-->
        </select>
        <noscript><div><input type="submit" value="Go" /></div></noscript>
      </div>
      </form>';
}

?>