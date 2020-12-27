require 'csv'
require_relative '../rand_text_core'

# The Entity class is a superclass to represent data stored in the CSV tables.
#
# A class extending Entity represents a table from a CSV file, and each of its
# instances represents a row.
#
# @author AlexieVQ
class RandTextCore::Entity

	############################
	# CLASS METHOD FOR A TABLE #
	############################

	class << self
		include Enumerable

		# @return [String] table name (frozen)
		attr_reader :table_name

		# @return [String] file path (frozen)
		attr_reader :file

		# @return [Hash{Integer=>Entity}] a hash map associating ids to entities
		attr_reader :entities_map

		# @return [Hash{String=>:string, :id, :weight, :reference}] a hash map
		#  associating attribute names to their types:
		#  [+:id+] the entity's id
		#  [+:weight+] the entity's weight
		#  [+:reference+] a reference to another entity
		#  [+:string+] a string value
		attr_reader :attr_types

		# @return [Hash{String=>String}] a hash map associating attribute names
		#	to the names of the table they reference
		attr_reader :references

		private

		# Set the list of tables in the system
		# @return [Array<Class>] list of classes representing tables
		attr_writer :tables
	end

	# Set file path.
	# File path can only be set one time.
	# The attribute +table_name+ is also inferred from the file name.
	# @param [#to_str] path path to the CSV file, must end with .csv
	# @return [String] path to the CSV file (frozen)
	# @raise [TypeError] no implicit conversion of path into String
	# @raise [ArgumentError] given String does not represent a path to a CSV
	#	file
	def self.file_path(path)
		begin
			path = path.to_str
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{path.class} into String"
		end
		@table_name = path.split('/').last.gsub(/\.csv$/,'').freeze
		@file = path.freeze
	end

	# Declares that given attribute is a reference to table +table_name+'s id.
	# @param [#to_str] attribute attribute from current table (must only contain
	#  non-zero integers)
	# @param [#to_str] table_name name of the table to reference (file name
	#  without full path and extension)
	# @return [nil]
	# @raise [TypeError] no implicit conversion for arguments into String
	def self.reference(attribute, table_name)
		@references ||= {}
		begin
			attribute = attribute.to_str.freeze
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{attribute.class} into String"
		end
		begin
			table_name = table_name.to_str.freeze
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{table_name.class} into String"
		end
		@references[attribute] = table_name
		nil
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
					self.table(attribute)[@attributes[attribute]]
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
			raise "no attribute id found for table #{self.table_name}"
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

	# Add a row from the file.
	# @param [CSV::Row] row row to add
	# @return [self]
	# @raise [ArgumentError] invalid attributes
	# @raise [RuntimeError] duplicated id
	def self.add_entity(row)
		entity = new(row)
		if @entities_map[entity.id]
			raise "id #{entity.id} duplicated in table #{self.table_name}"
		end
		@entities_map[entity.id] = entity
		self
	end
	private_class_method :add_entity

	# Import entities from CSV file.
	# @return [self]
	def self.import
		@entities_map = {}
		@references ||= {}
		CSV.read(self.file, col_sep: ';', headers: true).each do |row|
			self.attr_types = row.headers unless @attr_types
			self.add_entity(row)
		end
		self
	end
	private_class_method :import
	
	# Returns an array of entities stored in the table.
	# @return [Array<Entity>] entities stored in the table
	def self.entities
		self.entities_map.values
	end

	# Prevents further modifications to the table.
	# Must be called at the end of initialization.
	# @return [self]
	def self.freeze
		super
		@entities_map.freeze
		@attr_types.freeze
		@references.freeze
		self
	end

	# Returns entity of given id.
	# @param [#to_int] id id of the entity 
	# @return [Entity] entity of given id
	# @raise [KeyError] no entity of given id has been found
	# @raise [TypeError] no implicit conversion of +id+ into Integer
	def self.[](id)
		begin
			self.entities_map.fetch(id.to_int)
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{id.class} into Integer"
		end
	end

	# Executes given block for each entity of the table.
	# If no block is given, return an enumerator on the element of the table.
	# @yield [entity] block to execute on each element
	# @return [Enumerator<Entity>, self] +self+ if a block is given, or an
	#                                    enumerator on the elements of the table
	def self.each
		if block_given?
			self.entities.each { |entity| yield entity }
			self
		else
			self.entities.to_enum
		end
	end

	# Returns table of given name.
	# @param [#to_str] name name of the table
	# @return [Class] class extending Entity representing the table
	# @raise [TypeError] no implicit conversion of name into String
	# @raise [ArgumentError] no table of given name in the system
	def self.table(name)
		begin
			name = name.to_str
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{name.class} into String"
		end
		table = @tables.find { |table| table.table_name == name }
		unless table
			raise ArgumentError, "no table named #{name} in the system"
		end
		table
	end

	private_class_method :new

	###############################
	# INSTANCE METHODS FOR ENTITY #
	###############################

	# @attributes	=> [Hash{String=>Integer, String}] hash map associating
	#                  attribute names to their value: String for strings and
	#                  Integer for id, reference and weight

	# Creates a new entity from given row.
	# @param [CSV::Row] row row from the CSV file.
	# @raise [ArgumentError] invalid row
	def initialize(row)
		types = self.class.attr_types
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
				raise "unknown attribute #{attribute} for table " +
					self.class.table_name
			end
		end
		@attributes.freeze
	end

	# Returns table of given name.
	# @param [#to_str] name name of the table
	# @return [Class] class extending Entity representing the table
	# @raise [TypeError] no implicit conversion of name into String
	# @raise [ArgumentError] no table of given name in the system
	def table(name)
		begin
			name = name.to_str
		rescue NoMethodError
			raise TypeError,
				"no implicit conversion of #{name.class} into String"
		end
		self.class.table(name)
	end

	def inspect
		"#<#{self.class.name} #{@attributes.keys.map do |k|
			"#{k.inspect}:#{self.send(k.to_sym).inspect}"
		end.join(' ')}>"
	end

end