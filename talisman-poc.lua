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
		notations = nil, -- Cached notations
		balatro_notation = nil, -- Cached Balatro notation formatter
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
	local bignum_path = lovely.mod_dir .. "/Talisman/big-num/bignumber.lua"
	Big, err = nativefs.load(bignum_path)
	if not err then
		Big = Big()
		-- Cache common constants as big numbers to avoid repeated conversions
		TalMath.cache.e = Big:new(2.718281828459045)
		TalMath.cache.pi = Big:new(3.14159265358979)

		-- Load notations
		local Notations = nativefs.load(lovely.mod_dir .. "/Talisman/big-num/notations.lua")()
		TalMath.cache.notations = Notations
		TalMath.cache.balatro_notation = Notations.Balatro:new()
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

-- Convert big number to regular number
function TalMath.toNumber(x)
	-- Already a regular number
	if type(x) == "number" then
		return x
	end

	-- Try to convert big number to regular number
	if type(x) == "table" and getmetatable(x) == BigMeta then
		-- Special handling for values too large for Lua numbers
		if x:gt(Big:new(TalMath.config.conversion_threshold)) or x:lt(-TalMath.config.conversion_threshold) then
			-- TODO: should probably return naneinf
			-- but for now ...
			return x -- Return the BigNumber itself for very large values
		end

		local value = x:to_number()
		-- Check if result is valid and in range
		if value == value and value ~= math.huge and value ~= -math.huge then
			return value
		end
	end

	-- Can't convert, return as is
	-- TODO: should probably be that we return a very huge number
	return x
end

-- Format a number for display using Balatro's formatting system
function TalMath.format(value, places)
	places = places or 3

	if value == nil then
		return "0"
	end

	if value == 0 then
		return "0"
	end

	-- Format regular numbers using vanilla formatter for non-big numbers
	if type(value) == "number" and math.abs(value) < TalMath.config.display_threshold then
		return number_format(value, TalMath.config.display_threshold)
	end

	-- For big numbers, use scientific notation
	-- TODO replicate notations/Balatro.lua here without to_big fuckery
	if type(big_value) == "table" then
		local mantissa
		local exponent

		mantissa = math.floor(big_value.m * 10 ^ places + 0.5) / 10 ^ places
		exponent = big_value.e
		return mantissa .. "e" .. exponent
	end

	-- Last resort fallback
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
		exponent = TalMath.toNumber(exponent) -- Most big number implementations want regular number exponents
		return base:pow(exponent)
	end

	-- Fast path for regular numbers
	if type(base) == "number" and type(exponent) == "number" then
		print("TalMath.power: Both types are regular numbers")
		print(base .. "^^" .. exponent)
		-- Special cases where we know we need big numbers
		if
			exponent > 0
			and math.abs(base) > 10
			and exponent > math.log(TalMath.config.conversion_threshold) / math.log(math.abs(base))
		then
			local bigBase = TalMath.ensureBig(base)
			print("Before power" .. bigBase.m .. "^^" .. bigBase.e)

			local powered = bigBase:pow(exponent)
			print("After power: " .. powered.m .. "^^" .. powered.e)

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
		return TalMath.toNumber(value:ln()) -- Natural logarithm
	else
		base = TalMath.ensureBig(base)
		return TalMath.toNumber(value:log(base))
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
	return TalMath.toNumber(value:log10())
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

	-- Fallback
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

	-- Fallback
	return a > b
end

-- MONKEY PATCHING FOR BACKWARD COMPATIBILITY

-- Create backward compatibility wrappers
-- function to_big(x, y)
-- 	-- Initialize if not already done
-- 	if not TalMath.cache.provider_check then
-- 		TalMath.initialize()
-- 	end

-- 	-- Always return big number for consistency
-- 	return TalMath.ensureBig(x)
-- end

-- function lenient_bignum(x)
-- 	-- Just call our normalized function
-- 	return TalMath.toNumber(x)
-- end

-- -- Override math functions to use our safe versions
-- _original_math = {
-- 	max = math.max,
-- 	min = math.min,
-- 	abs = math.abs,
-- 	sqrt = math.sqrt,
-- 	log = math.log,
-- 	log10 = math.log10,
-- 	exp = math.exp,
-- }

-- function math.max(x, y)
-- 	-- Use simple comparison to determine maximum
-- 	if TalMath.gt(x, y) then
-- 		return x
-- 	else
-- 		return y
-- 	end
-- end

-- function math.min(x, y)
-- 	-- Use simple comparison to determine minimum
-- 	if TalMath.lt(x, y) then
-- 		return x
-- 	else
-- 		return y
-- 	end
-- end

-- function math.abs(x)
-- 	return TalMath.abs(x)
-- end

-- function math.sqrt(x)
-- 	-- Fast path for regular numbers
-- 	if type(x) == "number" then
-- 		return _original_math.sqrt(x)
-- 	end

-- 	-- Delegate to big number sqrt
-- 	return TalMath.power(x, 0.5)
-- end

-- function math.log(x, base)
-- 	return TalMath.log(x, base)
-- end

-- function math.log10(x)
-- 	return TalMath.log10(x)
-- end

-- function math.exp(x)
-- 	-- Use cached e value
-- 	return TalMath.power(TalMath.cache.e or 2.718281828459045, x)
-- end

-- HELPER FUNCTIONS FOR MODS

-- Initialize the system when this file is loaded
TalMath.initialize()

TalMath.power(300, 300)

-- Return the module
return TalMath
