require_relative '../rand_text_core'

# Module containing refinements for Ruby classes.
#
# @author AlexieVQ
module RandTextCore::Refinements

	refine String do

		# Tests if the string is in +lower_snake_case+, i.e. first character is
		# a lower case ASCII letter and following characters (if they exist) are
		# lower case ASCII letters, digits or underscore.
		# @return [true, false] +true+ if the string is in +lower_snake_case+,
		#  +false+ otherwise
		def lower_snake_case?
			self.match?(/^[a-z][a-z0-9_]*$/)
		end

		# Tests if the string is in +UpperCamelCase+, i.e. first character is a
		# capital ASCII letter, and following characters (if they exist) are
		# ASCII letters (whatever case) or digits.
		# @return [true, false] +true+ if the string is in +UpperCamelCase+,
		#  +false+ otherwise
		def upper_camel_case?
			self.match?(/^[A-Z][A-Za-z0-9]*$/)
		end

		# Returns a +UpperCamelCase+ string from a +lower_snake_case+ one.
		# @return [String] string in +UpperCamelCase+
		# @raise [RuntimeError] string is not in +lower_snake_case+
		def camelize
			unless self.lower_snake_case?
				raise "#{self.inspect} is not a lower_snake_case string"
			end
			self.split('_').map { |word| word.capitalize }.join('')
		end

		# Tests if the string represents a valid name for a CSV file.
		# A valid name is a name in the format +lower_snake_case.csv+.
		# @returns [true, false] +true+ if the name is valid, +false+ otherwise
		def valid_csv_file_name?
			parts = self.split('.')
			parts.length == 2 && parts[0].lower_snake_case? && parts[1] == 'csv'
		end

	end

end