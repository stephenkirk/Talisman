local nativefs = require("nativefs")
local lovely = require("lovely")

local TalMath = nativefs.load(lovely.mod_dir .. "/Talisman/talmath.lua")()

function test_basic_operations()
	print("\n=== TESTING BASIC OPERATIONS ===")

	-- Test addition
	print("Addition tests:")
	print("5 + 10 =" .. TalMath.add(5, 10))
	print("1e200 + 1e200 = (should use BigNum)" .. TalMath.add(1e200, 1e200))

	-- Test subtraction
	print("\nSubtraction tests:")
	print("20 - 8 =" .. TalMath.subtract(20, 8))
	print("1e200 - 1e199 = " .. TalMath.subtract(1e200, 1e199))

	-- Test multiplication
	print("\nMultiplication tests:")
	print("6 * 7 =" .. TalMath.multiply(6, 7))
	print("1e150 * 1e150 = (should use BigNum)" .. TalMath.multiply(1e150, 1e150))

	-- Test division
	print("\nDivision tests:")
	print("100 / 20 =" .. TalMath.divide(100, 20))
	local result = TalMath.divide(1e300, 0.0001)
	print("1e300 / 0.0001 = (should use BigNum)" .. result .. " (type: " .. type(result) .. ")")
	print("Division by zero handling: " .. TalMath.divide(5, 0))
end

function test_power_functions()
	print("\n=== TESTING POWER FUNCTIONS ===")

	-- Test basic power operations
	print("Power tests:")
	print("2^10 =" .. TalMath.power(2, 10))
	print("10^20 =" .. TalMath.power(10, 20))
	print("10^100 =" .. TalMath.power(10, 100))

	-- Test large powers that might trigger BigNum
	print("\nLarge power tests:")

	local result = TalMath.power(300, 300)
	print("300^300 = " .. TalMath.format(result) .. " (type: " .. type(result) .. ")")

	result = TalMath.power(2, 1000)
	print("2^1000 = " .. TalMath.format(result) .. " (type: " .. type(result) .. ")")

	result = TalMath.power(10, 200)
	print("10^200 = " .. TalMath.format(result) .. " (type: " .. type(result) .. ")")

	result = TalMath.power(1.5, 500)
	print("1.5^500 = " .. TalMath.format(result) .. " (type: " .. type(result) .. ")")

	-- Test fractional powers
	print("\nFractional power tests:")
	print("16^0.5 =" .. TalMath.power(16, 0.5))
	print("27^(1/3) =" .. TalMath.power(27, 1 / 3))

	-- Test negative powers
	print("\nNegative power tests:")
	print("2^(-3) =" .. TalMath.power(2, -3))
end

function test_logarithmic_functions()
	print("\n=== TESTING LOGARITHMIC FUNCTIONS ===")

	-- Test natural logarithm
	print("Natural logarithm tests:")
	print("ln(10) =" .. TalMath.log(10))
	print("ln(2.718...) =" .. TalMath.log(math.exp(1)))

	-- Test logarithm with custom base
	print("\nLogarithm with custom base:")
	print("log_2(8) =" .. TalMath.log(8, 2))
	print("log_10(1000) =" .. TalMath.log(1000, 10))

	-- Test log10 directly
	print("\nLog10 tests:")
	print("log10(100) =" .. TalMath.log10(100))
	print("log10(1e20) =" .. TalMath.log10(1e20))

	-- Test very large values
	print("\nLarge value logarithm:")
	print("log10(1e200) =" .. TalMath.log10(1e200))
end

function test_comparison_operators()
	print("\n=== TESTING COMPARISON OPERATORS ===")

	-- Test equality
	print("Equality tests:")
	print("5 == 5:" .. tostring(TalMath.eq(5, 5)))
	print("5 == 6:" .. tostring(TalMath.eq(5, 6)))
	print("1e200 == 1e200:" .. tostring(TalMath.eq(1e200, 1e200)))

	-- Test less than
	print("\nLess than tests:")
	print("5 < 10:" .. tostring(TalMath.lt(5, 10)))
	print("10 < 5:" .. tostring(TalMath.lt(10, 5)))
	print("1e200 < 1e201:" .. tostring(TalMath.lt(1e200, 1e201)))

	-- Test greater than
	print("\nGreater than tests:")
	print("10 > 5:" .. tostring(TalMath.gt(10, 5)))
	print("5 > 10:" .. tostring(TalMath.gt(5, 10)))
	print("1e201 > 1e200:" .. tostring(TalMath.gt(1e201, 1e200)))

	-- Test mixed number types
	print("\nMixed type comparisons:")
	local big_num = TalMath.ensureBig(100)
	print("BigNum(100) == 100:" .. tostring(TalMath.eq(big_num, 100)))
	print("BigNum(100) > 50:" .. tostring(TalMath.gt(big_num, 50)))
	print("BigNum(100) < 200:" .. tostring(TalMath.lt(big_num, 200)))
end

function test_absolute_value()
	print("\n=== TESTING ABSOLUTE VALUE ===")

	-- Test positive and negative numbers
	print("abs(10) =" .. TalMath.abs(10))
	print("abs(-10) =" .. TalMath.abs(-10))

	-- Test with BigNum
	local veryBigNumber = TalMath.power(20, 300)
	print("abs(1e200) =" .. TalMath.abs(veryBigNumber))
	print("abs(-1e200) =" .. TalMath.abs(-veryBigNumber))

	-- Test zero
	print("abs(0) =" .. TalMath.abs(0))
end

function test_number_formatting()
	print("\n=== TESTING NUMBER FORMATTING ===")

	-- Test small numbers
	print("Format 123.456:" .. TalMath.format(123.456))
	print("Format 0.123:" .. TalMath.format(0.123))

	-- Test large numbers that use scientific notation
	print("Format 1e12:" .. TalMath.format(1e12))
	print("Format 9.87654e20:" .. TalMath.format(9.87654e20))

	-- Test BigNum formatting
	local big_value = TalMath.power(10, 100)
	print("Format 10^100:" .. TalMath.format(big_value))
end

function test_type_conversion()
	print("\n=== TESTING TYPE CONVERSION ===")

	-- Test ensureBig with regular numbers
	local regular = 42
	local big = TalMath.ensureBig(regular)
	print("ensureBig(42) type:" .. type(big))

	-- Test converting back
	local converted = TalMath.normalizeNumber(big)
	print("toNumber(bignum) =" .. converted .. " type:" .. type(converted))

	-- Test with very large values
	local large = TalMath.power(10, 500)
	print("Result of tonumber with 10^500: " .. TalMath.normalizeNumber(large))
end

function test_edge_cases()
	print("\n=== TESTING EDGE CASES ===")

	-- Test with zero
	print("0 + 0 =" .. TalMath.add(0, 0))
	print("0 * 1e200 =" .. TalMath.multiply(0, 1e200))
	print("0 / 0 =" .. TalMath.divide(0, 0))

	-- Test with very small numbers
	print("1e-100 + 1e-100 =" .. TalMath.add(1e-100, 1e-100))
	print("1e-200 * 1e200 =" .. TalMath.multiply(1e-200, 1e200))

	-- Test power with zero and one
	print("0^0 =" .. TalMath.power(0, 0))
	print("0^1 =" .. TalMath.power(0, 1))
	print("1^1000 =" .. TalMath.power(1, 1000))
end

function test_tostring_conversion()
	print("\n=== TESTING IMPLICIT TOSTRING CONVERSION ===")

	-- Test with large powers
	local big1 = TalMath.power(20, 300)
	print("tostring(20^300) = " .. big1)

	local big2 = TalMath.power(10, 200)
	print("tostring(10^200) = " .. big2)

	local big3 = TalMath.power(2, 1000)
	print("tostring(2^1000) = " .. big3)

	-- Test with calculations that produce big numbers
	local big4 = TalMath.multiply(1e150, 1e150)
	print("tostring(1e150 * 1e150) = " .. big4)

	local big5 = TalMath.add(1e200, 1e200)
	print("tostring(1e200 + 1e200) = " .. big5)

	-- Compare tostring with format method
	print("\nComparing tostring with format:")
	print("tostring: " .. big1)
	print("format:   " .. TalMath.format(big1))
end

function test_mixed_operators()
	print("\n=== TESTING MIXED OPERATORS ===")

	-- Test addition operator
	local big100 = TalMath.ensureBig(100)
	print("Addition operator test:")
	print("BigNum(100) + 200 = " .. (big100 + 200))
	print("300 + BigNum(700) = " .. (300 + TalMath.ensureBig(700)))

	-- Test subtraction operator
	print("\nSubtraction operator test:")
	print("BigNum(500) - 200 = " .. (TalMath.ensureBig(500) - 200))
	print("1000 - BigNum(300) = " .. (1000 - TalMath.ensureBig(300)))

	-- Test multiplication operator
	print("\nMultiplication operator test:")
	print("BigNum(50) * 20 = " .. (TalMath.ensureBig(50) * 20))
	print("30 * BigNum(40) = " .. (30 * TalMath.ensureBig(40)))

	-- Test division operator
	print("\nDivision operator test:")
	print("BigNum(1000) / 20 = " .. (TalMath.ensureBig(1000) / 20))
	print("5000 / BigNum(25) = " .. (5000 / TalMath.ensureBig(25)))

	-- Test with very large numbers
	print("\nLarge number operator tests:")
	local veryBig = TalMath.power(10, 100)
	print("10^100 + 5000 = " .. (veryBig + 5000))
	print("10^100 * 2 = " .. (veryBig * 2))
	print("10^100 / 10 = " .. (veryBig / 10))
end

function test_mixed_operators_reverse()
	print("\n=== TESTING MIXED OPERATORS WITH NUMBER ON LEFT ===")

	-- Test addition operator
	local big100 = TalMath.ensureBig(100)
	print("Addition operator test:")
	print("200 + BigNum(100) = " .. (200 + big100))
	print("TalMath.ensureBig(700) + 300 = " .. (TalMath.ensureBig(700) + 300))

	-- Test subtraction operator
	print("\nSubtraction operator test:")
	print("200 - BigNum(500) = " .. (200 - TalMath.ensureBig(500)))
	print("TalMath.ensureBig(300) - 1000 = " .. (TalMath.ensureBig(300) - 1000))

	-- Test multiplication operator
	print("\nMultiplication operator test:")
	print("20 * BigNum(50) = " .. (20 * TalMath.ensureBig(50)))
	print("TalMath.ensureBig(40) * 30 = " .. (TalMath.ensureBig(40) * 30))

	-- Test division operator
	print("\nDivision operator test:")
	print("20 / BigNum(1000) = " .. (20 / TalMath.ensureBig(1000)))
	print("TalMath.ensureBig(25) / 5000 = " .. (TalMath.ensureBig(25) / 5000))

	-- Test with very large numbers
	print("\nLarge number operator tests:")
	local veryBig = TalMath.power(10, 100)
	print("5000 + 10^100 = " .. (5000 + veryBig))
	print("2 * 10^100 = " .. (2 * veryBig))
	print("10 / 10^100 = " .. (10 / veryBig))
end

-- Run all tests
print("STARTING TALMATH TESTS")
test_basic_operations()
test_power_functions()
test_logarithmic_functions()
test_comparison_operators()
test_absolute_value()
test_number_formatting()
test_type_conversion()
test_edge_cases()
test_tostring_conversion()
test_mixed_operators()
test_mixed_operators_reverse()
print("\nALL TESTS COMPLETED")
