use Test::More tests => 5;
BEGIN { use_ok('RDF::RDFa::Parser::Redland') };

use RDF::Redland;
use RDF::RDFa::Parser::Redland;

my $xhtml = <<EOF;
<html xmlns:foaf="http://xmlns.com/foaf/0.1/">
	<body xmlns:dc="http://purl.org/dc/elements/1.1/">
		<div rel="foaf:primaryTopic" rev="foaf:page">
			<h1 about="#topic" typeof="foaf:Person" property="foaf:name" 
                datatype="http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral"><strong>Albert Einstein</strong></h1>
		</div>
	</body>
</html>
EOF
$parser = RDF::RDFa::Parser::Redland->new($xhtml, 'http://example.com/einstein');

ok(lc($parser->dom->documentElement->tagName) eq 'html', 'DOM Tree returned OK.');

ok($parser->consume, "Parse OK");

ok(my $model = $parser->redland, "Model retrieved");

my $q  = 'ASK WHERE { <http://example.com/einstein#topic> a <http://xmlns.com/foaf/0.1/Person> }';
my $qr = $model->query_execute(RDF::Redland::Query->new($q, undef, undef, 'sparql'));

ok($qr->get_boolean, "Model seems to be working.");
