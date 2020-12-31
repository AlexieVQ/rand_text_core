#!/usr/bin/env ruby

require 'simplecov'
SimpleCov.start

require 'test/unit'
require_relative '../lib/rand_text_core/rule_variant'

class TestRuleVariant < Test::Unit::TestCase

	TEST_DIR = 'test/dir1/'
	INVALID_DIR = 'test/invalid_dir/'

	def setup
		@simple_rule = Class.new(RandTextCore::RuleVariant) do
			file_path TEST_DIR + 'simple_rule.csv'
		end
		@weighted_rule = Class.new(RandTextCore::RuleVariant) do
			file_path TEST_DIR + 'weighted_rule.csv'
		end
		@optional_references = Class.new(RandTextCore::RuleVariant) do
			file_path TEST_DIR + 'optional_references.csv'
			reference :simple_rule, :simple_rule
		end
		@required_references = Class.new(RandTextCore::RuleVariant) do
			file_path TEST_DIR + 'required_references.csv'
			reference :simple_rule, :simple_rule
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

	def test_rule_variant_class_calls
		assert_raise(RuntimeError) { RandTextCore::RuleVariant.rule_name }
		assert_raise(RuntimeError) { RandTextCore::RuleVariant.picker_name }
		assert_raise(RuntimeError) { RandTextCore::RuleVariant.file }
		assert_raise(RuntimeError) do 
			RandTextCore::RuleVariant.file_path(TEST_DIR + 'simple_rule.csv')
		end
		assert_raise(RuntimeError) do
			RandTextCore::RuleVariant.reference(:simple_rule, :simple_rule)
		end
		assert_raise(RuntimeError) { RandTextCore::RuleVariant.references }
		assert_raise(RuntimeError) do
			RandTextCore::RuleVariant.send(:attr_types)
		end
		assert_raise(RuntimeError) { RandTextCore::RuleVariant.each }
	end

	def test_rule_name
		assert_equal(:simple_rule, @simple_rule.rule_name)
		assert_equal(:weighted_rule, @weighted_rule.rule_name)
		assert_equal(:optional_references, @optional_references.rule_name)
		assert_equal(:required_references, @required_references.rule_name)
	end

	def test_picker_name
		assert_equal(:SimpleRule, @simple_rule.picker_name)
		assert_equal(:WeightedRule, @weighted_rule.picker_name)
		assert_equal(:OptionalReferences, @optional_references.picker_name)
		assert_equal(:RequiredReferences, @required_references.picker_name)
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

	def test_unset_file_path
			klass = Class.new(RandTextCore::RuleVariant)
		assert_raise(RuntimeError) { klass.file }
		assert_raise(RuntimeError) { klass.rule_name }
		assert_raise(RuntimeError) { klass.picker_name }
	end

	def test_reset_file_path
		assert_raise(RuntimeError) do
			@simple_rule.file_path(TEST_DIR + 'weighted_rule.csv')
		end
	end

	def test_wrong_argument_type
		assert_raise(TypeError) do
			Class.new(RandTextCore::RuleVariant) do
				file_path 3
			end
		end
		assert_raise(TypeError) do
			Class.new(RandTextCore::RuleVariant) do
				file_path TEST_DIR + 'required_references.csv'
				reference 4, :simple_rule
			end
		end
		assert_raise(TypeError) do
			Class.new(RandTextCore::RuleVariant) do
				file_path TEST_DIR + 'required_references.csv'
				reference :simple_rule, 5
			end
		end
		assert_raise(TypeError) do
			@simple_rule.send(:import)
			@simple_rule[:key]
		end
		assert_raise(TypeError) do
			@weighted_rule.send(:rules=, @rules_dir1)
			@weighted_rule.send(:import)
			@weighted_rule.rule(3)
		end
		assert_raise(TypeError) do
			@required_references.send(:rules=, @rules_dir1)
			@required_references.send(:import)
			@required_references[1].rule(4)
		end
	end

	def test_references
		assert_equal({}, @simple_rule.references)
		assert_equal({}, @weighted_rule.references)
		assert_equal(
			{ simple_rule: :simple_rule },
			@required_references.references
		)
		assert_equal(
			{ simple_rule: :simple_rule },
			@optional_references.references
		)
	end

	def test_attr_types
		@simple_rule.send(:attr_types=, [:id, :value])
		assert_equal(
			{ id: :id, value: :string },
			@simple_rule.send(:attr_types)
		)
		@weighted_rule.send(:attr_types=, [:id, :value, :weight])
		assert_equal(
			{ id: :id, value: :string, weight: :weight },
			@weighted_rule.send(:attr_types)
		)
		@optional_references.send(:attr_types=, [:id, :value, :simple_rule])
		assert_equal(
			{ id: :id, value: :string, simple_rule: :reference },
			@optional_references.send(:attr_types)
		)
		@required_references.send(:attr_types=, [:id, :value, :simple_rule])
		assert_equal(
			{ id: :id, value: :string, simple_rule: :reference },
			@required_references.send(:attr_types)
		)
	end

	def test_unset_attr_types
		assert_raise(RuntimeError) { @simple_rule.send(:attr_types) }
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

	def test_unitialized_each
		assert_raise(RuntimeError) { @simple_rule.each }
	end

	def test_rules
		@rules_dir1.each { |rule| rule.send(:rules=, @rules_dir1 ) }
		@rules_dir1.each do |rule|
			assert_equal(@simple_rule, rule.rule(:simple_rule))
			assert_equal(@weighted_rule, rule.rule(:weighted_rule))
			assert_equal(@optional_references, rule.rule(:optional_references))
			assert_equal(@required_references, rule.rule(:required_references))
		end
		@simple_rule.send(:import)
		@simple_rule.each do |variant|
			assert_equal(@simple_rule, variant.rule(:simple_rule))
			assert_equal(@weighted_rule, variant.rule(:weighted_rule))
			assert_equal(
				@optional_references,
				variant.rule(:optional_references)
			)
			assert_equal(
				@required_references,
				variant.rule(:required_references)
			)
		end
	end

	def test_no_id
		no_id = Class.new(RandTextCore::RuleVariant) do
			file_path INVALID_DIR + 'no_id.csv'
		end
		assert_raise(RuntimeError) { no_id.send(:import) }
	end

	def test_duplicated_id
		duplicated_id = Class.new(RandTextCore::RuleVariant) do
			file_path INVALID_DIR + 'duplicated_id.csv'
		end
		assert_raise(RuntimeError) { duplicated_id.send(:import) }
	end

	def test_unexisting_rule
		@simple_rule.send(:rules=, @rules_dir1)
		@simple_rule.send(:import)
		assert_raise(ArgumentError) { @simple_rule.rule(:complex_rule) }
	end

	def test_identical_attributes
		identical_attributes = Class.new(RandTextCore::RuleVariant) do
			file_path INVALID_DIR + 'identical_attributes.csv'
		end
		assert_raise { identical_attributes.send(:import) }
	end

	def test_null_id
		null_id = Class.new(RandTextCore::RuleVariant) do
			file_path INVALID_DIR + 'null_id.csv'
		end
		assert_raise(ArgumentError) { null_id.send(:import) }
	end

	def test_too_few_fields
		too_few_fields = Class.new(RandTextCore::RuleVariant) do
			file_path INVALID_DIR + 'too_few_fields.csv'
		end
		assert_raise(ArgumentError) { too_few_fields.send(:import) }
	end

	def test_too_much_fields
		too_much_fields = Class.new(RandTextCore::RuleVariant) do
			file_path INVALID_DIR + 'too_much_fields.csv'
		end
		assert_raise(ArgumentError) { too_much_fields.send(:import) }
	end

	######################
	# TESTS ON INSTANCES #
	######################

	def test_attributes
		@simple_rule.send(:rules=, @rules_dir1)
		@simple_rule.send(:import)
		@simple_rule.each do |variant|
			assert_respond_to(variant, :id)
			assert_respond_to(variant, :value)
			assert_respond_to(variant, :weight)
		end
		@weighted_rule.send(:rules=, @rules_dir1)
		@weighted_rule.send(:import)
		@weighted_rule.each do |variant|
			assert_respond_to(variant, :id)
			assert_respond_to(variant, :value)
			assert_respond_to(variant, :weight)
		end
		@required_references.send(:rules=, @rules_dir1)
		@required_references.send(:import)
		@required_references.each do |variant|
			assert_respond_to(variant, :id)
			assert_respond_to(variant, :value)
			assert_respond_to(variant, :weight)
			assert_respond_to(variant, :simple_rule)
		end
	end

	def test_reference_attributes
		@required_references.send(:rules=, @rules_dir1)
		@required_references.send(:import)
		@simple_rule.send(:rules=, @rules_dir1)
		@simple_rule.send(:import)
		assert_same(@simple_rule[2], @required_references[1].simple_rule)
	end

	def test_inspect
		@simple_rule.send(:import)
		assert_equal(
			'#<simple_rule id=1, value="a">',
			@simple_rule[1].inspect
		)
	end

end