#!/usr/bin/env ruby

require 'simplecov'
SimpleCov.start

require 'test/unit'
require_relative '../lib/rand_text_core/symbol_table'
require_relative '../lib/rand_text_core/rule_variant'
require_relative '../lib/rand_text_core/symbol_exception'

class TestSymbolTable < Test::Unit::TestCase

	TEST_DIR = 'test/dir1/'

	def setup
		@rules = {
			SimpleRule: Class.new(RandTextCore::RuleVariant) do
				attr_accessor :my_var
				self.file = TEST_DIR + 'simple_rule.csv'
				def init
					@my_var = 0
				end
			end,
			WeightedRule: Class.new(RandTextCore::RuleVariant) do
				self.file = TEST_DIR + 'weighted_rule.csv'
			end,
			RequiredReferences: Class.new(RandTextCore::RuleVariant) do
				self.file = TEST_DIR + 'required_references.csv'
				reference :simple_rule, :SimpleRule, :required
			end,
			OptionalReferences: Class.new(RandTextCore::RuleVariant) do
				self.file = TEST_DIR + 'optional_references.csv'
				reference :simple_rule, :SimpleRule, :optional
			end,
			EnumAttribute: Class.new(RandTextCore::RuleVariant) do
				self.file = TEST_DIR + 'enum_attribute.csv'
				enum :enum_attr, :value1, :value2, :value3
			end
		}
		@rules.each_value do |rule|
			rule.send(:rules=, @rules)
			rule.send(:import)
		end
		@symbol_table = RandTextCore::SymbolTable.new(
			{
				ret_arg: ->(arg, table) do
					arg
				end,
				add: ->(n1, n2, table) do
					n1.to_i + n2.to_i
				end,
				exists: ->(arg, table) do
					table.has?(arg.to_sym)
				end,
				join: ->(*args, table) do
					args.join(' ')
				end
			},
			@rules.values
		).tap do |t|
			t[:var1] = "string 1"
			t[:var2] = 2
			t[:var3] = @rules[:SimpleRule][3]
		end
	end

	def test_variables
		assert_equal(3, @symbol_table.variables.length)
	end

	def test_has
		assert_true(@symbol_table.has? :var1)
		assert_true(@symbol_table.has? :var2)
		assert_false(@symbol_table.has? :var4)
	end

	def test_invalid_has
		assert_raise(TypeError) { @symbol_table.has? 2 }
	end

	def test_get
		assert_equal("string 1", @symbol_table[:var1])
		assert_equal(2, @symbol_table[:var2])
		assert_equal(@rules[:SimpleRule][3], @symbol_table[:var3])
		assert_nil(@symbol_table[:var4])
	end

	def test_invalid_get
		assert_raise(TypeError) { @symbol_table[2] }
	end

	def test_fetch
		assert_equal("string 1", @symbol_table.fetch(:var1))
		assert_equal(2, @symbol_table.fetch(:var2))
		assert_equal(@rules[:SimpleRule][3], @symbol_table.fetch(:var3))
		assert_raise(RandTextCore::SymbolException) do
			@symbol_table.fetch(:var4)
		end
	end

	def test_invalid_fetch
		assert_raise(TypeError) { @symbol_table[3] }
	end

	def test_rule
		assert_same(@rules[:SimpleRule], @symbol_table.rule(:SimpleRule))
		assert_same(@rules[:WeightedRule], @symbol_table.rule(:WeightedRule))
		assert_same(
			@rules[:OptionalReferences],
			@symbol_table.rule(:OptionalReferences)
		)
		assert_same(
			@rules[:RequiredReferences],
			@symbol_table.rule(:RequiredReferences)
		)
		assert_same(
			@rules[:EnumAttribute],
			@symbol_table.rule(:EnumAttribute)
		)
	end

	def test_invalid_rule
		assert_raise(TypeError) { @symbol_table.rule(3) }
		assert_raise(KeyError) { @symbol_table.rule(:bad_rule) }
	end

	def test_call
		assert_equal('hello', @symbol_table.call(:ret_arg, 'hello'))
		assert_equal(5, @symbol_table.call(:add, '2', '3'))
		assert_true(@symbol_table.call(:exists, 'var2'))
		assert_false(@symbol_table.call(:exists, 'var4'))
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
		@symbol_table[:var4] = 8
		assert_equal(8, @symbol_table[:var4])
		assert_raise(RandTextCore::SymbolException) do
			@symbol_table[:var2] = 4
		end
	end

	def test_invalid_set
		assert_raise(TypeError) { @symbol_table[4] = 7 }
	end

	def test_clear
		@symbol_table.clear
		assert_equal(0, @symbol_table.variables.length)
	end

	def test_snapshot
		@rules[:SimpleRule][1].my_var = 3
		@symbol_table[:my_variant] = @rules[:SimpleRule][1]
		snapshot = @symbol_table.send(:current_state)
		@rules[:SimpleRule][1].my_var = 7
		assert_equal(7, @symbol_table.rule(:SimpleRule)[1].my_var)
		assert_equal(7, @symbol_table[:my_variant].my_var)
		@symbol_table.send(:restore, snapshot)
		assert_equal(3, @rules[:SimpleRule][1].my_var)
		assert_equal(3, @symbol_table[:my_variant].my_var)
		assert_same(@rules[:SimpleRule][1], @symbol_table[:my_variant])
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
		assert_raise(ArgumentError) do
			RandTextCore::SymbolTable.new({
				fun: proc { 7 }
			}, [])
		end
		assert_raise(TypeError) { RandTextCore::SymbolTable.new({}, [7]) }
		assert_raise(ArgumentError) do
			RandTextCore::SymbolTable.new({}, [Integer])
		end
		assert_raise(RuntimeError) do
			RandTextCore::SymbolTable.new(
				{},
				@rules.values + [@rules[:WeightedRule]]
			)
		end
	end

end