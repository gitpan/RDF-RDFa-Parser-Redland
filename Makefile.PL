use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'RDF::RDFa::Parser::Redland',
    VERSION_FROM      => 'lib/RDF/RDFa/Parser/Redland.pm', # finds $VERSION
    PREREQ_PM         => {
		'RDF::RDFa::Parser' => '0.11',
		'RDF::Redland'      => 1,
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/RDF/RDFa/Parser/Redland.pm', # retrieve abstract from module
       AUTHOR         => 'Toby Inkster <mail@tobyinkster.co.uk>') : ()),
);
