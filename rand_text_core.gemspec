Gem::Specification.new do |s|
	s.name			= 'rand_text_core'
	s.version		= '0.0.0'
	s.license		= 'GPL-2.0-or-later'
	s.author		= 'AlexieVQ'
	s.files			= [
		'lib/rand_text_core.rb',
		'lib/rand_text_core/rule_variant.rb',
		'lib/rand_text_core/refinements.rb',
		'lib/rand_text_core/symbol_table.rb',
		'lib/rand_text_core/symbol_exception.rb'
	]
	s.summary		= 'Core for writing random text generators in Ruby.'
	s.description	= 'RandTextCore provides classes to create a random text
					   generator in Ruby using grammar rules stored in csv
					   files.'
	s.homepage		= 'https://github.com/AlexieVQ/rand_text_core'
	s.metadata		= {
		'source_code_uri' => 'https://github.com/AlexieVQ/rand_text_core'
	}
	s.test_files	= [
		'test/test_rand_text_core.rb',
		'test/test_rule_variant.rb',
		'test/test_string.rb',
		'test/test_symbol_table.rb'
	]
end