require_relative '../data_types'

# Type for an attribute with string values.
#
# @author AlexieVQ
class RandTextCore::DataTypes::StringAttribute <
	RandTextCore::DataTypes::DataType

	# Returns an instance representing the StringAttribute type
	# @return [StringAttribute] instance representing the StringAttribute
	#  type
	def self.type
		@instance ||= self.new
		@instance
	end

end