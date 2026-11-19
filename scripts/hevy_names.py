#!/usr/bin/env python3
"""Builds the Hevy import tables.

  JourniFit/Resources/hevy_names.json      Hevy exercise name (lowercase) -> our exercise id
  JourniFit/Resources/extra_exercises.json exercises Hevy has that the Free Exercise DB lacks

Names that already match ours exactly (ignoring case) need no entry.
Run: python3 scripts/hevy_names.py
"""
import json, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "JourniFit/Resources")

# Hevy name -> our display name (in exercises.json) or an id from EXTRA below.
ALIASES = {
    "Bench Plyo Push Up": "Plyo Push-Up",
    "Bicep Curl (Cable)": "Standing Biceps Curl (Cable)",
    "Box Jump": "Front Box Jump",
    "Cable Core Pallof Press": "Pallof Press (Cable)",
    "Cable Twist (Up to down)": "Standing Wood Chop (Cable)",
    "Cable Twist (side Chop)": "Standing Wood Chop (Cable)",
    "Clean Pull": "Clean Pull (Barbell)",
    "Decline Bench Press (Machine)": "Decline Chest Press (Machine)",
    "Decline bench sit up": "Sit-Up",
    "Dumbbell Row": "Single-Arm Row (Dumbbell)",
    "Face Pull": "Face Pull (Cable)",
    "Farmers Walk": "Farmer's Walk",
    "Front Squat": "Front Squat (Barbell)",
    "Glute Bridge": "Butt Lift (Bridge)",
    "Goblet Squat": "Goblet Squat (Kettlebell)",
    "Incline Push Ups": "Incline Push-Up",
    "Iso-Lateral High Row (Machine)": "High Row (Machine)",
    "Iso-Lateral Row (Machine)": "Iso Row (Machine)",
    "Jumping Lunge": "Scissors Jump",
    "Kettlebell Shoulder Press": "Two-Arm Military Press (Kettlebell)",
    "Kettlebell Swing": "Single-Arm Swing (Kettlebell)",
    "Landmine 180": "Landmine 180's (Barbell)",
    "Landmine Row": "T-Bar Row (Barbell)",
    "Lat Pulldown (Cable)": "Lat Pulldown (Wide Grip)",
    "Leg Press Horizontal (Machine)": "Leg Press (Machine)",
    "Leg Raise Parallel Bars": "Knee/Hip Raise On Parallel Bars",
    "Lunge": "Walking Lunge (Bodyweight)",
    "Push Press": "Push Press (Barbell)",
    "Push Up": "Push-Up",
    "Romanian Deadlift (Dumbbell)": "Stiff-Leg Deadlift (Dumbbell)",
    "Rowing Machine": "Rowing (Machine)",
    "Russian Twist (Weighted)": "Russian Twist",
    "Seated Cable Row - Bar Grip": "Seated Row (Cable)",
    "Seated Cable Row - V Grip (Cable)": "Seated Row (Cable)",
    "Seated Dip Machine": "Dip (Machine)",
    "Seated Shoulder Press (Machine)": "Shoulder Press (Machine)",
    "Single Arm Snatch (Dumbbell)": "One-Arm Snatch (Kettlebell)",
    "Skater": "Skating",
    "Skullcrusher (Barbell)": "Lying Triceps Extension Behind The Head (Barbell, Close Grip)",
    "Sumo Deadlift": "Sumo Deadlift (Barbell)",
    "Treadmill": "Walking (Treadmill)",
    "Walking": "Walking (Treadmill)",
    "Triceps Pressdown": "Triceps Pushdown (Cable)",
    "Triceps Pushdown": "Triceps Pushdown (Cable)",
    "Triceps Rope Pushdown": "Triceps Pushdown (Rope)",
    "Walking Lunge (Dumbbell)": "Lunge (Dumbbell)",
    "Zercher Squat": "Zercher Squat (Barbell)",
    "push up to T-roatation": "Push Up to Side Plank",
    # New exercises (ids from EXTRA)
    "3D Lungue": "jf_3d_lunge",
    "Band Speed Row": "jf_speed_row_band",
    "Chest Dip (Assisted)": "jf_chest_dip_assisted",
    "Chest Fly (Machine)": "jf_chest_fly_machine",
    "Dead Hang": "jf_dead_hang",
    "Deadlift (Dumbbell)": "jf_deadlift_dumbbell",
    "Dunphy Squat": "jf_dunphy_squat",
    "Hip Thrust (Machine)": "jf_hip_thrust_machine",
    "Jumping Jack": "jf_jumping_jack",
    "Kettlebell Rotational Row": "jf_rotational_row_kettlebell",
    "Pause Squat": "jf_pause_squat_barbell",
    "Seated Row (Machine)": "jf_seated_row_machine",
    "Single Arm Landmine Press (Barbell)": "jf_single_arm_landmine_press",
    "Single Leg Romanian Deadlift (Dumbbell)": "jf_single_leg_rdl_dumbbell",
    "Stick ISO Drivers": "jf_stick_iso_drivers",
    "Stick Lateral Drivers": "jf_stick_lateral_drivers",
    "Stick Single Arm ISO Chest Press": "jf_stick_single_arm_iso_chest_press",
    "box squat (Dumbbell)": "jf_box_squat_dumbbell",
    "kettlebell clean squat and press": "jf_clean_squat_press_kettlebell",
    "Warm Up": "jf_warm_up",
}

def ex(id, name, primary, secondary, equipment, machine=None, level="beginner"):
    return {"id": id, "name": name, "originalName": None, "primaryMuscles": primary,
            "secondaryMuscles": secondary, "equipment": equipment, "machine": machine,
            "level": level, "instructions": [], "images": [], "popularRank": None}

EXTRA = [
    ex("jf_3d_lunge", "3D Lunge", ["quadriceps"], ["glutes", "adductors", "hamstrings"], "body only"),
    ex("jf_speed_row_band", "Speed Row (Band)", ["middle back"], ["lats", "biceps"], "bands"),
    ex("jf_chest_dip_assisted", "Chest Dip (Assisted)", ["chest"], ["triceps", "shoulders"], "machine", "Assisted dip machine"),
    ex("jf_chest_fly_machine", "Chest Fly (Machine)", ["chest"], ["shoulders"], "machine", "Pec deck machine"),
    ex("jf_dead_hang", "Dead Hang", ["forearms"], ["lats", "shoulders"], "body only"),
    ex("jf_deadlift_dumbbell", "Deadlift (Dumbbell)", ["hamstrings"], ["glutes", "lower back", "forearms"], "dumbbell"),
    ex("jf_dunphy_squat", "Dunphy Squat", ["quadriceps"], ["glutes", "hamstrings"], "body only"),
    ex("jf_hip_thrust_machine", "Hip Thrust (Machine)", ["glutes"], ["hamstrings"], "machine", "Hip thrust machine"),
    ex("jf_jumping_jack", "Jumping Jack", ["quadriceps"], ["calves", "shoulders"], "body only"),
    ex("jf_rotational_row_kettlebell", "Rotational Row (Kettlebell)", ["middle back"], ["lats", "abdominals", "biceps"], "kettlebells"),
    ex("jf_pause_squat_barbell", "Pause Squat (Barbell)", ["quadriceps"], ["glutes", "hamstrings", "lower back"], "barbell", None, "intermediate"),
    ex("jf_seated_row_machine", "Seated Row (Machine)", ["middle back"], ["lats", "biceps"], "machine", "Seated row machine"),
    ex("jf_single_arm_landmine_press", "Single-Arm Landmine Press (Barbell)", ["shoulders"], ["chest", "triceps"], "barbell"),
    ex("jf_single_leg_rdl_dumbbell", "Single-Leg Romanian Deadlift (Dumbbell)", ["hamstrings"], ["glutes", "lower back"], "dumbbell", None, "intermediate"),
    ex("jf_stick_iso_drivers", "ISO Drivers (Stick)", ["abdominals"], ["shoulders"], "other"),
    ex("jf_stick_lateral_drivers", "Lateral Drivers (Stick)", ["abdominals"], ["shoulders"], "other"),
    ex("jf_stick_single_arm_iso_chest_press", "Single-Arm ISO Chest Press (Stick)", ["chest"], ["triceps", "shoulders"], "other"),
    ex("jf_box_squat_dumbbell", "Box Squat (Dumbbell)", ["quadriceps"], ["glutes", "hamstrings"], "dumbbell"),
    ex("jf_warm_up", "Warm Up", [], [], "body only"),
    ex("jf_clean_squat_press_kettlebell", "Clean, Squat and Press (Kettlebell)", ["shoulders"], ["quadriceps", "glutes", "triceps"], "kettlebells", None, "intermediate"),
]

def main():
    base = json.load(open(os.path.join(RES, "exercises.json")))
    by_name = {e["name"]: e["id"] for e in base}
    extra_ids = {e["id"] for e in EXTRA}
    out = {}
    for hevy, target in ALIASES.items():
        if target in extra_ids:
            out[hevy.lower()] = target
        elif target in by_name:
            out[hevy.lower()] = by_name[target]
        else:
            raise SystemExit(f"Unknown target for {hevy!r}: {target!r}")
    with open(os.path.join(RES, "hevy_names.json"), "w") as f:
        json.dump(dict(sorted(out.items())), f, indent=1, ensure_ascii=False)
    with open(os.path.join(RES, "extra_exercises.json"), "w") as f:
        json.dump(EXTRA, f, indent=1, ensure_ascii=False)
    print(f"{len(out)} aliases, {len(EXTRA)} extra exercises")

if __name__ == "__main__":
    main()
