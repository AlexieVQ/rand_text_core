require_relative 'test_helper'
require_relative '../lib/rand_text_core/rule_variant'
require_relative '../lib/rand_text_core/symbol_table'
require_relative '../lib/rand_text_core/data_types'

class TestRuleVariant < Test::Unit::TestCase

	VALID_DIR1 = 'test/valid_dir1/'

	ENUM = [:value1, :value2, :value3]

	def setup
		@valid_dir1 = {
			SimpleRule: Class.new(RandTextCore::RuleVariant) do
				self.file = VALID_DIR1 + 'simple_rule.csv'
			end,

			WeightedRule: Class.new(RandTextCore::RuleVariant) do
				self.file = VALID_DIR1 + 'weighted_rule.csv'
			end,

			OptionalReference: Class.new(RandTextCore::RuleVariant) do
				self.file = VALID_DIR1 + 'optional_reference.csv'

				reference :variant_ref, :SimpleRule, :optional
			end,

			RequiredReference: Class.new(RandTextCore::RuleVariant) do
				self.file = VALID_DIR1 + 'required_reference.csv'

				reference :variant_ref, :SimpleRule, :required
			end,

			SimpleEnum: Class.new(RandTextCore::RuleVariant) do
				self.file = VALID_DIR1 + 'simple_enum.csv'

				enum :value, *ENUM
			end,

			MultipleEnum: Class.new(RandTextCore::RuleVariant) do
				self.file = VALID_DIR1 + 'multiple_enum.csv'
			end
		}
		@valid_dir1.each_value do |rule|
			rule.send(:init_rule)
		end
		@valid_dir1_st = RandTextCore::SymbolTable.new({}, @valid_dir1.values)
	end

	def test_rule_name
		@valid_dir1.each do |name, rule|
			assert_equal(name, rule.rule_name)
		end
	end

	def test_lower_snake_case_name
		assert_equal(
			:simple_rule,
			@valid_dir1[:SimpleRule].lower_snake_case_name
		)
		assert_equal(
			:weighted_rule,
			@valid_dir1[:WeightedRule].lower_snake_case_name
		)
		assert_equal(
			:optional_reference,
			@valid_dir1[:OptionalReference].lower_snake_case_name
		)
		assert_equal(
			:required_reference,
			@valid_dir1[:RequiredReference].lower_snake_case_name
		)
		assert_equal(
			:simple_enum,
			@valid_dir1[:SimpleEnum].lower_snake_case_name
		)
		assert_equal(
			:multiple_enum,
			@valid_dir1[:MultipleEnum].lower_snake_case_name
		)
	end

	def test_file
		assert_equal(
			VALID_DIR1 + 'simple_rule.csv',
			@valid_dir1[:SimpleRule].file
		)
		assert_equal(
			VALID_DIR1 + 'weighted_rule.csv',
			@valid_dir1[:WeightedRule].file
		)
		assert_equal(
			VALID_DIR1 + 'optional_reference.csv',
			@valid_dir1[:OptionalReference].file
		)
		assert_equal(
			VALID_DIR1 + 'required_reference.csv',
			@valid_dir1[:RequiredReference].file
		)
		assert_equal(
			VALID_DIR1 + 'simple_enum.csv',
			@valid_dir1[:SimpleEnum].file
		)
		assert_equal(
			VALID_DIR1 + 'multiple_enum.csv',
			@valid_dir1[:MultipleEnum].file
		)
	end

	def test_attr_types
		assert_equal(
			RandTextCore::DataTypes::Identifier.type,
			@valid_dir1[:SimpleEnum].attr_types[:id]
		)
		assert_equal(
			RandTextCore::DataTypes::Weight.type,
			@valid_dir1[:SimpleRule].attr_types[:weight]
		)
		assert_equal(
			RandTextCore::DataTypes::StringAttribute.type,
			@valid_dir1[:SimpleRule].attr_types[:value]
		)
		assert_equal(
			RandTextCore::DataTypes::Weight.type,
			@valid_dir1[:WeightedRule].attr_types[:weight]
		)
		assert_equal(
			RandTextCore::DataTypes::Reference.new(:SimpleRule, :optional),
			@valid_dir1[:OptionalReference].attr_types[:variant_ref]
		)
		assert_equal(
			RandTextCore::DataTypes::Reference.new(:SimpleRule, :required),
			@valid_dir1[:RequiredReference].attr_types[:variant_ref]
		)
		assert_equal(
			RandTextCore::DataTypes::Enum[*ENUM],
			@valid_dir1[:SimpleEnum].attr_types[:value]
		)
	end

	def test_initialized?
		simple_rule = Class.new(RandTextCore::RuleVariant) do
			self.file = VALID_DIR1 + 'simple_rule.csv'
		end
		assert_false(simple_rule.initialized?)
		simple_rule.send(:init_rule)
		assert_true(simple_rule.initialized?)
	end

	def test_verify
		assert_equal(
			0,
			@valid_dir1[:SimpleRule].send(:verify, @valid_dir1_st).size
		)
		assert_equal(
			0,
			@valid_dir1[:WeightedRule].send(:verify, @valid_dir1_st).size
		)
		assert_equal(
			0,
			@valid_dir1[:OptionalReference].send(:verify, @valid_dir1_st).size
		)
		assert_equal(
			0,
			@valid_dir1[:RequiredReference].send(:verify, @valid_dir1_st).size
		)
		assert_equal(
			0,
			@valid_dir1[:SimpleEnum].send(:verify, @valid_dir1_st).size
		)
		assert_equal(
			0,
			@valid_dir1[:MultipleEnum].send(:verify, @valid_dir1_st).size
		)
	end

	def test_size
		assert_equal(4, @valid_dir1[:SimpleRule].size)
		assert_equal(4, @valid_dir1[:WeightedRule].size)
		assert_equal(4, @valid_dir1[:OptionalReference].size)
		assert_equal(4, @valid_dir1[:RequiredReference].size)
		assert_equal(4, @valid_dir1[:SimpleEnum].size)
		assert_equal(4, @valid_dir1[:MultipleEnum].size)
	end

	def test_variants
		@valid_dir1.each_value do |rule|
			rule.variants.each do |id, variant|
				assert_equal(id, variant.id)
				assert_equal(variant, @valid_dir1[rule.rule_name].variants[id])
				assert_not_same(
					variant,
					@valid_dir1[rule.rule_name].variants[id]
				)
			end
		end
	end

end