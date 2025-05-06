# Talisman Phase 1-2 Action Plan

This document outlines the specific implementation steps for Phase 1 (Unify Big Number Providers) and Phase 2 (String Conversion Improvement).

## Phase 1: Unify Big Number Providers

### Step 1: Create a Common Interface

Create a file `big-num/provider.lua` that defines the required interface for all big number providers:

```lua
-- Interface definition for BigNum providers
-- All providers must implement these methods

BigNumProvider = {
    -- Required methods
    methods = {
        -- Creation/conversion
        "new",         -- Create a new big number
        "parse",       -- Parse from string
        "to_number",   -- Convert to regular number
        "clone",       -- Create a copy
        
        -- Basic arithmetic
        "add",         -- Addition
        "sub",         -- Subtraction
        "mul",         -- Multiplication
        "div",         -- Division
        "pow",         -- Power
        "sqrt",        -- Square root
        "log10",       -- Log base 10
        "ln",          -- Natural log
        "abs",         -- Absolute value
        
        -- Comparison
        "eq",          -- Equals
        "lt",          -- Less than
        "gt",          -- Greater than
        "lte",         -- Less than or equal
        "gte",         -- Greater than or equal
        
        -- Formatting
        "toString",    -- Convert to string
    },
    
    -- Additional methods (nice to have but not required)
    extended_methods = {
        "floor",       -- Floor function
        "ceil",        -- Ceiling function
        "round",       -- Round
        "mod",         -- Modulo
        "tetrate",     -- Tetration
        "slog",        -- Super-logarithm
        "logBase",     -- Log with arbitrary base
    }
}

-- Validation function to verify providers implement the interface
function BigNumProvider.validate(provider)
    local missing = {}
    for _, method in ipairs(BigNumProvider.methods) do
        if not provider[method] then
            table.insert(missing, method)
        end
    end
    
    if #missing > 0 then
        error("BigNumProvider validation failed. Missing methods: " .. table.concat(missing, ", "))
    end
    
    return true
end

-- Test if a value is a big number from any provider
function BigNumProvider.isBigNum(value)
    if type(value) ~= "table" then
        return false
    end
    
    -- BigNumber format
    if value.m ~= nil and value.e ~= nil then
        return true
    end
    
    -- OmegaNum format
    if value.array ~= nil and value.sign ~= nil then
        return true
    end
    
    return false
end

return BigNumProvider
```

### Step 2: Implement TaiAurori's OmegaNum Optimizations

Apply the optimizations mentioned in the Discord discussion to `omeganum.lua`:

1. Avoid cloning Big numbers until they are modified
2. Optimize arithmetic operations by reducing unnecessary allocations
3. Specifically optimize the most common operations (add, mul, div, comparison)

### Step 3: Update Both Provider Implementations

Ensure both `bignumber.lua` and `omeganum.lua` implement all the required interface methods consistently.

### Step 4: Create a Provider Factory

Create a provider factory that can instantiate either big number implementation:

```lua
-- big-num/factory.lua
local BigNumProvider = require("big-num/provider")

BigNumFactory = {}

-- Initialize the factory with provider instances
function BigNumFactory.initialize(provider_name)
    if provider_name == "bignumber" then
        BigNumFactory.provider = require("big-num/bignumber")()
    elseif provider_name == "omeganum" then
        BigNumFactory.provider = require("big-num/omeganum")()
    else
        error("Unknown big number provider: " .. tostring(provider_name))
    end
    
    -- Validate that the provider implements the required interface
    BigNumProvider.validate(BigNumFactory.provider)
    
    return BigNumFactory.provider
end

-- Create a new big number using the current provider
function BigNumFactory.create(value)
    return BigNumFactory.provider:new(value)
end

-- Test if value is a big number
function BigNumFactory.isBigNum(value)
    return BigNumProvider.isBigNum(value)
end

return BigNumFactory
```

## Phase 2: String Conversion Improvement

### Step 1: Implement Common Formatting Functions

Create a shared notations module that both providers can use:

```lua
-- big-num/formatting.lua
Formatting = {}

-- Thousands separators formatter
function Formatting.addThousandsSeparators(numStr)
    local wholePart, decimalPart = numStr:match("([^.]+)(.*)") -- Split at decimal point
    wholePart = wholePart:reverse():gsub("(%d%d%d)", "%1,"):gsub(",$", ""):reverse()
    return wholePart .. (decimalPart or "")
end

-- Format for numbers < display threshold (standard notation)
function Formatting.standardFormat(value, places)
    places = places or 2
    
    local formatString = "%.0f" -- Default for integers and numbers >= 100
    if value ~= math.floor(value) then -- If it's not an integer
        if value < 10 then
            formatString = "%." .. places .. "f"
        elseif value < 100 then
            formatString = "%.1f"
        end
    end
    
    -- Format with proper decimal places
    local formatted = string.format(formatString, value)
    
    -- Add thousands separators
    return Formatting.addThousandsSeparators(formatted)
end

-- Scientific notation with proper formatting
function Formatting.scientificFormat(mantissa, exponent, places)
    places = places or 2
    mantissa = math.floor(mantissa * 10^places + 0.5) / 10^places
    return mantissa .. "e" .. exponent
end

-- Balatro-style notation formatting
function Formatting.balatroPrecisionFormat(value, threshold, places)
    places = places or 2
    threshold = threshold or 1e10
    
    if value == nil or value == 0 then
        return "0"
    end
    
    -- For regular numbers using vanilla-ish formatter
    if type(value) == "number" and math.abs(value) < threshold then
        return Formatting.standardFormat(value, places)
    end
    
    -- For big numbers, use scientific notation
    local mantissa, exponent
    
    if type(value) == "table" then
        if value.m and value.e then
            -- BigNumber format
            mantissa = value.m
            exponent = value.e
        elseif value.array and value.sign then
            -- OmegaNum format (simplified - this would need proper implementation)
            -- This is just a placeholder for the real implementation
            local str = value:toString()
            local m, e = str:match("(.+)e(.+)")
            if m and e then
                mantissa = tonumber(m)
                exponent = tonumber(e)
            else
                return str
            end
        end
    end
    
    return Formatting.scientificFormat(mantissa, exponent, places)
end

return Formatting
```

### Step 2: Override `__tostring` Metamethods

Update both providers to implement the `__tostring` metamethod using the shared formatting functions:

For BigNumber:
```lua
function BigMeta.__tostring(self)
    local Formatting = require("big-num/formatting")
    return Formatting.balatroPrecisionFormat(self)
end
```

For OmegaNum:
```lua
function OmegaMeta.__tostring(self)
    local Formatting = require("big-num/formatting")
    return Formatting.balatroPrecisionFormat(self)
end
```

### Step 3: Implement Notations Consistently

Ensure that all notations from the original `notations.lua` are implemented consistently across both providers.

### Step 4: Update `TalMath.format` to Use Provider Formatting

Modify `talmath.lua` to use the native string conversion:

```lua
-- Format a number for display using provider's native toString
function TalMath.format(value, places)
    places = places or 3
    
    if value == nil then
        return "0"
    end
    
    if value == 0 then
        return "0"
    end
    
    -- For tables (big numbers), use their native toString method
    if type(value) == "table" then
        -- This will use the __tostring metamethod automatically
        return tostring(value)
    end
    
    -- For regular numbers
    local Formatting = require("big-num/formatting")
    return Formatting.balatroPrecisionFormat(value, TalMath.config.display_threshold, places)
end
```

## Testing Strategy

1. Create a test suite that verifies:
   - All providers implement the required interface
   - All providers produce identical results for the same inputs
   - String conversion works correctly in all cases
   - Math operations work correctly for both providers

2. Create a benchmark suite to measure performance improvements.

## Next Steps After Phase 1-2

1. Begin implementing the full TalMath operations (Phase 3)
2. Create the transition layer in talisman.lua (Phase 4)
3. Document the new APIs for mod authors