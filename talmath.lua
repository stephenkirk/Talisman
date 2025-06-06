-- Talisman Proof of Concept
-- Simplified approach with clear boundaries and consistent types
--
local lovely = require("lovely")
local nativefs = require("nativefs")

-- Initialize global namespace for our math operations
TalMath = {
	-- Configuration
	config = {
		use_bignum = true, -- Whether to use big numbers at all
		conversion_threshold = 1e300, -- When regular numbers should become bignums
		display_threshold = 1e10, -- When to switch to scientific notation for display
	},

	-- Cache commonly used values
	cache = {
		e = nil, -- Cached value of e as bignum
		pi = nil, -- Cached value of pi as bignum
		provider_check = nil, -- Have we checked which provider is available?
		use_omeganum = false, -- Are we using OmegaNum?
	},
}

-- Initialize big number system once at startup
function TalMath.initialize()
	-- Only do this check once
	if TalMath.cache.provider_check then
		return
	end
	TalMath.cache.provider_check = true

	-- Check if we're using bignum
	local bignum_path = lovely.mod_dir .. "/Talisman/big-num/bignumber-poc.lua"
	Big, err = nativefs.load(bignum_path)
	if not err then
		Big = Big()
		-- Cache common constants
		TalMath.cache.e = 2.718281828459045
		TalMath.cache.pi = 3.14159265358979
	else
		-- Fall back to regular Lua numbers
		TalMath.config.use_bignum = false
		print("[Talisman] Warning: BigNum provider not available, using regular numbers")
	end
end

-- Convert to big number always for consistency
function TalMath.ensureBig(x)
	-- Don't convert if bignums are disabled
	if not TalMath.config.use_bignum then
		return x
	end

	-- Already a big number
	if type(x) == "table" and getmetatable(x) == BigMeta then
		return x
	end

	-- Always convert to BigNumber for consistency
	return Big:new(x)
end

-- Convert big number to regular number if possible
function TalMath.normalizeNumber(number)
	-- Already a regular number
	if type(number) == "number" then
		return number
	end

	-- Try to convert big number to regular number
	if type(number) == "table" and getmetatable(number) == BigMeta then
		-- Special handling for values too large for Lua numbers
		if
			number:gt(Big:new(TalMath.config.conversion_threshold)) or number:lt(-TalMath.config.conversion_threshold)
		then
			return TalMath.config.conversion_threshold
		end

		return number:to_number()
	end

	-- Can't convert, return as is
	-- should never run
	print("Unexpected error: you shouldn't get here")
	return number
end

-- Format a number for display using Balatro's formatting system
-- TODO: Need to check this implementation because 1.450666453345345e23
-- has a lot of digits ;)
function TalMath.format(value, places)
	places = places or 3

	if value == nil then
		return "0"
	end

	if value == 0 then
		return "0"
	end

	-- Format regular numbers using vanilla-ish formatter for non-big numbers
	if type(value) == "number" and math.abs(value) < TalMath.config.display_threshold then
		local formatString = "%.0f" -- Default for integers and numbers >= 100
		if value ~= math.floor(value) then -- If it's not an integer
			if value < 10 then
				formatString = "%.2f"
			elseif value < 100 then
				formatString = "%.1f"
			end
		end

		-- Format with proper decimal places
		local formatted = string.format(formatString, value)

		-- Add thousands separators
		local wholePart, decimalPart = formatted:match("([^.]+)(.*)") -- Split at decimal point
		wholePart = wholePart:reverse():gsub("(%d%d%d)", "%1,"):gsub(",$", ""):reverse()

		return wholePart .. decimalPart
	end

	if type(value) == "number" and value >= 10 ^ 6 then
		local x = string.format("%.4g", value)
		local fac = math.floor(math.log(tonumber(x), 10))
		return string.format("%.3f", x / (10 ^ fac)) .. "e" .. fac
	end

	-- For big numbers, use scientific notation
	-- TODO replicate notations/Balatro.lua here without to_big fuckery
	if type(value) == "table" then
		local mantissa
		local exponent

		mantissa = math.floor(value.m * 10 ^ places + 0.5) / 10 ^ places
		exponent = value.e
		return mantissa .. "e" .. exponent
	end

	-- Last resort fallback
	-- todo: prob bypasses things now
	return tostring(value)
end

-- MATH OPERATIONS WITH TYPE SAFETY

-- Addition
function TalMath.add(a, b)
	-- If either operand is a big number, convert both to big numbers
	if type(a) == "table" or type(b) == "table" then
		a = TalMath.ensureBig(a)
		b = TalMath.ensureBig(b)
		return a + b -- Using operator overloading
	end

	-- Regular numbers
	if type(a) == "number" and type(b) == "number" then
		-- Perform addition and check for potential overflow
		local result = a + b
		if
			result ~= result
			or result == math.huge
			or result == -math.huge
			or math.abs(result) >= TalMath.config.conversion_threshold
		then
			-- Use big numbers if regular addition resulted in NaN or infinity
			return TalMath.ensureBig(a) + TalMath.ensureBig(b)
		end

		return result
	end

	-- Fallback
	return a + b
end

-- Subtraction
function TalMath.subtract(a, b)
	-- If either operand is a big number, convert both to big numbers
	if type(a) == "table" or type(b) == "table" then
		a = TalMath.ensureBig(a)
		b = TalMath.ensureBig(b)
		return a - b -- Leveraging operator overloading defined in Bignumber
	end

	-- Fast path for regular numbers
	if type(a) == "number" and type(b) == "number" then
		-- Attempt regular subtraction
		local result = a - b

		-- Check if result is valid (not NaN or infinity)
		if
			result ~= result
			or result == math.huge
			or result == -math.huge
			or math.abs(result) >= TalMath.config.conversion_threshold
		then
			-- If invalid, use big numbers instead
			return TalMath.ensureBig(a) - TalMath.ensureBig(b)
		end

		return result
	end

	-- Fallback
	return a - b
end

-- Multiplication
function TalMath.multiply(a, b)
	-- If either operand is a big number, convert both to big numbers
	if type(a) == "table" or type(b) == "table" then
		a = TalMath.ensureBig(a)
		b = TalMath.ensureBig(b)
		return a * b -- Using operator overloading
	end

	-- Fast path for regular numbers
	if type(a) == "number" and type(b) == "number" then
		-- Check if result might overflow
		if
			math.abs(a) > 0
			and math.abs(b) > 0
			and (math.abs(a) > TalMath.config.conversion_threshold / math.abs(b))
		then
			return TalMath.ensureBig(a) * TalMath.ensureBig(b)
		end

		-- Attempt regular multiplication
		local result = a * b

		-- Check if result is valid (not NaN or infinity)
		if
			result ~= result
			or result == math.huge
			or result == -math.huge
			or math.abs(result) >= TalMath.config.conversion_threshold
		then
			-- If invalid, use big numbers instead
			return TalMath.ensureBig(a) * TalMath.ensureBig(b)
		end

		return result
	end

	-- Fallback
	return a * b
end

-- Division
function TalMath.divide(a, b)
	-- If either operand is a big number, convert both to big numbers
	if type(a) == "table" or type(b) == "table" then
		a = TalMath.ensureBig(a)
		b = TalMath.ensureBig(b)
		return a / b -- Using operator overloading
	end

	-- Handle division by zero
	if type(b) == "number" and b == 0 then
		if type(a) == "number" and a == 0 then
			return 0 / 0 -- NaN for 0/0
		elseif type(a) == "number" and a > 0 then
			return TalMath.ensureBig(a) / TalMath.ensureBig(b) -- Use big number division
		elseif type(a) == "number" and a < 0 then
			return TalMath.ensureBig(a) / TalMath.ensureBig(b) -- Use big number division
		end
	end

	-- Fast path for regular numbers
	if type(a) == "number" and type(b) == "number" then
		-- Attempt regular division
		local result = a / b

		-- Check if result is valid (not NaN or infinity)
		if
			result ~= result
			or result == math.huge
			or result == -math.huge
			or math.abs(result) >= TalMath.config.conversion_threshold
		then
			-- If invalid, use big numbers instead
			return TalMath.ensureBig(a) / TalMath.ensureBig(b)
		end

		return result
	end

	-- Fallback
	return a / b
end

-- Power
function TalMath.power(base, exponent)
	-- If either operand is a big number, convert base to big number
	if type(base) == "table" or type(exponent) == "table" then
		base = TalMath.ensureBig(base)
		exponent = TalMath.normalizeNumber(exponent) -- Most big number implementations want regular number exponents
		return base:pow(exponent)
	end

	-- Fast path for regular numbers
	if type(base) == "number" and type(exponent) == "number" then
		-- Special cases where we know we need big numbers
		if
			exponent > 0
			and math.abs(base) > 10
			and exponent > math.log(TalMath.config.conversion_threshold) / math.log(math.abs(base))
		then
			local bigBase = TalMath.ensureBig(base)
			local powered = bigBase:pow(exponent)
			return powered
		end

		-- Try regular power operation safely
		-- TODO: Should probably be nuked
		local success, result = pcall(function()
			return base ^ exponent
		end)

		-- Check if result is valid and not too large
		if
			not success
			or result ~= result
			or result == math.huge
			or result == -math.huge
			or math.abs(result) >= TalMath.config.conversion_threshold
		then
			-- If invalid or too large, use big numbers instead
			return TalMath.ensureBig(base):pow(exponent)
		end

		return result
	end

	-- For safety, convert both to big numbers for large exponentiation
	base = TalMath.ensureBig(base)
	return base:pow(exponent)
end

-- Logarithm
function TalMath.log(value, base)
	base = base or TalMath.cache.e -- Default to natural logarithm

	-- Fast path for regular numbers
	if type(value) == "number" and type(base) == "number" then
		if value > 0 and base > 0 and base ~= 1 then
			return math.log(value, base)
		end
	end

	-- Ensure value is a big number
	value = TalMath.ensureBig(value)

	-- Use big number logarithm methods
	if type(base) == "number" and base == math.exp(1) then
		return TalMath.normalizeNumber(value:ln()) -- Natural logarithm
	else
		base = TalMath.ensureBig(base)
		return TalMath.normalizeNumber(value:log(base))
	end
end

-- Log base 10
function TalMath.log10(value)
	-- Fast path for regular numbers
	if type(value) == "number" then
		if value > 0 then
			return math.log10(value)
		end
	end

	-- Ensure value is a big number
	value = TalMath.ensureBig(value)

	-- Use big number log10 method
	return TalMath.normalizeNumber(value:log10())
end

-- Absolute value
function TalMath.abs(value)
	-- Fast path for regular numbers
	if type(value) == "number" then
		return math.abs(value)
	end

	-- Ensure value is a big number
	value = TalMath.ensureBig(value)

	-- Handle sign appropriately
	if value:lt(TalMath.ensureBig(0)) then
		return value:negate()
	else
		return value
	end
end

-- Comparison operators
function TalMath.eq(a, b)
	-- Fast path for regular numbers
	if type(a) == "number" and type(b) == "number" then
		return a == b
	end

	-- Ensure both are big numbers if either one is
	if type(a) == "table" or type(b) == "table" then
		a = TalMath.ensureBig(a)
		b = TalMath.ensureBig(b)
		return a:eq(b)
	end

	return a == b
end

function TalMath.lt(a, b)
	-- Fast path for regular numbers
	if type(a) == "number" and type(b) == "number" then
		return a < b
	end

	-- Ensure both are big numbers if either one is
	if type(a) == "table" or type(b) == "table" then
		a = TalMath.ensureBig(a)
		b = TalMath.ensureBig(b)
		return a:lt(b)
	end

	-- Fallback
	return a < b
end

function TalMath.gt(a, b)
	-- Fast path for regular numbers
	if type(a) == "number" and type(b) == "number" then
		return a > b
	end

	-- Ensure both are big numbers if either one is
	if type(a) == "table" or type(b) == "table" then
		a = TalMath.ensureBig(a)
		b = TalMath.ensureBig(b)
		return a:gt(b)
	end

	return a > b
end

TalMath.initialize()
return TalMath
