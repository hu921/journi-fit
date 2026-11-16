# journi Fit

iPhone workout app by journipod.
App Store name: **journipod Fit: Workout**.

## Version 1 (draft)

No server. Data stays on the phone, with iCloud backup.

- **Routines**: each exercise has a list of sets (weight and reps), add or remove sets, and a rest timer.
- **Machine Finder**: search by machine, muscle, or equipment. How-to steps, photos, "Add to routine", and similar exercises as substitutes.
- **My Gym**: name your gym and location. Save machines with your own settings and photo. Add custom machines the database lacks. Share the machine list with other members by link or `.journigym` file.
- **Goals**: goal tracks (strength, weight loss, muscle, endurance) with progress logs.
- **Diet notes**: optional, plain text.
- **Share**: send a routine as a link (`journifit://`) or a `.journifit` file.

## Open in Xcode

1. Open `JourniFit.xcodeproj` (Xcode 16 or newer).
2. Pick your team in Signing & Capabilities.
3. Run on an iPhone simulator (iOS 17+).

iCloud backup needs the container `iCloud.com.journipod.journifit` in your Apple Developer account.

## Colors

All colors are in `JourniFit/Theme/Theme.swift`.
The main color is #E87A4A, the journi Diary color. The rest are neutral supporting colors.

## Exercise data

`JourniFit/Resources/exercises.json` comes from
[Free Exercise DB](https://github.com/yuhonas/free-exercise-db) (public domain, Unlicense).
Rebuild it with `scripts/build_exercises.py`.
Photos (start and end position) are bundled in `JourniFit/Resources/ExercisePhotos`, resized to 480px wide.

## Later

Circles and challenges need a server. They are not in version 1.
