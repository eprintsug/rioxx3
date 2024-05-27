package EPrints::Plugin::Export::RIOXX3;

use base qw( EPrints::Plugin::Export::XMLFile );

use strict;

sub new
{
	my ($class, %params) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{accept} = [qw( dataobj/eprint )];
	$self->{name} = 'RIOXX3 XML';
	$self->{metadataPrefix} = "rioxx3";
	$self->{xmlns} = "http://www.rioxx.net/schema/v3.0/rioxx/",
	$self->{schemaLocation} = "http://www.rioxx.net/schema/v3.0/rioxx/rioxx.xsd";

	return $self;
}

sub output_dataobj
{
	my ($self, $dataobj, %opts) = @_;

	my $r = "";
	my $f = $opts{fh} ? sub { print {$opts{fh}} @_ } : sub { $r .= $_[0] };

	&$f( <<HEAD );
<?xml version="1.0" encoding="UTF-8"?>
HEAD

	&$f($self->repository->xml->to_string(
		$self->xml_dataobj($dataobj),
		indent => 1,
	));

	return $r;
}

sub xml_dataobj
{
	my ($self, $eprint) = @_;

	my $repo = $self->repository;
	my $xml = $repo->xml;

	my $rioxx = $xml->create_element('rioxx',
		# 'xmlns' => $self->param('xmlns'), #NB example XML files don't set the default(?)
		'xmlns:dc' => "http://purl.org/dc/elements/1.1/",
		'xmlns:dcterms' => "http://purl.org/dc/terms/",
		'xmlns:rioxxterms' => "http://docs.rioxx.net/schema/v3.0/rioxxterms/",
		'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
		'xsi:schemaLocation' => $self->param('xmlns')." ".$self->param('schemaLocation'),
	);

	my @data;

    foreach my $rioxx3_field ( keys( %{$repo->config( "rioxx3", "export_mappings" )} ) )
    {
        my $rioxx3_export = $repo->config( "rioxx3", "export_mappings" )->{$rioxx3_field};
        my $element;

        if( $repo->can_call( "rioxx3", $rioxx3_export ) )
        {
            # call it
            $element = $repo->call( ["rioxx3", $rioxx3_export], $repo, $eprint );
        }
        elsif( $eprint->exists_and_set( $rioxx3_export ) )
        {
            $element = $repo->make_element( $rioxx3_field );
            $element->appendChild( $repo->make_text( $eprint->value( $rioxx3_export ) ) );
        }
        else
        {
             $repo->log( "Cannot find RIOXX3 mapping for $rioxx3_field: $rioxx3_export" );
        }

        $rioxx->appendChild(  $element ) if defined $element;
    }

    return $rioxx;

}

1;
