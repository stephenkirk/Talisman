-- Talisman wrapper
-- This file serves as a drop-in replacement for the original talisman.lua
-- It maintains the same interface but uses TalMath for the actual implementation

local lovely = require("lovely")
local nativefs = require("nativefs")

-- Ensure the Talisman folder exists
if not nativefs.getInfo(lovely.mod_dir .. "/Talisman") then
	error(
		'Could not find proper Talisman folder.\nPlease make sure the folder for Talisman is named exactly "Talisman" and not "Talisman-main" or anything else.'
	)
end

-- Load our clean implementation with improved math operations
local TalMath = nativefs.load(lovely.mod_dir .. "/Talisman/talmath.lua")()
if not TalMath then
	error("Failed to load TalMath. Please ensure talmath.lua exists and is valid.")
end

-- "Borrowed" from Trance - Keep this for compatibility
function load_file_with_fallback2(a, aa)
	local success, result = pcall(function()
		return assert(load(nativefs.read(a)))()
	end)
	if success then
		return result
	end
	local fallback_success, fallback_result = pcall(function()
		return assert(load(nativefs.read(aa)))()
	end)
	if fallback_success then
		return fallback_result
	end
end

-- Preserve the original localization function for compatibility
local talismanloc = init_localization
function init_localization()
	local abc = load_file_with_fallback2(
		lovely.mod_dir .. "/Talisman/localization/" .. (G.SETTINGS.language or "en-us") .. ".lua",
		lovely.mod_dir .. "/Talisman/localization/en-us.lua"
	)
	for k, v in pairs(abc) do
		if k ~= "descriptions" then
			G.localization.misc.dictionary[k] = v
		end
		G.localization.misc.dictionary[k] = v
	end
	talismanloc()
end

Talisman = { config_file = { disable_anims = true, break_infinity = "bignumber-poc", score_opt_id = 2 } }

-- Load configuration
if nativefs.read(lovely.mod_dir .. "/Talisman/config.lua") then
	Talisman.config_file = STR_UNPACK(nativefs.read(lovely.mod_dir .. "/Talisman/config.lua"))

	if not Talisman.config_file.break_infinity or type(Talisman.config_file.break_infinity) ~= "string" then
		Talisman.config_file.break_infinity = "bignumber-poc"
	end
end

-- UI hooks
if not SMODS or not JSON then
	local createOptionsRef = create_UIBox_options
	function create_UIBox_options()
		contents = createOptionsRef()
		local m = UIBox_button({
			minw = 5,
			button = "talismanMenu",
			label = {
				localize({ type = "name_text", set = "Spectral", key = "c_talisman" }),
			},
			colour = G.C.GOLD,
		})
		table.insert(contents.nodes[1].nodes[1].nodes[1].nodes, #contents.nodes[1].nodes[1].nodes[1].nodes + 1, m)
		return contents
	end
end

-- Configuration UI - Keep exactly the same as original
Talisman.config_tab = function()
	tal_nodes = {
		{
			n = G.UIT.R,
			config = { align = "cm" },
			nodes = {
				{
					n = G.UIT.O,
					config = {
						object = DynaText({
							string = localize("talisman_string_A"),
							colours = { G.C.WHITE },
							shadow = true,
							scale = 0.4,
						}),
					},
				},
			},
		},
		create_toggle({
			label = localize("talisman_string_B"),
			ref_table = Talisman.config_file,
			ref_value = "disable_anims",
			callback = function(_set_toggle)
				nativefs.write(lovely.mod_dir .. "/Talisman/config.lua", STR_PACK(Talisman.config_file))
			end,
		}),
		create_option_cycle({
			label = localize("talisman_string_C"),
			scale = 0.8,
			w = 6,
			options = {
				localize("talisman_vanilla"),
				localize("talisman_bignum"),
				localize("talisman_omeganum") .. "(e10##1000)",
			},
			opt_callback = "talisman_upd_score_opt",
			current_option = Talisman.config_file.score_opt_id,
		}),
	}
	return {
		n = G.UIT.ROOT,
		config = {
			emboss = 0.05,
			minh = 6,
			r = 0.1,
			minw = 10,
			align = "cm",
			padding = 0.2,
			colour = G.C.BLACK,
		},
		nodes = tal_nodes,
	}
end

-- Preserve original menu functions
G.FUNCS.talismanMenu = function(e)
	local tabs = create_tabs({
		snap_to_nav = true,
		tabs = {
			{
				label = localize({ type = "name_text", set = "Spectral", key = "c_talisman" }),
				chosen = true,
				tab_definition_function = Talisman.config_tab,
			},
		},
	})
	G.FUNCS.overlay_menu({
		definition = create_UIBox_generic_options({
			back_func = "options",
			contents = { tabs },
		}),
		config = { offset = { x = 0, y = 10 } },
	})
end

G.FUNCS.talisman_upd_score_opt = function(e)
	Talisman.config_file.score_opt_id = e.to_key
	local score_opts = { "", "bignumber", "bignumber-poc", "omeganum" }
	Talisman.config_file.break_infinity = score_opts[e.to_key]
	nativefs.write(lovely.mod_dir .. "/Talisman/config.lua", STR_PACK(Talisman.config_file))
end

if Talisman.config_file.break_infinity then
	Big, err = nativefs.load(lovely.mod_dir .. "/Talisman/big-num/bignumber-poc.lua")
	if not err then
		Big = Big()
	else
		Big = nil
	end

	Notations = nativefs.load(lovely.mod_dir .. "/Talisman/big-num/notations.lua")()

	-- Game object initialization - keep same as original
	Talisman.igo = function(obj)
		for _, v in pairs(obj.hands) do
			v.chips = to_big(v.chips)
			v.mult = to_big(v.mult)
			v.s_chips = to_big(v.s_chips)
			v.s_mult = to_big(v.s_mult)
			v.l_chips = to_big(v.l_chips)
			v.l_mult = to_big(v.l_mult)
			v.level = to_big(v.level)
		end
		obj.starting_params.dollars = to_big(obj.starting_params.dollars)
		return obj
	end
end

-- GLOBAL FUNCTION WRAPPERS FOR COMPATIBILITY
function abs(x)
	return TalMath.abs(x)
end

-- Global to_big function - use TalMath's implementation
function to_big(x, y)
	if type(x) == "string" or x == "0" or type(x) == "nil" then
		return 0
	end

	if is_number(x) then
		return x
	end

	-- Always return big number for consistency
	print(TalMath.ensureBig(x))
	return TalMath.ensureBig(x)
end

-- Global to_number function - use TalMath's implementation
function to_number(x)
	-- Just call our normalized function
	return TalMath.normalizeNumber(x)
end

-- Check if a value is a number (regular or big)
function is_number(x)
	if type(x) == "number" then
		return true
	end
	if type(x) == "table" and ((x.e and x.m) or (x.array and x.sign)) then
		return true
	end
	return false
end

-- -- Helper function for conversion between bignums and regular numbers
function lenient_bignum(x)
	if type(x) == "number" then
		return x
	end
	if to_big(x) < to_big(1e300) and to_big(x) > to_big(-1e300) then
		return x:to_number()
	end
	return x
end

-- -- Overrides for native math functions to handle big numbers
-- local mf = math.floor
-- function math.floor(x)
-- 	if type(x) == "table" then
-- 		return x:floor()
-- 	end
-- 	return mf(x)
-- end

-- local mc = math.ceil
-- function math.ceil(x)
-- 	if type(x) == "table" then
-- 		return x:ceil()
-- 	end
-- 	return mc(x)
-- end

-- -- Overrides for math functions to handle big numbers
-- local l10 = math.log10
-- function math.log10(x)
-- 	if type(x) == "table" then
-- 		if x.log10 then
-- 			return lenient_bignum(x:log10())
-- 		end
-- 		return lenient_bignum(l10(math.min(x:to_number(), 1e300)))
-- 	end
-- 	return lenient_bignum(l10(x))
-- end

-- local lg = math.log
-- function math.log(x, y)
-- 	if not y then
-- 		y = 2.718281828459045
-- 	end
-- 	if type(x) == "table" then
-- 		if x.log then
-- 			return lenient_bignum(x:log(to_big(y)))
-- 		end
-- 		if x.logBase then
-- 			return lenient_bignum(x:logBase(to_big(y)))
-- 		end
-- 		return lenient_bignum(lg(math.min(x:to_number(), 1e300), y))
-- 	end
-- 	return lenient_bignum(lg(x, y))
-- end

-- function math.exp(x)
-- 	local big_e = to_big(2.718281828459045)

-- 	if type(big_e) == "number" then
-- 		return lenient_bignum(big_e ^ x)
-- 	else
-- 		return lenient_bignum(big_e:pow(x))
-- 	end
-- end

-- local max = math.max
-- function math.max(x, y)
-- 	-- Use TalMath for comparisons
-- 	return TalMath.gt(x, y) and x or y
-- end

-- local min = math.min
-- function math.min(x, y)
-- 	-- Use TalMath for comparisons
-- 	return TalMath.lt(x, y) and x or y
-- end

-- local sqrt = math.sqrt
-- function math.sqrt(x)
-- 	if type(x) == "table" then
-- 		if getmetatable(x) == BigMeta then
-- 			return x:sqrt()
-- 		end
-- 		if getmetatable(x) == OmegaMeta then
-- 			return x:pow(0.5)
-- 		end
-- 	end
-- 	return sqrt(x)
-- end

-- local old_abs = math.abs
-- function math.abs(x)
-- 	return TalMath.abs(x)
-- end

-- Replace number_format with TalMath version
local nf = number_format
function number_format(num, e_switch_point)
	-- Use TalMath's formatting
	return TalMath.format(num)
end

-- Copy over animation-related functions as-is for now
-- These will need to be replaced with cleaner implementations, but for a
-- drop-in replacement, we keep them the same initially

-- Animation control functions
local cest = card_eval_status_text
function card_eval_status_text(a, b, c, d, e, f)
	if not Talisman.config_file.disable_anims then
		cest(a, b, c, d, e, f)
	end
end

local jc = juice_card
function juice_card(x)
	if not Talisman.config_file.disable_anims then
		jc(x)
	end
end

local cju = Card.juice_up
function Card:juice_up(...)
	if not Talisman.config_file.disable_anims then
		cju(self, ...)
	end
end

-- Text update function for hand displays
function tal_uht(config, vals)
	local col = G.C.GREEN
	if vals.chips and G.GAME.current_round.current_hand.chips ~= vals.chips then
		local delta = (is_number(vals.chips) and is_number(G.GAME.current_round.current_hand.chips))
				and (vals.chips - G.GAME.current_round.current_hand.chips)
			or 0
		if to_big(delta) < to_big(0) then
			delta = number_format(delta)
			col = G.C.RED
		elseif to_big(delta) > to_big(0) then
			delta = "+" .. number_format(delta)
		else
			delta = number_format(delta)
		end
		if type(vals.chips) == "string" then
			delta = vals.chips
		end
		G.GAME.current_round.current_hand.chips = vals.chips
		if G.hand_text_area.chips.config.object then
			G.hand_text_area.chips:update(0)
		end
	end
	if vals.mult and G.GAME.current_round.current_hand.mult ~= vals.mult then
		local delta = (is_number(vals.mult) and is_number(G.GAME.current_round.current_hand.mult))
				and (vals.mult - G.GAME.current_round.current_hand.mult)
			or 0
		if to_big(delta) < to_big(0) then
			delta = number_format(delta)
			col = G.C.RED
		elseif to_big(delta) > to_big(0) then
			delta = "+" .. number_format(delta)
		else
			delta = number_format(delta)
		end
		if type(vals.mult) == "string" then
			delta = vals.mult
		end
		G.GAME.current_round.current_hand.mult = vals.mult
		if G.hand_text_area.mult.config.object then
			G.hand_text_area.mult:update(0)
		end
	end
	if vals.handname and G.GAME.current_round.current_hand.handname ~= vals.handname then
		G.GAME.current_round.current_hand.handname = vals.handname
	end
	if vals.chip_total then
		G.GAME.current_round.current_hand.chip_total = vals.chip_total
		G.hand_text_area.chip_total.config.object:pulse(0.5)
	end
	if
		vals.level
		and G.GAME.current_round.current_hand.hand_level ~= " " .. localize("k_lvl") .. tostring(vals.level)
	then
		if vals.level == "" then
			G.GAME.current_round.current_hand.hand_level = vals.level
		else
			G.GAME.current_round.current_hand.hand_level = " " .. localize("k_lvl") .. tostring(vals.level)
			if is_number(vals.level) then
				G.hand_text_area.hand_level.config.colour = G.C.HAND_LEVELS[type(vals.level) == "number" and math.floor(
					math.min(vals.level, 7)
				) or math.floor(to_big(math.min(vals.level, 7))):to_number()]
			else
				G.hand_text_area.hand_level.config.colour = G.C.HAND_LEVELS[1]
			end
		end
	end
	return true
end

-- Override update_hand_text to support animation disabling
local uht = update_hand_text
function update_hand_text(config, vals)
	if Talisman.config_file.disable_anims then
		if G.latest_uht then
			local chips = G.latest_uht.vals.chips
			local mult = G.latest_uht.vals.mult
			if not vals.chips then
				vals.chips = chips
			end
			if not vals.mult then
				vals.mult = mult
			end
		end
		G.latest_uht = { config = config, vals = vals }
	else
		uht(config, vals)
	end
end

-- STEAMODDED INTEGRATION
-- This would need to be implemented based on whether SMODS is available
if SMODS and SMODS.calculate_individual_effect then
	-- Add implementation for SMODS integration
	-- Similar to the original talisman.lua's implementation
end

-- BASIC GAME LOOP HOOKS
-- This ensures TalMath is fully initialized and doesn't interfere with animations

-- Game update hook to ensure text updates
local upd = Game.update
function Game:update(dt)
	upd(self, dt)
	if G.latest_uht and G.latest_uht.config and G.latest_uht.vals then
		tal_uht(G.latest_uht.config, G.latest_uht.vals)
		G.latest_uht = nil
	end
	if Talisman.dollar_update then
		G.HUD:get_UIE_by_ID("dollar_text_UI").config.object:update()
		G.HUD:recalculate()
		Talisman.dollar_update = false
	end
end

-- Safe string unpacking with environment restrictions
function safe_str_unpack(str)
	local chunk, err = loadstring(str)
	if chunk then
		setfenv(chunk, { Big = Big, BigMeta = BigMeta, OmegaMeta = OmegaMeta, to_big = to_big, inf = 1.79769e308 }) -- Use an empty environment to prevent access to potentially harmful functions
		local success, result = pcall(chunk)
		if success then
			return result
		else
			print("[Talisman] Error unpacking string: " .. result)
			print(tostring(str))
			return nil
		end
	else
		print("[Talisman] Error loading string: " .. err)
		print(tostring(str))
		return nil
	end
end

local g_start_up = G.start_up
function G:start_up()
	STR_UNPACK = safe_str_unpack
	g_start_up(self)
	STR_UNPACK = safe_str_unpack
end

function mod_chips(value)
	-- Simply pass through for now
	return value
end

function mod_mult(value)
	-- Simply pass through for now
	return value
end

-- Scale number implementation
-- Dynamically reduces the scale factor for large numbers to prevent UI overflow,
-- using logarithmic scaling based on the number's magnitude
-- TODO: This currently breaks starting a new game
-- and might be... unnecessary...? since bignum supports operations etc
-- But...
-- function scale_number(number, scale, max, e_switch_point)
-- 	if not Big then
-- 		return scale
-- 	end
-- 	scale = to_big(scale)
-- 	G.E_SWITCH_POINT = G.E_SWITCH_POINT or 100000000000
-- 	if not number or not is_number(number) then
-- 		return scale
-- 	end
-- 	if not max then
-- 		max = 10000
-- 	end
-- 	if to_big(number).e and to_big(number).e == 10 ^ 1000 then
-- 		scale = scale * math.floor(math.log(max * 10, 10)) / 7
-- 	end
-- 	if to_big(number) >= to_big(e_switch_point or G.E_SWITCH_POINT) then
-- 		if to_big(to_big(number):log10()) <= to_big(999) then
-- 			scale = scale * math.floor(math.log(max * 10, 10)) / math.floor(math.log(1000000 * 10, 10))
-- 		else
-- 			scale = scale
-- 				* math.floor(math.log(max * 10, 10))
-- 				/ math.floor(math.max(7, string.len(number_format(number)) - 1))
-- 		end
-- 	elseif to_big(number) >= to_big(max) then
-- 		scale = scale * math.floor(math.log(max * 10, 10)) / math.floor(math.log(number * 10, 10))
-- 	end
-- 	return math.min(3, scale:to_number())
-- end

-- Blind amount calculation
-- TODO: Determine if this is necessary
-- But at least good news that it works with big numbers
local gba = get_blind_amount -- vanilla
function get_blind_amount(ante)
	return to_big(gba(ante))
end

if SMODS then
	function SMODS.get_blind_amount(ante)
		return get_blind_amount(ante)
	end
end

-- Check and set high score (simplified version)
function check_and_set_high_score(score, amt)
	if G.GAME.round_scores[score] and to_big(math.floor(amt)) > to_big(G.GAME.round_scores[score].amt) then
		G.GAME.round_scores[score].amt = to_big(math.floor(amt))
	end
	if G.GAME.seeded then
		return
	end
end

-- Career stat tracking
function inc_career_stat(stat, mod)
	if G.GAME.seeded or G.GAME.challenge then
		return
	end
	if not G.PROFILES[G.SETTINGS.profile].career_stats[stat] then
		G.PROFILES[G.SETTINGS.profile].career_stats[stat] = 0
	end
	G.PROFILES[G.SETTINGS.profile].career_stats[stat] = G.PROFILES[G.SETTINGS.profile].career_stats[stat] + (mod or 0)
	-- Make sure this isn't ever a talisman number
	if type(G.PROFILES[G.SETTINGS.profile].career_stats[stat]) == "table" then
		if G.PROFILES[G.SETTINGS.profile].career_stats[stat] > to_big(1e300) then
			G.PROFILES[G.SETTINGS.profile].career_stats[stat] = to_big(1e300)
		elseif G.PROFILES[G.SETTINGS.profile].career_stats[stat] < to_big(-1e300) then
			G.PROFILES[G.SETTINGS.profile].career_stats[stat] = to_big(-1e300)
		end
		G.PROFILES[G.SETTINGS.profile].career_stats[stat] =
			G.PROFILES[G.SETTINGS.profile].career_stats[stat]:to_number()
	end
	G:save_settings()
end

-- Evaluate play Overrides
-- TODO: This currently breaks playing a hand
-- G.FUNCS.evaluate_play = function(e)
-- 	text, disp_text, poker_hands, scoring_hand, non_loc_disp_text, percent, percent_delta = evaluate_play_intro()
-- 	if not G.GAME.blind:debuff_hand(G.play.cards, poker_hands, text) then
-- 		text, disp_text, poker_hands, scoring_hand, non_loc_disp_text, percent, percent_delta =
-- 			evaluate_play_main(text, disp_text, poker_hands, scoring_hand, non_loc_disp_text, percent, percent_delta)
-- 	else
-- 		text, disp_text, poker_hands, scoring_hand, non_loc_disp_text, percent, percent_delta =
-- 			evaluate_play_debuff(text, disp_text, poker_hands, scoring_hand, non_loc_disp_text, percent, percent_delta)
-- 	end
-- 	text, disp_text, poker_hands, scoring_hand, non_loc_disp_text, percent, percent_delta = evaluate_play_final_scoring(
-- 		text,
-- 		disp_text,
-- 		poker_hands,
-- 		scoring_hand,
-- 		non_loc_disp_text,
-- 		percent,
-- 		percent_delta
-- 	)
-- 	evaluate_play_after(text, disp_text, poker_hands, scoring_hand, non_loc_disp_text, percent, percent_delta)
-- end

function ease_dollars(mod, instant)
	if Talisman.config_file.disable_anims then
		mod = mod or 0
		if to_big(mod) < to_big(0) then
			inc_career_stat("c_dollars_earned", mod)
		end
		G.GAME.dollars = G.GAME.dollars + mod
		Talisman.dollar_update = true
	else
		-- Call original ease_dollars
		return edo(mod, instant)
	end
end
