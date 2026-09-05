# Overworld balance report

Generated from the live crafting recipes, machine recipes, processing constants, technology stages, and boss registry.

## Assumptions

- One unit of a raw resource takes 2.0 seconds to gather.
- One manual craft takes 0.4 seconds.
- Every new stage reserves 6.0 minutes for travel and exploration.
- Boss duration uses 35.0 sustained player DPS.
- Machine time is serial active time; parallel machines reduce elapsed time.

## Unlock catalog summary

This table prices one copy of every unlock in the stage. It is an upper-bound catalog audit, not the mandatory route.

| Stage | Targets | Raw units | Machine time | Energy | Steam | Peak EU/s | Generators | Estimated time |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Foundation | 8 | 223 | 4.8 min | 3090 EU | 0 L | 15 | 1 | 13.1 min |
| Steam Age | 23 | 537.5 | 80.1 min | 9735 EU | 4915.9 L | 15 | 1 | 105.2 min |
| Electricity | 5 | 83.4 | 4.7 min | 2576.3 EU | 242.3 L | 25 | 1 | 14.5 min |
| Automation | 7 | 452.7 | 46.7 min | 17619.4 EU | 749.4 L | 25 | 1 | 70.9 min |
| Heavy Industry | 8 | 495.4 | 47.0 min | 20750 EU | 617.6 L | 25 | 1 | 72.9 min |
| Industrial Chemistry | 5 | 378.4 | 37.0 min | 17865 EU | 461.9 L | 25 | 1 | 58.6 min |
| Bioengineering | 5 | 247.1 | 20.1 min | 11477.5 EU | 391.8 L | 25 | 1 | 37.0 min |
| Solar Industry | 4 | 397 | 35.7 min | 25735 EU | 352 L | 25 | 1 | 58.6 min |
| Abyss Engineering | 6 | 715.9 | 60.6 min | 52801 EU | 552.5 L | 200 | 1 | 95.5 min |
| Frontier Technology | 4 | 783.3 | 55.1 min | 60038 EU | 562 L | 200 | 1 | 93.1 min |
| Quantum Logistics | 18 | 1677.5 | 130.1 min | 103551 EU | 1853 L | 200 | 1 | 202.6 min |

## Recommended progression package

This smaller package includes the infrastructure needed to use the stage plus the access item for the next biome.

| Stage | Core targets | Raw units | Machine time | Estimated time |
|---|---:|---:|---:|---:|
| Foundation | 8 | 223 | 4.8 min | 13.1 min |
| Steam Age | 12 | 393.1 | 55.2 min | 75.1 min |
| Electricity | 4 | 63.4 | 4.2 min | 13.2 min |
| Automation | 5 | 413.7 | 44.6 min | 67.3 min |
| Heavy Industry | 5 | 289 | 24.1 min | 42.3 min |
| Industrial Chemistry | 4 | 319.8 | 32.5 min | 51.8 min |
| Bioengineering | 4 | 223.0 | 18.5 min | 34.4 min |
| Solar Industry | 4 | 397 | 35.7 min | 58.6 min |
| Abyss Engineering | 5 | 619.9 | 47.2 min | 78.7 min |
| Frontier Technology | 4 | 783.3 | 55.1 min | 93.1 min |
| Quantum Logistics | 6 | 761.5 | 57.0 min | 94.3 min |

## Stage details

### Foundation

- Targets: `furnace`, `primitive_drill`, `primitive_blast_furnace`, `coal_generator`, `crusher`, `electric_furnace`, `conveyor`, `bronze_drill`
- Estimated stage time: **13.1 min**.
- Recommended core: `furnace`, `primitive_drill`, `primitive_blast_furnace`, `coal_generator`, `crusher`, `conveyor`, `bronze_drill`, `electric_furnace` — **13.1 min**.
- Active processing: **4.8 min**, 3090 EU, peak 15 EU/s.
- Power baseline: 1 generator(s) at 40 EU/s each.
- Main raw bill: `stone` 84, `iron_ore` 68.5, `copper_ore` 29.8, `coal` 24, `coke` 8, `tin_ore` 4.8, `wood` 4.
- Machine operations: `electric_furnace` 103, `primitive_blast_furnace` 4.
- Most expensive targets: `primitive_blast_furnace` 42 raw / 16.0 s, `coal_generator` 42 raw / 1.9 min, `bronze_drill` 42 raw / 1.0 min, `electric_furnace` 34 raw / 32.0 s, `crusher` 29 raw / 58.0 s.

### Steam Age

- Targets: `primitive_crusher`, `mechanical_water_pump`, `steam_water_pump`, `mechanical_inserter`, `steam_boiler`, `high_pressure_steam_boiler`, `steam_furnace`, `steam_crusher`, `steam_press`, `steam_assembler`, `steam_turbine`, `coke_oven`, `fluid_tank_t1`, `fluid_pipe`, `fluid_pipe_t2`, `fluid_valve`, `steam_machine_casing`, `bronze_boiler_tube`, `pressure_valve`, `steam_piston`, `precision_flywheel`, `steam_research_core`, `steam_science_pack`
- Estimated stage time: **105.2 min**.
- Recommended core: `primitive_crusher`, `mechanical_water_pump`, `fluid_pipe`, `fluid_tank_t1`, `mechanical_inserter`, `steam_boiler`, `high_pressure_steam_boiler`, `steam_turbine`, `steam_press`, `steam_assembler`, `coke_oven`, `steam_science_pack` — **75.1 min**.
- Active processing: **80.1 min**, 9735 EU, peak 15 EU/s.
- Power baseline: 1 generator(s) at 40 EU/s each.
- Main raw bill: `copper_ore` 146.1, `stone` 140, `tin_ore` 124.9, `coal` 98, `iron_ore` 27.5, `wood` 1.
- Machine operations: `steam_assembler` 396.1, `electric_furnace` 298.5, `steam_press` 243.1, `coke_oven` 49, `primitive_blast_furnace` 23.5, `crusher` 13.
- Most expensive targets: `high_pressure_steam_boiler` 120.5 raw / 15.3 min, `steam_turbine` 93 raw / 20.9 min, `steam_water_pump` 44.3 raw / 10.8 min, `coke_oven` 41.3 raw / 58.0 s, `steam_furnace` 39.5 raw / 3.3 min.
- Balance flags: **raw-resource spike**, **more than 10 minutes of serial processing**.

### Electricity

- Targets: `extractor`, `conveyor_t2`, `machine_module_efficiency`, `electrical_science_pack`, `sand_amulet`
- Estimated stage time: **14.5 min**.
- Recommended core: `extractor`, `conveyor_t2`, `electrical_science_pack`, `sand_amulet` — **13.2 min**.
- Active processing: **4.7 min**, 2576.3 EU, peak 25 EU/s.
- Power baseline: 1 generator(s) at 40 EU/s each.
- Main raw bill: `copper_ore` 35.3, `iron_ore` 25.8, `wood` 11, `tree_resin` 7, `tin_ore` 4.3.
- Machine operations: `electric_furnace` 64.9, `steam_press` 25.1, `extractor` 6, `steam_assembler` 5.5, `crusher` 0.5.
- Most expensive targets: `extractor` 38.6 raw / 2.9 min, `machine_module_efficiency` 20 raw / 32.0 s, `electrical_science_pack` 11.5 raw / 50.0 s, `sand_amulet` 8 raw / 12.0 s, `conveyor_t2` 5.3 raw / 17.5 s.

### Automation

- Targets: `compressor`, `mixer`, `conveyor_t3`, `conveyor_splitter`, `machine_module_speed`, `automation_science_pack`, `thermal_gloves`
- Estimated stage time: **70.9 min**.
- Recommended core: `compressor`, `mixer`, `conveyor_splitter`, `automation_science_pack`, `thermal_gloves` — **67.3 min**.
- Active processing: **46.7 min**, 17619.4 EU, peak 25 EU/s.
- Power baseline: 1 generator(s) at 40 EU/s each.
- Main raw bill: `copper_ore` 120.4, `iron_ore` 87.3, `tree_resin` 78, `coal` 67.5, `wood` 52, `silver_ore` 42, `tin_ore` 2.9, `gold_ore` 2.7.
- Machine operations: `electric_furnace` 253.2, `extractor` 96, `steam_press` 78.6, `coke_oven` 59.5, `primitive_blast_furnace` 29.8, `steam_assembler` 16.1, `crusher` 6, `compressor` 0.5.
- Most expensive targets: `mixer` 190.7 raw / 24.5 min, `compressor` 158.3 raw / 16.0 min, `automation_science_pack` 50.6 raw / 2.8 min, `machine_module_speed` 23 raw / 1.0 min, `conveyor_t3` 16 raw / 1.0 min.
- Balance flags: **raw-resource spike**, **more than 10 minutes of serial processing**.

### Heavy Industry

- Targets: `centrifuge`, `ore_washer`, `ore_melter`, `magnetic_separator`, `conveyor_t4`, `machine_module_capacity`, `industrial_science_pack`, `miasma_boots`
- Estimated stage time: **72.9 min**.
- Recommended core: `ore_washer`, `ore_melter`, `magnetic_separator`, `industrial_science_pack`, `miasma_boots` — **42.3 min**.
- Active processing: **47.0 min**, 20750 EU, peak 25 EU/s.
- Power baseline: 1 generator(s) at 40 EU/s each.
- Main raw bill: `copper_ore` 131, `tree_resin` 94, `iron_ore` 67.5, `coal` 66, `wood` 66, `silver_ore` 53.5, `stone` 8, `gold_ore` 6.7, `tin_ore` 2.5, `titanium_ore` 0.3.
- Machine operations: `electric_furnace` 255.2, `extractor` 126, `steam_press` 69, `coke_oven` 58, `primitive_blast_furnace` 29, `steam_assembler` 8.8, `crusher` 8.3.
- Most expensive targets: `centrifuge` 149.7 raw / 16.8 min, `ore_melter` 114 raw / 8.3 min, `magnetic_separator` 104.8 raw / 9.1 min, `conveyor_t4` 36.8 raw / 2.4 min, `ore_washer` 29.5 raw / 2.3 min.
- Balance flags: **raw-resource spike**, **more than 10 minutes of serial processing**.

### Industrial Chemistry

- Targets: `chemical_reactor`, `distillation_column`, `machine_module_productivity`, `chemical_science_pack`, `savage_belt`
- Estimated stage time: **58.6 min**.
- Recommended core: `chemical_reactor`, `distillation_column`, `chemical_science_pack`, `savage_belt` — **51.8 min**.
- Active processing: **37.0 min**, 17865 EU, peak 25 EU/s.
- Power baseline: 1 generator(s) at 40 EU/s each.
- Main raw bill: `copper_ore` 96.9, `tree_resin` 85.5, `wood` 54, `silver_ore` 48.5, `coal` 47.5, `iron_ore` 36.5, `gold_ore` 7.7, `tin_ore` 1.9.
- Machine operations: `electric_furnace` 186.4, `extractor` 117, `steam_press` 50, `coke_oven` 44, `primitive_blast_furnace` 22, `crusher` 8.5, `steam_assembler` 8.3, `compressor` 0.5.
- Most expensive targets: `distillation_column` 192.5 raw / 20.8 min, `chemical_reactor` 100.3 raw / 9.1 min, `machine_module_productivity` 58.7 raw / 4.5 min, `chemical_science_pack` 21 raw / 1.5 min, `savage_belt` 6 raw / 1.0 min.
- Balance flags: **more than 10 minutes of serial processing**.

### Bioengineering

- Targets: `farming_station`, `cobblestone_generator`, `solar_panel`, `bio_science_pack`, `sun_crown`
- Estimated stage time: **37.0 min**.
- Recommended core: `farming_station`, `solar_panel`, `bio_science_pack`, `sun_crown` — **34.4 min**.
- Active processing: **20.1 min**, 11477.5 EU, peak 25 EU/s.
- Power baseline: 1 generator(s) at 40 EU/s each.
- Main raw bill: `copper_ore` 70.1, `iron_ore` 49.5, `tree_resin` 43, `wood` 30, `silver_ore` 22.5, `coal` 20, `gold_ore` 7.3, `stone` 2, `titanium_ore` 2, `tin_ore` 0.6.
- Machine operations: `electric_furnace` 151.6, `extractor` 60, `steam_press` 44.8, `coke_oven` 16, `crusher` 10.5, `primitive_blast_furnace` 8, `steam_assembler` 4.5, `farming_station` 4.
- Most expensive targets: `solar_panel` 78 raw / 7.0 min, `bio_science_pack` 70.3 raw / 6.1 min, `farming_station` 66.6 raw / 5.2 min, `cobblestone_generator` 24.1 raw / 1.6 min, `sun_crown` 8 raw / 16.0 s.
- Balance flags: **more than 10 minutes of serial processing**.

### Solar Industry

- Targets: `advanced_solar_panel`, `energy_storage_t2`, `solar_science_pack`, `cryo_mantle`
- Estimated stage time: **58.6 min**.
- Recommended core: `advanced_solar_panel`, `energy_storage_t2`, `solar_science_pack`, `cryo_mantle` — **58.6 min**.
- Active processing: **35.7 min**, 25735 EU, peak 25 EU/s.
- Power baseline: 1 generator(s) at 120 EU/s each.
- Main raw bill: `tree_resin` 107, `copper_ore` 99.5, `silver_ore` 57.5, `coal` 56.5, `wood` 36, `iron_ore` 33.5, `stone` 4, `titanium_ore` 3.
- Machine operations: `electric_furnace` 193.5, `extractor` 178, `steam_press` 44, `crusher` 35.5, `coke_oven` 29, `primitive_blast_furnace` 14.5.
- Most expensive targets: `solar_science_pack` 143 raw / 12.5 min, `energy_storage_t2` 127 raw / 11.8 min, `advanced_solar_panel` 109 raw / 9.1 min, `cryo_mantle` 18 raw / 2.4 min.
- Balance flags: **more than 10 minutes of serial processing**.

### Abyss Engineering

- Targets: `molecular_transformer`, `elite_solar_panel`, `energy_storage_t3`, `fluid_tank_t4`, `abyss_science_pack`, `void_respirator`
- Estimated stage time: **95.5 min**.
- Recommended core: `molecular_transformer`, `elite_solar_panel`, `energy_storage_t3`, `abyss_science_pack`, `void_respirator` — **78.7 min**.
- Active processing: **60.6 min**, 52801 EU, peak 200 EU/s.
- Power baseline: 1 generator(s) at 360 EU/s each.
- Main raw bill: `tree_resin` 188.5, `copper_ore` 149.6, `coal` 106.3, `silver_ore` 104, `wood` 63, `iron_ore` 48.5, `gold_ore` 25, `titanium_ore` 19, `stone` 11, `uranium_ore` 1.
- Machine operations: `electric_furnace` 350.1, `extractor` 306, `crusher` 87.3, `steam_press` 68.1, `coke_oven` 42, `primitive_blast_furnace` 21, `molecular_transformer` 4, `steam_assembler` 1, `compressor` 0.5.
- Most expensive targets: `molecular_transformer` 190.3 raw / 12.0 min, `energy_storage_t3` 185 raw / 16.1 min, `elite_solar_panel` 177 raw / 13.4 min, `fluid_tank_t4` 96 raw / 13.4 min, `abyss_science_pack` 52.6 raw / 4.4 min.
- Balance flags: **raw-resource spike**, **more than 10 minutes of serial processing**.

### Frontier Technology

- Targets: `ultimate_solar_panel`, `conveyor_t5`, `frontier_science_pack`, `primeval_potion`
- Estimated stage time: **93.1 min**.
- Recommended core: `ultimate_solar_panel`, `conveyor_t5`, `frontier_science_pack`, `primeval_potion` — **93.1 min**.
- Active processing: **55.1 min**, 60038 EU, peak 200 EU/s.
- Power baseline: 1 generator(s) at 1080 EU/s each.
- Main raw bill: `tree_resin` 218, `copper_ore` 190.3, `coal` 106, `silver_ore` 100, `wood` 90, `iron_ore` 47.3, `gold_ore` 27.5, `mythril_ore` 2, `titanium_ore` 1.5, `tin_ore` 0.8.
- Machine operations: `electric_furnace` 369.3, `extractor` 350, `crusher` 86, `steam_press` 70.3, `coke_oven` 20, `primitive_blast_furnace` 10, `molecular_transformer` 5.5.
- Most expensive targets: `frontier_science_pack` 453 raw / 30.9 min, `ultimate_solar_panel` 272 raw / 20.1 min, `conveyor_t5` 42.3 raw / 2.6 min, `primeval_potion` 16 raw / 1.5 min.
- Balance flags: **raw-resource spike**, **more than 10 minutes of serial processing**.

### Quantum Logistics

- Targets: `quantum_solar_panel`, `me_controller`, `me_drive`, `me_terminal`, `me_crafting_terminal`, `me_molecular_assembler`, `me_interface`, `me_import_bus`, `me_export_bus`, `me_cable`, `me_item_cell_1k`, `me_item_cell_4k`, `me_item_cell_16k`, `me_item_cell_64k`, `me_fluid_cell_1k`, `me_fluid_cell_4k`, `me_fluid_cell_16k`, `me_fluid_cell_64k`
- Estimated stage time: **202.6 min**.
- Recommended core: `quantum_solar_panel`, `me_controller`, `me_drive`, `me_terminal`, `me_cable`, `me_item_cell_1k` — **94.3 min**.
- Active processing: **130.1 min**, 103551 EU, peak 200 EU/s.
- Power baseline: 1 generator(s) at 3240 EU/s each.
- Main raw bill: `tree_resin` 426, `copper_ore` 420, `wood` 234.8, `silver_ore` 186, `iron_ore` 180.9, `coal` 162, `gold_ore` 65.3, `tin_ore` 2.5.
- Machine operations: `electric_furnace` 838.7, `extractor` 632, `steam_press` 207.3, `coke_oven` 89, `crusher` 89, `primitive_blast_furnace` 44.5, `steam_assembler` 26, `molecular_transformer` 6, `compressor` 2.
- Most expensive targets: `quantum_solar_panel` 510 raw / 33.5 min, `me_molecular_assembler` 251.4 raw / 26.1 min, `me_controller` 164 raw / 17.2 min, `me_item_cell_64k` 116 raw / 6.4 min, `me_fluid_cell_64k` 109.3 raw / 5.9 min.
- Balance flags: **raw-resource spike**, **more than 10 minutes of serial processing**.

