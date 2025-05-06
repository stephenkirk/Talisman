# Solving the Comparison Operator Problem

One of the key issues in the current Talisman implementation is the comparison operator problem. As noted in the Discord discussion, LuaJIT (based on Lua 5.1) only calls relational metamethods like `__lt` for `a < b` if both values have the same metamethod - which means regular numbers can't be directly compared with Big numbers.

## The Problem

Consider this code:

```lua
local bigNum = to_big(100)  -- Creates a big number
local result = bigNum > 50   -- This doesn't work as expected!
```

In this case, the `>` operator doesn't work because `50` is a regular number and doesn't have the `__lt` metamethod. LuaJIT won't call the `__lt` metamethod on the big number.

The current workaround is manual type conversion:

```lua
local bigNum = to_big(100)
local result = bigNum > to_big(50)  -- Works, but verbose and inefficient
```

Or using explicit comparison methods:

```lua
local bigNum = to_big(100)
local result = bigNum:gt(50)  -- Works, but not as intuitive
```

## Proposed Solution: TalMath Comparison Functions

Since we can't change LuaJIT's behavior, we'll provide a set of clean, intuitive functions for comparisons in TalMath:

```lua
-- In talmath.lua

-- Equal comparison that handles mixed types
function TalMath.eq(a, b)
    -- Fast path for regular numbers
    if type(a) == "number" and type(b) == "number" then
        return a == b
    end

    -- Ensure both are big numbers if either one is
    if TalMath.isBigNum(a) or TalMath.isBigNum(b) then
        a = TalMath.ensureBig(a)
        b = TalMath.ensureBig(b)
        return a:eq(b)
    end

    -- Fallback for other types
    return a == b
end

-- Less than comparison that handles mixed types
function TalMath.lt(a, b)
    -- Fast path for regular numbers
    if type(a) == "number" and type(b) == "number" then
        return a < b
    end

    -- Ensure both are big numbers if either one is
    if TalMath.isBigNum(a) or TalMath.isBigNum(b) then
        a = TalMath.ensureBig(a)
        b = TalMath.ensureBig(b)
        return a:lt(b)
    end

    -- Fallback
    return a < b
end

-- Greater than comparison that handles mixed types
function TalMath.gt(a, b)
    -- Fast path for regular numbers
    if type(a) == "number" and type(b) == "number" then
        return a > b
    end

    -- Ensure both are big numbers if either one is
    if TalMath.isBigNum(a) or TalMath.isBigNum(b) then
        a = TalMath.ensureBig(a)
        b = TalMath.ensureBig(b)
        return a:gt(b)
    end

    -- Fallback
    return a > b
end

-- Less than or equal comparison
function TalMath.lte(a, b)
    return TalMath.lt(a, b) or TalMath.eq(a, b)
end

-- Greater than or equal comparison
function TalMath.gte(a, b)
    return TalMath.gt(a, b) or TalMath.eq(a, b)
end

-- Helper to check if a value is a big number from any provider
function TalMath.isBigNum(x)
    if type(x) ~= "table" then
        return false
    end

    -- BigNumber format
    if x.m ~= nil and x.e ~= nil then
        return true
    end

    -- OmegaNum format
    if x.array ~= nil and x.sign ~= nil then
        return true
    end

    return false
end
```

## Usage Examples

### For Mod Developers

We'll document clear patterns for mod developers to use:

```lua
-- Method 1: Using TalMath comparison functions (recommended)
local TalMath = require("talmath")

if TalMath.gt(score, 1000) then
    -- Do something when score > 1000
end

-- Method 2: Using explicit comparisons on big numbers
if score:gt(1000) then
    -- Do something when score > 1000
end

-- Method 3: Ensuring both sides are big numbers (works but less efficient)
if to_big(score) > to_big(1000) then
    -- Do something when score > 1000
end
```

### For Talisman Internal Use

Within Talisman itself, we'll consistently use TalMath functions:

```lua
-- Redefine math.max to use our safe comparison
local max = math.max
function math.max(x, y)
    -- Use TalMath for comparisons
    return TalMath.gt(x, y) and x or y
end

local min = math.min
function math.min(x, y)
    -- Use TalMath for comparisons
    return TalMath.lt(x, y) and x or y
end
```

TODO: Should we even monkey patch these functions in the long term?

## Global Helper Functions

For ease of use, we could expose global helper functions (though this would require careful consideration):

```lua
-- Global helpers (optional, but would make migration easier)
function greater_than(a, b)
    return TalMath.gt(a, b)
end

function less_than(a, b)
    return TalMath.lt(a, b)
end

function equals(a, b)
    return TalMath.eq(a, b)
end
```

## Long-term Solution: LuaJIT 2.1 Beta

As mentioned in the Discord discussion, LuaJIT 2.1 with Lua 5.2 compatibility enabled does support `__lt` and `__le` being used for mixed types. If Balatro ever upgrades to a newer LuaJIT version, or there's an ergonomic solution where we can ship this with Talisman, we could use this feature directly.

In the meantime, our TalMath functions provide a clean, consistent approach that works with the current engine.

## Documentation Example

Here's how we'd document this for mod developers:

```markdown
# Using Comparisons with Big Numbers in Talisman

When comparing big numbers in your mod, there are a few approaches to ensure correct behavior:

## Recommended: Use TalMath Comparison Functions

```lua
local TalMath = require("talmath")

if TalMath.gt(score, 100) then
    -- This works correctly for all number types
end

-- Available comparison functions:
-- TalMath.eq(a, b)  -- Equal to (a == b)
-- TalMath.lt(a, b)  -- Less than (a < b)
-- TalMath.gt(a, b)  -- Greater than (a > b)
-- TalMath.lte(a, b) -- Less than or equal (a <= b)
-- TalMath.gte(a, b) -- Greater than or equal (a >= b)
```

## Alternative: Use Big Number Methods Directly

```lua
if someValue:gt(100) then
    -- This works if someValue is already a big number
end
```

## Not Recommended: Manual Type Conversion

```lua
if to_big(someValue) > to_big(100) then
    -- This works but is inefficient
end
```

## Why This Is Necessary

Due to limitations in LuaJIT, the standard comparison operators (`<`, `>`, etc.)
don't work correctly when comparing big numbers with regular numbers. The TalMath
functions handle all the type checking and conversion for you.
```
