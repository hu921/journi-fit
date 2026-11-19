#!/usr/bin/env python3
"""Exercise display names and the popular list.

Names follow "Name (Equipment)", e.g. "Deadlift (Barbell)", "Lat Pulldown (Wide Grip)".
The exercise id never changes, so saved routines and workouts are not affected.

Files (edit these, then run `apply`):
  scripts/exercise_names.csv      id, equipment, original_name, display_name
  scripts/popular_exercises.txt   one exercise id per line, most popular first

Usage:
  python3 scripts/exercise_names.py generate   # rebuild the CSV from rules + OVERRIDES
  python3 scripts/exercise_names.py apply      # write names + popular ranks into exercises.json

`generate` overwrites the CSV. To keep a hand edit, put it in OVERRIDES below,
or only edit the CSV and run `apply`.
"""
import csv
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
JSON_PATH = os.path.join(ROOT, "JourniFit/Resources/exercises.json")
CSV_PATH = os.path.join(ROOT, "scripts/exercise_names.csv")
POPULAR_PATH = os.path.join(ROOT, "scripts/popular_exercises.txt")

# Equipment label shown in parentheses. None = no label (body weight, stretches).
EQUIPMENT_LABEL = {
    "barbell": "Barbell",
    "dumbbell": "Dumbbell",
    "cable": "Cable",
    "machine": "Machine",
    "kettlebells": "Kettlebell",
    "bands": "Band",
    "e-z curl bar": "EZ Bar",
    "medicine ball": "Medicine Ball",
    "exercise ball": "Exercise Ball",
    "foam roll": "Foam Roller",
    "body only": None,
    "none": None,
    "other": None,
}

# Words removed from the name because the label already says them.
EQUIPMENT_WORDS = {
    "barbell": ["Barbell"],
    "dumbbell": ["Two-Dumbbell", "Dumbbells", "Dumbbell", "DB"],
    "cable": ["Cable Pulley", "Cable"],
    "machine": ["Leverage", "Machine"],
    "kettlebells": ["Two Kettlebells", "Kettlebells", "Kettlebell"],
    "bands": ["With Bands", "with Bands", "Bands", "Band"],
    "e-z curl bar": ["EZ-Bar", "EZ Bar", "E-Z Bar"],
    "medicine ball": ["Medicine Ball"],
    "exercise ball": [],
    "foam roll": [],
}

# Grip or attachment words moved into the parentheses.
GRIPS = [
    ("Wide-Grip", "Wide Grip"), ("Wide Grip", "Wide Grip"),
    ("Close-Grip", "Close Grip"), ("Close Grip", "Close Grip"),
    ("Narrow-Grip", "Close Grip"),
    ("V-Bar", "V-Bar"), ("Rope Attachment", "Rope"), ("Rope", "Rope"),
    ("Underhand", "Underhand"),
]

# Plural to singular, whole words only.
SINGULAR = {
    "Curls": "Curl", "Rows": "Row", "Flyes": "Fly", "Flye": "Fly", "Flys": "Fly",
    "Lunges": "Lunge", "Squats": "Squat", "Raises": "Raise", "Shrugs": "Shrug",
    "Crunches": "Crunch", "Extensions": "Extension", "Deadlifts": "Deadlift",
    "Dips": "Dip", "Presses": "Press", "Pulldowns": "Pulldown", "Swings": "Swing",
    "Twists": "Twist", "Climbers": "Climber", "Pushups": "Push-Up", "Pullups": "Pull-Up",
    "Pushup": "Push-Up", "Pullup": "Pull-Up", "Push-Ups": "Push-Up", "Pull-Ups": "Pull-Up",
    "Push-up": "Push-Up", "Step Ups": "Step-Up", "Step-ups": "Step-Up", "Kickbacks": "Kickback",
}

# Hand-picked names. These win over the rules. Change freely.
OVERRIDES = {
    "Barbell_Squat": "Squat (Barbell)",
    "Barbell_Full_Squat": "Full Squat (Barbell)",
    "Front_Barbell_Squat": "Front Squat (Barbell)",
    "Front_Squat_Clean_Grip": "Front Squat (Barbell, Clean Grip)",
    "Bodyweight_Squat": "Squat (Bodyweight)",
    "Dumbbell_Squat": "Squat (Dumbbell)",
    "Smith_Machine_Squat": "Squat (Smith Machine)",
    "Goblet_Squat": "Goblet Squat (Kettlebell)",
    "Hack_Squat": "Hack Squat (Machine)",
    "Barbell_Hack_Squat": "Hack Squat (Barbell)",
    "Barbell_Deadlift": "Deadlift (Barbell)",
    "Sumo_Deadlift": "Sumo Deadlift (Barbell)",
    "Romanian_Deadlift": "Romanian Deadlift (Barbell)",
    "Stiff-Legged_Barbell_Deadlift": "Stiff-Leg Deadlift (Barbell)",
    "Stiff-Legged_Dumbbell_Deadlift": "Stiff-Leg Deadlift (Dumbbell)",
    "Barbell_Bench_Press_-_Medium_Grip": "Bench Press (Barbell)",
    "Barbell_Incline_Bench_Press_-_Medium_Grip": "Incline Bench Press (Barbell)",
    "Decline_Barbell_Bench_Press": "Decline Bench Press (Barbell)",
    "Close-Grip_Barbell_Bench_Press": "Bench Press (Barbell, Close Grip)",
    "Dumbbell_Bench_Press": "Bench Press (Dumbbell)",
    "Incline_Dumbbell_Press": "Incline Bench Press (Dumbbell)",
    "Decline_Dumbbell_Bench_Press": "Decline Bench Press (Dumbbell)",
    "Smith_Machine_Bench_Press": "Bench Press (Smith Machine)",
    "Smith_Machine_Incline_Bench_Press": "Incline Bench Press (Smith Machine)",
    "Machine_Bench_Press": "Bench Press (Machine)",
    "Leverage_Chest_Press": "Chest Press (Machine)",
    "Leverage_Incline_Chest_Press": "Incline Chest Press (Machine)",
    "Cable_Chest_Press": "Chest Press (Cable)",
    "Standing_Military_Press": "Overhead Press (Barbell)",
    "Seated_Barbell_Military_Press": "Seated Overhead Press (Barbell)",
    "Dumbbell_Shoulder_Press": "Shoulder Press (Dumbbell)",
    "Seated_Dumbbell_Press": "Seated Shoulder Press (Dumbbell)",
    "Machine_Shoulder_Military_Press": "Shoulder Press (Machine)",
    "Leverage_Shoulder_Press": "Shoulder Press (Plate-Loaded Machine)",
    "Arnold_Dumbbell_Press": "Arnold Press (Dumbbell)",
    "Wide-Grip_Lat_Pulldown": "Lat Pulldown (Wide Grip)",
    "Close-Grip_Front_Lat_Pulldown": "Lat Pulldown (Close Grip)",
    "V-Bar_Pulldown": "Lat Pulldown (V-Bar)",
    "Underhand_Cable_Pulldowns": "Lat Pulldown (Underhand)",
    "One_Arm_Lat_Pulldown": "Lat Pulldown (Single Arm)",
    "Full_Range-Of-Motion_Lat_Pulldown": "Lat Pulldown (Full Range)",
    "Wide-Grip_Pulldown_Behind_The_Neck": "Lat Pulldown (Behind the Neck)",
    "Straight-Arm_Pulldown": "Straight-Arm Pulldown (Cable)",
    "Rope_Straight-Arm_Pulldown": "Straight-Arm Pulldown (Rope)",
    "Seated_Cable_Rows": "Seated Row (Cable)",
    "Bent_Over_Barbell_Row": "Bent Over Row (Barbell)",
    "Bent_Over_Two-Dumbbell_Row": "Bent Over Row (Dumbbell)",
    "One-Arm_Dumbbell_Row": "Single-Arm Row (Dumbbell)",
    "T-Bar_Row_with_Handle": "T-Bar Row (Barbell)",
    "Lying_T-Bar_Row": "Chest-Supported T-Bar Row (Machine)",
    "Leverage_Iso_Row": "Iso Row (Machine)",
    "Leverage_High_Row": "High Row (Machine)",
    "Upright_Barbell_Row": "Upright Row (Barbell)",
    "Pullups": "Pull-Up",
    "Chin-Up": "Chin-Up",
    "Pushups": "Push-Up",
    "Dips_-_Triceps_Version": "Triceps Dip",
    "Dips_-_Chest_Version": "Chest Dip",
    "Bench_Dips": "Bench Dip",
    "Dip_Machine": "Dip (Machine)",
    "Leg_Press": "Leg Press (Machine)",
    "Leg_Extensions": "Leg Extension (Machine)",
    "Lying_Leg_Curls": "Lying Leg Curl (Machine)",
    "Seated_Leg_Curl": "Seated Leg Curl (Machine)",
    "Standing_Leg_Curl": "Standing Leg Curl (Machine)",
    "Standing_Calf_Raises": "Standing Calf Raise (Machine)",
    "Seated_Calf_Raise": "Seated Calf Raise (Machine)",
    "Thigh_Abductor": "Hip Abduction (Machine)",
    "Thigh_Adductor": "Hip Adduction (Machine)",
    "Barbell_Hip_Thrust": "Hip Thrust (Barbell)",
    "Barbell_Glute_Bridge": "Glute Bridge (Barbell)",
    "Dumbbell_Lunges": "Lunge (Dumbbell)",
    "Barbell_Lunge": "Lunge (Barbell)",
    "Barbell_Walking_Lunge": "Walking Lunge (Barbell)",
    "Bodyweight_Walking_Lunge": "Walking Lunge (Bodyweight)",
    "Split_Squat_with_Dumbbells": "Split Squat (Dumbbell)",
    "Side_Lateral_Raise": "Lateral Raise (Dumbbell)",
    "Seated_Side_Lateral_Raise": "Seated Lateral Raise (Dumbbell)",
    "Front_Dumbbell_Raise": "Front Raise (Dumbbell)",
    "Reverse_Flyes": "Reverse Fly (Dumbbell)",
    "Reverse_Machine_Flyes": "Reverse Fly (Machine)",
    "Face_Pull": "Face Pull (Cable)",
    "Barbell_Shrug": "Shrug (Barbell)",
    "Dumbbell_Shrug": "Shrug (Dumbbell)",
    "Barbell_Curl": "Bicep Curl (Barbell)",
    "Dumbbell_Bicep_Curl": "Bicep Curl (Dumbbell)",
    "Machine_Bicep_Curl": "Bicep Curl (Machine)",
    "EZ-Bar_Curl": "Bicep Curl (EZ Bar)",
    "Hammer_Curls": "Hammer Curl (Dumbbell)",
    "Preacher_Curl": "Preacher Curl (Barbell)",
    "Incline_Dumbbell_Curl": "Incline Curl (Dumbbell)",
    "Concentration_Curls": "Concentration Curl (Dumbbell)",
    "Triceps_Pushdown": "Triceps Pushdown (Cable)",
    "Triceps_Pushdown_-_Rope_Attachment": "Triceps Pushdown (Rope)",
    "Triceps_Pushdown_-_V-Bar_Attachment": "Triceps Pushdown (V-Bar)",
    "Cable_Rope_Overhead_Triceps_Extension": "Overhead Triceps Extension (Rope)",
    "Standing_Dumbbell_Triceps_Extension": "Overhead Triceps Extension (Dumbbell)",
    "EZ-Bar_Skullcrusher": "Skull Crusher (EZ Bar)",
    "Cable_Crossover": "Cable Crossover",
    "Dumbbell_Flyes": "Chest Fly (Dumbbell)",
    "Incline_Dumbbell_Flyes": "Incline Chest Fly (Dumbbell)",
    "Butterfly": "Pec Deck (Machine)",
    "Cable_Crunch": "Crunch (Cable)",
    "Crunches": "Crunch",
    "Plank": "Plank",
    "Hanging_Leg_Raise": "Hanging Leg Raise",
    "Russian_Twist": "Russian Twist",
    "Ab_Crunch_Machine": "Crunch (Machine)",
    "Hyperextensions_Back_Extensions": "Back Extension",
    "One-Arm_Kettlebell_Swings": "Single-Arm Swing (Kettlebell)",
    "Rowing_Stationary": "Rowing (Machine)",
    "Running_Treadmill": "Running (Treadmill)",
    "Walking_Treadmill": "Walking (Treadmill)",
    "Jogging_Treadmill": "Jogging (Treadmill)",
    "Bicycling_Stationary": "Cycling (Stationary Bike)",
    "Elliptical_Trainer": "Elliptical (Machine)",
}


def strip_word(name, word):
    return re.sub(r"(?<![\w-])" + re.escape(word) + r"(?![\w-])", " ", name)


def tidy(name):
    name = re.sub(r"\s+", " ", name).strip(" -,")
    # Drop words left dangling after a removal: "Extension with" -> "Extension".
    name = re.sub(r"(?i)\s+(with|on|on a|to|to a|and|using)$", "", name).strip(" -,")
    return name[:1].upper() + name[1:]


def rule_name(name, equipment):
    """Turn a source name into "Name (Equipment, Detail)"."""
    details = []
    n = name

    # "Squat (Clean Grip)" -> detail
    m = re.search(r"\(([^)]*)\)\s*$", n)
    if m:
        details.append(m.group(1).strip())
        n = n[:m.start()]

    # "Bench Press - Powerlifting" -> detail
    if " - " in n:
        n, suffix = n.split(" - ", 1)
        suffix = re.sub(r"^(With|with)\s+(A\s+)?", "", suffix).strip()
        if suffix.lower() not in ("medium grip", "bands", "band"):
            details.append(suffix)

    label = EQUIPMENT_LABEL.get(equipment)
    if "Smith" in n:
        label = "Smith Machine"
        n = strip_word(strip_word(n, "Smith Machine"), "Smith")

    for word in EQUIPMENT_WORDS.get(equipment, []):
        n = strip_word(n, word)

    grip = None
    for word, short in GRIPS:
        if strip_word(n, word) != n:
            grip = short
            n = strip_word(n, word)
            break

    for plural, single in SINGULAR.items():
        n = re.sub(r"(?<![\w-])" + re.escape(plural) + r"(?![\w-])", single, n)

    n = tidy(n)
    if not n:  # name was only equipment words
        return name

    parts = []
    # For cables, the attachment says more than "Cable".
    if label and not (equipment == "cable" and grip):
        parts.append(label)
    if grip:
        parts.append(grip)
    parts += [tidy(d) for d in details if d]
    return f"{n} ({', '.join(parts)})" if parts else n


def generate():
    exercises = json.load(open(JSON_PATH))
    rows = []
    for x in exercises:
        original = x.get("originalName") or x["name"]
        display = OVERRIDES.get(x["id"]) or rule_name(original, x["equipment"])
        rows.append([x["id"], x["equipment"], original, display])

    # Same display name twice: fall back to the original name for the later ones.
    seen = {}
    for row in rows:
        key = row[3].lower()
        if key in seen:
            row[3] = tidy(row[2])
        seen.setdefault(row[3].lower(), row[0])
    dupes = {}
    for row in rows:
        dupes.setdefault(row[3].lower(), []).append(row[0])
    for name, ids in dupes.items():
        if len(ids) > 1:
            print("duplicate name:", name, ids)

    rows.sort(key=lambda r: r[3].lower())
    with open(CSV_PATH, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["id", "equipment", "original_name", "display_name"])
        w.writerows(rows)
    print(f"wrote {len(rows)} names to {CSV_PATH}")


def apply():
    names = {}
    with open(CSV_PATH, newline="") as f:
        for row in csv.DictReader(f):
            names[row["id"]] = row["display_name"].strip()
    popular = [l.split("#")[0].strip() for l in open(POPULAR_PATH)]
    popular = [p for p in popular if p]
    rank = {pid: i + 1 for i, pid in enumerate(popular)}

    exercises = json.load(open(JSON_PATH))
    ids = {x["id"] for x in exercises}
    for pid in popular:
        if pid not in ids:
            print("unknown popular id:", pid)
    for x in exercises:
        original = x.get("originalName") or x["name"]
        x["originalName"] = original
        x["name"] = names.get(x["id"]) or original
        x["popularRank"] = rank.get(x["id"])
    exercises.sort(key=lambda e: e["name"].lower())
    json.dump(exercises, open(JSON_PATH, "w"), indent=1, ensure_ascii=False)
    print(f"applied {len(names)} names and {len(rank)} popular ranks to {JSON_PATH}")


if __name__ == "__main__":
    {"generate": generate, "apply": apply}[sys.argv[1] if len(sys.argv) > 1 else "apply"]()
