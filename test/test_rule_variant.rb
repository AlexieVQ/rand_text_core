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
			reference :simple_rule, :simple_rule, :optional
		end
		@required_references = Class.new(RandTextCore::RuleVariant) do
			file_path TEST_DIR + 'required_references.csv'
			reference :simple_rule, :simple_rule, :required
		end
		@enum_attribute = Class.new(RandTextCore::RuleVariant) do
			file_path TEST_DIR + 'enum_attribute.csv'
			enum :enum_attr, :value1, :value2, :value3
		end
		@rules_dir1 = [
			@simple_rule,
			@weighted_rule,
			@optional_references,
			@required_references
		]
	end

	###################################
	# TESTS ON ATTRIBUTE_TYPE CLASSES #
	###################################
	
	def test_attribute_type_singletons
		assert_kind_of(
			RandTextCore::RuleVariant::Identifier,
			RandTextCore::RuleVariant::Identifier.type
		)
		assert_kind_of(
			RandTextCore::RuleVariant::Weight,
			RandTextCore::RuleVariant::Weight.type
		)
		assert_kind_of(
			RandTextCore::RuleVariant::StringAttribute,
			RandTextCore::RuleVariant::StringAttribute.type
		)
	end

	def test_attribute_type_initializations
		required_reference = RandTextCore::RuleVariant::Reference[
			:my_rule,
			:required
		]
		assert_equal(:my_rule, required_reference.target)
		assert_equal(:required, required_reference.type)
		optional_reference = RandTextCore::RuleVariant::Reference[
			:my_rule,
			:optional
		]
		assert_equal(:my_rule, optional_reference.target)
		assert_equal(:optional, optional_reference.type)
		enum = RandTextCore::RuleVariant::Enum[
			:value2,
			:value1,
			:value3,
			:value1
		]
		assert_equal([
			:value1,
			:value2,
			:value3
		], enum.values)
	end

	def test_attribute_type_invalid_initializations
		assert_raise(TypeError) do
			RandTextCore::RuleVariant::Reference[84, :required]
		end
		assert_raise(ArgumentError) do
			RandTextCore::RuleVariant::Reference[:my_rule, :optimal]
		end
		assert_raise(TypeError) do
			RandTextCore::RuleVariant::Enum[10, 20, 30]
		end
	end

	def test_attribute_type_inspect
		assert_equal(
			'Identifier',
			RandTextCore::RuleVariant::Identifier.type.inspect
		)
		assert_equal(
			'Weight',
			RandTextCore::RuleVariant::Weight.type.inspect
		)
		assert_equal(
			'Reference<my_rule, optional>',
			RandTextCore::RuleVariant::Reference[:my_rule, :optional].inspect
		)
		assert_equal(
			'Enum<:value1, :value2, :value3>',
			RandTextCore::RuleVariant::Enum[:value1, :value2, :value3].inspect
		)
		assert_equal(
			'StringAttribute',
			RandTextCore::RuleVariant::StringAttribute.type.inspect
		)
	end

	def test_attribute_type_convert
		assert_equal(
			38,
			RandTextCore::RuleVariant::Identifier.type.convert('38 ')
		)
		assert_equal(
			5,
			RandTextCore::RuleVariant::Weight.type.convert(' 5')
		)
		assert_equal(
			0,
			RandTextCore::RuleVariant::Reference[
				:my_rule,
				:optional
			].convert('0')
		)
		assert_equal(
			5,
			RandTextCore::RuleVariant::Reference[
				:my_rule,
				:required
			].convert('5')
		)
		assert_equal(
			:value2,
			RandTextCore::RuleVariant::Enum[
				:value1,
				:value2,
				:value3
			].convert('value2')
		)
		assert_equal(
			'my string',
			RandTextCore::RuleVariant::StringAttribute.type.convert('my string')
		)
	end

	def test_attribute_type_invalid_convert
		assert_raise(ArgumentError) do
			RandTextCore::RuleVariant::Identifier.type.convert('0')
		end
		assert_raise(ArgumentError) do
			RandTextCore::RuleVariant::Reference[
				:my_rule,
				:required
			].convert('0')
		end
		assert_raise(ArgumentError) do
			RandTextCore::RuleVariant::Enum[
				:value1,
				:value2,
				:value3
			].convert('value4')
		end
		assert_raise(TypeError) do
			RandTextCore::RuleVariant::StringAttribute.type.convert(83)
		end
	end

	def test_attribute_type_equal
		assert_true(
			RandTextCore::RuleVariant::Identifier.type ==
			RandTextCore::RuleVariant::Identifier.type
		)
		assert_false(
			RandTextCore::RuleVariant::Identifier.type ==
			RandTextCore::RuleVariant::Weight.type
		)
		assert_true(
			RandTextCore::RuleVariant::Weight.type ==
			RandTextCore::RuleVariant::Weight.type
		)
		assert_true(
			RandTextCore::RuleVariant::Reference[:rule1, :optional] ==
			RandTextCore::RuleVariant::Reference[:rule1, :optional]
		)
		assert_false(
			RandTextCore::RuleVariant::Reference[:rule1, :optional] ==
			RandTextCore::RuleVariant::Reference[:rule2, :optional]
		)
		assert_false(
			RandTextCore::RuleVariant::Reference[:rule1, :required] ==
			RandTextCore::RuleVariant::Reference[:rule1, :optional]
		)
		assert_true(
			RandTextCore::RuleVariant::StringAttribute.type ==
			RandTextCore::RuleVariant::StringAttribute.type
		)
		assert_true(
			RandTextCore::RuleVariant::Enum[
				:value1,
				:value3,
				:value2,
				:value1
			] == RandTextCore::RuleVariant::Enum[
				:value2,
				:value3,
				:value1
			]
		)
		assert_false(
			RandTextCore::RuleVariant::Enum[
				:value1,
				:value3,
				:value2,
				:value1
			] == RandTextCore::RuleVariant::Enum[
				:value2,
				:value3,
				:value1,
				:value4
			]
		)
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
		assert_raise(RuntimeError) do
			RandTextCore::RuleVariant.enum(:my_rule, :val1, :val2, :val3)
		end
		assert_raise(RuntimeError) do
			RandTextCore::RuleVariant.send(:attr_types)
		end
		assert_raise(RuntimeError) { RandTextCore::RuleVariant.each }
		assert_raise(RuntimeError) { RandTextCore::RuleVariant[1] }
		assert_raise(RuntimeError) { RandTextCore::RuleVariant.size }
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

	def test_non_existing_file
		assert_raise(ArgumentError) do
			Class.new(RandTextCore::RuleVariant) do
				file_path TEST_DIR + 'complex_rule.csv'
			end
		end
	end

	def test_invalid_file_name
		assert_raise(ArgumentError) do
			Class.new(RandTextCore::RuleVariant) do
				file_path INVALID_DIR + 'invalid name.csv'
			end
		end
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
				reference 4, :simple_rule, :required
			end
		end
		assert_raise(TypeError) do
			Class.new(RandTextCore::RuleVariant) do
				file_path TEST_DIR + 'required_references.csv'
				reference :simple_rule, 5, :optional
			end
		end
		assert_raise(ArgumentError) do
			Class.new(RandTextCore::RuleVariant) do
				file_path TEST_DIR + 'required_references.csv'
				reference :simple_rule, :simple_rule, 8
			end
		end
		assert_raise(ArgumentError) do
			Class.new(RandTextCore::RuleVariant) do
				file_path TEST_DIR + 'required_references.csv'
				reference :id, :simple_rule, :required
			end
		end
		assert_raise(ArgumentError) do
			Class.new(RandTextCore::RuleVariant) do
				file_path TEST_DIR + 'required_references.csv'
				reference :weight, :simple_rule, :required
			end
		end
		assert_raise(RuntimeError) do
			Class.new(RandTextCore::RuleVariant) do
				file_path TEST_DIR + 'required_references.csv'
				reference :simple_rule, :simple_rule, :required
				reference :simple_rule, :simple_rule, :opitonal
			end
		end
		assert_raise(TypeError) do
			Class.new(RandTextCore::RuleVariant) do
				file_path TEST_DIR + 'enum_attribute.csv'
				enum 2, :value1, :value2, :value3
			end
		end
		assert_raise(TypeError) do
			Class.new(RandTextCore::RuleVariant) do
				file_path TEST_DIR + 'enum_attribute.csv'
				enum :enum_attr, :value1, 2, :value3
			end
		end
		assert_raise(ArgumentError) do
			Class.new(RandTextCore::RuleVariant) do
				file_path TEST_DIR + 'enum_attribute.csv'
				enum :id, :value1, :value2, :value3
			end
		end
		assert_raise(RuntimeError) do
			Class.new(RandTextCore::RuleVariant) do
				file_path TEST_DIR + 'enum_attribute.csv'
				enum :enum_attr, :value1, :value2, :value3
				enum :enum_attr, :value4
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

	def test_attr_types
		@simple_rule.send(:headers=, [:id, :value])
		@simple_rule.instance_variable_set(:@initialized, true)
		assert_equal(
			{
				id: RandTextCore::RuleVariant::Identifier.type,
				value: RandTextCore::RuleVariant::StringAttribute.type
			},
			@simple_rule.attr_types
		)
		@weighted_rule.send(:headers=, [:id, :value, :weight])
		@weighted_rule.instance_variable_set(:@initialized, true)
		assert_equal(
			{
				id: RandTextCore::RuleVariant::Identifier.type,
				value: RandTextCore::RuleVariant::StringAttribute.type,
				weight: RandTextCore::RuleVariant::Weight.type
			},
			@weighted_rule.attr_types
		)
		@optional_references.send(:headers=, [:id, :value, :simple_rule])
		@optional_references.instance_variable_set(:@initialized, true)
		assert_equal(
			{
				id: RandTextCore::RuleVariant::Identifier.type,
				value: RandTextCore::RuleVariant::StringAttribute.type,
				simple_rule: RandTextCore::RuleVariant::Reference[
					:simple_rule,
					:optional
				]
			},
			@optional_references.attr_types
		)
		@required_references.send(:headers=, [:id, :value, :simple_rule])
		@required_references.instance_variable_set(:@initialized, true)
		assert_equal(
			{
				id: RandTextCore::RuleVariant::Identifier.type,
				value: RandTextCore::RuleVariant::StringAttribute.type,
				simple_rule: RandTextCore::RuleVariant::Reference[
					:simple_rule,
					:required
				]
			},
			@required_references.attr_types
		)
		@enum_attribute.send(:headers=, [:id, :enum_attr])
		@enum_attribute.instance_variable_set(:@initialized, true)
		assert_equal(
			{
				id: RandTextCore::RuleVariant::Identifier.type,
				enum_attr: RandTextCore::RuleVariant::Enum[
					:value1,
					:value2,
					:value3
				]
			},
			@enum_attribute.attr_types
		)
	end

	def test_unset_attr_types
		assert_raise(RuntimeError) { @simple_rule.send(:attr_types) }
	end

	def test_invalid_attr_name
		invalid_attr_name = Class.new(RandTextCore::RuleVariant) do
			file_path INVALID_DIR + 'invalid_attr_name.csv'
		end
		assert_raise(RuntimeError) { invalid_attr_name.send(:import) }
	end

	def test_import
		@simple_rule.send(:import)
		@weighted_rule.send(:import)
		@optional_references.send(:import)
		@required_references.send(:import)
		@enum_attribute.send(:import)

		assert_equal(4, @simple_rule.size)
		assert_equal(5, @weighted_rule.size)
		assert_equal(4, @optional_references.size)
		assert_equal(4, @required_references.size)
		assert_equal(4, @enum_attribute.size)
	end

	def test_get
		@simple_rule.send(:rules=, @rules_dir1)
		@simple_rule.send(:import)
		@required_references.send(:rules=, @rules_dir1)
		@required_references.send(:import)
		@optional_references.send(:rules=, @rules_dir1)
		@optional_references.send(:import)
		@enum_attribute.send(:rules=, @rules_dir1)
		@enum_attribute.send(:import)
		assert_equal(1, @simple_rule[1].id)
		assert_equal("b,b", @simple_rule[2].value)
		assert_same(@simple_rule[4], @required_references[3].simple_rule)
		assert_nil(@optional_references[3].simple_rule)
		assert_equal(:value2, @enum_attribute[4].enum_attr)
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

	def test_unitialized_rule
		assert_raise(RuntimeError) { @simple_rule.each }
		assert_raise(RuntimeError) { @simple_rule[1] }
		assert_raise(RuntimeError) { @simple_rule.size }
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
		assert_raise(RuntimeError) { null_id.send(:import) }
	end

	def test_too_few_fields
		too_few_fields = Class.new(RandTextCore::RuleVariant) do
			file_path INVALID_DIR + 'too_few_fields.csv'
		end
		assert_raise(RuntimeError) { too_few_fields.send(:import) }
	end

	def test_too_much_fields
		too_much_fields = Class.new(RandTextCore::RuleVariant) do
			file_path INVALID_DIR + 'too_much_fields.csv'
		end
		assert_raise(RuntimeError) { too_much_fields.send(:import) }
	end

	def test_invalid_enum_value
		invalid_enum_value = Class.new(RandTextCore::RuleVariant) do
			file_path INVALID_DIR + 'invalid_enum_value.csv'
			enum :enum_attr, :value1, :value2, :value3
		end
		assert_raise(RuntimeError) { invalid_enum_value.send(:import) }
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
		@optional_references.send(:rules=, @rules_dir1)
		@optional_references.send(:import)
		@optional_references.each do |variant|
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

	def test_optional_reference
		@optional_references.send(:rules=, @rules_dir1)
		@optional_references.send(:import)
		@simple_rule.send(:rules=, @rules_dir1)
		@simple_rule.send(:import)
		assert_same(@simple_rule[2], @optional_references[1].simple_rule)
		assert_nil(@optional_references[3].simple_rule)
	end

	def test_inspect
		@simple_rule.send(:import)
		assert_equal(
			'#<simple_rule id=1, value="a">',
			@simple_rule[1].inspect
		)
	end

end