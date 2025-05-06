-- TalMath Test Suite
-- Run these tests to verify the TalMath library functions correctly

-- Import TalMath
local TalMath = require("talmath")

-- Simple test framework
local tests = {}
local passed = 0
local failed = 0

function tests.assert_equal(a, b, message)
    if a == b then
        passed = passed + 1
        return true
    else
        failed = failed + 1
        print("FAIL: " .. (message or "") .. " - Expected " .. tostring(a) .. " to equal " .. tostring(b))
        return false
    end
end

function tests.assert_true(value, message)
    return tests.assert_equal(value, true, message)
end

function tests.assert_false(value, message)
    return tests.assert_equal(value, false, message)
end

function tests.run_suite(suite_name, test_functions)
    print("\nRunning test suite: " .. suite_name)
    local suite_passed = 0
    local suite_failed = 0
    
    for name, func in pairs(test_functions) do
        local before_passed = passed
        local before_failed = failed
        
        print("  Test: " .. name)
        local success, err = pcall(func)
        
        if not success then
            failed = failed + 1
            suite_failed = suite_failed + 1
            print("  ERROR: " .. tostring(err))
        else
            suite_passed = suite_passed + (passed - before_passed)
            suite_failed = suite_failed + (failed - before_failed)
        end
    end
    
    print("  Suite results: " .. suite_passed .. " passed, " .. suite_failed .. " failed")
end

-- Addition Tests
local addition_tests = {}

function addition_tests.test_regular_number_addition()
    local result = TalMath.add(5, 3)
    tests.assert_equal(result, 8, "Regular number addition")
end

function addition_tests.test_big_number_addition()
    local a = TalMath.ensureBig(5)
    local b = TalMath.ensureBig(3)
    local result = TalMath.add(a, b)
    
    tests.assert_true(TalMath.isBigNum(result), "Result should be a big number")
    tests.assert_equal(result:to_number(), 8, "Big number addition")
end

function addition_tests.test_mixed_number_addition()
    local a = TalMath.ensureBig(5)
    local result = TalMath.add(a, 3)
    
    tests.assert_true(TalMath.isBigNum(result), "Result should be a big number")
    tests.assert_equal(result:to_number(), 8, "Mixed number addition")
end

function addition_tests.test_large_number_addition()
    local a = 1e300
    local b = 1e300
    local result = TalMath.add(a, b)
    
    tests.assert_true(TalMath.isBigNum(result), "Result should be a big number")
    tests.assert_true(result:gt(1e300), "Large number addition")
end

-- Comparison Tests
local comparison_tests = {}

function comparison_tests.test_regular_number_comparison()
    tests.assert_true(TalMath.gt(5, 3), "5 > 3")
    tests.assert_false(TalMath.gt(3, 5), "3 > 5")
    tests.assert_true(TalMath.lt(3, 5), "3 < 5")
    tests.assert_false(TalMath.lt(5, 3), "5 < 3")
    tests.assert_true(TalMath.eq(5, 5), "5 == 5")
    tests.assert_false(TalMath.eq(5, 3), "5 == 3")
end

function comparison_tests.test_big_number_comparison()
    local a = TalMath.ensureBig(5)
    local b = TalMath.ensureBig(3)
    
    tests.assert_true(TalMath.gt(a, b), "Big 5 > Big 3")
    tests.assert_false(TalMath.gt(b, a), "Big 3 > Big 5")
    tests.assert_true(TalMath.lt(b, a), "Big 3 < Big 5")
    tests.assert_false(TalMath.lt(a, b), "Big 5 < Big 3")
    tests.assert_true(TalMath.eq(a, TalMath.ensureBig(5)), "Big 5 == Big 5")
    tests.assert_false(TalMath.eq(a, b), "Big 5 == Big 3")
end

function comparison_tests.test_mixed_number_comparison()
    local a = TalMath.ensureBig(5)
    
    tests.assert_true(TalMath.gt(a, 3), "Big 5 > 3")
    tests.assert_false(TalMath.gt(3, a), "3 > Big 5")
    tests.assert_true(TalMath.lt(3, a), "3 < Big 5")
    tests.assert_false(TalMath.lt(a, 3), "Big 5 < 3")
    tests.assert_true(TalMath.eq(a, 5), "Big 5 == 5")
    tests.assert_false(TalMath.eq(a, 3), "Big 5 == 3")
end

function comparison_tests.test_large_number_comparison()
    local a = TalMath.ensureBig(1e300)
    local b = TalMath.ensureBig(1e299)
    
    tests.assert_true(TalMath.gt(a, b), "1e300 > 1e299")
    tests.assert_true(TalMath.gt(a, 1e299), "Big 1e300 > 1e299")
    tests.assert_true(TalMath.lt(1e299, a), "1e299 < Big 1e300")
end

-- Pow Tests
local pow_tests = {}

function pow_tests.test_regular_power()
    local result = TalMath.power(2, 3)
    tests.assert_equal(result, 8, "2^3 = 8")
end

function pow_tests.test_big_number_power()
    local a = TalMath.ensureBig(2)
    local result = TalMath.power(a, 3)
    
    tests.assert_true(TalMath.isBigNum(result), "Result should be a big number")
    tests.assert_equal(result:to_number(), 8, "Big 2^3 = 8")
end

function pow_tests.test_large_exponent()
    local result = TalMath.power(10, 301)
    
    tests.assert_true(TalMath.isBigNum(result), "Result should be a big number")
    tests.assert_true(TalMath.gt(result, 1e300), "10^301 > 1e300")
end

-- Formatting Tests
local format_tests = {}

function format_tests.test_regular_number_format()
    tests.assert_equal(TalMath.format(123), "123", "Format 123")
    tests.assert_equal(TalMath.format(1234), "1,234", "Format 1234")
    tests.assert_equal(TalMath.format(1234.5), "1,234.5", "Format 1234.5")
    tests.assert_equal(TalMath.format(1.23), "1.23", "Format 1.23")
end

function format_tests.test_big_number_format()
    local a = TalMath.ensureBig(1234)
    tests.assert_equal(TalMath.format(a), "1,234", "Format Big 1234")
    
    local b = TalMath.ensureBig(1e15)
    local formatted = TalMath.format(b)
    tests.assert_true(formatted:find("e") ~= nil, "Scientific notation for large number")
end

-- Run all test suites
tests.run_suite("Addition Tests", addition_tests)
tests.run_suite("Comparison Tests", comparison_tests)
tests.run_suite("Power Tests", pow_tests)
tests.run_suite("Formatting Tests", format_tests)

-- Print overall results
print("\nOverall results: " .. passed .. " passed, " .. failed .. " failed")

if failed > 0 then
    print("❌ Some tests failed")
    os.exit(1)
else
    print("✅ All tests passed")
    os.exit(0)
end