#!/usr/bin/env python3
"""Convert Free Exercise DB (public domain, Unlicense) into the app's bundled exercises.json.

Usage:
  curl -L -o /tmp/ex.json https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json
  python3 scripts/build_exercises.py /tmp/ex.json JourniFit/Resources/exercises.json

Photos are not bundled yet. The app shows a placeholder icon until they are.
"""
import json
import sys

src, dst = sys.argv[1], sys.argv[2]
out = []
for x in json.load(open(src)):
    equipment = x.get("equipment") or "none"
    machine = None
    if equipment == "machine":
        machine = x["name"]
    elif equipment == "cable":
        machine = "Cable station"
    out.append({
        "id": x["id"],
        "name": x["name"],
        "primaryMuscles": x.get("primaryMuscles", []),
        "secondaryMuscles": x.get("secondaryMuscles", []),
        "equipment": equipment,
        "machine": machine,
        "level": x.get("level", "beginner"),
        "instructions": x.get("instructions", []),
        "images": [],
    })
out.sort(key=lambda e: e["name"])
json.dump(out, open(dst, "w"), indent=1, ensure_ascii=False)
print(f"wrote {len(out)} exercises to {dst}")
