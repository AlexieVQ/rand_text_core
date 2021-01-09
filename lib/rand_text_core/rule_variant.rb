require 'csv'
require_relative '../rand_text_core'
require_relative 'refinements'
require_relative 'data_types'

# A variant of a rule is a tuple from a CSV file.
#
# A class extending RuleVariant represents a rule, i.e. a CSV table, and all its
# instances are variants of this rule.
#
# A subclass of RuleVariant is an Enumerable object, i.e. all its instances can
# be accessed through Enumerable's methods on the class.
#
# @author AlexieVQ
class RandTextCore::RuleVariant

	using RandTextCore::Refinements

	###########################
	# CLASS METHOD FOR A RULE #
	###########################

	# Returns rule name, in +UpperCamelCase+, as in file name.
	# @return [Symbol] rule name, in +UpperCamelCase+, as in file name
	# @raise [RuntimeError] called on RuleVariant, or file path not set with
	#  {RuleVariant#file=}
	# @example
	#  class MyRule < RandTextCore::RuleVariant
	#      self.file = 'rules/my_rule.csv'
	#  end
	#  
	#  MyRule.rule_name	#=> :MyRule
	def self.rule_name
		if self == RandTextCore::RuleVariant
			raise "class RuleVariant does not represent any rule"
		end
		unless @rule_name
			raise "file path not set for class #{self}"
		end
		@rule_name
	end

	# Returns rule name, in +lower_snake_case+, as in file name.
	# @return [Symbol] rule name, in +lower_snake_case+, as in file name
	# @raise [RuntimeError] called on RuleVariant, or file path not set with
	#  {RuleVariant#file=}
	# @example
	#  class MyRule < RandTextCore::RuleVariant
	#      self.file = 'rules/my_rule.csv'
	#  end
	#  
	#  MyRule.lower_snake_case_name	#=> :my_rule
	def self.lower_snake_case_name
		if self == RandTextCore::RuleVariant
			raise "class RuleVariant does not represent any rule"
		end
		unless @lower_snake_case_name
			raise "file path not set for class #{self}"
		end
		@lower_snake_case_name
	end

	# Returns file path set with {RuleVariant#file=}.
	# @return [String] file path (frozen)
	# @raise [RuntimeError] called on RuleVariant, or file path not set with
	#  {RuleVariant#file=}
	def self.file
		if self == RandTextCore::RuleVariant
			raise "class RuleVariant does not represent any rule"
		end
		unless @file
			raise "file path not set for class #{self}"
		end
		@file
	end

	# Set file path.
	# File path can only be set one time.
	# The attribute {RuleVariant#rule_name} is inferred from the file name.
	# File name must be in the format +lower_snake_case.csv+.
	# @param [#to_str] path path to the CSV file, must end with .csv
	# @return [String] path to the CSV file (frozen)
	# @raise [TypeError] no implicit conversion of path into String
	# @raise [ArgumentError] given String does not represent a path to a CSV
	#  file
	# @raise [RuntimeError] called on RuleVariant, or called multiple time
	def self.file=(path)
		if self == RandTextCore::RuleVariant
			raise "cannot set file path for class RuleVariant"
		end
		if @file
			raise "file path already set for class #{self}"
		end
		begin
			path = path.to_str
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{path.class} into String"
		end
		unless File.exist?(path)
			raise ArgumentError, "file #{path} does not exist"
		end
		file_name = path.split('/').last
		unless file_name.valid_csv_file_name?
			raise ArgumentError, "file #{path} does not have a valid name"
		end
		@lower_snake_case_name = file_name.split('.').first.to_sym
		@rule_name = @lower_snake_case_name.id2name.camelize.to_sym
		@file = path.freeze
	end

	# Declares that given attribute is a reference to rule +rule_name+'s id.
	# @param [#to_sym] attribute attribute from current rule (must only contain
	#  non-zero integers)
	# @param [#to_sym] rule_name name of the rule to reference (returned by 
	#  {RuleVariant#rule_name})
	# @param [:required, :optional] type +:required+ for a required reference,
	#  +:optional+ for an optional one
	# @return [nil]
	# @raise [TypeError] no implicit conversion for arguments into Symbol
	# @raise [ArgumentError] wrong argument for +type+ or reserved attribute
	#  (+id+ or +weight+)
	# @raise [RuntimeError] called on RuleVariant or type already set for
	#  +attribute+
	def self.reference(attribute, rule_name, type = :required)
		if self == RandTextCore::RuleVariant
			raise "cannot set reference for class RuleVariant"
		end
		if self.initialized?
			raise "rule #{self.rule_name} has already been initialized"
		end
		@attr_types ||= {}
		begin
			attribute = attribute.to_sym
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{attribute.class} into Symbol"
		end
		if [:id, :weight].include?(attribute)
			raise ArgumentError, "attribute #{attribute} cannot be a reference"
		end
		if @attr_types[attribute]
			raise "type already set for attribute #{attribute}"
		end
		@attr_types[attribute] = RandTextCore::DataTypes::Reference[
			rule_name,
			type
		]
		nil
	end

	# Declares that given attribute only accepts given values.
	# The values are symbols.
	# @param [#to_sym] attribute attribute in question
	# @param [Array<#to_sym>] values accepted values
	# @return [nil]
	# @raise [TypeError] no implicit conversion for arguments into Symbol
	# @raise [ArgumentError] reserved attribute (+id+ or +weight+)
	# @raise [RuntimeError] called on RuleVariant, or type already set for
	#  +attribute+
	def self.enum(attribute, *values)
		if self == RandTextCore::RuleVariant
			raise "cannot set enum attribute for class RuleVariant"
		end
		if self.initialized?
			raise "rule #{self.rule_name} has already been initialized"
		end
		@attr_types ||= {}
		begin
			attribute = attribute.to_sym
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{attribute.class} into Symbol"
		end
		if [:id, :weight].include?(attribute)
			raise ArgumentError, "attribute #{attribute} cannot be an enum"
		end
		if @attr_types[attribute]
			raise "type already set for attribute #{attribute}"
		end
		@attr_types[attribute] = RandTextCore::DataTypes::Enum[*values]
		nil
	end

	# Declares that a variant of current rule is associated with several
	# variants of a given rule.
	# For a rule +TargetRule+, this will creates a private method
	# +default_target_rule+ returning an array of all the associated variants,
	# and an overridable public method +target_rule+ picking one of the variants
	# randomly. 
	# @param [#to_sym] target name of the associated rule
	# @param [#to_sym] attribute attribute of target referencing current rule
	# @param [:required, :optional] type +:optional+ allows for a variant to not
	#  have any associated variant in the target rule; in this case the
	#  dynamically defined public method will return +nil+
	# @return [nil]
	# @raise [TypeError] no implicit conversion for arguments into Symbol
	# @raise [ArgumentError] wrong value for +type+
	# @raise [RuntimeError] called on RuleVariant, or relation already set for
	#  target rule
	def self.has_many(target, attribute, type)
		if self == RandTextCore::RuleVariant
			raise "cannot set assosiation with class RuleVariant"
		end
		if self.initialized?
			raise "rule #{self.rule_name} has already been initialized"
		end
		begin
			target = target.to_sym
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{target.class} into Symbol"
		end
		begin
			attribute = attribute.to_sym
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{attribute.class} into Symbol"
		end
		unless [:required, :optional].include?(type)
			raise ArgumentError,
				"wrong type argument (expected :required or :optional, given " +
				type.to_s
		end
		@relations ||= {}
		if @relations[target]
			raise "relation already set with rule #{target}"
		end
		@relations[target] = {
			attribute: attribute,
			type: type
		}.freeze
		nil
	end

	# Set attribute types from given CSV header.
	# @param [Array<Symbol>] header CSV header (names of attributes)
	# @return [nil]
	# @raise [ArgumentError] not a valid attribute name
	# @raise [RuntimeError] no +id+ attribute found
	def self.headers=(header)
		@attr_types ||= {}
		header.each do |attribute|
			if attribute == :id
				@attr_types[attribute] =
					RandTextCore::DataTypes::Identifier.type
			elsif attribute == :weight
				@attr_types[attribute] = RandTextCore::DataTypes::Weight.type
				define_method(:default_weight) do
					RandTextCore::DataTypes::Weight.type.convert(
						@attributes[:weight],
						self.symbol_table
					)
				end
			else
				@attr_types[attribute] ||= 
					RandTextCore::DataTypes::StringAttribute.type
				type = @attr_types[attribute]
				sym = "default_#{attribute}"
				define_method(sym) do
					type.convert(@attributes[attribute], self.symbol_table)
				end
				private(sym)
				unless method_defined?(attribute)
					define_method(attribute) { self.send(sym) }
				end
			end
		end
		unless @attr_types[:id]
			raise "no attribute id found for rule #{self.rule_name}"
		end
		unless @attr_types[:weight]
			define_method(:default_weight) { 1 }
		end
		private(:default_weight)
		@attr_types.freeze
		nil
	end
	private_class_method :headers=

	# Returns a hash map associating attributes' names to their type.
	# @return [Hash{Symbol => DataType}] hash map associating attributes'
	#  names to their type
	# @raise [RuntimeError] called on RuleVariant, or attributes' types not yet
	#  set
	def self.attr_types
		self.require_initialized_rule
		@attr_types
	end

	# Add a row from the file.
	# @param [CSV::Row] row row to add
	# @return [self]
	# @raise [ArgumentError] invalid row or attributes
	# @raise [RuntimeError] duplicated id
	def self.add_entity(row)
		unless row.size == @attr_types.size
			raise ArgumentError, "wrong number of arguments in tuple #{row} " +
				"(given #{row.size}, expected #{@attr_types.size})"
		end
		entity = new(row)
		if @variants[entity.id]
			raise "id #{entity.id} duplicated in rule #{self.rule_name}"
		end
		@variants[entity.id] = entity
		self
	end
	private_class_method :add_entity

	# Import entities from CSV file, then freeze the class.
	# The class is now considered initialized in regard of
	# {RuleVariant#initialized?}.
	# @return [SymbolTable] symbol table associated to the core
	# @return [self]
	# @raise [RuntimeError] wrong number of fields in the row, or error in a row
	def self.init_rule(symbol_table)
		@symbol_table = symbol_table
		@variants = {}
		CSV.read(
			self.file,
			nil_value: '',
			headers: true,
			return_headers: true,
			header_converters: ->(str) do
				unless str.lower_snake_case?
					raise "invalid name for attribute \"#{str}\""
				end
				str.to_sym
			end
		).each_with_index do |row, i|
			if i == 0
				self.headers = row.headers
			else
				begin
					self.add_entity(row)
#				rescue ArgumentError => e
#					raise e.message
				end
			end
		end
		@initialized = true
		@relations.freeze
		self
	end
	private_class_method :init_rule

	# Tests whether the class is initialized or not, i.e. all its data have been
	# imported, and no more modification can be done.
	# @return [true, false] +true+ if the class has been initialized, +false+
	#  otherwise
	def self.initialized?
		@initialized || false
	end

	# Verifies the rule, i.e. searches for and lists anomalies in the variants.
	# @return [Array<Message>] generated messages
	# @raise [RuntimeError] called on RuleVariant, or class not initialized
	def self.verify
		messages = []
		self.attr_types.each do |attribute, type|
			messages += type.verify_self(
				self.symbol_table,
				self,
				attribute
			)
		end
		self.each { |variant| messages += variant.send(:verify) }
		messages
	end
	private_class_method :verify

	# Returns variant of given id.
	# @param [#to_int] id id of the variant 
	# @return [RuleVariant, nil] variant of given id, or +nil+ if no variant
	#  has been found
	# @raise [TypeError] no implicit conversion of +id+ into Integer
	# @raise [RuntimeError] called on RuleVariant or class not initialized
	def self.[](id)
		self.require_initialized_rule
		begin
			@variants[id.to_int]
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{id.class} into Integer"
		end
	end

	# Executes given block for each variant of the rule.
	# If no block is given, return an enumerator on the variants of the rule.
	# @yield [variant] block to execute on each variant
	# @return [Enumerator<RuleVariant>, self] +self+ if a block is given, or an
	#  enumerator on the variants of the rule
	# @raise [RuntimeError] called on RuleVariant or class not initialized
	def self.each
		self.require_initialized_rule
		if block_given?
			@variants.values.each { |variant| yield variant }
			self
		else
			@variants.values.to_enum
		end
	end

	# Decides whether a given variant must be picked in a random picking
	# according to given arguments.
	# Returns true for all variants by default.
	# @param [RuleVariant] variant variant to test
	# @param [Array<String>] args arguments (never empty when called from an
	#  expansion node, if no arguments are explecitly given, an empty string is
	#  given by default; can be empty if called from ruby code)
	# @return [true, false] +true+ if the variant must be picked, +false+
	#  otherwise
	def self.pick?(variant, *args)
		true
	end

	# Pick a variant of the rule randomly, using a weighted random choice.
	# The pickable variants are definad by {RuleVariant#pick?} using given
	# arguments.
	# @param [Array<String>] args arguments (never empty when called from an
	#  expansion node, if no arguments are explecitly given, an empty string is
	#  given by default; can be empty if called from ruby code)
	# @return [RuleVariant, nil] a randomly chosen variant, or +nil+ if no
	#  variant satisfies the arguments
	def self.pick(*args)
		ary = self.select { |variant| self.pick?(variant, *args) }
		class << ary
			include Enumerable
		end
		ary.pick
	end

	# Returns the number of variants of the rule.
	# @returns [Integer] number of variants of the rule
	# @raise [RuntimeError] called on RuleVariant, or class not initialized
	def self.size
		self.require_initialized_rule
		return @variants.size
	end

	# Returns the symbol table of this core.
	# @return [SymbolTable] symbol table used by the core
	# @raise [RuntimeError] called on RuleVariant, or rule not initialized
	def self.symbol_table
		self.require_initialized_rule
		@symbol_table
	end

	# Calls {RuleVariant#init} on each variant.
	# @return [self]
	# @raise [RuntimeError] called on RuleVariant, or rule not initialized
	def self.reset
		self.require_initialized_rule
		@variants.each_value { |variant| variant.init }
		self
	end

	# Creates a snapshot of the current state of the rule, i.e. the current
	# state of its variants' instance variables.
	def self.current_state
		@variants.keys.each_with_object({}) do |id, hash|
			hash[id] = @variants[id].send(:current_state)
		end
	end
	private_class_method :current_state

	# Restore the rule's state.
	def self.restore(state)
		state.each do |id, state|
			@variants[id].send(:restore, state)
		end
		self
	end
	private_class_method :restore
	
	# Raises RuntimeError if current class is RuleVariant, or if the rule is
	# not initiaziled.
	def self.require_initialized_rule
		if self == RandTextCore::RuleVariant
			raise "class RuleVariant has no data"
		end
		unless self.initialized?
			raise "class #{self} not initialized"
		end
	end
	private_class_method :require_initialized_rule

	private_class_method :new

	class << self
		include Enumerable

		alias :length :size
	end

	################################
	# INSTANCE METHODS FOR VARIANT #
	################################

	# @ attributes	=> [Hash{Symbol=>Integer, String}] hash map associating
	#                  attribute names to their value: String for strings and
	#                  Integer for id, reference and weight

	# Creates a new variant from given row.
	# @note It is strongly recommended to not override this method. If you want
	#  to add a special behaviour at initialization, override
	#  {RuleVariant#init}.
	# @param [CSV::Row] row row from the CSV file.
	# @param [Hash{Symbol => DataType}] types hash map associating
	#  attribute names to their types
	# @raise [ArgumentError] invalid row
	def initialize(row)
		@attributes = {}
		row.headers.each do |attribute|
			@attributes[attribute] = row[attribute]
		end
		@attributes.freeze
		init
	end

	# Returns the variant's id.
	# @note It is strongly recommended to not override this method, as the
	#  +id+ attribute must always return the id as it is in the table.
	# @return [Integer] variant's id, as in the CSV file
	def id
		RandTextCore::DataTypes::Identifier.type.convert(@attributes[:id], nil)
	end

	# Returns the variant's weight.
	# Returns +1+ if no weight has been defined.
	# @note If you want to override this method to calculate the weight
	#  dynamicly, it is recommended to call the private method :default_weight:
	#  if you want to get the weight value as it is written in the table. Using
	#  +super+ is also possible for this particular attribute, but not for
	#  dynamicly added attributes from the CSV file.
	# @return [Integer] weight of the variant for random picking
	def weight
		self.default_weight
	end

	# Returns the symbol table for this core.
	# @return [SymbolTable] symbol table of the core
	def symbol_table
		self.rule.symbol_table
	end

	alias :rule :class

	# Override this method to add a specific behaviour when initializing the
	# variant or resetting the symbol table.
	# Does nothing by default.
	def init
	end

	# Returns itself, as variants cannot be cloned.
	# @return [self]
	def clone
		self
	end

	alias :dup :clone

	# Returns a human-readable representation of the variant, listing its
	# attributes.
	# The attributes are printed as they are stored, ignoring their redefinition
	# by the user.
	# @return [String] representation of the variants and its attributes
	# @example
	#  # my_rule.csv:
	#  # id,value,weight
	#  # 1,aaa,10
	#  # 2,bbb,20
	#  
	#  class MyRule < RandTextCore::RuleVariant
	#      self.file = 'my_rule.csv'
	#  end
	#  
	#  MyRule[1].inspect	#=> '#<MyRule id=1, value="aaa", weight=10>'
	def inspect
		"#<#{self.class.rule_name} #{@attributes.map do |k, v|
			"#{k}=#{self.rule.attr_types[k].inspect_value(v)}"
		end.join(', ')}>"
	end

	alias :to_s :inspect

	private

	# Verifies the variant, i.e. searches for and lists anomalies.
	# @return [Array<Message>] generated messages
	def verify
		@attributes.keys.inject([]) do |messages, attribute|
			messages + self.rule.attr_types[attribute].verify(
				@attributes[attribute],
				self.symbol_table,
				self.rule,
				self,
				attribute
			)
		end
	end

	# Returns current state of the variant (instance variables).
	def current_state
		self.instance_variables.each_with_object({}) do |symbol, hash|
			hash[symbol] = self.instance_variable_get(symbol)
		end
	end

	# Restore a previous state of the variant.
	def restore(state)
		state.each do |symbol, value|
			self.instance_variable_set(symbol, value)
		end
		self.instance_variables.each do |symbol|
			unless state.key?(symbol)
				self.remove_instance_variable(symbol)
			end
		end
		self
	end

end