require 'csv'
require_relative '../rand_text_core'
require_relative 'refinements/string'

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

	# Superclass for classes representing attribute types.
	class AttributeType
		private_class_method :new

		# Returns the name of the type
		# @return [String] name of the type
		def inspect
			self.class.name.split('::').last
		end

		alias :to_s :inspect

		# Converts given value into expected type (default, keep it as a
		# String).
		# @param [#to_str] value value to convert
		# @return [Object] converted value
		# @raise [TypeError] no implicit conversion of value into String
		# @raise [ArgumentError] invalid value
		def convert(value)
			begin
				value.to_str.freeze
			rescue NoMethodError
				raise TypeError,
					"no implicit conversion of #{value.class} into String"
			end
		end
	end

	# Type for the 'id' attribute.
	class Identifier < AttributeType
		# Returns an instance representing the Identifier type.
		# @return [Identifier] instance representing the type
		def self.type
			@instance ||= self.new
			@instance
		end

		# Converts given value into Integer.
		# @param [#to_str] value value to convert
		# @return [Integer] converted value
		# @raise [TypeError] no implicit conversion of value into String
		# @raise [ArgumentError] value does not represent a non-null integer
		def convert(value)
			int = super(value).to_i
			if int == 0
				raise ArgumentError,
					"wrong value for an id (expected non-null integer, given " +
					value.inspect
			end
			int
		end
	end

	# Type for the 'weight' attribute.
	class Weight < AttributeType
		# Returns an instance representing the Weight type.
		# @returns [Weight] instance representing the type
		def self.type
			@instance ||= self.new
			@instance
		end
		
		# Converts given value into Integer.
		# @param [#to_str] value value to convert
		# @return [Integer] converted value
		# @raise [TypeError] no implicit conversion of value into String
		# @raise [ArgumentError] no implicit conversion of +value+ into String
		def convert(value)
			super(value).to_i
		end
	end

	# Type for an attribute referencing another rule.
	class Reference < AttributeType
		# @see Reference#initialize
		def self.[](target, type)
			self.new(target, type)
		end

		# @return [Symbol] referenced rule
		attr_reader :target

		# @return [:required, :optional] type of the reference
		attr_reader :type

		# Creates a type for an attribute referencing given rule.
		# @param [#to_sym] target name of referenced rule
		# @param [:required, :optional] +:required+ for a required reference,
		#  +:optional+ for an optional one
		# @raise [TypeError] no implicit conversion of target into Symbol
		# @raise [ArgumentError] wrong type given
		def initialize(target, type)
			begin
				@target = target.to_sym
			rescue NoMethodError
				raise TypeError,
					"no implicit conversion of #{target.class} into Symbol"
			end
			unless [:required, :optional].include?(type)
				raise ArgumentError,
					"wrong reference type (:required or :optional expected, " +
					"#{type} given)"
			end
			@type = type
		end

		# Converts given value into an Integer.
		# Does not test if the variant of the target rule exists.
		# @param [#to_str] value value to convert
		# @return [Integer] converted value
		# @raise [TypeError] no implicit conversion of value into String
		# @raise [ArgumentError] null value for a required reference
		def convert(value)
			int = super(value).to_i
			if type == :required && int == 0
				raise ArgumentError,
					"wrong value for a required reference (expected non-null " +
					"integer, given #{value.inspect})"
			end
			int
		end

		# Testing if another object is a Reference type referencing the same
		# rule with the same type of requirement.
		# @param [Object] o the object to compare
		# @return [true, false] +true+ if +o+ is a Reference type referencing
		#  the same rule with the same type of requirement, +false+ otherwise
		def ==(o)
			o.kind_of?(Reference) &&
				o.target == self.target &&
				o.type == self.type
		end

		# Returns a string in the format +"Reference<rule_name, type>"+.
		# @return [String] string representing the type
		# @example
		#  p RandTextCore::RuleVariant::Reference[:my_rule, :optional]
		#  # Reference<my_rule, optional>
		def inspect
			super + "<#{target}, #{type}>"
		end

		alias :to_s :inspect
	end

	# Type for an attribute with string values.
	class StringAttribute < AttributeType
		# Returns an instance representing the StringAttribute type
		# @return [StringAttribute] instance representing the StringAttribute
		#  type
		def self.type
			@instance ||= self.new
			@instance
		end
	end

	# Type for an attribute with a set of accepted values.
	class Enum < AttributeType
		# @see Enum#initialize
		def self.[](*values)
			self.new(*values)
		end

		# @return [Array<Symbol>] set of accepted values (frozen)
		attr_reader :values

		# Creates a type for an attribute with a set of accepted values.
		# @param [Array<#to_sym>] values values accepted by the attribute
		# @raise [TypeError] no implicit conversion of value into Symbol
		def initialize(*values)
			@values = values.map do |value|
				begin
					value.to_sym
				rescue NoMethodError
					raise TypeError,
						"no implicit conversion of #{value.class} into Symbol"
				end
			end.uniq.sort.freeze
		end

		# Converts given value into expected Symbol.
		# @param [#to_str] value value to convert
		# @return [Symbol] converted value
		# @raise [TypeError] no implicit conversion of value into String
		# @raise [ArgumentError] non-accepted value
		def convert(value)
			str = super(value)
			unless values.any? { |accepted| accepted.id2name == str }
				raise ArgumentError,
					"wrong value for the enum type (expected #{values.map do |v|
						v.id2name.inspect
					end.join(', ')}, given #{value}"
			end
			str.to_sym
		end

		# Testing if another object is an Enum type with the same set of values.
		# @param [Object] o the object to compare
		# @return [true, false] +true+ if +o+ is an Enum type with the same set
		#  of referenced values, +false+ otherwise
		def ==(o)
			o.kind_of?(Enum) && o.values == self.values
		end

		# Returns a string in the format +"Enum<:value1, :value2, :value3>"+.
		# @return [String] a string representing the type and its accepted
		#  values
		def inspect
			super + "<#{self.values.map { |v| v.inspect }.join(', ')}>"
		end

		alias :to_s :inspect
	end

	###########################
	# CLASS METHOD FOR A RULE #
	###########################

	# Returns rule name, in +lower_snake_case+, as in file name.
	# @return [Symbol] rule name, in +lower_snake_case+, as in file name
	# @raise [RuntimeError] called on RuleVariant, or file path not set with
	#  {RuleVariant#file_path}
	# @example
	#  class MyRule < RandTextCore::RuleVariant
	#      file_path 'rules/my_rule.csv'
	#  end
	#  
	#  MyRule.rule_name	#=> :my_rule
	def self.rule_name
		if self == RandTextCore::RuleVariant
			raise "class RuleVariant does not represent any rule"
		end
		unless @rule_name
			raise "file path not set for class #{self}"
		end
		@rule_name
	end

	# Returns rule name, in +UpperCamelCase+, as in file name.
	# @return [Symbol] rule name, in +UpperCamelCase+, as in file name
	# @raise [RuntimeError] called on RuleVariant, or file path not set with
	#  {RuleVariant#file_path}
	# @example
	#  class MyRule < RandTextCore::RuleVariant
	#      file_path 'rules/my_rule.csv'
	#  end
	#  
	#  MyRule.picker_name	#=> :MyRule
	def self.picker_name
		if self == RandTextCore::RuleVariant
			raise "class RuleVariant does not represent any rule"
		end
		unless @picker_name
			raise "file path not set for class #{self}"
		end
		@picker_name
	end

	# Returns file path set with {RuleVariant#file_path}.
	# @return [String] file path (frozen)
	# @raise [RuntimeError] called on RuleVariant, or file path not set with
	#  {RuleVariant#file_path}
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
	# The attribute {RuleVariant#rule_name} and {RuleVariant#picker_name} are
	# inferred from the file name.
	# File name must be in the format +lower_snake_case.csv+.
	# @param [#to_str] path path to the CSV file, must end with .csv
	# @return [String] path to the CSV file (frozen)
	# @raise [TypeError] no implicit conversion of path into String
	# @raise [ArgumentError] given String does not represent a path to a CSV
	#  file
	# @raise [RuntimeError] called on RuleVariant, or called multiple time
	def self.file_path(path)
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
		@rule_name = file_name.split('.').first.to_sym
		@picker_name = @rule_name.to_s.camelize.to_sym
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
		@attr_types[attribute] = Reference[rule_name, type]
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
		@attr_types[attribute] = Enum[*values]
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
				@attr_types[attribute] = Identifier.type
				define_method(:default_id) { @attributes[:id] }
				private(:default_id)
				unless method_defined?(:id)
					define_method(:id) { self.send(:default_id) }
				end
			elsif attribute == :weight
				@attr_types[attribute] = Weight.type
				define_method(:default_weight) { @attributes[:weight] }
			elsif @attr_types[attribute].kind_of?(Reference)
				sym = "default_#{attribute}".to_sym
				define_method(sym) do
					id = @attributes[attribute]
					if id == 0
						nil
					else
						self.rule(attribute)[@attributes[attribute]]
					end
				end
				private(sym)
				unless method_defined?(attribute)
					define_method(attribute) { self.send(sym) }
				end
			else
				@attr_types[attribute] ||= StringAttribute.type
				sym = "default_#{attribute}"
				define_method(sym) { @attributes[attribute] }
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
		unless method_defined?(:weight)
			define_method(:weight) { self.send(:default_weight) }
		end
		@attr_types.freeze
		nil
	end
	private_class_method :headers=

	# Returns a hash map associating attributes' names to their type.
	# @return [Hash{Symbol=>AttributeType}] hash map associating attributes'
	#  names to their type
	# @raise [RuntimeError] called on RuleVariant, or attributes' types not yet
	#  set
	def self.attr_types
		if self == RandTextCore::RuleVariant
			raise "class RuleVariant has no attributes"
		end
		unless self.initialized?
			name = @rule_name ? "rule #{@rule_name}" : "class #{self}"
			raise "attributes' types not yet set for #{name}"
		end
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
		entity = new(row, @attr_types)
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
	# @return [self]
	# @raise [RuntimeError] wrong number of fields in the row, or error in a row
	def self.import
		@variants = {}
		CSV.read(
			self.file,
			nil_value: '',
			headers: true,
			return_headers: true,
			header_converters: ->(str) do
				unless str.lower_snake_case?
					raise "invalid name for attribute\"#{str}\""
				end
				str.to_sym
			end
		).each_with_index do |row, i|
			if i == 0
				self.headers = row.headers
			else
				begin
					self.add_entity(row)
				rescue ArgumentError => e
					raise e.message
				end
			end
		end
		@initialized = true
		self.freeze
		self
	end
	private_class_method :import

	# Tests whether the class is initialized or not, i.e. all its data have been
	# imported, and no more modification can be done.
	# @return [true, false] +true+ if the class has been initialized, +false+
	#  otherwise
	def self.initialized?
		@initialized || false
	end

	# Prevents further modifications to the class.
	# @return [self]
	def self.freeze
		super
		@variants.freeze
		@attr_types.freeze
		@references.freeze
		self
	end

	# Returns variant of given id.
	# @param [#to_int] id id of the variant 
	# @return [RuleVariant] variant of given id
	# @raise [KeyError] no variant of given id has been found
	# @raise [TypeError] no implicit conversion of +id+ into Integer
	# @raise [RuntimeError] called on RuleVariant or class not initialized
	def self.[](id)
		if self == RandTextCore::RuleVariant
			raise "class RuleVariant has no data"
		end
		unless self.initialized?
			raise "class #{self} not initialized"
		end
		begin
			@variants.fetch(id.to_int)
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
		if self == RandTextCore::RuleVariant
			raise "class RuleVariant has no data"
		end
		unless self.initialized?
			raise "class #{self} not initialized"
		end
		if block_given?
			@variants.values.each { |variant| yield variant }
			self
		else
			@variants.values.to_enum
		end
	end

	# Returns the number of variants of the rule.
	# @returns [Integer] number of variants of the rule
	# @raise [RuntimeError] called on RuleVariant, or class not initialized
	def self.size
		if self == RandTextCore::RuleVariant
			raise "class RuleVariant has no data"
		end
		unless self.initialized?
			raise "class #{self} not initialized"
		end
		return @variants.size
	end

	# Returns rule of given name.
	# @param [#to_sym] name name of the rule (returned by
	#  {RuleVariant#rule_name})
	# @return [Class] class extending RuleVariant representing the rule
	# @raise [TypeError] no implicit conversion of name into Symbol
	# @raise [ArgumentError] no rule of given name in the system
	def self.rule(name)
		begin
			name = name.to_sym
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{name.class} into Symbol"
		end
		rule = @rules.find { |rule| rule.rule_name == name }
		unless rule
			raise ArgumentError, "no rule named #{name} in the system"
		end
		rule
	end

	private_class_method :new

	class << self
		include Enumerable

		alias :length :size

		private

		# Set the list of rules in the system
		# @return [Array<Class>] list of classes representing rules
		attr_writer :rules
	end

	################################
	# INSTANCE METHODS FOR VARIANT #
	################################

	# @ attributes	=> [Hash{Symbol=>Integer, String}] hash map associating
	#                  attribute names to their value: String for strings and
	#                  Integer for id, reference and weight

	# Creates a new variant from given row.
	# @param [CSV::Row] row row from the CSV file.
	# @param [Hash{Symbol=>AttributeType}] types hash map associating attribute
	#  names to their types
	# @raise [ArgumentError] invalid row
	def initialize(row, types)
		@attributes = {}
		row.headers.each do |attribute|
			begin
				@attributes[attribute] =
					types[attribute].convert(row[attribute])
			rescue => e
				msg = if @attributes[:id]
					"variant #{@attributes[:id]}, "
				else
					""
				end + "attribute #{attribute}: #{e.message}"
				raise ArgumentError, msg
			end
		end
		@attributes.freeze
		self.freeze
	end

	# Returns rule of given name.
	# @param [#to_sym] name name of the rule
	# @return [Class] class extending RuleVariant representing the rule
	# @raise [TypeError] no implicit conversion of name into Symbol
	# @raise [ArgumentError] no rule of given name in the system
	def rule(name)
		begin
			name = name.to_sym
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{name.class} into Symbol"
		end
		self.class.rule(name)
	end

	# Returns a human-readable representation of the variant, listing its
	# attributes.
	# @return [String] representation of the variants and its attributes
	# @example
	#  # my_rule.csv:
	#  # id,value,weight
	#  # 1,aaa,10
	#  # 2,bbb,20
	#  
	#  class MyRule < RandTextCore::RuleVariant
	#      file_path 'my_rule.csv'
	#  end
	#  
	#  MyRule[1].inspect	#=> '#<my_rule id=1, value="aaa", weight=10>'
	def inspect
		"#<#{self.class.rule_name} #{@attributes.keys.map do |k|
			"#{k}=#{self.send(k.to_sym).inspect}"
		end.join(', ')}>"
	end

	alias :to_s :inspect

end