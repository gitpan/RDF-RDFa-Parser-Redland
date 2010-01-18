package RDF::RDFa::Parser::Redland;

use 5.008001;
use strict;
use RDF::Redland;
use RDF::RDFa::Parser '0.30';
our @ISA = qw(RDF::RDFa::Parser);
our $VERSION = '0.30';

sub new
{
	my $class = shift;
	my $xhtml = shift;
	my $base  = shift;
	my $opts  = shift;
	my $model = shift;
	
	my $self  = $class->SUPER::new($xhtml, $base, $opts);
	
	if (!UNIVERSAL::isa($model, 'RDF::Redland::Model'))
	{
		my $store = RDF::Redland::Storage->new(
			"hashes", "test", "new='yes',hash-type='memory',contexts='yes'");
		$model = RDF::Redland::Model->new($store, "");
	}
	
	$self->{'redland'} = $model;
	$self->SUPER::set_callbacks({
		pretriple_resource => \&redland_triple_resource ,	
		pretriple_literal  => &redland_triple_literal ,
		});

	return $self;
}

sub set_callbacks
{
	my $this = shift;

	if ('HASH' eq ref $_[0])
	{
		$this->{'redland_sub'} = $_[0];
		$this->{'redland_sub'}->{'pretriple_resource'} = \&_print0
			if lc $this->{'redland_sub'}->{'pretriple_resource'}  eq 'print';
		$this->{'redland_sub'}->{'pretriple_literal'} = \&_print1
			if lc $this->{'redland_sub'}->{'pretriple_literal'}  eq 'print';
	}
	else
	{
		if (lc($_[0]) eq 'print')
			{ $this->{'redland_sub'}->{'pretriple_resource'} = \&_print0; }
		elsif ('CODE' eq ref $_[0])
			{ $this->{'redland_sub'}->{'pretriple_resource'} = $_[0]; }
		else
			{ $this->{'redland_sub'}->{'pretriple_resource'} = undef; }

		if (lc($_[1]) eq 'print')
			{ $this->{'redland_sub'}->{'pretriple_literal'} = \&_print1; }
		elsif ('CODE' eq ref $_[1])
			{ $this->{'redland_sub'}->{'pretriple_literal'} = $_[1]; }
		else
			{ $this->{'redland_sub'}->{'pretriple_literal'} = undef; }
	}
	
	return $this;
}

sub redland_triple_common
{
	my $self      = shift;
	my $element   = shift;  # A reference to the XML::LibXML element being parsed
	my $subject   = shift;  # Subject URI or bnode
	my $predicate = shift;  # Predicate URI
	my $ro        = shift;  # Redland Object
	my $graph     = shift;  # Graph URI or bnode (if named graphs feature is enabled)
	
	my ($rs, $rp, $rg);
	
	$rs = ($subject =~ /^_:(.*)$/) 
		? RDF::Redland::BlankNode->new($1)
		: RDF::Redland::URINode->new($subject);
		
	$rp = ($predicate =~ /^_:(.*)$/) 
		? RDF::Redland::BlankNode->new($1)
		: RDF::Redland::URINode->new($predicate);
	
	my $rst = RDF::Redland::Statement->new($rs, $rp, $ro);

	my $suppress_triple = 0;
	$suppress_triple = $self->{'redland_sub'}->{'ontriple'}($self, $element, $rst)
		if ($self->{'redland_sub'}->{'ontriple'});
	return if $suppress_triple;

	if ($graph)
	{
		$rg = ($graph =~ /^_:(.*)$/) 
			? RDF::Redland::BlankNode->new($1)
			: RDF::Redland::URINode->new($graph);
		$self->{'redland'}->add_statement($rst, $rg);
	}
	else
	{
		$self->{'redland'}->add_statement($rst);
	}
		
	return 1; # Suppress triple from RDF::Trine::Model.
}

sub redland_triple_resource
{
	my $self      = shift;
	
	# Callback subroutine
	my $suppress_triple = 0;
	$suppress_triple = $self->{'redland_sub'}->{'pretriple_resource'}($self, @_)
		if defined $self->{'redland_sub'}->{'pretriple_resource'};
	return if $suppress_triple;
	
	my $element   = shift;  # A reference to the XML::LibXML element being parsed
	my $subject   = shift;  # Subject URI or bnode
	my $predicate = shift;  # Predicate URI
	my $object    = shift;  # Resource URI or bnode
	my $graph     = shift;  # Graph URI or bnode (if named graphs feature is enabled)

	my $ro = ($object =~ /^_:(.*)$/) 
		? RDF::Redland::BlankNode->new($1)
		: RDF::Redland::URINode->new($object);

	return $self->redland_triple_common($element, $subject, $predicate, $ro, $graph);
}

sub redland_triple_literal
{
	my $self      = shift;

	# Callback subroutine
	my $suppress_triple = 0;
	$suppress_triple = $self->{'redland_sub'}->{'pretriple_literal'}($self, @_)
		if defined $self->{'redland_sub'}->{'pretriple_literal'};
	return if $suppress_triple;
	
	my $element   = shift;  # A reference to the XML::LibXML element being parsed
	my $subject   = shift;  # Subject URI or bnode
	my $predicate = shift;  # Predicate URI
	my $object    = shift;  # Resource Literal
	my $datatype  = shift;  # Datatype URI (possibly undef or '')
	my $language  = shift;  # Language (possibly undef or '')
	my $graph     = shift;  # Graph URI or bnode (if named graphs feature is enabled)

	my $ro;
	if ($datatype)
	{
		$ro = RDF::Redland::LiteralNode->new($object, $datatype, undef);
	}
	else
	{
		$ro = RDF::Redland::LiteralNode->new($object, undef, $language);
	}

	return $self->redland_triple_common($element, $subject, $predicate, $ro, $graph);
}

sub graph
{
	my $self  = shift;
	my $graph = shift;
	
	return $self->{'redland'}
		unless defined $graph;

	my $rg = ($graph =~ /^_:(.*)$/) 
			? RDF::Redland::BlankNode->new($1)
			: RDF::Redland::URINode->new($graph);
	my $store  = RDF::Redland::Storage->new(
		"hashes", "test", "new='yes',hash-type='memory'");
	my $model  = RDF::Redland::Model->new($store, '');
	my $sttmpl = RDF::Redland::Statement->new(undef, undef, undef);
	my $stream = $self->{'redland'}->find_statements($sttmpl, $rg);
	$model->add_statements($stream);
	return $model;
}

sub graphs
{
	my $self = shift;
	
	my $rv = {};
	my @contexts = $self->{'redland'}->contexts;
	foreach my $c (@contexts)
	{		
		my $g = $c->is_resource ?
			$c->uri->as_string :
			('_:'.$c->blank_identifier) ;
		$rv->{$g} = $self->graph($g);
	}
	
	return $rv;
}

1;
__END__

=head1 NAME

RDF::RDFa::Parser::Redland - Parses RDFa into a RDF::Redland::Model.

=head1 VERSION

0.30

=head1 SYNOPSIS

  use LWP::Simple qw(get);
  use RDF::RDFa::Parser::Redland;
  
  my $uri    = 'http://example.com/rdfa-enabled-page.xhtml';
  my $parser = RDF::RDFa::Parser::Redland->new(get($uri), $uri);
  $parser->consume;
  my $model  = $parser->graph;
  
=head1 DESCRIPTION

This module extends RDF::RDFa::Parser to be able to output an
RDF::Redland::Model.

The C<graph> method will return a Redland model instead of the
RDF::Trine::Model that C<RDF::RDFa::Parser::graph> returns.

Other than that it should have an identical API to RDF::RDFa::Parser.

=head1 BUGS

RDF::RDFa::Parser::Redland 0.21 passes all approved tests in the W3C's
XHTML+RDFa test suite.

There seem to be one or two problems using the named graphs feature,
but I've not had a chance to discover if the problems are in this package
or in RDF::Redland (probably the former). The named graphs feature is
only useful in a very small set of cases, and is disabled by default.

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<RDF::RDFa::Parser>, L<RDF::Redland>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster, E<lt>tobyink@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
