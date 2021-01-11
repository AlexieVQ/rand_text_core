require_relative 'test_helper'
require_relative '../lib/rand_text_core'

class TestRandTextCore < Test::Unit::TestCase

	FILES = [
		'simple_rule.csv',
		'weighted_rule.csv',
		'simple_enum.csv',
		'multiple_enum.csv',
		'optional_reference.csv',
		'required_reference.csv',
	]

	def test_files_no_slash
		path = 'test/valid_dir1'
		files = FILES.map { |f| path + '/' + f }.sort
		core = RandTextCore.new(path)
		assert_equal(files, core.files.sort)
	end

	def test_files_slash
		path = 'test/valid_dir1/'
		files = FILES.map { |f| path + f }.sort
		core = RandTextCore.new(path)
		assert_equal(files, core.files.sort)
	end

	def test_path_type
		assert_raise(TypeError) { RandTextCore.new(3) }
	end

end
