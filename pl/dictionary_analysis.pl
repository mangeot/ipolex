#!/usr/bin/perl
#
# dictionary-analysis.pl
#

use strict;
use warnings;
use utf8;

# À faire : use of PerlSAX instead of the generic XML::Parser because of the use of line numbers
# use XML::Parser::PerlSAX;
use XML::Parser;
use Unicode::Collate;
binmode STDOUT, ':utf8'; 
binmode STDERR, ':utf8'; 

my $maxAffichageListeValeurs = 50;
my $maxMemoireListeValeurs = 1000;

@ARGV or die "usage: dictionary-analysis.pl file.xml\n";

my $root;
my $Encoding = 'UTF-8';
my @tree_stack;
my $Collator = Unicode::Collate->new();

my $parser = XML::Parser->new(
    Handlers => {
    	XMLDecl  => \&xmldecl,
        Start => \&start_element,
        Char  => \&characters,
        End   => \&end_element,
    },
);

print STDERR "Début de l'analyse du dictionnaire ",$ARGV[0],"\n";
$parser->parsefile($ARGV[0]);
print STDERR "Fin de l'analyse du dictionnaire\n";
print STDERR "Début de l'écriture du résultat\n";

print '<?xml version="1.0"?>
<html>
	<head>
		<meta charset="UTF-8" />
		<title>Dictionary analysis report</title>
		<style type="text/css">
		<!--
			body {
				font-family: "Lucida Grande", verdana, arial, sans-serif;
			}
			h1, h2 {
				font-family: arial, sans-serif;
				text-align:center;
				color:navy;
			}
			table {
				margin: auto;
				width:70%;
			}
			td.f {
				text-align: right;
			}
		// -->
		</style>
	</head>
	<body>
		<header>
			<h1>Rapport d\'analyse du dictionnaire</h1>
		</header>
		<section id="signature">
			<h2>Signature</h2> 
			<pre>';
&print_signature($root,0);

print '</pre>
		</section>';
		
print '		<section id="elementsArray">
			<h2>Tableau des éléments</h2>
				<table>
					<thead>
						<tr><th>Nom</th><th>Fréquence</th></tr>
					</thead>
					<tbody>';
					
my %elementsArray;
&buildElementsArray($root);	

foreach my $key (sort (keys(%elementsArray))) {
   print "						<tr><td>$key</td><td class='f'>",$elementsArray{$key},"</td></tr>\n";
}
print '					</tbody>
				</table>
		</section>
';

my @tableauEntry;
&guess_entry($root,0,'',0);
@tableauEntry = reverse sort { $a->{ match } <=> $b->{ match } } @tableauEntry;
my $entry = $tableauEntry[0]->{ element };
my $entryXpath = $tableauEntry[0]->{ xpath };
my $entryCompte = $tableauEntry[0]->{ count };
my $volumeXpath = $entryXpath;
$volumeXpath =~ s/\/[^\/]+$//;

my @tableauEntryId;
&guess_entry_id($entry,$entryXpath);
@tableauEntryId = reverse sort { $a->{ match } <=> $b->{ match } } @tableauEntryId;
#foreach my $ligne (@tableauEntryId) {
#	print "hypothesis EID: \n";
#	foreach my $key (keys %$ligne) {
#		print "\t",'- ', $key, ': ',$ligne->{ $key }, "\n";
#	}
#}
my @tableauHeadword;
&guess_headword($entry,0,$entryXpath,$entryCompte);
@tableauHeadword = reverse sort { $a->{ match } <=> $b->{ match } } @tableauHeadword;
my $headword = $tableauHeadword[0]->{ element };
my $headwordName =  $tableauHeadword[0]->{ name };
my @tableauHeadwordHn;
&guess_headword_hn($headword,$tableauHeadword[0]->{ xpath });
@tableauHeadwordHn = reverse sort { $a->{ match } <=> $b->{ match } } @tableauHeadwordHn;
my @tableauPronun;
&guess_pronun($entry,0,$entryXpath, $entryCompte, $headwordName);
@tableauPronun = reverse sort { $a->{ match } <=> $b->{ match } } @tableauPronun;
my @tableauPos;
&guess_pos($entry,0,$entryXpath, $entryCompte);
@tableauPos = reverse sort { $a->{ match } <=> $b->{ match } } @tableauPos;
my @tableauSens;
&guess_sense($entry,0,$entryXpath, $entryCompte);
@tableauSens = reverse sort { $a->{ match } <=> $b->{ match } } @tableauSens;
my $sense_block = &guess_sense_block($tableauSens[0]->{ xpath });
my @tableauDef;
&guess_def($entry,0,$entryXpath, $entryCompte, $headwordName);
@tableauDef = reverse sort { $a->{ match } <=> $b->{ match } } @tableauDef;
my @tableauEx;
&guess_example($entry,0,$entryXpath, $entryCompte, $headwordName);
@tableauEx = reverse sort { $a->{ match } <=> $b->{ match } } @tableauEx;
my $example_block = (scalar(@tableauEx)>0)?$tableauEx[0]->{ xpath }:'';
$example_block = &guess_example_block($example_block);

print '		<section id="CDMElements">
			<h2>Tableau des éléments CDM</h2>
';
print '			<table><thead><th>Nom</th><th>XPath</th></thead>
				<tbody>
			';
print "\t\t\t<tr><td>cdm-volume</td><td>$volumeXpath</td></tr>\n";
print "\t\t\t<tr><td>cdm-entry</td><td>$tableauEntry[0]->{ xpath }</td></tr>\n";
if (@tableauEntryId) {
	print "\t\t\t<tr><td>cdm-entry-id</td><td>$tableauEntryId[0]->{ xpath }</td></tr>\n";
}
else {
	print "\t\t\t<tr><td>cdm-entry-id</td><td>$tableauEntry[0]->{ xpath }/\@id</td></tr>\n";
}
print "\t\t\t<tr><td>cdm-headword</td><td>$tableauHeadword[0]->{ xpath }</td></tr>\n";
if (@tableauHeadwordHn) {
	print "\t\t\t<tr><td>cdm-homograph-number</td><td>$tableauHeadwordHn[0]->{ xpath }</td></tr>\n";
}
print "\t\t\t<tr><td>cdm-pronunciation</td><td>$tableauPronun[0]->{ xpath }</td></tr>\n";
print "\t\t\t<tr><td>cdm-pos</td><td>$tableauPos[0]->{ xpath }</td></tr>\n";
print "\t\t\t<tr><td>cdm-definition</td><td>$tableauDef[0]->{ xpath }</td></tr>\n";
if (@tableauSens) {
	print "\t\t\t<tr><td>cdm-sense-block</td><td>$sense_block</td></tr>\n";
	print "\t\t\t<tr><td>cdm-sense</td><td>$tableauSens[0]->{ xpath }</td></tr>\n";
}
if (@tableauEx) {
print "\t\t\t<tr><td>cdm-example-block</td><td>$example_block</td></tr>\n";
print "\t\t\t<tr><td>cdm-example</td><td>$tableauEx[0]->{ xpath }</td></tr>\n";
}
print '				</tbody>
			</table>
		</section>
';	
	print '	</body>
';

my $entryName = $tableauEntry[0]->{ name };
print '<volume-metadata encoding="',$Encoding,'" hwnumber="',$elementsArray{$entryName}, '"
	xmlns="http://www-clips.imag.fr/geta/services/dml" 
	xmlns:d="http://www-clips.imag.fr/geta/services/dml">
			<cdm-elements>
';
print "\t\t\t<cdm-volume xpath='$volumeXpath' />\n";
print "\t\t\t<cdm-entry xpath='$tableauEntry[0]->{ xpath }' />\n";
if (@tableauEntryId) {
	print "\t\t\t<cdm-entry-id xpath='$tableauEntryId[0]->{ xpath }' />\n";
}
else {
	print "\t\t\t<cdm-entry-id xpath='$tableauEntry[0]->{ xpath }/\@id' />\n";
}
print "\t\t\t<cdm-headword xpath='$tableauHeadword[0]->{ xpath }/text()' />\n";
if (@tableauHeadwordHn) {
	print "\t\t\t<cdm-homograph-number xpath='$tableauHeadwordHn[0]->{ xpath }' />\n";
}
print "\t\t\t<cdm-pronunciation xpath='$tableauPronun[0]->{ xpath }/text()' />\n";
print "\t\t\t<cdm-pos xpath='$tableauPos[0]->{ xpath }/text()' />\n";
print "\t\t\t<cdm-definition xpath='$tableauDef[0]->{ xpath }/text()' />\n";
if (@tableauSens) {
	print "\t\t\t<cdm-sense-block xpath='$sense_block' />\n";
	print "\t\t\t<cdm-sense xpath='$tableauSens[0]->{ xpath }' />\n";
}
else {
	print "\t\t\t<cdm-sense-block xpath='' />\n";
	print "\t\t\t<cdm-sense xpath='' />\n";
}
if (@tableauEx) {
print "\t\t\t<cdm-example-block xpath='$example_block' d:lang='' />\n";
print "\t\t\t<cdm-example xpath='$tableauEx[0]->{ xpath }/text()' d:lang='qaa' />\n";
}
else {
	print "\t\t\t<cdm-example xpath=''  d:lang='' />\n";
}

print '	</cdm-elements>
</volume-metadata>
';

print "<template-entry>\n";
&print_template($root,0);
print "\n</template-entry>\n";

print "\n</html>";

print STDERR "Fin de l'écriture du résultat";	

sub xmldecl {
    my ( $parser, $version, $encoding, $standalone ) = @_;
    $Encoding = defined($encoding)?$encoding:'UTF-8';
}

sub start_element {

    my ( $parser, $element, @attrval ) = @_;

	my $parent;
	my $leaf;
	if (@tree_stack) {
		$parent = $tree_stack[ -1 ];
		$leaf = $parent->{ child }{ $element };
	}
	unless ($leaf) {
		$leaf->{ order } = keys %{$parent->{ child }};
		$leaf->{ name } = $element;
	}
	$leaf->{ count }++;	
	if ($leaf->{ count } % 1000 == 0) {
		print STDERR $leaf->{ count }, ' ', $leaf->{ name }, ,' analysés', "\n";
	}

    while ( my ( $attribute, $value ) = splice @attrval, 0, 2 ) {
    	my $attr =  $leaf->{ attribute }{ $attribute };
    	$attr->{ count }++;
    	my $prev = $attr->{ previous };
    	if ($prev && ($Collator->ge($value,$prev))) {
    		$attr->{ sup }++;
    	}
    	$attr->{ previous } = $value;
    	$leaf->{ attribute }{ $attribute } = $attr;
    	if ($attr->{ count }<$maxMemoireListeValeurs) {
    		$attr->{ values } { $value }++;
    	}
    }

	if ($parent) {
		$leaf->{ parent } = $parent;
		$parent->{ child }{ $element } = $leaf;
	}

    push @tree_stack, $leaf;
}


sub characters {
    my ($parser, $string) = @_;
	my $parent = $tree_stack[ -1 ];
	$string =~ s/^[\s]+//;
	$string =~ s/[\s]+$//;
	if (length($string)>0) {
		my @words = split(/\s+/, $string);
		my $words = @words;
		$parent->{ charnumber }++;
		$parent->{ charsize } += length($string);
		$parent->{ words } += $words;
    	my $prev = $parent->{ previous };
    	if ($prev && ($Collator->ge($string,$prev))) {
    		$parent->{ sup }++;
    	}
    	$parent->{ previous } = $string;
    	if ($parent->{ charnumber }<$maxMemoireListeValeurs) {
    		$parent->{ values } { $string }++;
    	}
	}
}


sub end_element {
    $root = pop @tree_stack;
}

sub XMLEntities {
	my $string = $_[0];
	$string =~ s/</&lt;/g;
	$string =~ s/>/&gt;/g;
	$string =~ s/&/&amp;/g;
	$string =~ s/'/&quot;/g;
	return $string;
}

sub print_signature {
	my $elt = $_[0];
	my $level = $_[1];
	for (my $i=0;$i<$level;$i++) {
		print '  ';
	}
	print '&lt;',$elt->{ name },':',$elt->{ count };
	foreach my $attribute ($Collator->sort(keys %{ $elt->{ attribute }})) {
		my $attr = $elt->{ attribute }{ $attribute };
		my $diff = keys %{$attr->{ values }};
		my $sup = $attr->{ sup } || '';
		print ' ',$attribute,'=',$diff,'≠',$sup,'≥',$attr->{ count };
		if ($diff<$maxAffichageListeValeurs) {
			print '(';
			my $i=0;
			foreach my $key ($Collator->sort(keys %{$attr->{ values }})) {
				$i++;
				print XMLEntities($key),':',$attr->{ values }{ $key };
				if ($i<$diff) {print ','};
			}
			print ')';
		}
	}	
	print '&gt;';
	my $charnumber = $elt->{ charnumber };
	my $charsize = $elt->{ charsize };
	my $words = $elt->{ words };
	if ($charnumber) {
		my $diff = keys %{$elt->{ values }};
		my $sup = $elt->{ sup } || '';
		print 'chars:';
		printf("%.1f", $charsize/$charnumber);
		print ';words:';
		printf("%.0f", $words/$charnumber);
		print ';', $diff,'≠',$sup,'≥',$charnumber; 
		if ($diff<$maxAffichageListeValeurs) {
			print '(';
			my $i=0;
			foreach my $key ($Collator->sort(keys %{$elt->{ values }})) {
				$i++;
				print XMLEntities($key),':',$elt->{ values }{ $key };
				if ($i<$diff) {print ','};
			}
			print ')';
		}
	}
	print "\n";
	foreach my $child (sort { $a->{ order } <=> $b->{ order } } values %{$elt->{ child }}) {
		&print_signature($child, $level+1);
	}
}

sub buildElementsArray {
	my $elt = $_[0];
	$elementsArray{$elt->{ name }} += $elt->{ count };
	foreach my $child (values %{$elt->{ child }}) {
		&buildElementsArray($child);
	}
}

sub print_template {
	my $elt = $_[0];
	my $level = $_[1];
	my $childs = 0;
	for (my $i=0;$i<$level;$i++) {
		print '  ';
	}
	print '<',$elt->{ name };
	foreach my $attribute ($Collator->sort(keys %{ $elt->{ attribute }})) {
		my $attr = $elt->{ attribute }{ $attribute };
        my @keys = keys %{$attr->{ values }};
        my $diff = @keys;
        print ' ',$attribute,'="';
        if ($diff == 1 && $elt->{ count } == $attr->{ count }) {
            my $firstkey = $keys[0];
            print $firstkey;
        }
        elsif ($attribute =~ /^xmlns:/ || $attribute =~ /^xsi:/) {
            my $firstkey = $keys[0];
            print $firstkey;
        }
		print '"';
	}	
	print '>';
	foreach my $child (sort { $a->{ order } <=> $b->{ order } } values %{$elt->{ child }}) {
		print "\n";
		&print_template($child, $level+1);
		$childs++;
	}
	if ($childs>0) {
		print "\n";
		for (my $i=0;$i<$level;$i++) {
			print '  ';
		}
	}
	print '</',$elt->{ name },'>';
}


sub guess_entry {
	my $elt = $_[0];
	my $level = $_[1];
	my $xpath = $_[2];
	my $comptemax = $_[3];
	
	my $match = 0.1;
		
	if ($elt->{ count } > $comptemax) {
		$comptemax = $elt->{ count };
		$xpath .= '/' . $elt->{ name };
	    if ($comptemax >1) {
			if ($elt->{ name } =~ /entry/) {
				# print " match nom\n";
				$match = 1;
			}
			my $tableau_elt;
			$tableau_elt->{ element } = $elt;
			$tableau_elt->{ level } = $level;
			$tableau_elt->{ name } = $elt->{ name };
			$tableau_elt->{ count } = $elt->{ count };
			$tableau_elt->{ match } = $match / $level;
			$tableau_elt->{ xpath } = $xpath;
			$tableau_elt->{ parent } = $elt->{ parent }->{ name };
			push @tableauEntry, $tableau_elt;
		}
		foreach my $child (reverse sort { $a->{ count } <=> $b->{ count } } values %{$elt->{ child }}) {
			$comptemax = &guess_entry($child, $level+1, $xpath, $comptemax);
		}
	}
	return $comptemax;
}


sub guess_entry_id {
	my $elt = $_[0];
	my $xpath = $_[1];
	foreach my $attribute (keys %{ $elt->{ attribute }}) {
		my $match = 0;
		my $attr = $elt->{ attribute }{ $attribute };
		my $diff = keys %{$attr->{ values }};
		my $sup = $attr->{ sup } || '';
		my $count = $attr->{ count };
		if ($attribute =~ /id/) {
			$match += 0.3
		}
		if ($diff<$maxAffichageListeValeurs) {
			if ($diff == ($attr->{ count } -1)) {
				$match += 0.5
			}
		}
		else {
				$match += 0.2
		}
		my $tableau_elt;
		$tableau_elt->{ element } = $attr;
		$tableau_elt->{ name } = $attribute;
		$tableau_elt->{ count } = $attr->{ count };
		$tableau_elt->{ match } = $match;
		$tableau_elt->{ xpath } = $xpath . '/@' . $attribute;

		push @tableauEntryId, $tableau_elt;
	}
}


sub guess_headword {
	my $elt = $_[0];
	my $level = $_[1];
	my $xpath = $_[2];
	my $compte = $_[3];     # 'count' of entry
	my $word = $elt->{ words };
	my $charnumber = $elt->{ charnumber };
	my $diff = keys %{$elt->{ values }};
	
	my $match = 0;
	
	if ($level > 0) {$xpath .= '/' . $elt->{ name };};

	if ($level >0 && $charnumber) {       #  descendant de entry && nombre d'entry == nombre d'element
		
		# autant de headword que de entry
		if ($elt->{ count } == $compte) {
			$match += 0.4;
		}
		elsif (abs($elt->{ count } - $compte)< 0.01){
			$match += 0.3;
		}
		
		if (($elt->{ name } =~ /headword/) || ($elt->{ name } =~ /vedette/)){
			# print " match nom; \n";
			$match += 0.4;
		}
		
		# peu de mots
		 if (($word/$charnumber >= 1.0) && ($word/$charnumber <= 3.0)){
			# print " match number of words; \n";
			$match += 0.3;
		 }
		 
		 if ($elt->{ count }  < $maxMemoireListeValeurs) {
			if ($elt->{ count } / $diff < 1.5) {
				# beaucoup de valeurs différentes
				$match += 0.3 
			}
		}
		else {
			if ($maxMemoireListeValeurs / $diff < 1.5) {
				# beaucoup de valeurs différentes
				$match += 0.3 
			}
		}
		 
		 # le headword est souvent le premier de ses frères
		 $match += 0.1 / ($elt->{ order } +1);

		my $tableau_elt;
		$tableau_elt->{ element } = $elt;
		$tableau_elt->{ level } = $level;
		$tableau_elt->{ name } = $elt->{ name };
		$tableau_elt->{ count } = $elt->{ count };
		$tableau_elt->{ match } = $match / $level;	 # se trouve en priorité dans le début de l'arbre	
		$tableau_elt->{ xpath } = $xpath;

		push @tableauHeadword, $tableau_elt;

	}
	foreach my $child (reverse sort { $a->{ count } <=> $b->{ count } } values %{$elt->{ child }}) {
		&guess_headword($child, $level+1, $xpath, $compte);
	}
}

sub guess_headword_hn {
	my $elt = $_[0];
	my $xpath = $_[1];
	foreach my $attribute (keys %{ $elt->{ attribute }}) {
		my $match = 0;
		my $attr = $elt->{ attribute }{ $attribute };
		my $diff = keys %{$attr->{ values }};
		my $sup = $attr->{ sup } || '';
		my $count = $attr->{ count };
		if ($attribute =~ /hn/) {
			$match += 0.1
		}
		$match += 5/$diff;
		my $num = 0.3;
		foreach my $key (keys %{$attr->{ values }}) {
			if ($attr->{ values }{ $key } !~ /^\d+\z/) {
				$num = 0;
			}
		}
		$match += $num;
		
		my $tableau_elt;
		$tableau_elt->{ element } = $attr;
		$tableau_elt->{ name } = $attribute;
		$tableau_elt->{ count } = $attr->{ count };
		$tableau_elt->{ match } = $match;
		$tableau_elt->{ xpath } = $xpath . '/@' . $attribute;

		push @tableauHeadwordHn, $tableau_elt;
	}
}


sub guess_pronun {
	my $elt = $_[0];
	my $level = $_[1];
	my $xpath = $_[2];
	my $compte = $_[3];    # 'count' of entry
	my $headword = $_[4];
	my $match = 0;
	
	my $charnumber = $elt->{ charnumber };
	my $charsize = $elt->{ charsize };
	my $words = $elt->{ words };
	my $diff = keys %{$elt->{ values }};

	if ($level > 0) {$xpath .= '/' . $elt->{ name };};

	if ($level >0 && $elt->{ name } ne $headword && $charnumber && $words) { # descendant de entry
 		
 		#  nombre de pronunciation proche de celui de headword
		if (($elt->{ count } > ($compte - $compte*0.02)) && ($elt->{ count } < ($compte + $compte*0.02))) {      
			$match += 0.2;
		}
		if ($elt->{ name } =~ /pron/){
			# print " match nom; \n";
			$match += 0.7;
		}
		
		# peu de mots
		if (($words/$charnumber)<2) {
			$match += 0.2;
		}
		
		if ($elt->{ count }  < $maxMemoireListeValeurs) {
			if ($elt->{ count } / $diff < 1.5) {
				# beaucoup de valeurs différentes
				$match += 0.3 
			}
		}
		else {
			if ($maxMemoireListeValeurs / $diff < 1.5) {
				# beaucoup de valeurs différentes
				$match += 0.3 
			}
		}

		my $tableau_elt;
		$tableau_elt->{ level } = $level;
		$tableau_elt->{ name } = $elt->{ name };
		$tableau_elt->{ count } = $elt->{ count };
		$tableau_elt->{ match } = $match / $level;		
		$tableau_elt->{ xpath } = $xpath;
		push @tableauPronun, $tableau_elt;
	
	}
	foreach my $child (reverse sort { $a->{ count } <=> $b->{ count } } values %{$elt->{ child }}) {
		&guess_pronun($child, $level+1, $xpath, $compte, $headword);
	}
}


sub guess_pos {
	my $elt = $_[0];
	my $level = $_[1];
	my $xpath = $_[2];
	my $compte = $_[3];    # 'count' of entry

	my $charnumber = $elt->{ charnumber };
	my $charsize = $elt->{ charsize };
	my $words = $elt->{ words };
	
	my $match = 0;
	my $diff = keys %{$elt->{ values }};
	if ($level > 0) {$xpath .= '/' . $elt->{ name };};
	if ($level >0 && $charnumber) {

		if ($elt->{ count } >= $compte) {       # fréquence de POS est élevée >= HW
	 		
			$match += 0.1;
			if ($elt->{ name } =~ /pos/ || $elt->{ name } =~ /gram/ || $elt->{ name } =~ /cat/){
				# print " match nom; \n";
				$match += 0.45;
			}
			
			# peu de mots
			if (($words/$charnumber) <3) {
				$match += 0.2;
			}
			
			# beaucoup de valeurs différentes
			my $ratiodiff = 0;
			if ($elt->{ count }  < $maxMemoireListeValeurs) {
				$ratiodiff = $elt->{ count } / $diff;
			}
			else {
				$ratiodiff = $maxMemoireListeValeurs / $diff;
			}
			$match += 0.007 * $ratiodiff;
			
			my $tableau_elt;
			$tableau_elt->{ level } = $level;
			$tableau_elt->{ name } = $elt->{ name };
			$tableau_elt->{ count } = $elt->{ count };
			$tableau_elt->{ match } = $match; # / $level;	 # se trouve en priorité dans le début de l'arbre			
			$tableau_elt->{ xpath } = $xpath;
			push @tableauPos, $tableau_elt;
		}
	}
	foreach my $child (values %{$elt->{ child }}) {
		&guess_pos($child, $level+1, $xpath, $compte);
	}
}


sub guess_sense {
	my $elt = $_[0];
	my $level = $_[1];
	my $xpath = $_[2];
	my $compte = $_[3];    # 'count' of entry

	my $charnumber = $elt->{ charnumber };
	
	my $match = 0;
	if ($level > 0) {$xpath .= '/' . $elt->{ name };};
	if ($level >0 && !$charnumber){  	

		# il y a plus de sense que de entry
		if ($elt->{ count } > 1.5 * $compte) {       
			$match += 0.3;
		}
		if ($elt->{ name } =~ /sens/){
			# print " match nom; \n";
			$match += 0.75;
		}
		
		# l'élément a un attribut avec liste de valeurs (ressemblant au numéro de sens)
		foreach my $attribute ($Collator->sort(keys %{ $elt->{ attribute }})) {
			my $attr = $elt->{ attribute }{ $attribute };
			my $diff = keys %{$attr->{ values }};
			if ($diff<$maxAffichageListeValeurs) {
				$match += 0.3
			}
		}	

	
		my $tableau_elt;
		$tableau_elt->{ element } = $elt;
		$tableau_elt->{ level } = $level;
		$tableau_elt->{ name } = $elt->{ name };
		$tableau_elt->{ count } = $elt->{ count };
		$tableau_elt->{ match } = $match / $level;	 # se trouve en priorité dans le début de l'arbre
		$tableau_elt->{ xpath } = $xpath;
		push @tableauSens, $tableau_elt;
	}
	foreach my $child (reverse sort { $a->{count} <=> $b->{count} } values %{$elt->{ child }}) {
		&guess_sense($child, $level+1, $xpath, $compte);
	}
}

sub guess_sense_block {
	my $senseXpath = $_[0];
	$senseXpath =~ s/\/[^\/]+$//;
	return $senseXpath;
}

sub guess_def {
	my $elt = $_[0];
	my $level = $_[1];
	my $xpath = $_[2];
	my $compte = $_[3];    # 'count' of entry
	my $headword = $_[4];
	my $match = 0;
	my $diff = keys %{$elt->{ values }};
		
	my $charnumber = $elt->{ charnumber };
	my $charsize = $elt->{ charsize };
	my $words = $elt->{ words };
	if ($level > 0) {$xpath .= '/' . $elt->{ name };};
	if ($level >0 && $elt->{ name } ne $headword && $charnumber && ($words >= 2)) {
       
       #  nombre de def proche de entry ou supérieur
       	if ($elt->{ count } >= $compte * 0.9) {
       			$match += 0.3;
#       			print $elt->{ name }, " : nombre de def proche de entry ou supérieur : " .$elt->{ count } . " $compte et $match\n";
		}

		# beaucoup de mots 
		#$match += (0.01 * $words/$charnumber);
        #print $elt->{ name }, " : beaucoup de mots : $words et $match\n";
		# beaucoup de caractères
		$match += (0.001 * $charsize/$charnumber);
#       	print $elt->{ name }, " : beaucoup de caractères : " . $charsize/$charnumber . " et $match\n";

		if ($elt->{ name } =~ /d[eé]finition/){
			# print " match nom; \n";
			$match += 0.5;
		}
		elsif ($elt->{ name } =~ /^d[eé]f$/){
			# print " match nom; \n";
			$match += 0.3;
		}
		
		# beaucoup de valeurs différentes
		if ($elt->{ count }  < $maxMemoireListeValeurs) {
			if ($elt->{ count } / $diff < 1.2) {
				$match += 0.3;
 #     			print $elt->{ name }, " : beaucoup de valeurs différentes : $match\n";
			}
		}
		else {
			if ($maxMemoireListeValeurs / $diff < 1.2) {
				$match += 0.3; 
#   			print $elt->{ name }, " : beaucoup de valeurs différentes : $match\n";
			}
		}

		 # la définition est souvent avant l'exemple qui lui ressemble
		 $match += 0.05 / ($elt->{ order } +1);
#       	print $elt->{ name }, " : définition souvent avant l'exemple : " .$elt->{ order } . " et $match\n";
		 # et tôt dans l'arbre
		 $match += 0.1 / $level;
 #      	print $elt->{ name }, " : définition tôt dans l'arbre : $level et $match\n";
	
		my $tableau_elt;
		$tableau_elt->{ level } = $level;
		$tableau_elt->{ name } = $elt->{ name };
		$tableau_elt->{ count } = $elt->{ count };
		$tableau_elt->{ match } = $match;			
		$tableau_elt->{ xpath } = $xpath;
		push @tableauDef, $tableau_elt;
	}
	foreach my $child (reverse sort { $a->{count} <=> $b->{count} } values %{$elt->{ child }}) {
		&guess_def($child, $level+1, $xpath, $compte, $headword);
	}
}


sub guess_example {
	my $elt = $_[0];
	my $level = $_[1];
	my $xpath = $_[2];
	my $compte = $_[3];    # 'count' of entry
	my $headword = $_[4];
	my $match = 0;
	my $diff = keys %{$elt->{ values }};
		
	my $charnumber = $elt->{ charnumber };
	my $charsize = $elt->{ charsize };
	my $words = $elt->{ words };
	if ($level > 0) {$xpath .= '/' . $elt->{ name };};
	if ($level >0 && $elt->{ name } ne $headword && $charnumber && ($words >= 2)) {
       
       #  nombre de exemple proche de entry ou supérieur
       	if ($elt->{ count } >= $compte * 0.4) {
       			$match += 0.3;
       	#		print $elt->{ name }, " : nombre de ex proche de entry : " .$elt->{ count } . " $compte et $match\n";
		}

		# beaucoup de mots 
		$match += (0.01 * $words/$charnumber);
        # print $elt->{ name }, " : beaucoup de mots : $words et $match\n";
		# beaucoup de caractères
		$match += (0.001 * $charsize/$charnumber);
       	# print $elt->{ name }, " : beaucoup de caractères : " . $charsize/$charnumber . " et $match\n";

		if ($xpath =~ /\/ex[ea]mple\//){
		#	 print " match xpath; \n";
			$match += 0.5;
		}
		elsif ($xpath =~ /\/ex\//) {
			$match += 0.2;
		}
		
		# beaucoup de valeurs différentes
		if ($elt->{ count }  < $maxMemoireListeValeurs) {
			if ($elt->{ count } / $diff < 1.2) {
				$match += 0.3;
      	#		print $elt->{ name }, " : beaucoup de valeurs différentes : $match\n";
			}
		}
		else {
			if ($maxMemoireListeValeurs / $diff < 1.2) {
				$match += 0.3; 
   		#	print $elt->{ name }, " : beaucoup de valeurs différentes : $match\n";
			}
		}

		 # l'exemple est souvent après les autres éléments
		 $match += 0.01 * ($elt->{ order } +1);
       	 #   print $elt->{ name }, " : exemple après les autres éléments : " .$elt->{ order } . " et $match\n";
		 # et tard dans l'arbre
		 $match += 0.01 * $level;
 	    # 	print $elt->{ name }, " : exemple tard dans l'arbre : $level et $match\n";
	
		my $tableau_elt;
		$tableau_elt->{ level } = $level;
		$tableau_elt->{ name } = $elt->{ name };
		$tableau_elt->{ count } = $elt->{ count };
		$tableau_elt->{ match } = $match;			
		$tableau_elt->{ xpath } = $xpath;
		push @tableauEx, $tableau_elt;
	}
	foreach my $child (reverse sort { $a->{count} <=> $b->{count} } values %{$elt->{ child }}) {
		&guess_example($child, $level+1, $xpath, $compte, $headword);
	}
}

sub guess_example_block {
	my $exampleXpath = $_[0] || '';
	$exampleXpath =~ s/\/[^\/]+$//;
	return $exampleXpath;
}

