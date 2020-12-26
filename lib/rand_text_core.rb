# Main class for the +rand_text_core+ gem.
#
# Class for generators objects. A generator object is created for a given
# directory.
class RandTextCore
	# @return [Array<String>] Files' names
	attr_reader :files

	# Creates a new generator for CSV files stored into directory of given path.
	#
	# @param path [#to_str] directory's path, ending with a +'/'+, or not
	# @raise [TypeError] +path+ is not a String
	def initialize(path)
		begin
			path = path.to_str
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{path.class} into String"
		end
		path += path[-1] == '/' ? '' : '/'
		@files = Dir.glob(path + '*.csv')
	end
end