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
		'lib/rand_text_core/rtc_exception.rb',
		'lib/rand_text_core/symbol_exception.rb',
		'lib/rand_text_core/messages.rb',
		'lib/rand_text_core/data_types.rb',
		'lib/rand_text_core/data_types/integer_type.rb',
		'lib/rand_text_core/data_types/identifier.rb',
		'lib/rand_text_core/data_types/weight.rb',
		'lib/rand_text_core/data_types/reference.rb',
		'lib/rand_text_core/data_types/string_attribute.rb',
		'lib/rand_text_core/data_types/enum.rb'
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
		'test/test_refinements.rb',
		'test/test_symbol_table.rb',
		'test/test_rule_variant.rb'
	]
	s.add_runtime_dependency 'csv', '~> 3.1'
	s.add_development_dependency 'simplecov', '~> 0.21'
end
