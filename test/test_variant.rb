#!/usr/bin/env ruby

require 'simplecov'
SimpleCov.start

require 'test/unit'
require_relative '../lib/rand_text_core/variant'

class TestVariant < Test::Unit::TestCase

	TEST_DIR = 'test/dir1/'

	def setup
		@simple_rule = Class.new(RandTextCore::Variant) do
			file_path TEST_DIR + 'simple_rule.csv'
		end
		@weighted_rule = Class.new(RandTextCore::Variant) do
			file_path TEST_DIR + 'weighted_rule.csv'
		end
		@optional_references = Class.new(RandTextCore::Variant) do
			file_path TEST_DIR + 'optional_references.csv'
			reference 'simple_rule', 'simple_rule'
		end
		@required_references = Class.new(RandTextCore::Variant) do
			file_path TEST_DIR + 'required_references.csv'
			reference 'simple_rule', 'simple_rule'
		end
		@rules_dir1 = [
			@simple_rule,
			@weighted_rule,
			@optional_references,
			@required_references
		]
	end

	##################
	# TESTS ON CLASS #
	##################

	def test_variant_class_calls
		assert_raise(RuntimeError) { RandTextCore::Variant.rule_name }
		assert_raise(RuntimeError) { RandTextCore::Variant.picker_name }
		assert_raise(RuntimeError) { RandTextCore::Variant.file }
		assert_raise(RuntimeError) do 
			RandTextCore::Variant.file_path(TEST_DIR + 'simple_rule.csv')
		end
		assert_raise(RuntimeError) do
			RandTextCore::Variant.reference('simple_rule', 'simple_rule')
		end
		assert_raise(RuntimeError) { RandTextCore::Variant.references }
		assert_raise(RuntimeError) { RandTextCore::Variant.send(:attr_types) }
		assert_raise(RuntimeError) { RandTextCore::Variant.each }
	end

	def test_rule_name
		assert_equal('simple_rule', @simple_rule.rule_name)
		assert_equal('weighted_rule', @weighted_rule.rule_name)
		assert_equal('optional_references', @optional_references.rule_name)
		assert_equal('required_references', @required_references.rule_name)
	end

	def test_picker_name
		assert_equal('SimpleRule', @simple_rule.picker_name)
		assert_equal('WeightedRule', @weighted_rule.picker_name)
		assert_equal('OptionalReferences', @optional_references.picker_name)
		assert_equal('RequiredReferences', @required_references.picker_name)
	end

	def test_file_name
		assert_equal(TEST_DIR + 'simple_rule.csv', @simple_rule.file)
		assert_equal(TEST_DIR + 'weighted_rule.csv', @weighted_rule.file)
		assert_equal(
			TEST_DIR + 'optional_references.csv',
			@optional_references.file
		)
		assert_equal(
			TEST_DIR + 'required_references.csv',
			@required_references.file
		)
	end

	def test_references
		assert_equal({}, @simple_rule.references)
		assert_equal({}, @weighted_rule.references)
		assert_equal(
			{ 'simple_rule' => 'simple_rule' },
			@required_references.references
		)
		assert_equal(
			{ 'simple_rule' => 'simple_rule' },
			@optional_references.references
		)
	end

	def test_attr_types
		@simple_rule.send(:attr_types=, ['id', 'value'])
		assert_equal(
			{ 'id' => :id, 'value' => :string },
			@simple_rule.send(:attr_types)
		)
		@weighted_rule.send(:attr_types=, ['id', 'value', 'weight'])
		assert_equal(
			{ 'id' => :id, 'value' => :string, 'weight' => :weight },
			@weighted_rule.send(:attr_types)
		)
		@optional_references.send(:attr_types=, ['id', 'value', 'simple_rule'])
		assert_equal(
			{ 'id' => :id, 'value' => :string, 'simple_rule' => :reference },
			@optional_references.send(:attr_types)
		)
		@required_references.send(:attr_types=, ['id', 'value', 'simple_rule'])
		assert_equal(
			{ 'id' => :id, 'value' => :string, 'simple_rule' => :reference },
			@required_references.send(:attr_types)
		)
	end

	def test_import
		@simple_rule.send(:import)
		@weighted_rule.send(:import)
		# @optional_references.send(:import)
		@required_references.send(:import)
	end

	def test_get
		@simple_rule.send(:import)
		assert_equal(1, @simple_rule[1].id)
	end

	def test_each_no_block
		@simple_rule.send(:import)
		assert_kind_of(Enumerator, @simple_rule.each)
	end

	def test_each_block
		i = 0
		@simple_rule.send(:import)
		@simple_rule.each { |v| i += 1 }
		assert_equal(4, i)
	end

	def test_rules
		@rules_dir1.each { |rule| rule.send(:rules=, @rules_dir1 ) }
		@rules_dir1.each do |rule|
			assert_equal(@simple_rule, rule.rule('simple_rule'))
			assert_equal(@weighted_rule, rule.rule('weighted_rule'))
			assert_equal(@optional_references, rule.rule('optional_references'))
			assert_equal(@required_references, rule.rule('required_references'))
		end
	end

end