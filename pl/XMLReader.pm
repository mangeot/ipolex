###
### Event handler package XMLReader
###
package XMLReader;

#
# initialization
#
sub new {
    my $type = shift;
    return bless {}, $type;
}

#
# On receiving an start-of-element event, print the XML opening tag
# and the element attributes, passed as a hash reference argument
sub start_element {
    my( $self, $properties ) = @_;
    # note: as the attributes are received as a hashref, the order of
    # attributes in the input file is lost.

    print "<" . $properties->{'Name'};
    my %attributes = %{$properties->{'Attributes'}};
    foreach( keys( %attributes )) {
        print " $_=" . $attributes{$_} . "";
    }
    print ">";
}

#
# On receiving an end-of-element event, print the XML closing tag
#
sub end_element {
    my( $self, $properties) = @_;
    print "</" . $properties->{'Name'} . ">";
}

#
# On receiving text data, print them.
# Note that in order to generate valid XML, we must convert some characters
# into escape sequences: For instance, '<' must be converted into '&lt;'
#
sub characters {
    my( $self, $properties ) = @_;
    my $data = $properties->{'Data'};
    $data =~ s/&/&/;
    $data =~ s/</&lt;/;
    $data =~ s/>/&gt;/;
    print $data;
}

1;
