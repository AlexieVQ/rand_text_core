require_relative '../data_types'
require_relative 'integer_type'

# Type for the 'id' attribute.
#
# @author AlexieVQ
class RandTextCore::DataTypes::Identifier < RandTextCore::DataTypes::IntegerType

	# Returns an instance representing the Identifier type.
	# @return [Identifier] instance representing the type
	def self.type
		@instance ||= self.new
		@instance
	end

	# Verify is given value does represent a valid id.
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
		if value.to_i == 0
			messages << RandTextCore::ErrorMessage.new(
				"id cannot be null",
				rule,
				variant,
				attribute
			)
		end
		messages
	end

end