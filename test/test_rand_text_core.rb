#!/usr/bin/env ruby

require 'simplecov'
SimpleCov.start

require 'test/unit'
require_relative '../lib/rand_text_core'

class TestRandTextCore < Test::Unit::TestCase

	FILES = [
		'optional_references.csv',
		'required_references.csv',
		'simple_entities.csv',
		'weighted_entities.csv'
	]

	def test_files_no_slash
		path = 'test/dir1'
		files = FILES.map { |f| path + '/' + f }.sort
		core = RandTextCore.new(path)
		assert_equal(files, core.files.sort)
	end

	def test_files_slash
		path = 'test/dir1/'
		files = FILES.map { |f| path + f }.sort
		core = RandTextCore.new(path)
		assert_equal(files, core.files.sort)
	end

	def test_path_type
		assert_raise(TypeError) { RandTextCore.new(3) }
	end

end