require_relative '../data_types'
require_relative 'integer_type'

# Type for the 'weight' attribute.
#
# @author AlexieVQ
class RandTextCore::DataTypes::Weight < RandTextCore::DataTypes::IntegerType

	# Returns an instance representing the Weight type.
	# @returns [Weight] instance representing the type
	def self.type
		@instance ||= self.new
		@instance
	end
	
end