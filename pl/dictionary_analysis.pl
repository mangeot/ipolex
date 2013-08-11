#!/usr/bin/perl
#
# xmlelements-report.pl
#

use strict;
use warnings;
use utf8;

use XML::Parser;
use Unicode::Collate;
binmode STDOUT, ':utf8'; 
binmode STDERR, ':utf8'; 

my $maxAffichageListeValeurs = 50;
my $maxMemoireListeValeurs = 1000;

@ARGV or die "usage: xmlelements-report file.xml\n";

my $root;
my $Encoding;
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

print STDERR "Début de l'analyse du dictionnaire\n";
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
my $entryXpath = $tableauEntry[0]->{ xpath };
my $entryCompte = $tableauEntry[0]->{ count };
my $volumeXpath = $entryXpath;
$volumeXpath =~ s/\/[^\/]+$//;

my @tableauHeadword;
&guess_headword($root,1,'',$entryXpath, $entryCompte);
@tableauHeadword = reverse sort { $a->{ match } <=> $b->{ match } } @tableauHeadword;
my @tableauPronun;
&guess_pronun($root,0,'',$entryXpath, $entryCompte);
@tableauPronun = reverse sort { $a->{ match } <=> $b->{ match } } @tableauPronun;
my @tableauPos;
&guess_pos($root,0,'',$entryXpath, $entryCompte);
@tableauPos = reverse sort { $a->{ match } <=> $b->{ match } } @tableauPos;
my @tableauDef;
&guess_def($root,0,'',$entryXpath, $entryCompte);
@tableauDef = reverse sort { $a->{ match } <=> $b->{ match } } @tableauDef;
my @tableauSens;
&guess_sense($root,0,'',$entryXpath, $entryCompte);
@tableauSens = reverse sort { $a->{ match } <=> $b->{ match } } @tableauSens;

print '		<section id="CDMElements">
			<h2>Tableau des éléments CDM</h2>
';
print '			<table><thead><th>Nom</th><th>XPath</th></thead>
				<tbody>
			';
print "\t\t\t<tr><td>cdm-volume</td><td>$volumeXpath</td></tr>\n";
print "\t\t\t<tr><td>cdm-entry</td><td>$tableauEntry[0]->{ xpath }</td></tr>\n";
print "\t\t\t<tr><td>cdm-headword</td><td>$tableauHeadword[0]->{ xpath }</td></tr>\n";
print "\t\t\t<tr><td>cdm-pronunciation</td><td>$tableauPronun[0]->{ xpath }</td></tr>\n";
print "\t\t\t<tr><td>cdm-pos</td><td>$tableauPos[0]->{ xpath }</td></tr>\n";
print "\t\t\t<tr><td>cdm-definition</td><td>$tableauDef[0]->{ xpath }</td></tr>\n";
print "\t\t\t<tr><td>cdm-sense</td><td>$tableauSens[0]->{ xpath }</td></tr>\n";
print '				</tbody>
			</table>
		</section>
';	
	print '	</body>
';

my $entryName = $tableauEntry[0]->{ name };
print '<volume-metadata encoding="',$Encoding,'" hwnumber="',$elementsArray{$entryName}, '">
			<cdm-elements>
';
print "\t\t\t<cdm-volume xpath='$volumeXpath' />\n";
print "\t\t\t<cdm-entry xpath='$tableauEntry[0]->{ xpath }' />\n";
print "\t\t\t<cdm-headword xpath='$tableauHeadword[0]->{ xpath }' />\n";
print "\t\t\t<cdm-pronunciation xpath='$tableauPronun[0]->{ xpath }' />\n";
print "\t\t\t<cdm-pos xpath='$tableauPos[0]->{ xpath }' />\n";
print "\t\t\t<cdm-definition xpath='$tableauDef[0]->{ xpath }' />\n";
print "\t\t\t<cdm-sense xpath='$tableauSens[0]->{ xpath }' />\n";
print '	</cdm-elements>
</volume-metadata>
';

&print_template($root,0);

print "\n</html>";

print STDERR "Fin de l'écriture du résultat\n";	

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
				print $key,':',$attr->{ values }{ $key };
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
				print $key,':',$elt->{ values }{ $key };
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
		print ' ',$attribute,'=""';
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



sub guess_headword {
	my $elt = $_[0];
	my $level = $_[1];
	my $xpath = $_[2];
	my $entryXpath = $_[3];
	my $compte = $_[4];     # 'count' of entry
	my $word = $elt->{ words };
	my $char = $elt->{ charnumber };
	
	my $match = 0;
	$xpath .= '/' . $elt->{ name };

	if ($xpath =~ /^$entryXpath\/.+/  && $char) {       #  descendant de entry && nombre d'entry == nombre d'element
	 		
			if ($elt->{ count } == $compte){
				$match += 0.45;
			}
			if (($elt->{ name } =~ /headword/) || ($elt->{ name } =~ /vedette/)){
				# print " match nom; \n";
				$match += 0.45;
			}
			
			 if (($word/$char >= 1.0) && ($word/$char <= 3.0)){
				# print " match number of words; \n";
				$match += 0.3;
			 }

			my $tableau_elt;
			$tableau_elt->{ level } = $level;
			$tableau_elt->{ name } = $elt->{ name };
			$tableau_elt->{ count } = $elt->{ count };
			$tableau_elt->{ match } = $match / $level;	 # se trouve en priorité dans le début de l'arbre	
			$tableau_elt->{ xpath } = $xpath;

			push @tableauHeadword, $tableau_elt;

		}
	foreach my $child (reverse sort { $a->{ count } <=> $b->{ count } } values %{$elt->{ child }}) {
		&guess_headword($child, $level+1, $xpath, $entryXpath, $compte);
	}
}


sub guess_pronun {
	my $elt = $_[0];
	my $level = $_[1];
	my $xpath = $_[2];
	my $entryXpath = $_[3];
	my $compte = $_[4];    # 'count' of entry
	my $match = 0;
	$xpath .= '/' . $elt->{ name };
	
	my $charnumber = $elt->{ charnumber };
	my $charsize = $elt->{ charsize };
	my $words = $elt->{ words };

	if ($xpath =~ /^$entryXpath\/.+/ && $charnumber && $words) { # descendant de entry
		if (($elt->{ count } > ($compte - $compte*0.02)) && ($elt->{ count } < ($compte + $compte*0.02))) {       #  nombre de pronunciation soit proche de celui de headword
			$match += 0.2;
		}
		if ($elt->{ name } =~ /pron/){
			# print " match nom; \n";
			$match += 0.7;
		}
		if ($words<2) {
			$match += 0.2;
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
		&guess_pronun($child, $level+1, $xpath, $entryXpath, $compte);
	}
}


sub guess_pos {
	my $elt = $_[0];
	my $level = $_[1];
	my $xpath = $_[2];
	my $entryXpath = $_[3];
	my $compte = $_[4];    # 'count' of entry
	$xpath .= '/' . $elt->{ name };

	my $charnumber = $elt->{ charnumber };
	my $charsize = $elt->{ charsize };
	my $words = $elt->{ words };
	
	my $match = 0;
	my $diff = keys %{$elt->{ values }};
	if ($xpath =~ /^$entryXpath\/.+/ && $charnumber) {
		if  ($diff > 3 && $diff <= 40) { # descendant de entry
			$match += 0.4;
		}
		if ($elt->{ count } >= $compte) {       # fréquence de POS est élevée >= HW
	 		
			$match += 0.1;
			if ($elt->{ name } =~ /pos/ || $elt->{ name } =~ /gram/ || $elt->{ name } =~ /cat/){
				# print " match nom; \n";
				$match += 0.45;
			}
			
			if ($words <3) {
				$match += 0.2;
			}
			
			my $tableau_elt;
			$tableau_elt->{ level } = $level;
			$tableau_elt->{ name } = $elt->{ name };
			$tableau_elt->{ count } = $elt->{ count };
			$tableau_elt->{ match } = $match; # / $level;	 # se trouve en priorité dans le début de l'arbre			
			$tableau_elt->{ xpath } = $xpath;
			push @tableauPos, $tableau_elt;
		}
	}
#	foreach my $child (reverse sort { $a->{ count } <=> $b->{ count } } values %{$elt->{ child }}) {
	foreach my $child (values %{$elt->{ child }}) {
		&guess_pos($child, $level+1, $xpath, $entryXpath, $compte);
	}
}



sub guess_def {
	my $elt = $_[0];
	my $level = $_[1];
	my $xpath = $_[2];
	my $entryXpath = $_[3];
	my $compte = $_[4];    # 'count' of entry
	my $match = 0;
	$xpath .= '/' . $elt->{ name };
		
	my $charnumber = $elt->{ charnumber };
	#my $charsize = $elt->{ charsize };
	my $words = $elt->{ words };
	if ($xpath =~ /^$entryXpath\/.+/ && $charnumber) {
       
		if($words/$charnumber >= 3.0){
			$match += 0.2;
		}

		if ($elt->{ name } =~ /def/){
			# print " match nom; \n";
			$match += 0.75;
		}
	
		my $tableau_elt;
		$tableau_elt->{ level } = $level;
		$tableau_elt->{ name } = $elt->{ name };
		$tableau_elt->{ count } = $elt->{ count };
		$tableau_elt->{ match } = $match;			
		$tableau_elt->{ xpath } = $xpath;
		push @tableauDef, $tableau_elt;
	}
	foreach my $child (reverse sort { $a->{count} <=> $b->{count} } values %{$elt->{ child }}) {
		&guess_def($child, $level+1, $xpath, $entryXpath, $compte);
	}
}

sub guess_sense {
	my $elt = $_[0];
	my $level = $_[1];
	my $xpath = $_[2];
	my $entryXpath = $_[3];
	my $compte = $_[4];    # 'count' of entry
	$xpath .= '/' . $elt->{ name };

	my $charnumber = $elt->{ charnumber };
	#my $charsize = $elt->{ charsize };
	my $words = $elt->{ words };
	
	my $match = 0;
	if ($xpath =~ /^$entryXpath\/.+/ ){#&& $charnumber){  	

		if ($elt->{ count } >= 2*$compte) {       
			$match += 0.2;
		}
		if ($elt->{ name } =~ /sens/){
			# print " match nom; \n";
			$match += 0.75;
		}
	
		my $tableau_elt;
		$tableau_elt->{ level } = $level;
		$tableau_elt->{ name } = $elt->{ name };
		$tableau_elt->{ count } = $elt->{ count };
		$tableau_elt->{ match } = $match;			
		$tableau_elt->{ xpath } = $xpath;
		push @tableauSens, $tableau_elt;
	}
	foreach my $child (reverse sort { $a->{count} <=> $b->{count} } values %{$elt->{ child }}) {
		&guess_sense($child, $level+1, $xpath, $entryXpath, $compte);
	}
}
