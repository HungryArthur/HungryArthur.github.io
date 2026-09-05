class_name GameConstants

const TILE_SIZE := 32
const CHUNK_SIZE := Chunk.SIZE
const RENDER_RADIUS := 4

# TerrainTileSet source IDs
const TERRAIN_WATER := 0
const TERRAIN_GRASS := 1
const TERRAIN_DESERT := 2
const TERRAIN_JUNGLE := 3
const TERRAIN_SNOW := 4
const TERRAIN_SWAMP := 5
const TERRAIN_BEACH := 6
# Hard-sector biomes (end-game versions of each direction).
const TERRAIN_SUNNY_CANYON := 7    # за пустыней (запад)
const TERRAIN_ICY_ABYSS := 8       # за зимой (север)
const TERRAIN_ROTTING_BOG := 9     # за болотом (юг)
const TERRAIN_PRIMEVAL_THICKET := 10  # за джунглями (восток)
# Plain stone floor painted under a whole ore deposit (the "ore zone"); ore textures
# sit on top only at the diggable points, and the centre shows a drill hole.
const TERRAIN_ORE_STONE := 11
const TERRAIN_ORE_STONE_ATLAS := Vector2i(0, 0)

# ObjectsTileSet source IDs
const OBJECT_TREE := 0
# Logical-only id: marks a tile as ore in object_data (no tileset source — ore is
# drawn from the per-ore block sources / drill hole below, on the stone floor).
const OBJECT_ORE := 1
const OBJECT_FORAGE := 3
# Standalone forage textures reserve TileSet source ids 20–29. The exact source
# for each gatherable lives in its ForageData resource; keep other object kinds
# out of this range.
const OBJECT_OIL := 4
# Dedicated block-texture sources for ores that have one (single tile at 0,0 each).
const OBJECT_ORE_BLOCK_GOLD := 5
const OBJECT_ORE_BLOCK_SILVER := 6
const OBJECT_ORE_BLOCK_NICKEL := 7
const OBJECT_ORE_BLOCK_RESONITE := 13
# Drill hole drawn at a vein's centre (where a drill is placed).
const OBJECT_DRILL_HOLE := 8
# Fluid pools. Oil (Oil.png) and lava (Lava.png) each have their own single-tile
# source; the deposit centre is tracked in fluid_deposit_data, not by atlas column.
const OBJECT_LAVA := 9
# Farm plot / crop. Logical-only object kind (no tileset source): tilled soil and
# the crop growing on it are drawn by FarmTileNode instances, while the tile lives
# in object_data (kind = OBJECT_FARM) with its crop id + plant time in ore_state_data.
const OBJECT_FARM := 12

# Ore atlas_x → its block-texture source. Ores not listed have no texture yet and
# render as bare stone floor. gold=3, silver=6, nickel=11 (see ore definitions).
const ORE_BLOCK_SOURCE := {
	3: OBJECT_ORE_BLOCK_GOLD,
	6: OBJECT_ORE_BLOCK_SILVER,
	11: OBJECT_ORE_BLOCK_NICKEL,
	13: OBJECT_ORE_BLOCK_RESONITE,
}

const WALK_SPEED := 100.0
const RUN_SPEED := 2000.0
