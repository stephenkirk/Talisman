# Talisman Rewrite POC

A modernized implementation of the Talisman mod for Balatro that increases the score cap from ~10^308 to ~10^10^1000, allowing for endless runs to go past "naneinf" and Ante 39, while removing the long animations that come with these scores.

## About This Rewrite

This is a complete rewrite of the original Talisman mod, focused on solving several fundamental issues that make the original codebase difficult to maintain and extend:

### Key Improvements

- **Predictable Types**: Clear, consistent type handling with explicit conversions
- **Separation of Concerns**: Math operations are isolated from game logic
- **Performance**: Fast path for regular numbers, avoiding unnecessary allocations by maintaining type boundaries and limiting conversions to specific points
- **Developer-Friendly API**: Consistent interfaces that don't require defensive coding
- **Maintainable Code**: Smaller, focused functions that do one thing well

### Current Status

This rewrite is a work-in-progress. The core math functionality has been implemented, but some game integration features are still being developed:

- ⚠️ Core TalMath implementation with clear type boundaries
- ✅ Common mathematical operations with type safety
- ✅ Number formatting and display
- ✅ Configuration system
- ✅ Animation control
- ⚠️ Complete game integration (partial implementation)
- ⚠️ SteamOdded integration (partial implementation)

## Architecture

The rewrite uses a modular approach with clear separation of concerns:

- **TalMath**: A clean mathematical foundation that handles operations on both regular and big numbers
- **Wrapper Interface**: Maintains compatibility with the original Talisman API
- **Reworked BigNumber**: Can be coerced to string for proper notation eliminating the need of `number_format()`
- **Configuration UI**: Same UI as the original, but backed by the new implementation

### Design Philosophy

1. **Predictability > Convenience**
   - Clear typing so you know what you're getting
   - Functions that return what you expect them to
   - Explicit conversions instead of magic surprises

2. **Math ≠ Game Logic**
   - Math operations in their own library (TalMath)
   - Game stuff stays in game layer
   - Clean interfaces so they don't contaminate each other

3. **Performance Through Clarity**
   - Fast path for regular numbers when possible
   - Convert between types only at defined points
   - Clear thresholds for when big numbers kick in

4. **Developer-Friendly > Defensive**
   - From "handle with care" to "just use it"
   - Consistent API so you don't need protective gear
   - Way fewer "but what if..." edge cases

5. **Future-proof**
   - Actually documented
   - Smaller functions that do one thing
   - Easier to add new stuff without breaking everything

## Installation

Talisman requires [Lovely](https://github.com/ethangreen-dev/lovely-injector) to be installed in order to be loaded by Balatro. The code for Talisman must be installed in `%AppData%/Balatro/Mods/Talisman`.

## Limitations

- High scores will not be saved to your profile (this is to prevent your profile save from being incompatible with an unmodified instance of Balatro)
- Savefiles created/opened with Talisman aren't backwards-compatible with unmodified versions of Balatro
- The largest ante before score requirements reach the new limit is approximately 2e153

## Credits

- The "BigNum" representation used by Talisman is a modified version of [this](https://github.com/veprogames/lua-big-number) library by veprogames
- The "OmegaNum" representation used by Talisman is a port of [OmegaNum.js](https://github.com/Naruyoko/OmegaNum.js) by [Mathguy23](https://github.com/Mathguy23)
- Original Talisman mod by [TBD]
- Rewrite by [steph](https://github.com/stephenkirk)

## For Mod Developers

If you're developing mods that need to handle Talisman's big numbers, this rewrite would make your life much easier:

```lua
-- Old approach (defensive coding required)
local value = to_big(someValue)
if type(value) == "table" then
    -- Do something with big number
else
    -- Do something with regular number
end

-- New approach
local value = TalMath.ensureBig(someValue)  -- Always returns a big number
-- OR
local value = TalMath.normalizeNumber(someValue)  -- Returns a regular number when possible

-- Simple operations work consistently regardless of number type
local result = TalMath.add(value1, value2)
local product = TalMath.multiply(value1, value2)
```

## Contributing

This rewrite is open to collaboration. If you're interested in helping improve Talisman, here are some areas that could use attention:

1. Getting the actual bignumber implementation to work
2. Testing with different game scenarios
3. Implementing the remaining game integration features
4. Performance optimization
5. Documentation improvements

## License

See [LICENSE](LICENSE) for details.
