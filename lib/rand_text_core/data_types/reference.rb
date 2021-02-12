require_relative '../data_types'
require_relative 'integer_type'

# Type for an attribute referencing another rule.
#
# @author AlexieVQ
class RandTextCore::DataTypes::Reference < RandTextCore::DataTypes::IntegerType

	public_class_method :new

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

	# Testing if another object is a Reference type referencing the same
	# rule with the same type of requirement.
	# @param [Object] o the object to compare
	# @return [true, false] +true+ if +o+ is a Reference type referencing
	#  the same rule with the same type of requirement, +false+ otherwise
	def ==(o)
		o.kind_of?(RandTextCore::DataTypes::Reference) &&
			o.target == self.target &&
			o.type == self.type
	end

	# Returns a string in the format +"Reference<rule_name, type>"+.
	# @return [String] string representing the type
	# @example
	#  p RandTextCore::RuleVariant::Reference[:MyRule, :optional]
	#  # Reference<MyRule, optional>
	def inspect
		super + "<#{target}, #{type}>"
	end

	alias :to_s :inspect     

	# Inspect given value.
	# @param [String] value value to inspect
	# @return [String] inspected value
	def inspect_value(value)
		"#{self.target}[#{value.to_i}]"
	end

	# Verify itself for anomalies.
	# @param [SymbolTable] symbol_table symbol table used
	# @param [Class, nil] rule rule caling this method
	# @param [Symbol, nil] attribute concerned attribute
	# @return [Array<Message>] generated messages
	def verify_self(symbol_table, rule = nil, attribute = nil)
		unless symbol_table.has_rule?(self.target)
			[RandTextCore::ErrorMessage.new(
				"no rule named #{self.target}",
				rule,
				nil,
				attribute
			)]
		else
			[]
		end
	end

	# Verifies is given value does represent a valid reference to target.
	# @param [String] value value to verify
	# @param [SymbolTable] symbol_table symbol table used
	# @param [Array<Message>] messages message list
	# @param [Class, nil] rule rule calling this method
	# @param [RuleVariant, nil] variant variant calling this method
	# @param [Symbol, nil] attribute concerned attribute
	# @return [Array<Message>] generated messages
	def verify(value,
			   symbol_table,
			   rule = nil,
			   variant = nil,
			   attribute = nil)
		messages = super(value, symbol_table, rule, variant, attribute)
		if self.type == :required && value.to_i == 0
			messages << RandTextCore::ErrorMessage.new(
				"required reference to rule #{self.target} cannot be null",
				rule,
				variant,
				attribute
			)
		elsif value.to_i != 0 &&
			symbol_table.has_rule?(self.target) &&
			!symbol_table.rule(self.target)[value.to_i]
			messages << RandTextCore::ErrorMessage.new(
				"no variant of id #{value.to_i} in rule #{self.target}",
				rule,
				variant,
				attribute
			)
		end
		messages
	end

	# Returns referenced rule variant, or +nil+ for a null reference.
	# @param [String] value value to convert, considered valid in regard of
	#  {DataType#verify}
	# @param [SymbolTable] symbol_table symbol table used
	# @return [RuleVariant] referenced rule variant
	def convert(value, symbol_table)
		symbol_table.rule(self.target)[value.to_i]
	end
	
end