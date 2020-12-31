#!/usr/bin/env ruby

require 'simplecov'
SimpleCov.start

require 'test/unit'
require_relative '../lib/rand_text_core/refinements/string'

class TestString < Test::Unit::TestCase

	using RandTextCore::Refinements

	def test_lower_snake_case
		assert_true('abc'.lower_snake_case?)
		assert_true('abc_def'.lower_snake_case?)
		assert_true('abc1_def2'.lower_snake_case?)
		assert_false('_abc_def'.lower_snake_case?)
		assert_false('1abc_2def'.lower_snake_case?)
		assert_false(''.lower_snake_case?)
		assert_false('AbcDef'.lower_snake_case?)
	end

	def test_upper_camel_case
		assert_true('Abc'.upper_camel_case?)
		assert_true('AbcDef'.upper_camel_case?)
		assert_true('Abc1Def2'.upper_camel_case?)
		assert_false(' AbcDef'.upper_camel_case?)
		assert_false('1Abc2Def'.upper_camel_case?)
		assert_false(''.upper_camel_case?)
		assert_false('abc_def'.upper_camel_case?)
		assert_false('abc'.upper_camel_case?)
	end

	def test_camelize
		assert_equal('Abc', 'abc'.camelize)
		assert_equal('AbcDef', 'abc_def'.camelize)
		assert_equal('Abc1Def2', 'abc1_def2'.camelize)
		assert_equal('AbcDef', 'abc__def'.camelize)
		assert_raise(RuntimeError) { '_abc_def'.camelize }
		assert_raise(RuntimeError) { '1abc_2def'.camelize }
		assert_raise(RuntimeError) { ''.camelize }
		assert_raise(RuntimeError) { 'AbcDef'.camelize }
	end

	def test_valid_csv_file
		assert_true('abc.csv'.valid_csv_file_name?)
		assert_true('abc_def.csv'.valid_csv_file_name?)
		assert_true('abc1_def2.csv'.valid_csv_file_name?)
		assert_true('abc__def.csv'.valid_csv_file_name?)
		assert_false('abc_def.csv.bak'.valid_csv_file_name?)
		assert_false('abc_def'.valid_csv_file_name?)
		assert_false('.csv'.valid_csv_file_name?)
		assert_false('abc_def.txt'.valid_csv_file_name?)
		assert_false('Abc_Def.csv'.valid_csv_file_name?)
	end

end