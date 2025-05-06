# Talisman Rewrite Implementation Plan

## Current State Analysis

The Talisman library has several critical issues:
1. **Type Inconsistency**: Unpredictable return types from functions like `to_big()`
2. **Function Monkey-Patching**: Excessive overriding of math functions with little shared code
3. **Game Logic Spaghetti**: Big number logic mixed with game-specific functionality
4. **Defensive Coding Nightmare**: Excessive type checking and conversion
5. **Provider Confusion**: Inconsistent APIs between BigNumber and OmegaNum
6. **Performance Issues**: Unnecessary object allocations and conversions

## Guiding Principles

1. **Predictability over Convenience**: Clear and consistent typing
2. **Separation of Concerns**: Math operations separate from game logic
3. **Performance Through Clarity**: Fast paths for regular numbers, clear conversion points
4. **Developer-Friendly API**: Reduce defensive programming needs
5. **Future-Proof**: Well-documented, modular functions

## Implementation Strategy: Incremental Approach

Rather than a "big bang" rewrite, we'll implement improvements incrementally to minimize disruption.

### Phase 1: Unify Big Number Providers (Quick Win)

**Goal**: Create a consistent interface for both BigNumber and OmegaNum

1. Create a unified interface class/module that both providers implement
2. Update both implementations to have identical method names and behaviors
3. Implement TaiAurori's OmegaNum optimizations (3.3x performance improvement)
4. Add comprehensive tests for both providers

**Benefit**: Consistency without changing user-facing APIs

### Phase 2: String Conversion Improvement (Quick Win)

**Goal**: Eliminate need for `number_format()` function

1. Override `__tostring` for both big number types
2. Implement notations consistently between providers
3. Ensure proper formatting with Balatro's style
4. Add tests for all notation formats

**Benefit**: Simplifies code that displays numbers

### Phase 3: Safe Math Operations Layer (Incremental)

**Goal**: Standardize mathematical operations across providers and fill gaps

1. Identify inconsistencies between BigNumber and OmegaNum implementations
2. Create `TalMath` interface that normalizes behavior across providers
3. Optimize common operations with fast paths while maintaining type safety
4. Focus on complex operations (logarithms, exponents) where inconsistencies are common
5. Add comprehensive tests to verify consistent behavior

**Benefit**: Provides standardized mathematical operations that work predictably across providers while leveraging existing capabilities.

### Phase 4: Transition Strategy (Hybrid Approach)

**Goal**: Gradually move code to new APIs without breaking existing mods

1. Update talisman.lua to use the new TalMath functions internally
2. Keep original function names and signatures for backwards compatibility
3. Deprecate but maintain problematic functions like `to_big()` and `lenient_bignum()`
4. Create usage documentation for mod developers

**Benefit**: Allows incremental improvement without breaking existing mods

### Phase 5: Comparison Operators Solution

**Goal**: Address the LuaJIT limitation with mixed-type comparisons

1. Implement TalMath comparison functions that explicitly handle mixed types (`gt`, `lt`, `eq`, etc.)
2. Create a clear usage pattern for safe comparisons
3. Document best practices for mod authors
4. Consider a solution leveraging newer LuaJIT if possible

**Benefit**: Clear path forward for handling the most troublesome part of the API

**Notes**: Potentially coordinate with LuaJIT enhancements from the community

### Phase 6: Optimize Performance (Targeted Improvements)

**Goal**: Identify and fix key performance bottlenecks

1. Implement further optimizations to reduce unnecessary object creation
2. Profile the most common operations to identify hotspots
3. Optimize core math operations for common cases
4. Reduce unnecessary type conversions

**Benefit**: Better performance without sacrificing readability

### Phase 7: Documentation and Examples (Future-Proof)

**Goal**: Make the library easier to use correctly

1. Create comprehensive documentation of the API
2. Provide clear examples for mod authors
3. Document common patterns and anti-patterns
4. Create migration guides for existing code

**Benefit**: Reduces future maintenance burden and helps adoption

## Implementation Timeline

1. **Phase 1-2**: Quick wins to build momentum
2. **Phase 3-4**: Core functionality replacement
3. **Phase 5-6**: Address hardest problems and performance
4. **Phase 7**: Documentation and support

## Success Metrics

1. Clear, consistent APIs for developers
2. Measurable performance improvements
3. Positive feedback from mod community
4. Reduction in defensive coding patterns
5. Backward compatibility with existing mods
