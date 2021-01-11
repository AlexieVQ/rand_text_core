require_relative 'test_helper'
require_relative '../lib/rand_text_core/refinements'

class TestRefinements < Test::Unit::TestCase

	using RandTextCore::Refinements

	DRAW_NB = 1000

	class WeightedObject
		attr_reader :weight
		def initialize(weight)
			@weight = weight
		end
	end

	def setup
		@weighted_objects = [
			WeightedObject.new(10),
			WeightedObject.new(5),
			WeightedObject.new(7),
			WeightedObject.new(20),
			WeightedObject.new(30),
			WeightedObject.new(11),
			WeightedObject.new(0),
			WeightedObject.new(23),
			WeightedObject.new(5),
			WeightedObject.new(15)
		]
		@weighted_objects_sum = @weighted_objects.inject(0) do |sum, object|
			sum + object.weight
		end
		@weighted_objects_means = @weighted_objects.map do |object|
			object.weight.to_f / @weighted_objects_sum
		end

		@integers = [1, 8, 10, 30, 45, 3, 0, 11, 12, 3]
		@integers_sum = 10
		@integers_means = [0.1] * 10

		@mixed_objects = [
			WeightedObject.new(3),
			WeightedObject.new(8),
			1,
			10,
			WeightedObject.new(10),
			WeightedObject.new(-11),
			3,
			WeightedObject.new(7),
			WeightedObject.new(20),
			0
		]
		@mixed_objects_sum = @mixed_objects.inject(0) do |sum, object|
			sum + (object.kind_of?(WeightedObject) ? [object.weight, 0].max : 1)
		end
		@mixed_objects_means = @mixed_objects.map do |object|
			if object.kind_of?(WeightedObject)
				[object.weight.to_f, 0.0].max / @mixed_objects_sum
			else
				1.0 / @mixed_objects_sum
			end
		end
	end

	def test_lower_snake_case
		assert_true('abc'.lower_snake_case?)
		assert_true('abc_def'.lower_snake_case?)
		assert_true('abc1_def2'.lower_snake_case?)
		assert_false('_abc_def'.lower_snake_case?)
		assert_false('1abc_2def'.lower_snake_case?)
		assert_false(''.lower_snake_case?)
		assert_false('AbcDef'.lower_snake_case?)
	end

	def test_upper_camel_case
		assert_true('Abc'.upper_camel_case?)
		assert_true('AbcDef'.upper_camel_case?)
		assert_true('Abc1Def2'.upper_camel_case?)
		assert_false(' AbcDef'.upper_camel_case?)
		assert_false('1Abc2Def'.upper_camel_case?)
		assert_false(''.upper_camel_case?)
		assert_false('abc_def'.upper_camel_case?)
		assert_false('abc'.upper_camel_case?)
	end

	def test_camelize
		assert_equal('Abc', 'abc'.camelize)
		assert_equal('AbcDef', 'abc_def'.camelize)
		assert_equal('Abc1Def2', 'abc1_def2'.camelize)
		assert_equal('AbcDef', 'abc__def'.camelize)
		assert_raise(RuntimeError) { '_abc_def'.camelize }
		assert_raise(RuntimeError) { '1abc_2def'.camelize }
		assert_raise(RuntimeError) { ''.camelize }
		assert_raise(RuntimeError) { 'AbcDef'.camelize }
	end

	def test_valid_csv_file
		assert_true('abc.csv'.valid_csv_file_name?)
		assert_true('abc_def.csv'.valid_csv_file_name?)
		assert_true('abc1_def2.csv'.valid_csv_file_name?)
		assert_true('abc__def.csv'.valid_csv_file_name?)
		assert_false('abc_def.csv.bak'.valid_csv_file_name?)
		assert_false('abc_def'.valid_csv_file_name?)
		assert_false('.csv'.valid_csv_file_name?)
		assert_false('abc_def.txt'.valid_csv_file_name?)
		assert_false('Abc_Def.csv'.valid_csv_file_name?)
	end

	def test_total_weight
		assert_equal(0, [].total_weight)
		assert_equal(@weighted_objects_sum, @weighted_objects.total_weight)
		assert_equal(@integers_sum, @integers.total_weight)
		assert_equal(@mixed_objects_sum, @mixed_objects.total_weight)
	end

	def pick_test(enum, draw_nb, enum_means)
		enum_draws = enum.each_with_object({}) do |element, hash|
			hash[element] = 0
		end
		0.upto(draw_nb) do
			enum_draws[enum.pick] += 1
		end
		assert_false(enum_draws.keys.any? do |element|
			element.kind_of?(WeightedObject) &&
				element.weight <= 0 &&
				enum_draws[element] > 0
		end)
		deviations = Array.new(enum.length) do |i|
			Math.sqrt(draw_nb.to_f * enum_means[i] * (1.0 - enum_means[i]))
		end
		enum.each_with_index do |element, i|
			assert_in_delta(
				enum_means[i],
				enum_draws[element].to_f / draw_nb,
				deviations[i]
			)
		end
	end

	def test_pick_weighted_objects
		pick_test(@weighted_objects, DRAW_NB, @weighted_objects_means)
	end

	def test_pick_integers
		pick_test(@integers, DRAW_NB, @integers_means)
	end

	def test_pick_mixed_objects
		pick_test(@mixed_objects, DRAW_NB, @mixed_objects_means)
	end

end
