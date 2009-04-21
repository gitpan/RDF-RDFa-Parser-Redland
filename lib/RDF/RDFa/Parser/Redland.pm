package RDF::RDFa::Parser::Redland;

use 5.010000;
use strict;
use RDF::Redland;
use RDF::RDFa::Parser '0.11';
our @ISA = qw(RDF::RDFa::Parser);
our $VERSION = '0.02';

sub redland
{
	my $self  = shift;
	my $model = shift;
	
	unless ($model)
	{
		my $storage = RDF::Redland::Storage->new("hashes", "rdfa", "new='yes',hash-type='memory'");
		$model = RDF::Redland::Model->new($storage);
	}
	
	my $graph = $self->graph;
	
	return $model
		unless $graph;
		
	foreach my $subject (keys %$graph)
	{
		my $S = ($subject =~ /^_:(.+)$/) 
		      ? RDF::Redland::BlankNode->new($1)
		      : RDF::Redland::URINode->new($subject);
	
		foreach my $predicate (keys %{ $graph->{$subject} })
		{
			my $P = RDF::Redland::URINode->new($predicate);
	
			foreach my $object (@{ $graph->{$subject}->{$predicate} })
			{
				my $O;
				
				if ($object->{'type'} eq 'literal')
				{
					$O = RDF::Redland::LiteralNode->new(
						$object->{'value'},
						$object->{'datatype'},
						$object->{'lang'});

					$O = RDF::Redland::LiteralNode->new(
						$object->{'value'},
						undef,
						$object->{'lang'})
						unless $O;
				}
				else
				{
					$O = ($object->{'value'} =~ /^_:(.+)$/) 
					      ? RDF::Redland::BlankNode->new($1)
					      : RDF::Redland::URINode->new($object->{'value'});
				}
				
				$model->add($S, $P, $O);
			}
		}
	}

	return $model;
}

1;
__END__

=head1 NAME

RDF::RDFa::Parser::Redland - Parses RDFa into a RDF::Redland::Model.

=head1 SYNOPSIS

  use LWP::Simple qw(get);
  use RDF::RDFa::Parser::Redland;
  
  my $uri     = 'http://example.com/rdfa-enabled-page.xhtml';
  my $parser  = RDF::RDFa::Parser::Redland(get($uri), $uri);
  
  $parser->consume;
  my $model   = $parser->redland;
  
=head1 DESCRIPTION

This module extends RDF::RDFa::Parser to be able to output an
RDF::Redland::Model.

The C<redland> method will return a Redland model equivalent to the
C<graph> method that the usual RDF::RDFa::Parser has. (Indeed, the
C<graph> method is available in this module too.)

C<redland> can be passed a single optional parameter, consisting
of an existing Redland model which triples will be added to. If this
parameter is missing, then a new in-memory model will be created.

=head1 SEE ALSO

RDF::RDFa::Parser, RDF::RDFa::Parser::Trine, RDF::Redland.

=head1 AUTHOR

Toby Inkster, E<lt>mail@tobyinkster.co.ukE<gt>

=head1 COPYRIGHT AND LICENSE

 Copyright 2008, 2009 Toby Inkster

 This file is dual licensed under:
 The Artistic License
 GNU General Public License 3.0

 You may choose which of those two licences you are going to honour the
 terms of, but you cannot pick and choose the parts which you like of
 each. You must fulfil the licensing requirements of at least one of the
 two licenses.

 The Artistic License
 <http://www.perl.com/language/misc/Artistic.html>

 GNU General Public License 3.0
 <http://www.gnu.org/licenses/gpl-3.0.html>

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.

=cut
