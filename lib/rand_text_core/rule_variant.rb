require 'csv'
require_relative '../rand_text_core'

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

	###########################
	# CLASS METHOD FOR A RULE #
	###########################

	class << self
		include Enumerable

		private

		# Set the list of rules in the system
		# @return [Array<Class>] list of classes representing rules
		attr_writer :rules
	end

	# Returns rule name, in +lower_snake_case+, as in file name.
	# @return [String] rule name, in +lower_snake_case+, as in file name
	#  (frozen)
	# @raise [RuntimeError] called on RuleVariant, or file path not set with
	#  {RuleVariant#file_path}
	# @example
	#  class MyRule < RandTextCore::RuleVariant
	#      file_path 'rules/my_rule.csv'
	#  end
	#  
	#  MyRule.rule_name	#=> 'my_rule'
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
	# @return [String] rule name, in +UpperCamelCase+, as in file name
	#  (frozen)
	# @raise [RuntimeError] called on RuleVariant, or file path not set with
	#  {RuleVariant#file_path}
	# @example
	#  class MyRule < RandTextCore::RuleVariant
	#      file_path 'rules/my_rule.csv'
	#  end
	#  
	#  MyRule.picker_name	#=> 'MyRule'
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
		@rule_name = path.split('/').last.gsub(/\.csv$/,'').freeze
		@picker_name = @rule_name.split('_').map do |word|
			word.capitalize
		end.join('').freeze
		@file = path.freeze
	end

	# Declares that given attribute is a reference to rule +rule_name+'s id.
	# @param [#to_str] attribute attribute from current rule (must only contain
	#  non-zero integers)
	# @param [#to_str] rule_name name of the rule to reference (returned by 
	#  {RuleVariant#rule_name})
	# @return [nil]
	# @raise [TypeError] no implicit conversion for arguments into String
	# @raise [RuntimeError] called on RuleVariant
	def self.reference(attribute, rule_name)
		if self == RandTextCore::RuleVariant
			raise "cannot set reference for class RuleVariant"
		end
		@references ||= {}
		begin
			attribute = attribute.to_str.freeze
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{attribute.class} into String"
		end
		begin
			rule_name = rule_name.to_str.freeze
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{rule_name.class} into String"
		end
		@references[attribute] = rule_name
		nil
	end

	# Returns a hash map associating attribute names to the names of the rules
	# they reference.
	# @return [Hash{String=>String}] hash map associating attribute names to the
	#  names of the rules they reference (frozen)
	# @raise [RuntimeError] called on RuleVariant
	def self.references
		if self == RandTextCore::RuleVariant
			raise "class RuleVariant has no references"
		end
		@references ||= {}
		return self.initialized? ? @references : @references.clone.freeze
	end

	# Set +attr_types+ from given CSV header.
	# @param [Array<String>] header CSV header (names of attributes)
	# @return [nil]
	# @raise [RuntimeError] no id attribute found
	def self.attr_types=(header)
		@attr_types = {}
		header.each do |attribute|
			if attribute == 'id'
				@attr_types[attribute] = :id
				define_method(:default_id) { @attributes['id'] }
				private(:default_id)
				unless method_defined?(:id)
					define_method(:id) { self.send(:default_id) }
				end
			elsif attribute == 'weight'
				@attr_types[attribute] = :weight
				define_method(:default_weight) { @attributes['weight'] }
			elsif references.keys.include?(attribute)
				@attr_types[attribute] = :reference
				sym = "default_#{attribute}".to_sym
				define_method(sym) do
					self.rule(attribute)[@attributes[attribute]]
				end
				private(sym)
				unless method_defined?(attribute.to_sym)
					define_method(attribute.to_sym) { self.send(sym) }
				end
			else
				@attr_types[attribute] = :string
				sym = "default_#{attribute}"
				define_method(sym) { @attributes[attribute] }
				private(sym)
				unless method_defined?(attribute.to_sym)
					define_method(attribute.to_sym) { self.send(sym) }
				end
			end
		end
		unless @attr_types['id']
			raise "no attribute id found for rule #{self.rule_name}"
		end
		unless @attr_types['weight']
			define_method(:default_weight) { 1 }
		end
		private(:default_weight)
		unless method_defined?(:weight)
			define_method(:weight) { self.send(:default_weight) }
		end
		nil
	end
	private_class_method :attr_types=

	# Returns a hash map associating attributes' names to their types:
	#  [+:id+] the variant's id
	#  [+:weight+] the variant's weight
	#  [+:reference+] a reference to a variant of another rule
	#  [+:string+] a string value
	# @return [Hash{String=>:id,:weight,:reference,:string}] hash map
	#  associating attributes' names to their type
	# @raise [RuntimeError] called on RuleVariant, or attributes' types not yet
	#  set
	def self.attr_types
		if self == RandTextCore::RuleVariant
			raise "class RuleVariant has no attributes"
		end
		unless @attr_types
			name = @rule_name ? "rule #{@rule_name}" : "class #{self}"
			raise "attributes' types not yet set for #{name}"
		end
		@attr_types
	end
	private_class_method :attr_types

	# Add a row from the file.
	# @param [CSV::Row] row row to add
	# @return [self]
	# @raise [ArgumentError] invalid attributes
	# @raise [RuntimeError] duplicated id
	def self.add_entity(row)
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
	# @return [self]
	def self.import
		@variants = {}
		@references ||= {}
		CSV.read(self.file, col_sep: ';', headers: true).each do |row|
			self.attr_types = row.headers unless @attr_types
			self.add_entity(row)
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
	def self.[](id)
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

	# Returns rule of given name.
	# @param [#to_str] name name of the rule (returned by
	#  {RuleVariant#rule_name})
	# @return [Class] class extending RuleVariant representing the rule
	# @raise [TypeError] no implicit conversion of name into String
	# @raise [ArgumentError] no rule of given name in the system
	def self.rule(name)
		begin
			name = name.to_str
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{name.class} into String"
		end
		rule = @rules.find { |rule| rule.rule_name == name }
		unless rule
			raise ArgumentError, "no rule named #{name} in the system"
		end
		rule
	end

	private_class_method :new

	################################
	# INSTANCE METHODS FOR VARIANT #
	################################

	# @ attributes	=> [Hash{String=>Integer, String}] hash map associating
	#                  attribute names to their value: String for strings and
	#                  Integer for id, reference and weight

	# Creates a new variant from given row.
	# @param [CSV::Row] row row from the CSV file.
	# @raise [ArgumentError] invalid row
	def initialize(row)
		types = self.class.send(:attr_types)
		unless row.length == types.length
			raise ArgumentError,
				"wrong number of attributes (given #{row.length}, " +
				"expected #{types.length})"
		end
		@attributes = {}
		row.headers.each do |attribute|
			if [:id, :reference, :weight].include?(types[attribute])
				@attributes[attribute] = row[attribute].to_i
				if [:id, :reference].include?(types[attribute]) &&
					@attributes[attribute] == 0
					raise ArgumentError, "entity id or reference can't be 0"
				end
			elsif types[attribute] == :string
				@attributes[attribute] = row[attribute].freeze
			else
				raise "unknown attribute #{attribute} for rule " +
					self.class.rule_name
			end
		end
		@attributes.freeze
		self.freeze
	end

	# Returns rule of given name.
	# @param [#to_str] name name of the rule
	# @return [Class] class extending RuleVariant representing the rule
	# @raise [TypeError] no implicit conversion of name into String
	# @raise [ArgumentError] no rule of given name in the system
	def rule(name)
		begin
			name = name.to_str
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{name.class} into String"
		end
		self.class.rule(name)
	end

	# Returns a human-readable representation of the variant, listing its
	# attributes.
	# @return [String] representation of the variants and its attributes
	# @example
	#  # my_rule.csv:
	#  # id;value;weight
	#  # 1;aaa;10
	#  # 2;bbb;20
	#  
	#  class MyRule < RandTextCore::RuleVariant
	#      file_path 'my_rule.csv'
	#  end
	#  
	#  MyRule[1].inspect	#=> '#<my_rule "id":1 "value":"aaa" "weight":10>'
	def inspect
		"#<#{self.class.rule_name} #{@attributes.keys.map do |k|
			"#{k.inspect}:#{self.send(k.to_sym).inspect}"
		end.join(' ')}>"
	end

end