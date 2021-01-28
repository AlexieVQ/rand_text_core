require_relative '../rand_text_core.rb'
require_relative 'rule_variant'
require_relative 'symbol_exception'

# Object storing all used variants during a text generation, all defined methods
# for the generator and all rules.
#
# @author AlexieVQ
class RandTextCore::SymbolTable

	# @ rules [Set<Class>]
	# @ rule_variants [Hash{Symbol => Hash{Integer => RuleVariant}}]
	# @ variables [Hash{Symbol => Object}]

	# @return [Hash{Symbol => Proc}] hash map storing functions used in the
	#  expansion language (frozen)
	attr_reader :functions

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
		@rules = Set[]
		rules.each_with_index do |rule, i|
			unless rule.kind_of?(Class)
				raise TypeError,
					"wrong type for object of index #{i} in second argument " +
					"(Class espected, #{rule.class} given"
			end
			unless rule.ancestors.include?(RandTextCore::RuleVariant)
				raise ArgumentError,
					"class of index #{i} in second argument is not a subclass" +
					" of RandTextCore::RuleVariant"
			end
			@rules << rule
		end
		self.clear
	end

	# Copy constructor.
	# When {SymbolTable#clone} or {SymbolTable#dup} is called, what happened:
	# - the rule classes and the functions referenced in the new table are the
	#   same as in the original,
	# - the rule variants are copies or the ones of the original table,
	# - the variables referencing rule variants references theses copies,
	# - variables of other types are clones of their values in the original
	#   table, but if many variables store the same object (according to
	#   {BasicObject#equal?}) in the original table, the same variable in the
	#   copied table reference the same copy of the object from the original
	#   table.
	def initialize_copy(orig)
		@rules = orig.instance_variable_get(:rules).dup
		@functions = orig.instance_variable_get(:functions).dup.freeze
		rule_variants = orig.instance_variable_get(:rule_variants)
		@rule_variants = rule_variants.keys.each_with_object({}) do |rule, hash|
			hash[rule] = rule_variants[rule].keys.
				each_with_object({}) do |id, hash|
				hash[id] = rule_variants[rule][id].clone
			end
		end
		variables = orig.instance_variable_get(:variables)
		@variables = variables.keys.each_with_object({}) do |var, hash|
			same_var = variables.keys.find do |var2|
				variables[var2].equal?(variables[var]) && hash.key?(var2)
			end
			if variables[var].kind_of?(RuleVariant)
				hash[var] = @rule_variants[var.rule_name][var.id]
			elsif same_var
				hash[var] = hash[same_var]
			else
				hash[var] = variables[var].clone
			end
		end
	end

	# Tests if variable of given name exists in the table.
	# @param [#to_sym] name name of the variable
	# @return [true, false] +true+ if variable of given name exists, +false+
	#  otherwise
	# @raise [TypeError] no implicit conversion of name into Symbol
	def variable?(name)
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
	def variable(name)
		begin
			@variables[name.to_sym]
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{name.class} into Symbol"
		end
	end

	alias :[] :variable

	# Returns stored value into variable of given name.
	# Difference with {SymbolTable#[]} is that this method raises a
	# SymbolException if the table does not contains variable of given name.
	# @param [#to_sym] name variable name
	# @return [Object] value stored, or +nil+ if there is no variable of given
	#  name
	# @raise [TypeError] no implicit conversion of name into Symbol
	# @raise [SymbolException] no variable of given name
	def fetch_variable(name)
		unless self.has?(name)
			raise RandTextCore::SymbolException,
				"symbol #{name} does not exist in the table"
		end
		self[name]
	end

	alias :fetch :fetch_variable
	
	# Tests if rule of given name exists in the system.
	# @param [#to_sym] name name of the rule
	# @return [true, false] +true+ if rule of given name exists, +false+
	#  otherwise
	# @raise [TypeError] no implicit conversion of name into Symbol
	def rule?(name)
		begin
			@rule_variants.key?(name.to_sym)
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{name.class} into Symbol"
		end
	end

	# Tests if variant of given id exists in the rule.
	# @param [#to_sym] rule name of the rule
	# @param [#to_int] id id of the variant
	# @return [true, false] +true+ if variant of given name id, +false+
	#  otherwise
	# @raise [TypeError] wrong argument types
	def rule_variant?(rule, id)
		begin
			rule = rule.to_sym
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{rule.class} into Symbol"
		end
		begin
			id = id.to_int
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{id.class} into Integer"
		end
		@rule_variants.key?(rule) && @rule_variants[rule].key?(id)
	end

	# Get rule variant of given id
	# @param [#to_sym] rule name of the rule
	# @param [#to_int] id id of the variant
	# @return [RuleVariant, nil] variant of the rule of given id, or +nil+ if
	#  the rule has no variant of given id
	# @raise [TypeError] wrong argument types
	# @raise [NameError] no rule of given name
	def rule_variant(rule, id)
		begin
			rule = rule.to_sym
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{rule.class} into Symbol"
		end
		begin
			id = id.to_int
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{id.class} into Integer"
		end
		@rule_variants.fetch(rule) do |rule|
			raise NameError, "no rule named #{rule} in the system"
		end[id]
	end

	# Pick a variant of rule of given name randomly, using a weighted random
	# choice.
	# The pickable variants are definad by {RuleVariant#pick?} using given
	# arguments.
	# @param [#to_sym] rule name of the rule
	# @param [Array<String>] args arguments (never empty when called from an
	#  expansion node, if no arguments are explecitly given, an empty string is
	#  given by default; can be empty if called from ruby code)
	# @return [RuleVariant, nil] a randomly chosen variant, or +nil+ if no
	#  variant satisfies the arguments
	# @raise [TypeError] invalid argument types
	# @raise [NameError] no rule of given name
	def pick_variant(rule, *args)
		begin
			rule = rule.to_sym
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{rule.class} into Symbol"
		end
		args.each_with_index do |arg, i|
			unless arg.kind_of?(String)
				raise TypeError,
					"invalid type for #{i+2}th argument (expected String, " +
					"given #{arg.class})"
			end
		end
		@rule_variants.fetch(rule) do |rule|
			raise NameError, "no rule name #{rule} in the system"
		end.select { |variant| variant.pick?(*args) }.pick
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

	# Clear variables and rule variants.
	# @return [self]
	def clear
		@variables = {}
		@rule_variants = @rules.each_with_object({}) do |rule, hash|
			hash[rule.rule_name] = rule.variants
		end
		self
	end

end