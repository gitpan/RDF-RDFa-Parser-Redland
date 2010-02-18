use Test::More tests => 8;
BEGIN { use_ok('RDF::RDFa::Parser::Redland') };


my $xhtml = <<EOF;
<html xmlns:dc="http://purl.org/dc/terms/" xmlns:foaf="http://xmlns.com/foaf/0.1/" xml:lang="en" g:graph="#DEFAULT" xmlns:g="http://example.com/graphing">
	<head>
		<title property="dc:title">This is the title</title>
	</head>
	<body xmlns:dc="http://purl.org/dc/elements/1.1/">
		<div rel="foaf:primaryTopic" rev="foaf:page" xml:lang="de">
			<h1 about="#topic" typeof="foaf:Person" property="foaf:name">Albert Einstein</h1>
		</div>
		<address rel="foaf:maker dc:creator" rev="foaf:made">
			<a g:graph="#JOE" about="#maker" property="foaf:name" rel="foaf:homepage" href="joe">Joe Bloggs</a>
		</address>
	</body>
</html>
EOF
$parser = RDF::RDFa::Parser::Redland->new($xhtml, 'http://example.com/einstein',
	{ graph_attr=>'{http://example.com/graphing}graph' , graph=>1 , graph_type=>'about' } );

ok($parser->consume, "Parse OK");

ok(my $graphs = $parser->graphs, "Graphs retrieved");

ok(defined $graphs->{'http://example.com/einstein#DEFAULT'}, "Expected graph is present");
ok(defined $graphs->{'http://example.com/einstein#JOE'}, "Another expected graph is present");

my ($q, $qr);

$q  = 'ASK WHERE { <http://example.com/einstein#topic> a <http://xmlns.com/foaf/0.1/Person> }';

$qr = $graphs->{'http://example.com/einstein#DEFAULT'}->query_execute(RDF::Redland::Query->new($q, undef, undef, 'sparql'));
ok($qr->get_boolean, "Graph contains a triple that should be there.");

$qr = $graphs->{'http://example.com/einstein#JOE'}->query_execute(RDF::Redland::Query->new($q, undef, undef, 'sparql'));
ok(!$qr->get_boolean, "Other graph does not contain a triple that shouldn't be there.");

SKIP: {
	skip "This doesn't work??", 1;
	ok($parser->graph->contains_statement(
			RDF::Redland::Statement->new(
				RDF::Redland::URINode->new('http://example.com/einstein#topic'),
				RDF::Redland::URINode->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
				RDF::Redland::URINode->new('http://xmlns.com/foaf/0.1/Person')
			)
		), "Default graph working.");
}
