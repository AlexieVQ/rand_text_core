#!/usr/bin/env ruby

require 'test/unit'
require_relative '../lib/rand_text_core'

class TestRandTextCore < Test::Unit::TestCase

	def test_files_no_slash
		path = 'dir1'
		files = ['table1.csv', 'table2.csv'].map { |f| path + '/' + f }.sort
		core = RandTextCore.new(path)
		assert_equal(core.files.sort, files)
	end

	def test_files_slash
		path = 'dir1/'
		files = ['table1.csv', 'table2.csv'].map { |f| path + f }.sort
		core = RandTextCore.new(path)
		assert_equal(core.files.sort, files)
	end

	def test_path_type
		assert_raise(TypeError) { RandTextCore.new(3) }
	end

end