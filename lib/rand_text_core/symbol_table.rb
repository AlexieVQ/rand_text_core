require_relative '../rand_text_core.rb'
require_relative 'rule_variant'
require_relative 'symbol_exception'

# Object storing all used variants during a text generation, all defined methods
# for the generator and all rules.
#
# @author AlexieVQ
class RandTextCore::SymbolTable

	# Class storing a snapshot of the table's symbols at a precise moment.
	class Snapshot

		# @return [SymbolTable] concerned symbol table
		attr_reader :table

		# @return [Object] state of the table
		attr_reader :state

		# Creates a new snapshot for given table's state.
		# @param [SymbolTable] table table to store state
		# @param [Object] state state of the rule
		def initialize(table, state)
			@table, @state = table, state
		end

	end

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
		@functions[name].call(*args, self)
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

	# Creates a Snapshot of the current state of the table, i.e. the current
	# state of its symbols and its rules.
	# @return [Snapshot] snapshot of the table
	def current_state
		Snapshot.new(self, {
			variables: @variables.keys.each_with_object({}) do |symbol, hash|
				hash[symbol] = @variables[symbol].clone
			end,
			rules: @rules.values.map { |rule| rule.current_state }
		}.freeze)
	end

	# Restore the table's state from given Snapshot.
	# @param [Snapshot] snapshot snapshot to restore
	# @return [self]
	# @raise [TypeError] wrong argument type
	def restore(snapshot)
		unless snapshot.kind_of?(Snapshot)
			raise TypeError,
				"wrong type for argument (expected SymbolTable::Snapshot, " +
				"given #{snapshot.class})"
		end
		unless snapshot.table == self
			raise ArgumentError,
				"snapshot of wrong table"
		end
		@variables = snapshot.state[:variables].clone
		snapshot.state[:rules].each do |snapshot|
			snapshot.rule.restore(snapshot)
		end
		self
	end

	# Clear variables and send {RuleVariant#reset} to all rules.
	# @return [self]
	def clear
		@variables = {}
		@rules.each_value { |rule| rule.reset }
		self
	end

end