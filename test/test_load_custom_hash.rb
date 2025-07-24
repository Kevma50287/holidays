require 'test_helper'

class TestLoadCustomHash < Test::Unit::TestCase
  def test_load_custom_hash_with_simple_holiday
    # Test basic functionality with a simple holiday definition
    definition_hash = {
      'months' => {
        6 => [
          {
            'name' => 'Test Holiday',
            'regions' => ['test_region'],
            'mday' => 15
          }
        ]
      }
    }

    result = Holidays.load_custom_hash(definition_hash)

    expected = {6 => [{:mday => 15, :name => "Test Holiday", :regions => [:test_region]}]}
    assert_equal expected, result

    # Verify the holiday is actually loaded and findable
    holidays = Holidays.on(Date.civil(2023, 6, 15), :test_region)
    assert_equal 1, holidays.length
    assert_equal 'Test Holiday', holidays.first[:name]
  end

  def test_load_custom_hash_with_symbol_keys
    # Test that it works with symbol keys too
    definition_hash = {
      :months => {
        7 => [
          {
            :name => 'Symbol Test Holiday',
            :regions => ['symbol_test_region'],
            :mday => 20
          }
        ]
      }
    }

    result = Holidays.load_custom_hash(definition_hash)
    
    expected = {7 => [{:mday => 20, :name => "Symbol Test Holiday", :regions => [:symbol_test_region]}]}
    assert_equal expected, result
  end

  def test_load_custom_hash_with_week_and_wday
    # Test with nth weekday of month
    definition_hash = {
      'months' => {
        11 => [
          {
            'name' => 'Test Thanksgiving',
            'regions' => ['test_thanksgiving_region'],
            'week' => 4,
            'wday' => 4  # Thursday
          }
        ]
      }
    }

    result = Holidays.load_custom_hash(definition_hash)
    
    expected = {11 => [{:week => 4, :wday => 4, :name => "Test Thanksgiving", :regions => [:test_thanksgiving_region]}]}
    assert_equal expected, result
  end

  def test_load_custom_hash_raises_error_for_nil
    assert_raises(ArgumentError) do
      Holidays.load_custom_hash(nil)
    end
  end

  def test_load_custom_hash_raises_error_for_empty_hash
    assert_raises(ArgumentError) do
      Holidays.load_custom_hash({})
    end
  end

  def test_load_custom_hash_raises_error_for_non_hash
    assert_raises(ArgumentError) do
      Holidays.load_custom_hash("not a hash")
    end
  end

  def test_load_custom_hash_with_empty_months_returns_empty_result
    definition_hash = {
      'months' => {}
    }

    result = Holidays.load_custom_hash(definition_hash)
    assert_equal({}, result)
  end

  def test_load_custom_hash_with_multiple_holidays_same_month
    # Test multiple holidays in same month
    definition_hash = {
      'months' => {
        12 => [
          {
            'name' => 'Christmas Eve',
            'regions' => ['test_christmas_region'],
            'mday' => 24
          },
          {
            'name' => 'Christmas Day', 
            'regions' => ['test_christmas_region'],
            'mday' => 25
          }
        ]
      }
    }

    result = Holidays.load_custom_hash(definition_hash)
    
    assert_equal 2, result[12].length
    assert_equal 'Christmas Eve', result[12].first[:name]
    assert_equal 'Christmas Day', result[12].last[:name]
  end

  def test_load_custom_hash_with_custom_methods
    # Test with custom methods - this was the original failing case
    definition_hash = {
      'months' => {
        8 => [
          {
            'name' => 'Custom Method Holiday',
            'regions' => ['custom_method_test_region'],
            'function' => 'test_custom_method(year)'
          }
        ]
      },
      'methods' => {
        'test_custom_method' => {
          'arguments' => 'year',
          'ruby' => 'Date.civil(year, 8, 10)'
        }
      }
    }

    result = Holidays.load_custom_hash(definition_hash)
    
    # Check that the method was loaded with proper function arguments
    assert_not_nil result[8]
    assert_equal 1, result[8].length
    assert_equal 'Custom Method Holiday', result[8].first[:name]
    assert_equal 'test_custom_method(year)', result[8].first[:function]
    assert_equal [:year], result[8].first[:function_arguments]
    
    # Verify the holiday is actually findable and the custom method works
    holidays = Holidays.on(Date.civil(2023, 8, 10), :custom_method_test_region)
    assert_equal 1, holidays.length
    assert_equal 'Custom Method Holiday', holidays.first[:name]
    
    # Test that it works for different years
    holidays_2024 = Holidays.on(Date.civil(2024, 8, 10), :custom_method_test_region)
    assert_equal 1, holidays_2024.length
    assert_equal 'Custom Method Holiday', holidays_2024.first[:name]
  end
end
