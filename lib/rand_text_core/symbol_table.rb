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
	# @param [Hash{#to_sym => #to_proc}] functions hash map storing functions
	#  used in the expansion language (must be lambdas)
	# @param [Enumerable<Class>] rules set of rules
	# @raise [TypeError] wrong type of parameters
	# @raise [ArgumentError] function not a lambda, or class not a subclass of
	#  RuleVariant
	# @raise [RuntimeError] rules with the same name
	def initialize(functions, rules)
		unless functions.kind_of?(Hash)
			raise TypeError,
				"wrong type for first argument (Hash{Symbol=>Proc} expected, " +
				"#{functions.class} given)"
		end
		@functions = functions.each_with_object({}) do |pair, hash|
			symbol = nil
			function = nil
			begin
				symbol = pair[0].to_sym
			rescue NoMethodError
				raise TypeError,
					"wrong type of key in first argument (Symbol expected, " +
					"#{pair[0].class} given)"
			end
			begin
				function = pair[1].to_proc
			rescue NoMethodError
				raise TypeError,
					"wrong type of value for key #{symbol} in first argument " +
					"(Proc expected, #{pair[1].class} given)"
			end
			unless function.lambda?
				raise ArgumentError,
					"function #{symbol} is not a lambda"
			end
			hash[symbol] = function
		end
		unless rules.kind_of?(Enumerable)
			raise TypeError,
				"wrong type for second argument (Enumerable<Class> expected, " +
				"#{rules.class} given)"
		end
		rules.each_with_index do |rule, i|
			unless rule.kind_of?(Class)
				raise TypeError,
					"wrong type for object of index #{i} in second argument " +
					"(Class espected, #{rule.class} given"
			end
			unless rule.superclass == RandTextCore::RuleVariant
				raise ArgumentError,
					"class of index #{i} in second argument is not a subclass" +
					" of RandTextCore::RuleVariant"
			end
		end
		@rules = rules.each_with_object({}) do |rule, hash|
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

	# Returns rule of given name.
	# @param [#to_sym] name variable name
	# @return [Class] rule of given name
	# @raise [TypeError] no implicit conversion of name into Symbol
	# @raise [KeyError] no variable of given name
	def rule(name)
		begin
			name = name.to_sym
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{name.class} into Symbol"
		end
		@rules.fetch(name)
	end

	# Call function of given name with given arguments.
	# @param [#to_sym] name variable name
	# @param [Array<#to_str>] args arguments
	# @return function's return
	# @raise [TypeError] wrong types
	# @raise [KeyError] no function of given name
	# @raise [ArgumentError] wrong number of arguments
	def call(name, *args)
		begin
			name = name.to_sym
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{name.class} into Symbol"
		end
		args = args.map do |arg|
			begin
				arg.to_str
			rescue NoMethodError
				raise TypeError,
					"no implicit conversion of #{arg.class} into String"
			end
		end
		@functions.fetch(name).call(*args, self)
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

	# Clear variables and send {RuleVariant#reset} to all rules.
	# @return [self]
	def clear
		@variables = {}
		@rules.each_value { |rule| rule.reset if rule.initialized? }
		self
	end

	private

	# Creates a snapshot of the current state of the table, i.e. the current
	# state of its symbols and its rules.
	def current_state
		hash = { variables: {}, rules: {} }
		@variables.keys.each_with_object(hash[:variables]) do |symbol, hash|
			hash[symbol] = @variables[symbol].clone
		end
		@rules.keys.each_with_object(hash[:rules]) do |name, hash|
			hash[name] = @rules[name].send(:current_state)
		end
		hash
	end

	# Restore the table's state from given snapshot.
	def restore(state)
		@variables = state[:variables].clone
		state[:rules].each do |name, state|
			@rules[name].send(:restore, state)
		end
		self
	end

end