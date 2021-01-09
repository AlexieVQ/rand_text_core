require_relative '../rand_text_core'

# Module storing classes representing data types for the attributes.
#
# @author AlexieVQ
module RandTextCore::DataTypes

	# Superclass for classes representing attribute types.
	#
	# @author AlexieVQ
	class DataType

		private_class_method :new

		# Returns the name of the type
		# @return [String] name of the type
		def inspect
			self.class.name.split('::').last
		end

		alias :to_s :inspect

		# Inspect given value.
		# @param [String] value value to inspect
		# @return [String] inspected value
		def inspect_value(value)
			value.inspect
		end

		# Verify itself for anomalies.
		# @param [SymbolTable] symbol_table symbol table used
		# @param [Class, nil] rule rule calling this method
		# @param [Symbol, nil] attribute concerned attribute
		# @return [Array<Message>] generated messages
		def verify_self(symbol_table, rule = nil, attribute = nil)
			[]
		end

		# Verify given value for anomalies.
		# @param [String] value value to verify
		# @param [SymbolTable] symbol_table symbol table used
		# @param [Class, nil] rule rule calling this method
		# @param [RuleVariant, nil] variant variant calling this method
		# @param [Symbol, nil] attribute concerned attribute
		# @return [Array<Message>] generated messages
		def verify(value,
					symbol_table,
					messages,
					rule = nil,
					variant = nil,
					attribute = nil)
			if value == nil
				[RandTextCore::ErrorMessage.new(
					"attribute not defined",
					rule,
					variant,
					attribute
				)]
			else
				[]
			end
		end

		# Converts given value into expected type (default, keep it as a
		# String).
		# @param [String] value value to convert, considered valid in regard of
		#  {DataType#verify}
		# @param [SymbolTable] symbol_table symbol table used
		# @return [Object] converted value
		def convert(value, symbol_table)
			value
		end
		
	end

end

require_relative 'data_types/identifier'
require_relative 'data_types/weight'
require_relative 'data_types/reference'
require_relative 'data_types/string_attribute'
require_relative 'data_types/enum'