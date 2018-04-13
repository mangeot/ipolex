#!/usr/bin/perl -w
#
# Transformation extrait Thierno : 
# ./transformation-fichiercomplet.pl -v -i Donnees/anaan.xml -n 'Thierno' -m Donnees/Baat_fra-wol/Baat_wol_fra-metadata.xml -s Donnees/Baat_fra-wol/DicoArrivee_wol_fra-metadata.xml -t Donnees/Baat_fra-wol/dicoarrivee_wol_fra-template.xml > out.xml
#
# Transformation dico Thierno : 
# ./transformation-fichiercomplet.pl -v -i Donnees/Baat_fra-wol/baat_wol_fra-prep.xml  -m Donnees/Baat_fra-wol/Baat_wol_fra-metadata.xml -s Donnees/Baat_fra-wol/DicoArrivee_wol_fra-metadata.xml -t Donnees/Baat_fra-wol/dicoarrivee_wol_fra-template.xml -n 'Thierno' > out.xml
#
# Transformation extrait Cherif
# ./transformation-fichiercomplet.pl -v -i Donnees/cherif.xml  -m Donnees/Baat_fra-wol/DicoCherif_wol_fra-metadata.xml -s Donnees/Baat_fra-wol/DicoArrivee_wol_fra-metadata.xml -t Donnees/Baat_fra-wol/dicoarrivee_wol_fra-template.xml -n 'Chérif' > out.xml
#
# Transformation dico Chérif : 
# ./transformation-fichiercomplet.pl -v -i Donnees/Baat_fra-wol/dicocherif_wol_fra-prep.xml  -m Donnees/Baat_fra-wol/DicoCherif_wol_fra-metadata.xml -s Donnees/Baat_fra-wol/DicoArrivee_wol_fra-metadata.xml -t Donnees/Baat_fra-wol/dicoarrivee_wol_fra-template.xml -n 'Chérif' > out.xml


use strict;
use warnings;
use utf8::all;

use XML::DOM;
use XML::DOM::XPath;
use JSON;
use Data::Dumper;
use Getopt::Long; # pour gérer les arguments.

my $encoding = "UTF-8";
my $unicode = "UTF-8";
my $nomDicoDepart = '';
my ($metaEntree, $metaSortie, $entreeModele, $fichierEntree, $fichierSortie, $help, $verbeux) = ();

GetOptions( 
  'entree|in|from|i=s' => \$fichierEntree, 
  'sortie|out|to|o=s'           => \$fichierSortie, 
  'metaentree|min|m=s' => \$metaEntree, 
  'metasortie|mout|s=s'           => \$metaSortie, 
  'modele|template|t=s'           => \$entreeModele, 
  'nom|name|n=s' 	=> \$nomDicoDepart, 
  'encodage|encoding|enc|c=s' 	=> \$encoding, 
  'aide|help|h'                	  	=> \$help, 
  'verbeux|verbose|v'             	  	=> \$verbeux, 
  );
 
 
my %CDMPOSGENERIQUE = ('turu bokkale' => 'nom',

					);
 
my $date = localtime;
my $INFILE;
my $OUTFILE;

if ($fichierEntree) {
	open $INFILE, "<:encoding($encoding)",$fichierEntree or die ("$! $fichierEntree \n");
} # si le fichier entree n'est pas spécifié, on ouvre l'entrée standard
else {
	$INFILE  = *STDIN;
}
if ($fichierSortie) {
	open $OUTFILE, ">:encoding($unicode)",$fichierSortie or die ("$! $fichierSortie \n");
} # si le fichier sortie n'est pas spécifié, on ouvre la sortie standard
else {
	$OUTFILE = *STDOUT;
}
if (! ($entreeModele && $metaEntree && $metaSortie)) {&help;};
if (defined $help) {&help;};


sub help {
	print STDERR "Message d'aide, voir V_for_fusionInterne.pl pour exemple\n";
	exit 0;
}

# print STDERR "Chargement du modèle\n";
open my $MODELEFILE, "<:encoding($unicode)", $entreeModele or die "error opening $entreeModele: $!";
my $xmlarrivee = do { local $/; <$MODELEFILE> };
close $MODELEFILE;
#print STDERR "XMLarrivée : [",$xmlarrivee,"]",$entreeModele;

#print STDERR "load cdm départ:\n";
my %CDMSDEPART=load_cdm($metaEntree);
#print STDERR "load cdm arrivée:\n";
my %CDMSARRIVEE=load_cdm($metaSortie);

#print STDERR "load tables arrivée:\n";
my %TABLESARRIVEE = load_tables($metaSortie);
# print STDERR "tablesarrivee:",Dumper(%TABLESARRIVEE);

# on initialise le parseur XML DOM
my $parser= XML::DOM::Parser->new();

# print STDERR "Récupération de quelques pointeurs CDM utiles pour la suite\n";
my $cdmvolumedepart = delete($CDMSDEPART{'cdm-volume'});
my $cdmvolumearrivee = delete($CDMSARRIVEE{'cdm-volume'});

my $cdmentrydepart = delete($CDMSDEPART{'cdm-entry'});
my $cdmentryarrivee = delete($CDMSARRIVEE{'cdm-entry'});

my $cdmheadworddepart = $CDMSDEPART{'cdm-headword'};

my $cdmentrysource = $CDMSARRIVEE{'cdm-source-entry'};
my $cdmentrysourceorigin = $CDMSARRIVEE{'cdm-source-entry-origin'};

# print STDERR "Transformation des tables CDM en arbres\n";
my $CDMArbreDepart = arbre_cdm(\%CDMSDEPART);
my $CDMArbreArrivee = arbre_cdm_complet(\%CDMSARRIVEE);

if ($verbeux) {print STDERR "arbredepart: \n",Dumper($CDMArbreDepart);}
if ($verbeux) {print STDERR "arbrearrivee: \n",Dumper($CDMArbreArrivee);}

# On reconstruit les balises ouvrantes et fermantes du volume 
my $headerdepart = xpath2opentags($cdmvolumedepart);
my $footerdepart = xpath2closedtags($cdmvolumedepart);

my $closedtagentrydepart = xpath2closedtags(xpathdifference($cdmentrydepart,$cdmvolumedepart));
my $opentagvolumearrivee = xpath2opentags($cdmvolumearrivee, 'creation-date="' . $date . '"');
my $closedtagvolumearrivee = xpath2closedtags($cdmvolumearrivee);

# On va lire le fichier d'entrée article par article 
# donc on coupe après une balise de fin d'article.
$/ = $closedtagentrydepart;

# On imprime le début du fichier résultat = en-tête XML
print $OUTFILE '<?xml version="1.0" encoding="UTF-8" ?>
';
print $OUTFILE $opentagvolumearrivee,"\n";

# Boucle principale sur chaque entrée
while( my $line = <$INFILE>)  {   

	$line = $headerdepart . $line . $footerdepart;
	my $docdepart = $parser->parse ($line);
	my $docarrivee = $parser->parse ($xmlarrivee);
	
	my @headwords = $docdepart->findnodes($cdmheadworddepart);
	my $headword = getNodeText($headwords[0]);
	
if ($verbeux) 	{print STDERR "Transformation article : $headword\n";}
	copiePointeurs($CDMArbreDepart, $CDMArbreArrivee, $docdepart, $docarrivee);
	#	print STDERR "fin des copiePointeurs\n";

	my @entryarrivee = $docarrivee->findnodes($cdmentryarrivee);
	my $entryarrivee = $entryarrivee[0];

#	print STDERR "copie de l'entrée source $cdmentrydepart dans l'entrée arrivée\n";

	my @entrydepart = $docdepart->findnodes($cdmentrydepart);
	my $entrydepart = $entrydepart[0];

#	print STDERR "Recopie de l'article de départ tel quel dans l'article d'arrivée pour éventuel travail ultérieur\n";
	my @entrysourceorigin = $docarrivee->findnodes($cdmentrysourceorigin);
	if (scalar(@entrysourceorigin)>0) {
		my $entrysourceorigin = $entrysourceorigin[0];
		$entrysourceorigin->addText($nomDicoDepart);
	}
	my @entrysource = $docarrivee->findnodes($cdmentrysource);
	if (scalar(@entrysource)>0) {
		my $elementsource = $entrysource[0];
		$entrydepart->setOwnerDocument($docarrivee);
		$elementsource->appendChild($entrydepart);
	}
	print $OUTFILE $entryarrivee->toString,"\n";
#	print STDERR "Fin transformation article\n";
}
#print STDERR "Fin transformation fichier\n";
print $OUTFILE $closedtagvolumearrivee;


# Cette fonction permet de calculer la différence entre deux XPath
sub xpathdifference {
	my $xpath = $_[0];
	my $xpathcourt = $_[1];
	$xpath =~ s/\/$//;
	$xpathcourt =~ s/\/$//;
	
	my $len = length $xpathcourt;	
	my $xpathcourt2 = substr($xpath,0,$len);
	if ($xpathcourt eq $xpathcourt2) {
		$xpath = substr($xpath,$len);
	}
	return $xpath;
}

# Cette fonction convertit un XPath en balises ouvrantes
sub xpath2opentags {
	my $xpath = $_[0];
	my $attribut = $_[1] || '';
	if ($attribut ne '') {
		$attribut = ' ' . $attribut;
	}
	$xpath =~ s/\/$//;
	$xpath =~ s/\//></g;
	$xpath =~ s/^>//;
	$xpath .= $attribut . '>';
}

# Cette fonction convertit un XPath en balises fermantes
sub xpath2closedtags {
	my $xpath = $_[0];
	my $tags = '';
	my @xpath = reverse split(/\//,$xpath);
	foreach my $tag (@xpath) {
		if ($tag ne '') {
			$tags .= '</' . $tag . '>';	
		}
	}
	return $tags;
}

# Cette fonction permet de récupérer le texte dans un nœud DOM quel que soit le type de nœud
sub getNodeText {
	my $node = $_[0];
	my $text = '';
	if ($node) {
	if ($node->getNodeType == DOCUMENT_NODE) {
    	$node = $node->getDocumentElement();
	}
	if ($node->getNodeType == TEXT_NODE || $node->getNodeType == CDATA_SECTION_NODE) {
          $text = $node->getData();
    }
    elsif ($node->getNodeType == ATTRIBUTE_NODE) {
          $text = $node->getValue();
    }
    elsif ($node->getNodeType == ELEMENT_NODE || $node->getNodeType == ENTITY_REFERENCE_NODE || $node->getNodeType == DOCUMENT_FRAGMENT_NODE) {
    	foreach my $child ($node->getChildNodes()) {
          $text .= getNodeText($child);
        }
    }
    elsif ($node->getNodeType == COMMENT_NODE || $node->getNodeType == ENTITY_NODE || $node->getNodeType == PROCESSING_INSTRUCTION_NODE || $node->getNodeType == DOCUMENT_TYPE_NODE) {
    	;
    }
    else {
          $text = $node->toString();
    }
    }
    else {
    	print STDERR "Node undefined\n";
    }
	return $text;
}


# cette fonction permet de récupérer les pointeurs cdm à partir du fichier metada.
sub load_cdm {
  my ($fichier)=@_;
  open (IN, "<:encoding($unicode)", $fichier);
  my %dico=();
  while(my $ligne=<IN>){
      
      if($ligne=~/^\s*<(\S+)\s+xpath=\"([^\"]+)(\"\sd:lang=\")?(\w+)?/){
           my $cdm=$1; my $xpath=$2;  my $lang = $4;
           if ($ligne=~/d:lang/)
           {
           $dico{$cdm.$lang}=$xpath;}
           else
           {$dico{$cdm}=$xpath;}
  }
 
}
close(IN);
 return %dico;

 }

sub load_tables {
  my ($fichier)=@_;
  my $document = do {
    local $/ = undef;
    open (IN, "<:encoding($unicode)", $fichier);
    <IN>;
  };
 close(IN);
 $document =~ s/^.+<cdm\-tables>\s*//sm;
 $document =~ s/\s*<\/cdm\-tables>.+$//sm;
 
 print STDERR "doc: $document\n";
 
  my @tables = split(/<\/[^>]+>\s*/sm,$document),

  my %dico=();
  foreach my $table (@tables){
      $table =~ s/^\s*<table\-([^>]+)>//sm;
  	 	print STDERR "table: [$table]\n";
      my $tablename = $1;
      $dico{$tablename} = decode_json($table);
  }
 return %dico; 
}

# Cette fonction copie le résultat d'un pointeur XPath de départ dans un résultat de pointeur XPath d'arrivée
# Elle est récursive
sub copiePointeurs {
	my %ArbreDepart = %{ shift() };
	my %ArbreArrivee = %{ shift() };
	my $ancetreDepart = shift();
	my $ancetreArrivee = shift();
	
	foreach my $cle (keys %ArbreDepart) {
		my $pointeurDepart = $ArbreDepart{$cle};
		my @pointeursDepart = @$pointeurDepart;
		$pointeurDepart = $pointeursDepart[0];
		if ($verbeux) {print STDERR 'départ: ',$cle,' pointeur:',$pointeurDepart,"\n";}
		my $pointeurArrivee = $ArbreArrivee{$cle};
		if ($pointeurArrivee) {
			my @pointeursArrivee = @$pointeurArrivee;
			$pointeurArrivee = $pointeursArrivee[0];
			# ATTENTION : supprimer le / final sinon le module xpath bugue !
			$pointeurDepart =~ s/\/$//;
			$pointeurArrivee =~ s/\/$//;
			$pointeurArrivee =~ s/\/text\(\)$//;

			if ($verbeux) {print STDERR 'arrivée: ',$cle,' pointeur:',$pointeurArrivee,"\n";}
			my @noeudsArrivee = $ancetreArrivee->findnodes($pointeurArrivee);
			my $noeudArrivee = $noeudsArrivee[0];

			if ($noeudArrivee) {
				if ($verbeux) {print STDERR 'cdmd: ', $pointeurDepart, ' cdma: ', $pointeurArrivee,"\n";}
				
				
				my $noeudArriveeParent = $noeudArrivee->getParentNode();
				my $noeudArriveeSuivant = $noeudArrivee->getNextSibling();
				my @noeudsDepart = $ancetreDepart->findnodes($pointeurDepart);
				if (scalar(@noeudsDepart)>1) {
					$noeudArriveeParent->removeChild($noeudArrivee);
				}
				foreach my $noeudDepart (@noeudsDepart) {
					my $noeudClone = $noeudArrivee;
					# S'il y a plusieurs nœuds de départ, il faut cloner le nœud d'arrivée
					if (scalar(@noeudsDepart)>1) {
						$noeudClone = $noeudArrivee->cloneNode(1);
						$noeudClone->setOwnerDocument($noeudArrivee->getOwnerDocument());
					}
					# S'il y a des pointeurs CDM descendants du pointeur courant, 
					# on appelle récursivement copiePointeurs avec les descendants
					if (scalar(@pointeursDepart)>1) {
						my $descendantsDepart = $pointeursDepart[1];
						my $descendantsArrivee = \%ArbreArrivee;
						if (scalar(@pointeursArrivee)>1) {
							$descendantsArrivee = $pointeursArrivee[1];
						}
						if ($verbeux) {print STDERR "Appel récursif : copiePointeurs\n";}
						copiePointeurs($descendantsDepart,$descendantsArrivee, $noeudDepart,$noeudClone);
					}
					# Sinon, on recopie le texte
					else {
						my $noeudTexte = getNodeText($noeudDepart);
						my $table = $TABLESARRIVEE{$cle};
						if ($table) {
							$noeudTexte = $table->{$noeudTexte};
							if ($verbeux) {print STDERR "conversion noeudTexte: $noeudTexte\n";}
						}
						if ($verbeux) {print STDERR "noeudTexte: $noeudTexte\n";}
						$noeudClone->addText($noeudTexte);
					}
					# S'il y a plusieurs nœuds de départ, il faut insérer le nœud d'arrivée
					# cloné précédemment
					if (scalar(@noeudsDepart)>1) {
						if ($noeudArriveeSuivant) { # si le nœud d'arrivée a un noeud suivant
							$noeudArriveeParent->insertBefore($noeudClone,$noeudArriveeSuivant);
						}
						else { # sinon
							$noeudArriveeParent->appendChild($noeudClone);
						}
					}
				}
			}
			else {
				if ($verbeux) {print STDERR "noeudArrivee donne une valeur nulle\n";}
			}
		}
		else {
			if ($verbeux) {print STDERR "pointeurArrivee donne une valeur nulle\n";}
		}
	}	
}

# Cette fonction transforme un tableau de pointeurs CDM en arbre de pointeurs
# les pointeurs enfants sont des descendants de l'arbre XML
sub arbre_cdm {
	my $tableauDepart = $_[0];
#	print STDERR Dumper($tableauDepart);
	my @keys = reverse sort { $tableauDepart->{$a} cmp $tableauDepart->{$b} } keys %{ $tableauDepart };
#	print STDERR Dumper(\@keys);
	foreach my $key (keys %{ $tableauDepart }) {
		my $pointeur = $tableauDepart->{$key};
		my @feuille = ( $pointeur );
		$tableauDepart->{$key} = \@feuille;
	}	
	my $i=0;
	my $keyssize = scalar(@keys);
	foreach my $firstkey (@keys) {
#		print STDERR "FK: $firstkey\n";
		my $fpointeur = $tableauDepart->{$firstkey};
		my @fpointeur = @$fpointeur;
		$fpointeur = $fpointeur[0];
		my $j=$i+1;
		while ($j<$keyssize) {
			my $secondkey = $keys[$j];
#			print STDERR "$firstkey , $secondkey\n";
			my $spointeur = $tableauDepart->{$secondkey};
			my @spointeur = @$spointeur;
			$spointeur = $spointeur[0];
			if ($fpointeur =~ s/^\Q$spointeur\E/\./) {
				my %hash = ();
				if (scalar (@spointeur)>1) {
					my $hash = $spointeur[1];
					%hash = %$hash;
				}
				if (scalar(@fpointeur)>1) {
					@fpointeur = ($fpointeur,$fpointeur[1]);
				}
				else {
					@fpointeur = ($fpointeur);
				}
				$hash{$firstkey} = \@fpointeur;
				@spointeur = ($spointeur, \%hash);
				$tableauDepart->{$secondkey} = \@spointeur;
				delete ($tableauDepart->{$firstkey});
				$j = $keyssize;
			}
			else {
				$j++;
			}
		}
		$i++;
	}
	return $tableauDepart;
}

# Cette fonction transforme un tableau de pointeurs CDM en arbre de pointeurs
# les pointeurs enfants sont des descendants de l'arbre XML. Ils sont également conservés 
# dans l'arbre de départ
sub arbre_cdm_complet {
	my $tableauDepart = $_[0];
#	print STDERR Dumper($tableauDepart);
	my @keys = reverse sort { $tableauDepart->{$a} cmp $tableauDepart->{$b} } keys %{ $tableauDepart };
#	print STDERR Dumper(\@keys);
	foreach my $key (keys %{ $tableauDepart }) {
		my $pointeur = $tableauDepart->{$key};
		my @feuille = ( $pointeur );
		$tableauDepart->{$key} = \@feuille;
	}	
	my $i=0;
	my $keyssize = scalar(@keys);
	foreach my $firstkey (@keys) {
#		print STDERR "FK: $firstkey\n";
		my $fpointeur = $tableauDepart->{$firstkey};
		my @fpointeur = @$fpointeur;
		$fpointeur = $fpointeur[0];
		my $j=$i+1;
		while ($j<$keyssize) {
			my $secondkey = $keys[$j];
#			print STDERR "$firstkey , $secondkey\n";
			my $spointeur = $tableauDepart->{$secondkey};
			my @spointeur = @$spointeur;
			$spointeur = $spointeur[0];
			if ($fpointeur =~ s/^\Q$spointeur\E(.)/\.$1/) {
#				print STDERR 'sp:',$spointeur, 'fp:',$fpointeur,"\n";
				my %hash = ();
				if (scalar (@spointeur)>1) {
					my $hash = $spointeur[1];
					%hash = %$hash;
				}
				if (scalar(@fpointeur)>1) {
					@fpointeur = ($fpointeur,$fpointeur[1]);
				}
				else {
					@fpointeur = ($fpointeur);
				}
				$hash{$firstkey} = \@fpointeur;
				@spointeur = ($spointeur, \%hash);
#				if ($secondkey eq 'cdm-example-block') { print STDERR "change eb\n";}
				$tableauDepart->{$secondkey} = \@spointeur;
 				$j = $keyssize;
			}
			else {
				$j++;
			}
		}
		$i++;
	}
	return $tableauDepart;
}
