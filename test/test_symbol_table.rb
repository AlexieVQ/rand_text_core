require_relative 'test_helper'
require_relative '../lib/rand_text_core/symbol_table'
require_relative '../lib/rand_text_core/rule_variant'
require_relative '../lib/rand_text_core/symbol_exception'

class TestSymbolTable < Test::Unit::TestCase

	TEST_DIR = 'test/valid_dir1/'

	def setup
		@rules = {
			SimpleRule: Class.new(RandTextCore::RuleVariant) do

				attr_accessor :my_var

				self.file = TEST_DIR + 'simple_rule.csv'

				def init
					@my_var = 0
				end

				def pick?(number)
					self.id <= number.to_i
				end
			end,
			WeightedRule: Class.new(RandTextCore::RuleVariant) do
				self.file = TEST_DIR + 'weighted_rule.csv'
			end,
			RequiredReference: Class.new(RandTextCore::RuleVariant) do
				self.file = TEST_DIR + 'required_reference.csv'
				reference :variant_ref, :SimpleRule, :required
			end,
			OptionalReference: Class.new(RandTextCore::RuleVariant) do
				self.file = TEST_DIR + 'optional_reference.csv'
				reference :variant_ref, :SimpleRule, :optional
			end,
			SimpleEnum: Class.new(RandTextCore::RuleVariant) do
				self.file = TEST_DIR + 'simple_enum.csv'
				enum :value, :value1, :value2, :value3
			end
		}
		@rules.each_value { |rule| rule.send(:init_rule) }
		@symbol_table = RandTextCore::SymbolTable.new(
			{
				ret_arg: ->(arg, table) do
					arg
				end,
				add: ->(n1, n2, table) do
					n1.to_i + n2.to_i
				end,
				exists: ->(arg, table) do
					table.variable?(arg.to_sym)
				end,
				join: ->(*args, table) do
					args.join(' ')
				end
			},
			@rules.values
		)
		string1 = "string 1"
		@symbol_table.tap do |t|
			t[:var1] = string1
			t[:var2] = 2
			t[:var3] = t.rule_variant(:SimpleRule, 3)
			t[:var4] = string1
			t[:var5] = "string 1"
			t[:var6] = string1
		end
	end

	def test_variables
		assert_equal(6, @symbol_table.length)
	end

	def test_variable?
		assert_true(@symbol_table.variable? :var1)
		assert_true(@symbol_table.variable? :var4)
		assert_false(@symbol_table.variable? :var7)
	end

	def test_invalid_variable?
		assert_raise(TypeError) { @symbol_table.variable? 2 }
	end

	def test_variable
		assert_equal("string 1", @symbol_table[:var1])
		assert_equal(2, @symbol_table[:var2])
		assert_equal(
			@symbol_table.rule_variant(:SimpleRule, 3),
			@symbol_table[:var3]
		)
		assert_equal("string 1", @symbol_table[:var4])
		assert_equal("string 1", @symbol_table[:var5])
		assert_equal("string 1", @symbol_table[:var6])
		assert_nil(@symbol_table[:var7])
		assert_same(@symbol_table[:var1], @symbol_table[:var4])
		assert_same(@symbol_table[:var1], @symbol_table[:var6])
		assert_not_same(@symbol_table[:var1], @symbol_table[:var5])
	end

	def test_invalid_variable
		assert_raise(TypeError) { @symbol_table[2] }
	end

	def test_fetch_variable
		assert_equal("string 1", @symbol_table.fetch(:var1))
		assert_equal(2, @symbol_table.fetch(:var2))
		assert_equal(
			@symbol_table.rule_variant(:SimpleRule, 3),
			@symbol_table.fetch(:var3)
		)
		assert_raise(RandTextCore::SymbolException) do
			@symbol_table.fetch(:var8)
		end
	end

	def test_invalid_fetch_variable
		assert_raise(TypeError) { @symbol_table.fetch(3) }
	end

	def test_rule?
		assert_true(@symbol_table.rule?(:WeightedRule))
		assert_false(@symbol_table.rule?(:ComplexRule))
	end

	def test_invalid_param_rule?
		assert_raise(TypeError) { @symbol_table.rule?(3) }
	end

	def test_rule_variant?
		assert_true(@symbol_table.rule_variant?(:SimpleRule, 3))
		assert_false(@symbol_table.rule_variant?(:SimpleRule, 11))
		assert_false(@symbol_table.rule_variant?(:ComplexRule, 3))
	end

	def test_invalid_param_rule_variant?
		assert_raise(TypeError) do
			@symbol_table.rule_variant?(:SimpleRule, :v4)
		end
		assert_raise(TypeError) do
			@symbol_table.rule_variant?(4, 3)
		end
	end

	def test_rule_variant
		assert_equal(
			@rules[:SimpleRule].variants[3],
			@symbol_table.rule_variant(:SimpleRule, 3)
		)
		assert_nil(@symbol_table.rule_variant(:SimpleRule, 11))
		assert_nil(@symbol_table.rule_variant(:ComplexRule, 3))
	end

	def test_invalid_rule_variant
		assert_raise(TypeError) { @symbol_table.rule_variant(:SimpleRule, :v4) }
		assert_raise(TypeError) { @symbol_table.rule_variant(3, 5) }
	end

	def pick_test(rule, args, draw_nb)
		enum_draws = @rules[rule].variants.values.
			each_with_object({}) do |element, hash|
			hash[element] = 0
		end
		0.upto(draw_nb) do
			enum_draws[@symbol_table.pick_variant(rule, *args)] += 1
		end
		assert_false(enum_draws.keys.any? do |element|
			(element.weight <= 0 || !element.pick?(*args)) &&
				enum_draws[element] > 0
		end)
		enum_total = enum_draws.keys.reduce(0) do |total, variant|
			total + (variant.pick?(*args) ? variant.weight : 0)
		end
		enum_means = enum_draws.keys.map do |variant|
			variant.pick?(*args) ? variant.weight.to_f / enum_total.to_f : 0.0
		end
		deviations = Array.new(@rules[rule].length) do |i|
			Math.sqrt(draw_nb.to_f * enum_means[i] * (1.0 - enum_means[i]))
		end
		@rules[rule].variants.keys.each_with_index do |element, i|
			assert_in_delta(
				enum_means[i],
				enum_draws[element].to_f / draw_nb,
				deviations[i]
			)
		end
	end

	def test_pick_variant
		draw_nb = 1000
		pick_test(:SimpleRule, ["4"], draw_nb)
		pick_test(:WeightedRule, [""], draw_nb)
		pick_test(:SimpleRule, ["2"], draw_nb)
		assert_equal(
			@rules[:SimpleRule].variants[1],
			@symbol_table.pick_variant(:SimpleRule, "1")
		)
		assert_nil(@symbol_table.pick_variant(:SimpleRule, "0"))
		assert_nil(@symbol_table.pick_variant(:ComplexRule, ""))
	end

	def test_invalid_pick_variant
		assert_raise(TypeError) { @symbol_table.pick_variant(4) }
		assert_raise(TypeError) { @symbol_table.pick_variant(:SimpleRule, 3) }
	end

	def test_call
		assert_equal('hello', @symbol_table.call(:ret_arg, 'hello'))
		assert_equal(5, @symbol_table.call(:add, '2', '3'))
		assert_true(@symbol_table.call(:exists, 'var2'))
		assert_false(@symbol_table.call(:exists, 'var8'))
		assert_equal("A B C D", @symbol_table.call(:join, 'A', 'B', 'C', 'D'))
	end

	def test_invalid_call
		assert_raise(TypeError) { @symbol_table.call(4) }
		assert_raise(TypeError) { @symbol_table.call(:ret_arg, 8) }
		assert_raise(KeyError) { @symbol_table.call(:mul, '7', '8') }
		assert_raise(ArgumentError) { @symbol_table.call(:add, '7') }
		assert_raise(ArgumentError) { @symbol_table.call(:add, '8', '9', '10') }
	end

	def test_set
		@symbol_table[:var8] = 8
		assert_equal(8, @symbol_table[:var8])
		assert_raise(RandTextCore::SymbolException) do
			@symbol_table[:var2] = 4
		end
	end

	def test_invalid_set
		assert_raise(TypeError) { @symbol_table[4] = 7 }
	end

	def test_clear
		@symbol_table.clear
		assert_equal(0, @symbol_table.size)
		assert_raise(RandTextCore::SymbolException) do
			@symbol_table.fetch(:var1)
		end
		assert_raise(RandTextCore::SymbolException) do
			@symbol_table.fetch(:var2)
		end
		assert_raise(RandTextCore::SymbolException) do
			@symbol_table.fetch(:var3)
		end
		assert_raise(RandTextCore::SymbolException) do
			@symbol_table.fetch(:var4)
		end
		assert_raise(RandTextCore::SymbolException) do
			@symbol_table.fetch(:var5)
		end
		assert_raise(RandTextCore::SymbolException) do
			@symbol_table.fetch(:var6)
		end
	end

	def test_invalid_initialize
		assert_raise(TypeError) { RandTextCore::SymbolTable.new(4, []) }
		assert_raise(TypeError) { RandTextCore::SymbolTable.new({}, 8) }
		assert_raise(TypeError) do
			RandTextCore::SymbolTable.new({
				7 => -> { 7 }
			}, [])
		end
		assert_raise(TypeError) do
			RandTextCore::SymbolTable.new({
				fun: 7
			}, [])
		end
		assert_raise(TypeError) do
			RandTextCore::SymbolTable.new({
				fun: proc { 7 }
			}, [])
		end
		assert_raise(TypeError) { RandTextCore::SymbolTable.new({}, [7]) }
		assert_raise(TypeError) do
			RandTextCore::SymbolTable.new({}, [Integer])
		end
		assert_raise(RuntimeError) do
			RandTextCore::SymbolTable.new(
				{},
				@rules.values + [@rules[:WeightedRule]]
			)
		end
	end

	def test_fork
		fork1 = @symbol_table.clone
		fork2 = @symbol_table.clone

		assert_not_same(
			@symbol_table.rule_variant(:SimpleRule, 1),
			fork1.rule_variant(:SimpleRule, 1)
		)
		assert_same(
			@symbol_table,
			@symbol_table.rule_variant(:WeightedRule, 2).symbol_table
		)
		assert_same(
			fork1,
			fork1.rule_variant(:WeightedRule, 2).symbol_table
		)
		assert_same(
			fork2,
			fork2.rule_variant(:WeightedRule, 2).symbol_table
		)

		assert_equal(@symbol_table[:var1], fork1[:var1])
		assert_not_same(@symbol_table[:var1], fork1[:var1])
		assert_same(fork1[:var1], fork1[:var4])
		assert_not_same(fork1[:var1], fork1[:var5])
		assert_same(fork1[:var1], fork1[:var6])
		assert_equal(@rules[:SimpleRule].variants[3], fork1[:var3])
		assert_same(fork1.rule_variant(:SimpleRule, 3), fork1[:var3])
		assert_not_same(@symbol_table[:var3], fork1[:var3])

		fork1[:var7] = "string 2"
		fork2[:var7] = "string 3"
		assert_nil(@symbol_table[:var7])
		assert_equal("string 2", fork1[:var7])
		assert_equal("string 3", fork2[:var7])
	end

end
