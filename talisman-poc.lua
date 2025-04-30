-- Talisman Proof of Concept
-- Simplified approach with clear boundaries and consistent types

-- Initialize global namespace for our math operations
TalMath = {
	-- Configuration
	config = {
		use_bignum = true, -- Whether to use big numbers at all
		auto_convert = false, -- Whether to automatically convert between types
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
	local bignum_path = lovely.mod_dir .. "/Talisman/big-num/bignumber.lua"
	Big, err = nativefs.load(bignum_path)
	if not err then
		Big = Big()
		-- Cache common constants as big numbers to avoid repeated conversions
		TalMath.cache.e = Big:new(2.718281828459045)
		TalMath.cache.pi = Big:new(3.14159265358979)
	else
		-- Fall back to regular Lua numbers
		TalMath.config.use_bignum = false
		print("[Talisman] Warning: BigNum provider not available, using regular numbers")
	end
end

-- CORE TYPE OPERATIONS

-- Convert to big number ONLY if necessary
function TalMath.ensureBig(x)
	-- Don't convert if bignums are disabled
	if not TalMath.config.use_bignum then
		return x
	end

	-- Already a big number
	if type(x) == "table" and getmetatable(x) == BigMeta then
		return x
	end

	-- Regular number - convert only if above threshold or auto-convert is on
	if type(x) == "number" then
		if math.abs(x) >= TalMath.config.conversion_threshold or TalMath.config.auto_convert then
			return Big:new(x)
		else
			return x
		end
	end

	-- String number
	if type(x) == "string" and tonumber(x) then
		local num = tonumber(x)
		if math.abs(num) >= TalMath.config.conversion_threshold or TalMath.config.auto_convert then
			return Big:new(num)
		else
			return num
		end
	end

	-- Otherwise try direct conversion
	return Big:new(x)
end

-- Convert big number to regular number if possible
function TalMath.toNumber(x)
	-- Already a regular number
	if type(x) == "number" then
		return x
	end

	-- Try to convert big number to regular number
	if type(x) == "table" and getmetatable(x) == BigMeta then
		local value = x:to_number()
		-- Check if result is valid and in range
		if value == value and value ~= math.huge and value ~= -math.huge then
			return value
		end
	end

	-- Can't convert, return as is
	-- TODO this smells - here we return a bignumber?
	return x
end

-- Format for display
function TalMath.format(value, places)
	places = places or 3

	-- Special case for zero and small numbers
	if value == 0 or (type(value) == "number" and math.abs(value) < TalMath.config.display_threshold) then
		-- Format with commas for thousands
		local str = tostring(math.floor(value * 10 ^ places + 0.5) / 10 ^ places)
		local int, frac = string.match(str, "([^.]*)%.?(.*)")
		int = int:reverse():gsub("(%d%d%d)", "%1,"):gsub(",$", ""):reverse()
		if frac and frac ~= "" then
			return int .. "." .. frac
		else
			return int
		end
	end

	-- Ensure value is a big number for consistent formatting
	local big_value = TalMath.ensureBig(value)

	-- Format using scientific notation for large numbers
	if type(big_value) == "table" then
		local mantissa
		local exponent

		if big_value.e then -- BigNum format
			mantissa = math.floor(big_value.m * 10 ^ places + 0.5) / 10 ^ places
			exponent = big_value.e
		else -- Regular number
			exponent = math.floor(math.log10(math.abs(big_value)))
			mantissa = big_value / 10 ^ exponent
			mantissa = math.floor(mantissa * 10 ^ places + 0.5) / 10 ^ places
		end

		-- Return in scientific notation format
		return mantissa .. "e" .. exponent
	end

	-- Fallback for regular numbers
	return tostring(value)
end

-- MATH OPERATIONS WITH TYPE SAFETY

-- Addition
function TalMath.add(a, b)
	-- Fast path for regular numbers
	if type(a) == "number" and type(b) == "number" then
		local result = a + b
		-- Convert to big number if result exceeds threshold
		if math.abs(result) >= TalMath.config.conversion_threshold then
			-- TODO: We need to make the addition in "big domain" land
			return TalMath.ensureBig(result)
		end
		return result
	end

	-- Ensure both are big numbers if either one is
	if type(a) == "table" or type(b) == "table" then
		a = TalMath.ensureBig(a)
		b = TalMath.ensureBig(b)
		return a + b -- Using operator overloading
	end

	-- Fallback
	return a + b
end

-- Subtraction
function TalMath.subtract(a, b)
	-- Fast path for regular numbers
	if type(a) == "number" and type(b) == "number" then
		local result = a - b
		-- Convert to big number if result exceeds threshold
		if math.abs(result) >= TalMath.config.conversion_threshold then
			return TalMath.ensureBig(result)
		end
		return result
	end

	-- Ensure both are big numbers if either one is
	if type(a) == "table" or type(b) == "table" then
		a = TalMath.ensureBig(a)
		b = TalMath.ensureBig(b)
		return a - b -- Leveraging operator overloading defined in Bignumber
	end

	-- Fallback
	return a - b
end

-- Multiplication
function TalMath.multiply(a, b)
	-- Fast path for regular numbers
	if type(a) == "number" and type(b) == "number" then
		local result = a * b
		-- Convert to big number if result exceeds threshold
		if math.abs(result) >= TalMath.config.conversion_threshold then
			return TalMath.ensureBig(result)
		end
		return result
	end

	-- Ensure both are big numbers if either one is
	if type(a) == "table" or type(b) == "table" then
		a = TalMath.ensureBig(a)
		b = TalMath.ensureBig(b)
		return a * b -- Using operator overloading
	end

	-- Fallback
	return a * b
end

-- Division
function TalMath.divide(a, b)
	-- Fast path for regular numbers
	if type(a) == "number" and type(b) == "number" and b ~= 0 then
		local result = a / b
		-- Convert to big number if result exceeds threshold
		if math.abs(result) >= TalMath.config.conversion_threshold then
			return TalMath.ensureBig(result)
		end
		return result
	end

	-- Ensure both are big numbers if either one is
	if type(a) == "table" or type(b) == "table" then
		a = TalMath.ensureBig(a)
		b = TalMath.ensureBig(b)
		return a / b -- Using operator overloading
	end

	-- Fallback
	return a / b
end

-- Power
function TalMath.power(base, exponent)
	-- Fast path for regular numbers
	if type(base) == "number" and type(exponent) == "number" then
		-- Only try this if it's likely to succeed without overflow
		if math.abs(base) < 1000 and math.abs(exponent) < 100 then
			local success, result = pcall(function()
				return base ^ exponent
			end)
			if success and result == result and math.abs(result) < TalMath.config.conversion_threshold then
				return result
			end
		end
	end

	-- Ensure both are big numbers if either one is
	if type(base) == "table" or type(exponent) == "table" then
		base = TalMath.ensureBig(base)
		exponent = TalMath.toNumber(exponent) -- Most big number implementations want regular number exponents
		return base:pow(exponent)
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
function to_big(x, y)
	-- Initialize if not already done
	if not TalMath.cache.provider_check then
		TalMath.initialize()
	end

	-- Always return big number for compatibility
	return TalMath.ensureBig(x)
end

function lenient_bignum(x)
	-- Just call our normalized function
	return TalMath.toNumber(x)
end

-- Override math functions to use our safe versions
_original_math = {
	max = math.max,
	min = math.min,
	abs = math.abs,
	sqrt = math.sqrt,
	log = math.log,
	log10 = math.log10,
	exp = math.exp,
}

function math.max(x, y)
	-- Use simple comparison to determine maximum
	if TalMath.gt(x, y) then
		return x
	else
		return y
	end
end

function math.min(x, y)
	-- Use simple comparison to determine minimum
	if TalMath.lt(x, y) then
		return x
	else
		return y
	end
end

function math.abs(x)
	return TalMath.abs(x)
end

function math.sqrt(x)
	-- Fast path for regular numbers
	if type(x) == "number" then
		return _original_math.sqrt(x)
	end

	-- Delegate to big number sqrt
	return TalMath.power(x, 0.5)
end

function math.log(x, base)
	return TalMath.log(x, base)
end

function math.log10(x)
	return TalMath.log10(x)
end

function math.exp(x)
	-- Use cached e value
	return TalMath.power(TalMath.cache.e or 2.718281828459045, x)
end

-- HELPER FUNCTIONS FOR MODS

-- Format a big number for display
function number_format(num, e_switch_point)
	-- Use our TalMath formatter with a customizable threshold
	local threshold = e_switch_point or TalMath.config.display_threshold

	-- Always format numbers using our system
	return TalMath.format(num, 3)
end

-- Initialize the system when this file is loaded
TalMath.initialize()

-- Return the module
return TalMath
