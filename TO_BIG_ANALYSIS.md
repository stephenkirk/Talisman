# Analysis of `to_big()` Function

## Function Code Review

```lua
function to_big(x, y)
    -- Special case for string "0"
    if type(x) == "string" and x == "0" then
        return 0

    -- BigNum provider path (from bignumber.lua)
    elseif Big and Big.m then
        return Big:new(x, y)

    -- OmegaNum provider path (from omeganum.lua)
    elseif Big and Big.array then
        local result = Big:create(x)
        result.sign = y or result.sign or x.sign or 1
        return result

    -- Regular number path
    elseif is_number(x) then
        return x * 10 ^ (y or 0)

    -- Nil value handling
    elseif type(x) == "nil" then
        return 0

    -- Fallback/array handling path
    else
        -- Handling potential array representations of large numbers
        if (#x >= 2) and ((x[2] >= 2) or (x[2] == 1) and (x[1] > 308)) then
            return 1e309
        end
        if x[2] == 1 then
            return math.pow(10, x[1])
        end
        return x[1] * (y or 1)
    end
end
```

## Core Issues

### 1. Unclear Type Contract

This function has no clear contract about what types it accepts or returns. It tries to handle:

- Regular numbers
- Strings
- BigNum objects
- OmegaNum objects
- Array representations of numbers
- nil values

This lack of clear type boundaries creates a "kitchen sink" function that must handle every possible case.

### 2. Provider-Dependent Behavior

The function behaves differently based on the currently loaded big number provider:

```lua
-- Completely different code paths based on which provider is active
elseif Big and Big.m then  -- BigNum provider
    return Big:new(x, y)
elseif Big and Big.array then  -- OmegaNum provider
    local result = Big:create(x)
    result.sign = y or result.sign or x.sign or 1
    return result
```

This means the same input can produce different output types depending on configuration, making it impossible to reason about the function's behavior without knowing the global state.

### 3. Return Type Inconsistency

The function can return:
- A regular Lua number (`return 0`, `return 1e309`, etc.)
- A BigNum or OmegaNum object

Callers must defensively handle all these possible return types.

### 4. Parameter Overloading

The second parameter `y` has inconsistent meanings:
- For BigNum, it's the exponent part
- For OmegaNum, it might be used as a sign
- For regular numbers, it's used as an exponent multipler

This parameter overloading creates confusion and makes the function harder to use correctly.

### 5. Special Casing

Special cases like the string "0" handling reveal implementation difficulties:

```lua
if type(x) == "string" and x == "0" then --hack for when 0 is asked to be a bignumber need to really figure out the fix
    return 0
end
```

The comment itself admits this is a "hack" rather than a proper solution.

### 6. The "else" Fallback

The final else clause is especially problematic:

```lua
else
    if (#x >= 2) and ((x[2] >= 2) or (x[2] == 1) and (x[1] > 308)) then
        return 1e309
    end
    if x[2] == 1 then
        return math.pow(10, x[1])
    end
    return x[1] * (y or 1)
end
```

This assumes `x` is an array-like table The magic numbers (`308`, `1e309`) are also not explained or consistent with other thresholds.

## Performance Impact

### 1. Runtime Type Checking

Every call requires multiple type checks:
- `type(x) == "string"`
- `Big and Big.m`
- `Big and Big.array`
- `is_number(x)`
- `type(x) == "nil"`

These checks are performed even when the function is called hundreds or thousands of times with the same type.

### 2. Provider Detection Overhead

The function rechecks which provider is active on every call:

```lua
elseif Big and Big.m then       -- Is BigNum active?
    ...
elseif Big and Big.array then   -- Is OmegaNum active?
    ...
```

This information could be determined once at initialization rather than on every call.

### 3. Nested Conversions

The function gets called recursively in many cases:

```lua
function math.max(x, y)
    if type(x) == 'table' or type(y) == 'table' then
        x = to_big(x)  -- First conversion
        y = to_big(y)  -- Second conversion
        if (x > y) then
            return x
        else
            return y
        end
    else
        return max(x,y)
    end
end
```

Each of these conversions repeats all the type checking and provider detection, exponentially increasing the overhead.

### 4. Garbage Collection Pressure

Every call that returns a new big number object creates a new table, increasing memory usage and GC pressure. During heavy calculation phases, this can cause frequent GC pauses.

## Example Call Trace

When a simple operation like `math.max(a, b)` occurs where `a` is a regular number and `b` is a BigNum:

1. `math.max` detects mixed types, calls `to_big(a)` and `to_big(b)`
2. `to_big(a)` does 5+ type checks, finally reaching `is_number(a)`, returns `a * 10^0`
3. `to_big(b)` does 5+ type checks, reaches BigNum path, returns `Big:new(b)`
4. Comparison `x > y` happens using operator overloading
5. Result is returned back up the call stack

This simple operation involved 10+ type checks and multiple object creations, all to determine which type the return value should be.

## Root Causes

1. **No Type System**: Lua's dynamic typing makes this approach tempting but inefficient
2. **Multiple Number Representations**: Having two different big number implementations complicates matters
3. **Implicit Conversions**: The system tries to be "smart" by automatically converting between types
4. **Global Provider State**: The behavior depends on global configuration rather than explicit choices
5. **Defensive Programming Overspread**: The defensive approach spread throughout the codebase

## Impact


### 1. Constant Type Checking Even During Idle

```lua
-- this happens hundreds of times per second
	function math.exp(x)
   	sendInfoMessage("math.exp called")
		local big_e = to_big(2.718281828459045)

		if type(big_e) == "number" then
			return lenient_bignum(big_e ^ x)
		else
			return lenient_bignum(big_e:pow(x))
		end
	end
```

Even when the game is sitting at the main menu, these math operations are being called constantly for UI rendering, animations, etc. Each call incurs:
- Type checking overhead
- Potential conversion overhead
- Runtime branching


### 2. Defensive Coding Spreads Through Mods

Mod authors must write defensive code to handle the unpredictability:

```lua
function calculate(self, card, context)
  -- Every number needs defensive handling because
  -- we don't know if it's regular, BigNum, or OmegaNum
  return {
    chip_mod = lenient_bignum(card.ability.extra.stat1),
    mult_mod = lenient_bignum(card.ability.extra.stat1),
    Xchip_mod = lenient_bignum(card.ability.extra.stat2),
    Xmult_mod = lenient_bignum(card.ability.extra.stat2),
  }
}
```

Examining mod code shows how the problem compounds. For example, in the "Old Membership Card" joker:

```lua
chip_mod = lenient_bignum(
  to_big(card.ability.extra.chips)
    * math.floor(Cryptid.member_count / card.ability.immutable.chips_mod)
)
```

Every calculation requires:
1. Conversion to big number with `to_big()`
2. A math operation that may trigger additional conversions
3. Another conversion with `lenient_bignum()` for the return value

This pattern appears multiple times in a single joker implementation, multiplied across:
- Initial calculation
- Display formatting
- Localization
- Message generation

For complex mods with many jokers, this overhead accumulates rapidly, especially when values approach the conversion threshold.

This defensive pattern spreads throughout the codebase and all mods, creating unnecessary overhead in every calculation.

## Memory Impact

The current approach also creates significant garbage collection pressure:

- Each conversion can create a new table object
- These objects pile up during complex calculations
- The scoring coroutine has to run garbage collection frequently:

```lua
if collectgarbage("count") > 1024*1024 then
  collectgarbage("collect")
end
```

## Real Impact During Gameplay and Development

1. **Framerate Drops**: During complex scoring, FPS can drop significantly
2. **Scoring Time**: Scoring complex joker combinations takes significantly longer
3. **UI Responsiveness**: Even UI animations can stutter from math overheads
4. **Mod Compatibility**: Mods that do frequent calculations face compounding overhead
5. **Leaky Abstractions**: Mods implementing this inherit these issues, as the abstraction forces them to handle potentially different number types at every calculation point

## Thoughts

Looking through the codebase, the system is constantly wondering "What kind of number is this and how should I handle it?" at nearly every
  operation. For example:

  1. During UI rendering: math.max(x, y) needs to check types and potentially convert both values before a simple comparison
  2. In joker effects: Card:calculate_joker(context) performs dozens of conversions as values flow through calculations
  3. In math functions: math.log10(x) first checks if it's a table, then looks for different method names to determine which bignum
  implementation it has
  4. In display code: number_format(num) converts to bignum, compares against thresholds, then potentially converts back
  5. When updating scores: G.GAME.round_scores[score].amt = to_big(math.floor(amt)) potentially converts the same value multiple times

  These constant type checks and conversions are occurring even when the game is sitting idle at the main menu, as evidenced by your debug
  messages showing math.max, math.log, and math.exp being called frequently.

  A better approach would be to decide "This value WILL be a bignum throughout this entire calculation chain" and only convert at final
  boundaries.


## Synthesis
The most critical problem shown by this analysis is how much computational overhead comes from repeatedly handling type conversions at every calculation point. The deeper question we need to ask is: "What are the actual boundaries where we need something to be a specific number type?"

Looking at the code, we're constantly doing defensive checks and conversions, even when the game is just idling. Each of these conversions adds overhead:

- Converting UI values every frame
- Converting joker calculation inputs and outputs
- Converting for math functions (log, exp, max)
- Converting for display formatting
- Converting for game state updates

The real problem is we've made every math operation a boundary that needs type checking, rather than establishing clear points where conversion should happen.

This suggests we need a different architecture:

1. **Define type boundaries explicitly**: Only convert at specific interface points (UI input/output, save/load, etc.)

2. **Process in consistent formats**: Once we're in a calculation flow, stick with one number representation

3. **Isolate provider details**: Number types should present the same interface regardless of provider

4. **Push conversions to the edges**: Convert only when crossing system boundaries, not within calculation flows

This would dramatically reduce the hundreds of conversions happening during idle time, as we'd only convert when absolutely necessary rather than at every operation.

## Discord message:

I've been exploring optimization opportunities in Talisman after implementing some Cryptid jokers and just wanted to infodump some observations~

**The problem**

I keep running into patterns like this in Cryptid code:

```lua
chip_mod = lenient_bignum(
  to_big(card.ability.extra.chips)
    * math.floor(Cryptid.member_count / card.ability.immutable.chips_mod)
)
```

Basically every calculation needs:
1. `to_big()` to start with (which might not necessarily return a Big number, see below)
2. Some math operations (that I'm unsure if they may trigger additional conversions through the overrides in Talisman)
3. `lenient_bignum()` to wrap it up

**The developer experience**
The biggest pain point here is that mod authors have to play hot potato with values - wrapping almost everything in `to_big()` without knowing if it's actually necessary. And despite its name, `to_big()` might not even return a big number! This creates a ton of defensive coding where we constantly convert and check types. As a mod author, you can never be sure what type you're working with, so you end up wrapping everything just to be safe.

**What's Happening Under the Hood in Talisman**:

The `to_big()` function is pretty interesting:

```lua
elseif Big and Big.m then       -- Is BigNum active?
    ...
elseif Big and Big.array then   -- Is OmegaNum active?
    ...
elseif is_number(x) then
    ...
```

It checks which number system is active on every call and can actually return either primitive Lua numbers or complex BigNum/OmegaNum objects.

Then the overridden math functions have to handle both possibilities:

```lua
-- this happens hundreds of times per second even when idling at the main menu
function math.exp(x)
    local big_e = to_big(2.718281828459045)

    if type(big_e) == "number" then
        return lenient_bignum(big_e ^ x)
    else
        return lenient_bignum(big_e:pow(x))
    end
end
```

Confirmed just idling in the main menu calls the overridden `math.exp` hundreds of times a second!

I don't understand Lua fully behind the hood yet or the full implementation but I'm guessing this likely creates significant garbage collection pressure:
- New table objects with every conversion
- Garbage piles up in complex calculations
- That's probably why we see this in the scoring coroutine to force garbage collection:

```lua
if collectgarbage("count") > 1024*1024 then
  collectgarbage("collect")
end
```

**Optimization ideas**

I scrolled through this channel and saw a discussion about a talisman rework earlier which seems to hint at the same things I'm noticing, but I wanted to share some specific observations after my rabbit hole. Just thinking out loud:

1. **Cache provider detection**: We could determine the active number system once at initialization instead of checking which provider is active on every single call

2. **Clear type boundaries**: Right now it's a guessing game - establish when values should be primitives vs BigNum objects so mod authors aren't constantly wrapping everything "just in case"

3. **Consistent return types**: Make `to_big()` actually return big numbers consistently, or rename it to reflect what it actually does

4. **Reduce conversion points**: Only convert at well-defined boundaries (UI, save/load, etc.) instead of during intermediate calculations (note: I'm )

5. **Better abstraction**: Hide the implementation details so mod authors don't need to worry about whether they're dealing with a primitive or a BigNum

A cleaner abstraction would make writing mods easier while probably also improving performance a lot. Anyone else have thoughts on where the line should be between normal Lua numbers and BigNum objects?
