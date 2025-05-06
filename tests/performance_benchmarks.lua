-- Performance Benchmarks for Talisman
-- This script measures the performance of different approaches
-- Run before and after optimizations to track improvements

local TalMath = require("talmath")

-- Simple benchmark utility
local Benchmark = {}

function Benchmark.run(name, func, iterations)
    iterations = iterations or 10000
    
    print("Running benchmark: " .. name)
    print("  Iterations: " .. iterations)
    
    -- Warm up
    for i = 1, 100 do
        func()
    end
    
    -- Actual benchmark
    local start_time = os.clock()
    for i = 1, iterations do
        func()
    end
    local end_time = os.clock()
    
    local total_time = end_time - start_time
    local per_op = total_time / iterations
    
    print(string.format("  Total time: %.4f seconds", total_time))
    print(string.format("  Time per op: %.8f seconds", per_op))
    
    return {
        name = name,
        iterations = iterations,
        total_time = total_time,
        per_op = per_op
    }
end

function Benchmark.compare(benchmark1, benchmark2)
    if benchmark1.per_op == 0 then
        return "Infinite speedup (division by zero)"
    end
    
    local speedup = benchmark1.per_op / benchmark2.per_op
    print(string.format("Speedup: %.2fx (%s vs %s)", speedup, benchmark1.name, benchmark2.name))
    return speedup
end

-- Test data preparation
local small_numbers = {}
local medium_numbers = {}
local large_numbers = {}

for i = 1, 1000 do
    small_numbers[i] = math.random(1, 100)
    medium_numbers[i] = math.random(1e6, 1e9)
    large_numbers[i] = 1e200 + math.random(1, 1e10)
end

-- Benchmarks for to_big() function
print("\n=== to_big() Benchmarks ===")

local current_to_big = function(x)
    if type(x) == "string" or x == "0" or type(x) == "nil" then
        return 0
    end
    
    if is_number(x) then
        return x
    end
    
    return TalMath.ensureBig(x)
end

local optimized_to_big = function(x)
    -- Fast path for common case - numbers
    if type(x) == "number" then
        return x
    end
    
    -- Handle special cases
    if type(x) == "string" or x == "0" or type(x) == "nil" then
        return 0
    end
    
    -- Already a big number
    if TalMath.isBigNum(x) then
        return x
    end
    
    -- Convert to big number
    return TalMath.ensureBig(x)
end

Benchmark.run("Current to_big() with small numbers", function()
    for i = 1, 100 do
        current_to_big(small_numbers[i])
    end
end)

Benchmark.run("Optimized to_big() with small numbers", function()
    for i = 1, 100 do
        optimized_to_big(small_numbers[i])
    end
end)

-- Benchmarks for addition
print("\n=== Addition Benchmarks ===")

local regular_add = function(a, b)
    return a + b
end

local talmath_add = function(a, b)
    return TalMath.add(a, b)
end

local bignum_add = function(a, b)
    return TalMath.ensureBig(a) + TalMath.ensureBig(b)
end

Benchmark.run("Regular addition with small numbers", function()
    local sum = 0
    for i = 1, 100 do
        sum = regular_add(sum, small_numbers[i])
    end
    return sum
end)

Benchmark.run("TalMath.add with small numbers", function()
    local sum = 0
    for i = 1, 100 do
        sum = talmath_add(sum, small_numbers[i])
    end
    return sum
end)

Benchmark.run("Big number addition with small numbers", function()
    local sum = TalMath.ensureBig(0)
    for i = 1, 100 do
        sum = bignum_add(sum, small_numbers[i])
    end
    return sum
end)

Benchmark.run("TalMath.add with large numbers", function()
    local sum = 0
    for i = 1, 10 do  -- Fewer iterations for large numbers
        sum = talmath_add(sum, large_numbers[i])
    end
    return sum
end)

-- Benchmarks for comparison
print("\n=== Comparison Benchmarks ===")

local regular_compare = function(a, b)
    return a > b
end

local talmath_compare = function(a, b)
    return TalMath.gt(a, b)
end

local bignum_compare = function(a, b)
    local big_a = TalMath.ensureBig(a)
    return big_a:gt(b)
end

Benchmark.run("Regular comparison with small numbers", function()
    local count = 0
    for i = 1, 100 do
        if regular_compare(small_numbers[i], 50) then
            count = count + 1
        end
    end
    return count
end)

Benchmark.run("TalMath.gt with small numbers", function()
    local count = 0
    for i = 1, 100 do
        if talmath_compare(small_numbers[i], 50) then
            count = count + 1
        end
    end
    return count
end)

Benchmark.run("Big number comparison with small numbers", function()
    local count = 0
    for i = 1, 100 do
        if bignum_compare(small_numbers[i], 50) then
            count = count + 1
        end
    end
    return count
end)

Benchmark.run("TalMath.gt with mixed types", function()
    local count = 0
    local big_50 = TalMath.ensureBig(50)
    for i = 1, 100 do
        if talmath_compare(small_numbers[i], big_50) then
            count = count + 1
        end
    end
    return count
end)

-- Benchmarks for formatting
print("\n=== Formatting Benchmarks ===")

local original_format = function(num)
    if num == nil then
        return "0"
    end
    
    if num == 0 then
        return "0"
    end
    
    -- Simplified version of the original formatter
    if type(num) == "number" and math.abs(num) < 1e10 then
        local formatString = "%.0f"
        if num ~= math.floor(num) then
            if num < 10 then
                formatString = "%.2f"
            elseif num < 100 then
                formatString = "%.1f"
            end
        end
        return string.format(formatString, num)
    end
    
    -- For big numbers
    if type(num) == "table" then
        local mantissa, exponent
        if num.m and num.e then
            mantissa = math.floor(num.m * 1000 + 0.5) / 1000
            exponent = num.e
        else
            mantissa = 0
            exponent = 0
        end
        return mantissa .. "e" .. exponent
    end
    
    return tostring(num)
end

local tostring_format = function(num)
    return tostring(num)
end

Benchmark.run("Original number_format with small numbers", function()
    local results = {}
    for i = 1, 100 do
        results[i] = original_format(small_numbers[i])
    end
    return results
end)

Benchmark.run("TalMath.format with small numbers", function()
    local results = {}
    for i = 1, 100 do
        results[i] = TalMath.format(small_numbers[i])
    end
    return results
end)

Benchmark.run("Direct tostring with small numbers", function()
    local results = {}
    for i = 1, 100 do
        results[i] = tostring_format(small_numbers[i])
    end
    return results
end)

-- Convert some numbers to big numbers for formatting tests
local big_large_numbers = {}
for i = 1, 10 do
    big_large_numbers[i] = TalMath.ensureBig(large_numbers[i])
end

Benchmark.run("Original number_format with big numbers", function()
    local results = {}
    for i = 1, 10 do
        results[i] = original_format(big_large_numbers[i])
    end
    return results
end)

Benchmark.run("TalMath.format with big numbers", function()
    local results = {}
    for i = 1, 10 do
        results[i] = TalMath.format(big_large_numbers[i])
    end
    return results
end)

Benchmark.run("Direct tostring with big numbers", function()
    local results = {}
    for i = 1, 10 do
        results[i] = tostring_format(big_large_numbers[i])
    end
    return results
end)

print("\nBenchmarks complete!")