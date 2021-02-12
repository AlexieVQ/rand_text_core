require_relative '../data_types'

# Type for an attribute with a set of accepted values.
#
# @author AlexieVQ
class RandTextCore::DataTypes::Enum < RandTextCore::DataTypes::DataType

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

	# Testing if another object is an Enum type with the same set of values.
	# @param [Object] o the object to compare
	# @return [true, false] +true+ if +o+ is an Enum type with the same set
	#  of referenced values, +false+ otherwise
	def ==(o)
		o.kind_of?(RandTextCore::DataTypes::Enum) && o.values == self.values
	end

	# Returns a string in the format +"Enum<:value1, :value2, :value3>"+.
	# @return [String] a string representing the type and its accepted
	#  values
	def inspect
		super + "<#{self.values.map { |v| v.inspect }.join(', ')}>"
	end

	alias :to_s :inspect

	# Inspect given value.
	# @param [String] value value to inspect
	# @return [String] inspected value
	def inspect_value(value)
		":#{value}"
	end

	# Verifies that given value is accepted.
	# @param [String] value value to verify
	# @param [SymbolTable] symbol_table symbol table used
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
		unless self.values.any? { |v| v.id2name == value }
			messages << RandTextCore::ErrorMessage.new(
				"invalid value \"#{value}\" (expected " +
					"#{self.values.map { |v| v.id2name }.join(', ')})",
				rule,
				variant,
				attribute
			)
		end
		messages
	end

	# Converts given value into expected type (default, keep it as a
	# String).
	# @param [String] value value to convert, considered valid in regard of
	#  {DataType#verify}
	# @param [SymbolTable] symbol_table symbol table used
	# @return [Object] converted value
	def convert(value, symbol_table)
		value.to_sym
	end
	
end