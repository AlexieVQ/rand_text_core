#!/usr/bin/env ruby

require 'simplecov'
SimpleCov.start

require 'test/unit'
require_relative '../lib/rand_text_core/rule_variant'
require_relative '../lib/rand_text_core/symbol_table'
require_relative '../lib/rand_text_core/refinements'

class TestRuleVariant < Test::Unit::TestCase

	using RandTextCore::Refinements

	TEST_DIR = 'test/dir1/'
	INVALID_DIR = 'test/invalid_dir/'

	def setup
		@simple_rule = Class.new(RandTextCore::RuleVariant) do
			self.file = TEST_DIR + 'simple_rule.csv'
			has_many :OptionalReferences, :simple_rule, :optional
			has_many :RequiredReferences, :simple_rule, :required

			def self.pick?(variant, min)
				variant.id >= min.to_i
			end

			def value
				"value #{id}: #{default_value}"
			end
		end
		@weighted_rule = Class.new(RandTextCore::RuleVariant) do
			self.file = TEST_DIR + 'weighted_rule.csv'

			def weight
				default_weight * 10
			end
		end
		@optional_references = Class.new(RandTextCore::RuleVariant) do
			self.file = TEST_DIR + 'optional_references.csv'
			reference :simple_rule, :SimpleRule, :optional
		end
		@required_references = Class.new(RandTextCore::RuleVariant) do
			self.file = TEST_DIR + 'required_references.csv'
			reference :simple_rule, :SimpleRule, :required
		end
		@enum_attribute = Class.new(RandTextCore::RuleVariant) do
			self.file = TEST_DIR + 'enum_attribute.csv'
			enum :enum_attr, :value1, :value2, :value3
		end
		@rules_dir1 = [
			@simple_rule,
			@weighted_rule,
			@optional_references,
			@required_references,
			@enum_attribute
		]
		@symbol_table = RandTextCore::SymbolTable.new({}, @rules_dir1)
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
			RandTextCore::RuleVariant::Identifier.type.convert(
				'38 ',
				@symbol_table
			)
		)
		assert_equal(
			5,
			RandTextCore::RuleVariant::Weight.type.convert(
				' 5',
				@symbol_table
			)
		)
		@simple_rule.send(:init_rule, @symbol_table)
		assert_nil(
			RandTextCore::RuleVariant::Reference[
				:SimpleRule,
				:optional
			].convert('0', @symbol_table)
		)
		assert_equal(
			@simple_rule[3],
			RandTextCore::RuleVariant::Reference[
				:SimpleRule,
				:required
			].convert('3', @symbol_table)
		)
		assert_equal(
			:value2,
			RandTextCore::RuleVariant::Enum[
				:value1,
				:value2,
				:value3
			].convert('value2', @symbol_table)
		)
		assert_equal(
			'my string',
			RandTextCore::RuleVariant::StringAttribute.type.convert(
				'my string',
				@symbol_table
			)
		)
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
		assert_raise(RuntimeError) do
			RandTextCore::RuleVariant.lower_snake_case_name
		end
		assert_raise(RuntimeError) { RandTextCore::RuleVariant.file }
		assert_raise(RuntimeError) do 
			RandTextCore::RuleVariant.file = TEST_DIR + 'simple_rule.csv'
		end
		assert_raise(RuntimeError) do
			RandTextCore::RuleVariant.reference(:simple_rule, :simple_rule)
		end
		assert_raise(RuntimeError) do
			RandTextCore::RuleVariant.enum(:my_rule, :val1, :val2, :val3)
		end
		assert_raise(RuntimeError) do
			RandTextCore::RuleVariant.has_many(:MyRule, :this_rule, :required)
		end
		assert_raise(RuntimeError) do
			RandTextCore::RuleVariant.send(:attr_types)
		end
		assert_raise(RuntimeError) { RandTextCore::RuleVariant.each }
		assert_raise(RuntimeError) { RandTextCore::RuleVariant[1] }
		assert_raise(RuntimeError) { RandTextCore::RuleVariant.size }
	end

	def test_rule_name
		assert_equal(:SimpleRule, @simple_rule.rule_name)
		assert_equal(:WeightedRule, @weighted_rule.rule_name)
		assert_equal(:OptionalReferences, @optional_references.rule_name)
		assert_equal(:RequiredReferences, @required_references.rule_name)
		assert_equal(:simple_rule, @simple_rule.lower_snake_case_name)
		assert_equal(:weighted_rule, @weighted_rule.lower_snake_case_name)
		assert_equal(
			:optional_references,
			@optional_references.lower_snake_case_name
		)
		assert_equal(
			:required_references,
			@required_references.lower_snake_case_name
		)
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
		assert_raise(RuntimeError) { klass.lower_snake_case_name }
	end

	def test_non_existing_file
		assert_raise(ArgumentError) do
			Class.new(RandTextCore::RuleVariant) do
				self.file = TEST_DIR + 'complex_rule.csv'
			end
		end
	end

	def test_invalid_file_name
		assert_raise(ArgumentError) do
			Class.new(RandTextCore::RuleVariant) do
				self.file = INVALID_DIR + 'invalid name.csv'
			end
		end
	end

	def test_reset_file_path
		assert_raise(RuntimeError) do
			@simple_rule.file = TEST_DIR + 'weighted_rule.csv'
		end
	end

	def test_wrong_argument_type
		assert_raise(TypeError) do
			Class.new(RandTextCore::RuleVariant) do
				self.file = 3
			end
		end
		assert_raise(TypeError) do
			Class.new(RandTextCore::RuleVariant) do
				self.file = TEST_DIR + 'required_references.csv'
				reference 4, :simple_rule, :required
			end
		end
		assert_raise(TypeError) do
			Class.new(RandTextCore::RuleVariant) do
				self.file = TEST_DIR + 'required_references.csv'
				reference :simple_rule, 5, :optional
			end
		end
		assert_raise(ArgumentError) do
			Class.new(RandTextCore::RuleVariant) do
				self.file = TEST_DIR + 'required_references.csv'
				reference :simple_rule, :simple_rule, 8
			end
		end
		assert_raise(ArgumentError) do
			Class.new(RandTextCore::RuleVariant) do
				self.file = TEST_DIR + 'required_references.csv'
				reference :id, :simple_rule, :required
			end
		end
		assert_raise(ArgumentError) do
			Class.new(RandTextCore::RuleVariant) do
				self.file = TEST_DIR + 'required_references.csv'
				reference :weight, :simple_rule, :required
			end
		end
		assert_raise(RuntimeError) do
			Class.new(RandTextCore::RuleVariant) do
				self.file = TEST_DIR + 'required_references.csv'
				reference :simple_rule, :simple_rule, :required
				reference :simple_rule, :simple_rule, :opitonal
			end
		end
		assert_raise(TypeError) do
			Class.new(RandTextCore::RuleVariant) do
				self.file = TEST_DIR + 'enum_attribute.csv'
				enum 2, :value1, :value2, :value3
			end
		end
		assert_raise(TypeError) do
			Class.new(RandTextCore::RuleVariant) do
				self.file = TEST_DIR + 'enum_attribute.csv'
				enum :enum_attr, :value1, 2, :value3
			end
		end
		assert_raise(ArgumentError) do
			Class.new(RandTextCore::RuleVariant) do
				self.file = TEST_DIR + 'enum_attribute.csv'
				enum :id, :value1, :value2, :value3
			end
		end
		assert_raise(RuntimeError) do
			Class.new(RandTextCore::RuleVariant) do
				self.file = TEST_DIR + 'enum_attribute.csv'
				enum :enum_attr, :value1, :value2, :value3
				enum :enum_attr, :value4
			end
		end
		assert_raise(TypeError) do
			Class.new(RandTextCore::RuleVariant) do
				self.file = TEST_DIR + 'simple_rule.csv'
				has_many 8, :simple_rule, :optional
			end
		end
		assert_raise(TypeError) do
			Class.new(RandTextCore::RuleVariant) do
				self.file = TEST_DIR + 'simple_rule.csv'
				has_many :RequiredReferences, 7, :required
			end
		end
		assert_raise(ArgumentError) do
			Class.new(RandTextCore::RuleVariant) do
				self.file = TEST_DIR + 'simple_rule.csv'
				has_many :RequiredReferences, :simple_rule, :optimal
			end
		end
		assert_raise(RuntimeError) do
			Class.new(RandTextCore::RuleVariant) do
				self.file = TEST_DIR + 'simple_rule.csv'
				has_many :RequiredReferences, :simple_rule, :required
				has_many :RequiredReferences, :attribute, :optional
			end
		end
		assert_raise(TypeError) do
			@simple_rule.send(:init_rule, @symbol_table)
			@simple_rule[:key]
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
					:SimpleRule,
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
					:SimpleRule,
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
			self.file = INVALID_DIR + 'invalid_attr_name.csv'
		end
		assert_raise(RuntimeError) do
			invalid_attr_name.send(
				:init_rule,
				RandTextCore::SymbolTable.new({}, [])
			)
		end
	end

	def test_import
		@simple_rule.send(:init_rule, @symbol_table)
		@weighted_rule.send(:init_rule, @symbol_table)
		@optional_references.send(:init_rule, @symbol_table)
		@required_references.send(:init_rule, @symbol_table)
		@enum_attribute.send(:init_rule, @symbol_table)

		assert_equal(4, @simple_rule.size)
		assert_equal(5, @weighted_rule.size)
		assert_equal(4, @optional_references.size)
		assert_equal(4, @required_references.size)
		assert_equal(4, @enum_attribute.size)
	end

	def test_each_no_block
		@simple_rule.send(:init_rule, @symbol_table)
		assert_kind_of(Enumerator, @simple_rule.each)
	end

	def test_each_block
		i = 0
		@simple_rule.send(:init_rule, @symbol_table)
		@simple_rule.each { |v| i += 1 }
		assert_equal(4, i)
	end

	def test_pick
		@simple_rule.send(:init_rule, @symbol_table)
		@weighted_rule.send(:init_rule, @symbol_table)
		picks = Array.new(100) { @simple_rule.pick("2") }
		assert_false(picks.any? { |variant| variant.id < 2 })
		assert_nil(@simple_rule.pick("5"))
		picks = Array.new(100) { @weighted_rule.pick }
		@weighted_rule.each do |variant|
			pb = variant.weight.to_f / @weighted_rule.total_weight
			assert_in_delta(
				pb,
				picks.count do
					|v| v.id == variant.id
				end.to_f / @weighted_rule.total_weight,
				Math.sqrt(100 * pb * (1 - pb))
			)
		end
	end

	def test_unitialized_rule
		assert_raise(RuntimeError) { @simple_rule.each }
		assert_raise(RuntimeError) { @simple_rule[1] }
		assert_raise(RuntimeError) { @simple_rule.size }
	end

	def test_snapshot
		simple_rule = Class.new(RandTextCore::RuleVariant) do
			attr_accessor :var1
			attr_accessor :var2

			self.file = TEST_DIR + 'simple_rule.csv'

			def init
				@my_var = 0
			end
		end
		simple_rule.send(:init_rule, @symbol_table)
		simple_rule[1].var1 = 2
		snapshot = simple_rule.send(:current_state)
		simple_rule[1].var1 += 1
		simple_rule[1].var2 = 8
		assert_equal(3, simple_rule[1].var1)
		assert_equal(8, simple_rule[1].var2)
		simple_rule.send(:restore, snapshot)
		assert_equal(2, simple_rule[1].var1)
		assert_nil(simple_rule[1].var2)
		assert_false(simple_rule[1].instance_variable_defined?(:@var2))
	end

	def test_reset
		simple_rule = Class.new(RandTextCore::RuleVariant) do
			attr_accessor :my_var

			self.file = TEST_DIR + 'simple_rule.csv'

			def init
				@my_var = 0
			end
		end
		simple_rule.send(:init_rule, RandTextCore::SymbolTable.new({}, []))
		simple_rule[1].my_var = 2
		simple_rule.reset
		assert_equal(0, simple_rule[1].my_var)
	end

	def test_clone
		@simple_rule.send(:init_rule, @symbol_table)
		assert_same(@simple_rule[1], @simple_rule[1].clone)
	end

	def test_already_initialized_rule
		simple_rule = Class.new(RandTextCore::RuleVariant) do
			self.file = TEST_DIR + 'simple_rule.csv'
		end
		simple_rule.send(:init_rule, @symbol_table)
		assert_raise(RuntimeError) do
			simple_rule.has_many(:OptionalReferences, :simple_rule, :optional)
		end
		required_references = Class.new(RandTextCore::RuleVariant) do
			self.file = TEST_DIR + 'required_references.csv'
		end
		required_references.send(
			:init_rule,
			RandTextCore::SymbolTable.new({}, [])
		)
		assert_raise(RuntimeError) do
			required_references.reference(:SimpleRule, :simple_rule, :required)
		end
		enum_attribute = Class.new(RandTextCore::RuleVariant) do
			self.file = TEST_DIR + 'enum_attribute.csv'
		end
		enum_attribute.send(:init_rule, RandTextCore::SymbolTable.new({}, []))
		assert_raise(RuntimeError) do
			enum_attribute.enum(:enum_attr, :value1, :value2, :value3)
		end
	end

	def test_no_id
		no_id = Class.new(RandTextCore::RuleVariant) do
			self.file = INVALID_DIR + 'no_id.csv'
		end
		assert_raise(RuntimeError) do
			no_id.send(:init_rule, RandTextCore::SymbolTable.new({}, []))
		end
	end

	def test_duplicated_id
		duplicated_id = Class.new(RandTextCore::RuleVariant) do
			self.file = INVALID_DIR + 'duplicated_id.csv'
		end
		assert_raise(RuntimeError) do
			duplicated_id.send(
				:init_rule,
				RandTextCore::SymbolTable.new({}, [])
			)
		end
	end

	def test_identical_attributes
		identical_attributes = Class.new(RandTextCore::RuleVariant) do
			self.file = INVALID_DIR + 'identical_attributes.csv'
		end
		assert_raise do
			identical_attributes.send(
				:init_rule,
				RandTextCore::SymbolTable.new({}, [])
			)
		end
	end

	######################
	# TESTS ON INSTANCES #
	######################

	def test_attributes
		@simple_rule.send(:init_rule, @symbol_table)
		@simple_rule.each do |variant|
			assert_respond_to(variant, :id)
			assert_respond_to(variant, :value)
			assert_respond_to(variant, :weight)
		end
		@weighted_rule.send(:init_rule, @symbol_table)
		@weighted_rule.each do |variant|
			assert_respond_to(variant, :id)
			assert_respond_to(variant, :value)
			assert_respond_to(variant, :weight)
		end
		@required_references.send(:init_rule, @symbol_table)
		@required_references.each do |variant|
			assert_respond_to(variant, :id)
			assert_respond_to(variant, :value)
			assert_respond_to(variant, :weight)
			assert_respond_to(variant, :simple_rule)
		end
		@optional_references.send(:init_rule, @symbol_table)
		@optional_references.each do |variant|
			assert_respond_to(variant, :id)
			assert_respond_to(variant, :value)
			assert_respond_to(variant, :weight)
			assert_respond_to(variant, :simple_rule)
		end
	end

	def test_get
		@simple_rule.send(:init_rule, @symbol_table)
		@weighted_rule.send(:init_rule, @symbol_table)
		@required_references.send(:init_rule, @symbol_table)
		@optional_references.send(:init_rule, @symbol_table)
		@enum_attribute.send(:init_rule, @symbol_table)
		assert_equal(1, @simple_rule[1].id)
		assert_equal("value 2: b,b", @simple_rule[2].value)
		assert_equal(1, @simple_rule[3].weight)
		assert_equal(30, @weighted_rule[3].weight)
		assert_same(@simple_rule[4], @required_references[3].simple_rule)
		assert_nil(@optional_references[3].simple_rule)
		assert_equal(:value2, @enum_attribute[4].enum_attr)
	end

	def test_reference_attributes
		@required_references.send(:init_rule, @symbol_table)
		@simple_rule.send(:init_rule, @symbol_table)
		assert_same(@simple_rule[2], @required_references[1].simple_rule)
	end

	def test_optional_reference
		@optional_references.send(:init_rule, @symbol_table)
		@simple_rule.send(:init_rule, @symbol_table)
		assert_same(@simple_rule[2], @optional_references[1].simple_rule)
		assert_nil(@optional_references[3].simple_rule)
	end

	def test_has_many
		@simple_rule.send(:init_rule, @symbol_table)
		@optional_references.send(:init_rule, @symbol_table)
		@required_references.send(:init_rule, @symbol_table)
		assert_equal(
			{
				attribute: :simple_rule,
				type: :required
			},
			@simple_rule.instance_variable_get(
				:@relations
			)[:RequiredReferences]
		)
		assert_equal(
			{
				attribute: :simple_rule,
				type: :optional
			},
			@simple_rule.instance_variable_get(
				:@relations
			)[:OptionalReferences]
		)
	end

	def test_inspect
		@simple_rule.send(:init_rule, @symbol_table)
		assert_equal(
			'#<SimpleRule id=1, value="a">',
			@simple_rule[1].inspect
		)
	end

end