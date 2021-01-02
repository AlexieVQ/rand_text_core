require_relative '../rand_text_core.rb'
require_relative 'rule_variant'
require_relative 'symbol_exception'

# Object storing all used variants during a text generation, all defined methods
# for the generator and all rules.
#
# @author AlexieVQ
class RandTextCore::SymbolTable

	# @return [Hash{Symbol => Proc}] hash map storing functions used in the
	#  expansion language (frozen)
	attr_reader :functions

	# @return [Hash{Symbol => Class}] hash map associating names of the rules to
	#  the rules (frozen)
	attr_reader :rules

	# Creates a new symbol table.
	# @param [Hash{Symbol => Proc}] functions hash map storing functions used in
	#  the expansion language
	# @param [Enumerable<Class>] rules set of rules
	# @raise [TypeError] wrong type of parameters
	# @raise [RuntimeError] rules with the same name
	def initialize(functions, rules)
		unless functions.kind_of?(Hash)
			raise TypeError,
				"wrong type for first argument (Hash{Symbol=>Proc} expected, " +
				"#{functions.class} given)"
		end
		functions.each do |symbol, function|
			unless symbol.kind_of?(Symbol)
				raise TypeError,
					"wrong type of key in first argument (Symbol expected, " +
					"#{symbol.class} given)"
			end
			unless function.kind_of?(Proc)
				raise TypeError,
					"wrong type of value for key #{symbol} in first argument " +
					"(Proc expected, #{function} given)"
			end
		end
		unless rules.kind_of?(Enumerable)
			raise TypeError,
				"wrong type for second argument (Enumerable<Class> expected, " +
				"#{rules.class} given)"
		end
		rules.each_with_index do |rule, i|
			unless rule.kind_of(Class)
				raise TypeError,
					"wrong type for object of index #{i} in second argument " +
					"(Class espected, #{rule.class} given"
			end
			unless rule.superclass == RandTextCore::RuleVariant
				raise TypeError,
					"class of index #{i} in second argument is not a subclass" +
					" of RandTextCore::RuleVariant"
			end
		end
		@functions = functions.clone.freeze
		@rules = rules.reduce({}) do |hash, rule|
			if hash[rule.rule_name]
				raise "two rules with the same name #{rule.rule_name.inspect}"
			end
			hash[rule.rule_name] = rule
		end.freeze
		self.clear
	end

	# Returns stored variables (not rules and functions).
	# Modifications on the returned hash map has no consequences on the table.
	# @return [Hash{Symbol => Object}] hash map associating variables names to
	#  the values they store
	def variables
		@variables.clone
	end

	# Tests if variable of given name exists in the table.
	# @return [true, false] +true+ if variable of given name exists, +false+
	#  otherwise
	# @raise [TypeError] no implicit conversion of name into Symbol
	def has?(name)
		begin
			@variables.key?(name.to_sym)
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{name.class} into Symbol"
		end
	end

	# Returns stored value into variable of given name.
	# @param [#to_sym] name variable name
	# @return [Object, nil] value stored, or +nil+ if there is no variable of
	#  given name
	# @raise [TypeError] no implicit conversion of name into Symbol
	def [](name)
		begin
			@variables[name.to_sym]
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{name.class} into Symbol"
		end
	end

	# Returns stored value into variable of given name.
	# Difference with {SymbolTable#[]} is that this method raises a
	# SymbolException if the table does not contains variable of given name.
	# @param [#to_sym] name variable name
	# @return [Object] value stored, or +nil+ if there is no variable of given
	#  name
	# @raise [TypeError] no implicit conversion of name into Symbol
	# @raise [SymbolException] no variable of given name
	def fetch(name)
		unless self.has?(name)
			raise RandTextCore::SymbolException,
				"symbol #{name} does not exist in the table"
		end
		self[name]
	end

	# Add a variable with given name that stores given value.
	# @param [#to_sym] name variable name
	# @param [Object] value value to store
	# @return [Object] value stored
	# @raise [TypeError] no implicit conversion of +name+ into Symbol
	# @raise [SymbolException] variable of given name already
	#  exists in the table
	def []=(name, value)
		begin
			name = name.to_sym
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{name.class} into Symbol"
		end
		if @variables[name]
			raise RandTextCore::SymbolException,
				"symbol #{name} already exists in the table"
		end
		@variables[name] = value
	end

	# Clear the table, without loosing the functions and the rules.
	# @return [self]
	def clear
		@variables = {}
	end

end