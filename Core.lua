local ADDON_NAME, ns = ...

-- HandyNotes must be loaded for this module to do anything.
local HandyNotes = _G.HandyNotes
if not HandyNotes then
	return
end

-- Val's uiMapID (Patch 12.0.7 / Midnight Void Showdown zone)
-- via: /dump C_Map.GetBestMapForUnit("player")
local MAP_ID = 2599

-- Icon shown for each teleport pin on the world map
-- Uses the Blizzard "FlightMaster-Argus-Taxi_Frame_Yellow" atlas. HandyNotes' pin code only
-- ever calls SetTexture() (never SetAtlas()), so we resolve the atlas into its underlying
-- texture file + crop coordinates once here, and pass that table as the "icon" everywhere.

local ATLAS_NAME = "FlightMaster_Argus-TaxiNode_Neutral"
local ICON

do
	local atlasInfo = C_Texture.GetAtlasInfo(ATLAS_NAME)
	if atlasInfo then
		ICON = {
			icon = atlasInfo.file,
			tCoordLeft = atlasInfo.leftTexCoord,
			tCoordRight = atlasInfo.rightTexCoord,
			tCoordTop = atlasInfo.topTexCoord,
			tCoordBottom = atlasInfo.bottomTexCoord,
		}
	else
		-- Fallback in case the atlas name ever changes/disappears.
		print("|cffff8800HandyNotes_ValTeleports:|r atlas '" .. ATLAS_NAME .. "' not found, using fallback icon.")
		ICON = "interface/icons/spell_arcane_portaldarnassus"
	end
end

--------------------------------------------------------------------------------
-- NODE DATA
--------------------------------------------------------------------------------
-- Node coordinates below are entered as percentages (matching /way, e.g. 46.68, 82.91).
-- The C() helper converts them to HandyNotes' packed coord format.
--------------------------------------------------------------------------------

local function C(x, y)
	-- x, y are given as percentages (0-100), matching /way output.
	-- HandyNotes packs coords from FRACTIONS (0-1), using:
	--   floor(x*10000+0.5)*10000 + floor(y*10000+0.5)
	-- which it later unpacks as:
	--   x = floor(coord/10000)/10000,  y = (coord % 10000)/10000
	x, y = x / 100, y / 100
	return math.floor(x * 10000 + 0.5) * 10000 + math.floor(y * 10000 + 0.5)
end

local nodes = {
	[C(62, 15)] = {
		name = "Umbral Base Camp",
		desc = "Main hub teleport node.",
	},
	[C(42, 71)] = {
		name = "Portal to the Forgotten Depths",
		desc = "Teleport node leading to the Forgotten Depths.",
	},
	[C(33, 75)] = {
		name = "Transit Platform Portal",
		desc = "Transit platform teleport node.",
	},
}

--------------------------------------------------------------------------------
-- HandyNotes plugin registration
--------------------------------------------------------------------------------

-- Stateless iterator: called repeatedly by HandyNotes as (nodes, previousCoord).
-- Must return: coord, uiMapID (nil = same map queried), iconpath, scale, alpha
-- Icon scale multiplier. HandyNotes renders world map pins at a base size of
-- 12px, multiplied by this value (and the user's global HandyNotes icon scale
-- setting). 4.5 -> ~54x54px at default global scale.
local ICON_SCALE = 2.0

local function iterator(t, previousCoord)
	local coord = next(t, previousCoord)
	if coord then
		return coord, nil, ICON, ICON_SCALE, 1
	end
end

local pluginHandler = {}

function pluginHandler:GetNodes2(mapID, minimap)
	-- Val already has Blizzard's own icon for this on the minimap;
	-- only show our pins on the big world map.
	if minimap then
		return
	end
	if mapID ~= MAP_ID then
		return
	end
	return iterator, nodes
end

-- Called by HandyNotes when the mouse enters a pin.
function pluginHandler:OnEnter(uiMapID, coord)
	local node = nodes[coord]
	if not node then
		return
	end

	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:AddLine(node.name)
	GameTooltip:AddLine(node.desc, 1, 1, 1, true)
	GameTooltip:Show()
end

-- Called by HandyNotes when the mouse leaves a pin.
function pluginHandler:OnLeave(uiMapID, coord)
	GameTooltip:Hide()
end

-- Called by HandyNotes on pin click.
function pluginHandler:OnClick(button, down, uiMapID, coord)
	-- No default click behavior yet. Hook a teleport-item/spell cast here if you want
	-- one-click travel.
end

HandyNotes:RegisterPluginDB(ADDON_NAME, pluginHandler)
