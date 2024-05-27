=head1 NAME

EPrints::Plugin::Screen::EPrint::View::RIOXX3

=cut

package EPrints::Plugin::Screen::EPrint::RIOXX3;

our @ISA = ( 'EPrints::Plugin::Screen::EPrint' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{appears} = [
		{
			place => "eprint_view_tabs",
			position => 2501, #rioxx2 was 2500
		},
	];

	# NB I feel this should live in an EPrints::RIOXX3 or EPrints::Plugin::RIOXX3 module
	#
	# Retrieving XSD over HTTPS appears not to be supported by LibXML::Schema :(
	# A local copy ships with this plugin. 
	#$self->{schema_location} = "https://www.rioxx.net/schema/v3.0/rioxx/rioxx.xsd";
	$self->{schema_location} = $self->{repository}->config( "lib_path") . "/schema/rioxx3/rioxx.xsd";

	$self->{xsl_location} = $self->{repository}->config( "lib_path") . "/static/rioxx3.xsl";

	if( defined $self->{repository} && defined $self->{repository}->{plugins} )
        {
		$self->{export_plugin} = $self->{repository}->plugin( "Export::RIOXX3" );
        }

	return $self;
}

# As the RIOXX3 plugin doesn't allow 'polishing' of records, this
# could be viewable by anyone who can view the EPrint.
sub can_be_viewed
{
	my( $self ) = @_;

	return $self->allow( "eprint/view" );
}

# cache XML representation - re-use it when validating/processing 
sub get_exported_xml
{
	my( $self ) = @_;

	return $self->{exported_xml} if defined $self->{exported_xml};

	if( !defined $self->{export_plugin} || $self->{export_plugin}->broken )
	{
		return $self->html_phrase( "bad_export_plugin" );
	}
	$self->{exported_xml} = $self->{export_plugin}->xml_dataobj( $self->{processor}->{eprint} );

	return $self->{exported_xml};
}

sub render
{
	my( $self ) = @_;

	my $repo = $self->{repository};
	my $eprint = $self->{processor}->{eprint};

	my $page = $repo->make_element( "div", class => "rioxx3" );
	$page->appendChild( $self->html_phrase( "intro" ) );

	# THIS IS BROKEN - as the XSD isn't retrievable via https, and the LibXML validator doesn't understand v1.1 schema
	#if ( my $error = $self->validate_exported_xml_against_xsd ) {
	#	$page->appendChild( $self->html_phrase( "invalid_export", errors => $repo->make_text( $error ) ) );
	#}
	#else
	#{
	#	$page->appendChild( $self->html_phrase( "valid_export" ) );
	#}
	
	#TODO add title/explanation
	$page->appendChild( $self->render_xml_via_xslt );

	my $oai_p = $repo->make_element( "p", class => "rioxx3_oai" );
	$page->appendChild( $oai_p );

	if( !$eprint->is_set( "datestamp" ) )
	{
		# eprint never been live, won't be in OAI interface
		$oai_p->appendChild( $self->html_phrase( "no_oai_link" ) );
	}
	else
	{
		my $oai_id = EPrints::OpenArchives::to_oai_identifier(
			EPrints::OpenArchives::archive_id( $repo ),
			$eprint->get_id
		);
		my $oai_uri = URI->new( $repo->config( "oai", "v2", "base_url" ) );
		$oai_uri->query_form(
			verb            => "GetRecord",
			#TODO turn this into a plugin param $self->{metadataPrefix} or $self->plugin->{metadataPrefix}?
			metadataPrefix  => "rioxx3",
			identifier      => $oai_id,
		);
		my $link = $repo->render_link( $oai_uri, target => "_blank" );

		$oai_p->appendChild( $self->html_phrase( "oai_link", link => $link ) );
	}
	
	$page->appendChild( $self->html_phrase( "export", link => $self->render_export_link ) );

	my $box_id = "rioxx3_xml";
	$page->appendChild( EPrints::Box::render(
                id => $box_id,
                session => $repo,
                title => $self->html_phrase( $box_id ),
                content => $self->render_xml,
                collapsed => "true",
        ) );

	return $page;
}

sub render_export_link
{
	my( $self ) = @_;

	my $repo = $self->{repository};
	my $plugin = $repo->plugin( "Export::RIOXX3" );

	my $link = $repo->render_link( $plugin->dataobj_export_url( $self->{processor}->{eprint} ), target => "_blank" );

	return $self->html_phrase( "export_link", link => $link );
}


sub render_xml
{
	my( $self ) = @_;
	
	my $repo = $self->{repository};
	my $frag = $repo->make_doc_fragment;

	# set overflow, because first line with XSD declarations is a bit long
	#TODO if we include an auto css for RIOXX3, add below style to calsss defintion
	my $pre = $repo->make_element( "pre", class => "rioxx3", style=>"overflow-x:scroll" );
	
	$frag->appendChild( $pre );
	$pre->appendChild( $repo->make_text( $repo->xml->to_string( $self->get_exported_xml, indent => 1 ) ) );

	return $frag;
}

sub render_xml_via_xslt
{
	my( $self ) = @_;

	# could check $EPrints::XSLT global ?
	eval "use XML::LibXSLT";
	if( $@ )
	{
		return $self->phrase( "no_libxslt" );
	}

	my $xslt = XML::LibXSLT->new();
	if( ! -f $self->{xsl_location} )
	{
		return $self->html_phrase( "no_xsl", path => $self->{repository}->make_text( $self->{xsl_location} ) );
	}

	my $style_doc = XML::LibXML->load_xml( location => $self->{xsl_location}, no_cdata=>1 );
	my $stylesheet = $xslt->parse_stylesheet($style_doc);
	my $xml = $self->get_exported_xml;

        my $result = $stylesheet->transform($xml); #returns a LibXML doc

	# Need to do this to avoid a segfault
	my $node = $result->documentElement->cloneNode( 1 ); #deep

	# also doing these, just in case...
	$stylesheet = undef;
	$xslt = undef;
	$result = undef;

	return $node;
}

# This doesn't work for a couple of reasons:
# - schema location is https (only) and LibXML::Schema can't access it.
# - (using a local version of XSD) libxml2 doesn't support XMLSchema v1.1
#
# This sub has been left as an aide-memoir, but currently isn't called.
# It could offload validation to e.g. a Python validator
sub validate_exported_xml_against_xsd
{
	my( $self ) = @_;

	my $schema = XML::LibXML::Schema->new( location => $self->{schema_location} );

	eval {
		$schema->validate( $self->get_exported_xml, no_network => 0 );
	};
	if ( my $err = $@ ) {
		return $err;
	}

	return;
}

1;
