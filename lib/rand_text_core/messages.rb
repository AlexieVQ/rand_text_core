require_relative '../rand_text_core'

# Object storing a message when analyzing a rule.
#
# @author AlexieVQ
class RandTextCore::Message

	private_class_method :new

	# @return [String] message
	attr_reader :message

	# @return [String] level (usually +'ERROR'+, +'WARNING'+)
	attr_reader :level

	# @return [Class, nil] concerned rule (or +nil+ if none)
	attr_reader :rule

	# @return [RuleVariant, nil] concerned rule variant (or +nil+ if none)
	attr_reader :rule_variant

	# Creates a message.
	# @param [#to_str] message message
	# @param [Class] rule concerned rule
	# @param [RuleVariant] rule_variant concerned variant of the rule
	def initialize(message, rule = nil, rule_variant = nil)
		@message, @rule, @rule_variant = message.to_str, rule, rule_variant
	end

	# Returns the message, with its level, concerned rule and variant.
	# @return [String] message, with its level, concerned rule and variant
	def to_s
		"#{
			if self.rule
				"Rule #{self.rule.rule_name} (#{self.rule.file})#{
					if self.rule_variant
						", variant #{self.rule_variant.inspect}: "
					else
						": "
					end
				}"
			else
				""
			end
		}#{self.level}: #{self.message}"
	end

end

# Class for message of error level.
#
# @author AlexieVQ
class RandTextCore::ErrorMessage < RandTextCore::Message

	public_class_method :new

	# @see Message#initialize
	def initialize(*args)
		@level = 'ERROR'
		super(*args)
	end

end