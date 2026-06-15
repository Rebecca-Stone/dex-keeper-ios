#!/usr/bin/env node
// Generates the iOS app's bundled Pokédex data from the sister web app's
// embedded dataset (dex-keeper-1/src/data.js), so the two apps share one
// source of truth.
//
// Usage:
//   node Tools/generate-dex-data.mjs [path/to/web/src/data.js]
//
// Defaults to the sibling checkout on this machine. Emits:
//   DexKeeper/DexKeeper/Resources/dex.json        (1025 species, fully decoded)
//   DexKeeper/DexKeeper/Resources/bossteams.json  (preset gym/E4/champion teams)

import { writeFileSync, mkdirSync } from "node:fs";
import { fileURLToPath, pathToFileURL } from "node:url";
import { dirname, resolve } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "..");
const dataPath = process.argv[2]
  ? resolve(process.argv[2])
  : resolve(repoRoot, "..", "dex-keeper-1", "src", "data.js");

const { RAW, GROWTH_RATES, EGG_GROUPS, POKE_COLORS, POKE_SHAPES, PRESET_GROUPS } =
  await import(pathToFileURL(dataPath).href);

// These two tables live in the web app's App.jsx (not data.js), copied verbatim.
const HABITATS = ["Unknown", "Cave", "Forest", "Grassland", "Mountain", "Rare",
  "Rough terrain", "Sea", "Urban", "Water's edge"];
const GEN_REGIONS = ["Kanto", "Johto", "Hoenn", "Sinnoh", "Unova", "Kalos",
  "Alola", "Galar", "Paldea"];
const RARITY = ["regular", "legendary", "mythical"];

// RAW row layout:
// [name, gen, habitatCode, [stats6], evoFrom, legendCode, [abilities],
//  [genus, heightDm, weightHg, capture, happiness, growthId, genderRate,
//   [eggGroupIds], colorId, shapeId, evoHow], type1, type2?]
const pokemon = RAW.map((r, i) => {
  const extra = r[7];
  return {
    id: i + 1,
    name: r[0],
    gen: r[1],
    region: GEN_REGIONS[r[1] - 1] ?? "",
    habitat: HABITATS[r[2]] ?? "Unknown",
    stats: r[3],
    evoFrom: r[4],
    rarity: RARITY[r[5]] ?? "regular",
    abilities: r[6].map((a) => ({
      name: a.replace(/\*$/, ""),
      hidden: a.endsWith("*"),
    })),
    genus: extra[0],
    heightDm: extra[1],
    weightHg: extra[2],
    captureRate: extra[3],
    baseHappiness: extra[4],
    growthRate: GROWTH_RATES[extra[5] - 1] ?? "—",
    genderRate: extra[6], // eighths female, -1 = genderless
    eggGroups: extra[7].map((g) => EGG_GROUPS[g - 1]).filter(Boolean),
    color: POKE_COLORS[extra[8] - 1] ?? "—",
    shape: POKE_SHAPES[extra[9] - 1] ?? "—",
    evoHow: extra[10] ?? "",
    types: r.slice(8).map((t) => t.toLowerCase()), // lowercase => matches PokemonType.rawValue
  };
});

const bossTeams = PRESET_GROUPS.map((g) => ({
  label: g.label,
  trainers: g.trainers.map(([name, ids]) => ({ name, pokemon: ids })),
}));

const outDir = resolve(repoRoot, "DexKeeper", "DexKeeper", "Resources");
mkdirSync(outDir, { recursive: true });
writeFileSync(resolve(outDir, "dex.json"), JSON.stringify(pokemon));
writeFileSync(resolve(outDir, "bossteams.json"), JSON.stringify(bossTeams));

console.log(`Source:      ${dataPath}`);
console.log(`Pokémon:     ${pokemon.length}`);
console.log(`Boss groups: ${bossTeams.length} (${bossTeams.reduce((n, g) => n + g.trainers.length, 0)} trainers)`);
console.log(`Wrote:       ${outDir}/{dex,bossteams}.json`);
