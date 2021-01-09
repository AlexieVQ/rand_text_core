require_relative '../data_types'

# Super type for types storing integer values.
#
# @author AlexieVQ
class RandTextCore::DataTypes::IntegerType < RandTextCore::DataTypes::DataType

	# Inspect given value.
	# @param [String] value value to inspect
	# @return [String] inspected value
	def inspect_value(value)
		value.to_i.inspect
	end

	# Verify is given value does represent a valid integer.
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
		unless value.match?(/\A\s*\d+\s*\z/)
			messages << RandTextCore::WarningMessage.new(
				"\"#{value}\" is confusing for an integer (#{value.to_i} " +
					"infered)",
				rule,
				variant,
				attribute
			)
		end
		messages
	end

	# Converts given value into Integer.
	# @param [String] value value to convert, considered valid in regard of
	#  {DataType#verify}
	# @param [SymbolTable] symbol_table symbol table used
	# @return [Integer] converted value
	def convert(value, symbol_table)
		value.to_i
	end

end