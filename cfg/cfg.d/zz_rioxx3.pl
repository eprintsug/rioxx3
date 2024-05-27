$c->{plugins}{'Export::RIOXX3'}{params}{disable} = 0;
$c->{plugins}{'Screen::EPrint::RIOXX3'}{params}{disable} = 0;

$c->{rioxx3}->{export_mappings} = {
    "rioxxterms:contributor" => "contributor_value",
    "dc:identifier" => "identifier",
    "dc:relation" => "relation",
    "dc:title" => "title",
};

$c->{rioxx3}->{mandatory_fields} = [qw(
    dc:identifier
    dc:type
    dc:title
    dc:language
    rioxxterms:creator
)];

$c->{rioxx3}->{"identifier"} = sub{
    my( $repo, $eprint ) = @_;

    my $frag = $repo->make_doc_fragment;
    my $element = $repo->make_element( "dc:identifier" );
    $element->appendChild( $repo->make_text( $eprint->url ) );
    $frag->appendChild( $element );

    return $frag;
};

$c->{rioxx3}->{"contributor_value"} = sub{
    my( $repo, $eprint ) = @_;

    my $frag = $repo->make_doc_fragment;
    my $element = $repo->make_element( "rioxxterms:contributor" );
    $element->appendChild( $repo->make_text( "hello there" ) );
    $frag->appendChild( $element );

    return $frag;
}
