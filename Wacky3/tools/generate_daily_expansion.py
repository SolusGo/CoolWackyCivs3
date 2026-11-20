"""Render the Daily expansion definitions using the pinned CP151 schema."""
import json
import os
from pathlib import Path

from baseline import ROOT
from generate_hollow_choir import clone, companions, literal
from target_schema import schema_database

ROSTER = json.loads((ROOT / "tools/daily_expansion.json").read_text(encoding="utf-8"))


def code(spec):
    return f"D{spec['id']:03}"


def insert(table, **fields):
    return f"INSERT INTO {table}({','.join(fields)}) VALUES ({','.join(map(literal, fields.values()))});\n"


def copy_key(table, key, old, new):
    return (f"CREATE TEMP TABLE CWC3_DailyCopy AS SELECT * FROM {table} WHERE {key}={literal(old)};\n"
            f"UPDATE CWC3_DailyCopy SET {key}={literal(new)};\n"
            f"INSERT INTO {table} SELECT * FROM CWC3_DailyCopy;\nDROP TABLE CWC3_DailyCopy;\n")


def generate(db, spec):
    stem = code(spec)
    namespace = f"CWC3_{stem}"
    civ, leader, trait, unit, building, promo = [
        f"{kind}_{namespace}" for kind in ("CIVILIZATION", "LEADER", "TRAIT", "UNIT", "BUILDING", "PROMOTION")
    ]
    prefix = f"TXT_KEY_{namespace}_"
    unit_parent = "UNIT_" + spec["unit_parent"]
    building_parent = "BUILDING_" + spec["building_parent"]
    civ_sql = ""
    for option in spec.get("options", []):
        civ_sql += f"UPDATE CustomModOptions SET Value=1 WHERE Name={literal(option)};\n"
    civ_sql += insert("Traits", Type=trait, Description=prefix+"ABILITY_HELP", ShortDescription=prefix+"ABILITY")
    civ_sql += clone("Civilizations", "CIVILIZATION_AMERICA", civ, dict(
        Description=prefix+"CIV", ShortDescription=prefix+"CIV", Adjective=prefix+"ADJECTIVE",
        Civilopedia=prefix+"CIV_PEDIA", CivilopediaTag=prefix+"CIV5", Strategy=prefix+"STRATEGY",
        Playable=1, AIPlayable=0, PackageID=None, DawnOfManQuote=prefix+"DAWN", DawnOfManAudio=""))
    civ_sql += clone("Leaders", "LEADER_WASHINGTON", leader, dict(
        Description=prefix+"LEADER", Civilopedia=prefix+"LEADER_PEDIA", CivilopediaTag=prefix+"LEADERPAGE", PackageID=None))
    for table in ("Civilization_FreeBuildingClasses", "Civilization_FreeTechs", "Civilization_FreeUnits"):
        civ_sql += copy_key(table, "CivilizationType", "CIVILIZATION_AMERICA", civ)
    for table in ("Leader_Flavors", "Leader_MajorCivApproachBiases", "Leader_MinorCivApproachBiases"):
        civ_sql += copy_key(table, "LeaderType", "LEADER_WASHINGTON", leader)
    civ_sql += insert("Civilization_Leaders", CivilizationType=civ, LeaderheadType=leader)
    civ_sql += insert("Leader_Traits", LeaderType=leader, TraitType=trait)
    # Resolve actual parent classes, including where a parent differs from its class name.
    civ_sql += f"INSERT INTO Civilization_UnitClassOverrides SELECT '{civ}',Class,'{unit}' FROM Units WHERE Type='{unit_parent}';\n"
    civ_sql += f"INSERT INTO Civilization_BuildingClassOverrides SELECT '{civ}',BuildingClass,'{building}' FROM Buildings WHERE Type='{building_parent}';\n"
    names = {}
    for i, name in enumerate([spec["capital"], *spec["cities"]], 1):
        tag = f"CITY_{i}"
        names[tag] = name
        civ_sql += insert("Civilization_CityNames", CivilizationType=civ, CityName=prefix+tag)

    unit_sql = clone("Units", unit_parent, unit, dict(Description=prefix+"UNIT", Help=prefix+"UNIT_HELP",
                    Strategy=prefix+"UNIT_STRATEGY", Civilopedia=prefix+"UNIT_PEDIA"))
    unit_sql += companions(db, "Unit_", "UnitType", unit_parent, unit)
    for field, delta in spec.get("unit_fields", {}).items():
        unit_sql += f"UPDATE Units SET {field}={field}+{delta} WHERE Type='{unit}';\n"
    texts = {}
    promotions = dict(spec.get("extra_promotions", {}))
    if "promotion" in spec:
        promotions["LINEAGE"] = spec["promotion"]
    for suffix, changes in promotions.items():
        tag = "PROMO_" + suffix
        promo_id = promo + "_" + suffix
        texts[tag] = {
            "DEFEND": "Home Defence" if spec["id"] != 25 else "Shore Defence",
            "DOCTRINE": "Revised Doctrine", "COUNTER": "Reflected Lesson",
            "DEPOT": "Friendly Dispatch", "RESOLUTION": "Defence Resolution", "MIST": "The Living Mist",
        }.get(suffix, spec["unit"])
        texts[tag+"_HELP"] = spec["unit_help"] if suffix not in {"DOCTRINE", "RESOLUTION", "MIST"} else spec["ability_help"]
        fields = dict(Type=promo_id, Description=prefix+tag, Help=prefix+tag+"_HELP", CannotBeChosen=1,
                      LostWithUpgrade=0, PortraitIndex=0, IconAtlas="PROMOTION_ATLAS",
                      PediaType="PEDIA_ATTRIBUTES", PediaEntry=prefix+tag)
        unit_sql += insert("UnitPromotions", **(fields | changes))
        if suffix == "LINEAGE":
            unit_sql += insert("Unit_FreePromotions", UnitType=unit, PromotionType=promo_id)
    for terrain, attack in spec.get("terrain_attack", {}).items():
        unit_sql += insert("UnitPromotions_TerrainModifiers", PromotionType=promo+"_LINEAGE", TerrainType="TERRAIN_"+terrain, Attack=attack, Defense=0)
    for terrain, defense in spec.get("terrain_defense", {}).items():
        unit_sql += insert("UnitPromotions_TerrainModifiers", PromotionType=promo+"_LINEAGE", TerrainType="TERRAIN_"+terrain, Attack=0, Defense=defense)
    for terrain in spec.get("terrain_move", []):
        unit_sql += insert("UnitPromotions_Terrains", PromotionType=promo+"_LINEAGE", TerrainType="TERRAIN_"+terrain, DoubleMove=1)
    for suffix, feature, defense, move in spec.get("features", []):
        unit_sql += insert("UnitPromotions_Features", PromotionType=promo+"_"+suffix, FeatureType="FEATURE_"+feature, Defense=defense, DoubleMove=move)
    for promotion in spec.get("free_promotions", []):
        unit_sql += (f"INSERT INTO Unit_FreePromotions(UnitType,PromotionType) "
                     f"SELECT '{unit}',Type FROM UnitPromotions WHERE Type='{promotion}' "
                     f"AND NOT EXISTS (SELECT 1 FROM Unit_FreePromotions WHERE UnitType='{unit}' AND PromotionType='{promotion}');\n")

    building_sql = clone("Buildings", building_parent, building, dict(
        Description=prefix+"BUILDING", Help=prefix+"BUILDING_HELP", Strategy=prefix+"BUILDING_STRATEGY",
        Civilopedia=prefix+"BUILDING_PEDIA", **spec.get("building_fields", {})))
    building_sql += companions(db, "Building_", "BuildingType", building_parent, building)
    for kind, amount in spec["yields"].items():
        condition = f"FROM Building_YieldChanges WHERE BuildingType='{building}' AND YieldType='YIELD_{kind}'"
        building_sql += (f"UPDATE Building_YieldChanges SET Yield=Yield+{amount} WHERE rowid=(SELECT MIN(rowid) {condition});\n"
                         f"INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) SELECT '{building}','YIELD_{kind}',{amount} "
                         f"WHERE NOT EXISTS (SELECT 1 {condition});\n")
    for suffix, yields in spec["controllers"].items():
        dummy = building+"_"+suffix
        cls = f"BUILDINGCLASS_{namespace}_{suffix}"
        building_sql += insert("BuildingClasses", Type=cls, DefaultBuilding=dummy, Description=prefix+"DUMMY")
        building_sql += insert("Buildings", Type=dummy, BuildingClass=cls, Description=prefix+"DUMMY", Cost=-1,
                               FaithCost=-1, GoldMaintenance=0, GreatWorkCount=-1, NeverCapture=1, NukeImmune=1,
                               IsDummy=1, ShowInPedia=0, ConquestProb=0, IconAtlas="CIV_COLOR_ATLAS", PortraitIndex=0)
        for kind, amount in yields.items():
            building_sql += insert("Building_YieldChanges", BuildingType=dummy, YieldType="YIELD_"+kind, Yield=amount)
        if suffix == "METHOD":
            building_sql += insert("Building_YieldModifiers", BuildingType=dummy, YieldType="YIELD_SCIENCE", Yield=10)

    dialogue = {"FIRST_GREETING": f"Welcome to {spec['capital']}.",
                "DECLAREWAR": "We will defend what our people have built.",
                "DEFEATED": "Remember our people and what they made."} | spec.get("dialogue", {})
    texts.update(names, CIV=spec["name"], LEADER=spec["leader"], ADJECTIVE=spec["adjective"],
                 ABILITY=spec["ability"], ABILITY_HELP=spec["ability_help"], CIV_PEDIA=spec["pedia"],
                 STRATEGY=spec["strategy"], LEADER_PEDIA=spec["pedia"], DAWN=spec["pedia"],
                 UNIT=spec["unit"], UNIT_HELP=spec["unit_help"], UNIT_STRATEGY=spec["unit_help"], UNIT_PEDIA=spec["unit_help"],
                 BUILDING=spec["building"], BUILDING_HELP=spec["building_help"], BUILDING_PEDIA=spec["building_help"],
                 BUILDING_STRATEGY=spec["strategy"], DUMMY="Internal city yield controller", CIV5_HEADING_1=spec["name"],
                 CIV5_TEXT_1=spec["pedia"], LEADERPAGE_NAME=spec["leader"], LEADERPAGE_SUBTITLE=spec["name"],
                 LEADERPAGE_HEADING_1="Leadership", LEADERPAGE_TEXT_1=spec["pedia"], FALLBACK_1="We have heard your terms.")
    texts.update({f"{key}_1": val for key, val in dialogue.items()})
    text_sql = "".join(insert("Language_en_US", Tag=prefix+key, Text=value) for key, value in texts.items())
    for response in dialogue:
        text_sql += insert("Diplomacy_Responses", LeaderType=leader, ResponseType="RESPONSE_"+response, Response=prefix+response+"_%", Bias=1)
    text_sql += (f"INSERT INTO Diplomacy_Responses SELECT DISTINCT '{leader}',N.ResponseType,'{prefix}FALLBACK_%',1 "
                 "FROM Diplomacy_Responses N WHERE N.LeaderType='LEADER_WASHINGTON' AND NOT EXISTS "
                 f"(SELECT 1 FROM Diplomacy_Responses C WHERE C.LeaderType='{leader}' AND C.ResponseType=N.ResponseType);\n")

    return {"Civilization": civ_sql, "Units": unit_sql, "Buildings": building_sql, "Text": text_sql}


def main():
    with schema_database() as db:
        for spec in ROSTER:
            output = Path(os.environ.get("CWC3_SQL_ROOT", ROOT)) / spec["folder"] / "SQL"
            output.mkdir(parents=True, exist_ok=True)
            for part, sql in generate(db, spec).items():
                (output / f"{code(spec)}_{part}.sql").write_text(
                    "-- Generated by tools/generate_daily_expansion.py. Clones active CP151 rows.\n"+sql,
                    encoding="utf-8", newline="\n")
    print(f"Generated SQL for {len(ROSTER)} Daily Surprise civilizations")


if __name__ == "__main__":
    main()
