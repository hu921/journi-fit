#!/usr/bin/env python3
"""Convert Free Exercise DB (public domain, Unlicense) into the app's bundled exercises.json.

Usage:
  curl -L -o /tmp/ex.json https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json
  python3 scripts/build_exercises.py /tmp/ex.json JourniFit/Resources/exercises.json

Photos: pass a photos folder as a third argument. Each exercise lists the photos
named <id>_0.jpg and <id>_1.jpg that exist there (start and end position).
To fetch and shrink them:
  url=https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/<id>/0.jpg
  convert in.jpg -resize 480x -strip -quality 65 JourniFit/Resources/ExercisePhotos/<id>_0.jpg
"""
import os
import json
import sys

src, dst = sys.argv[1], sys.argv[2]
photos = sys.argv[3] if len(sys.argv) > 3 else None
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
        "images": [f"{x['id']}_{i}" for i in range(2)
                   if photos and os.path.exists(os.path.join(photos, f"{x['id']}_{i}.jpg"))],
    })
out.sort(key=lambda e: e["name"])
json.dump(out, open(dst, "w"), indent=1, ensure_ascii=False)
print(f"wrote {len(out)} exercises to {dst}")
