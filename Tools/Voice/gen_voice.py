"""Generates the spoken voice lines (Assets/Audio/Voice/*.ogg) with Piper TTS.

Collects every line the game speaks from the level / mechanic scenes and
scripts (prompts, feedback texts) plus the fixed lines below, and writes one
OGG per line named by slug(text) (must match Voice.slug() in
Scripts/Autoload/Voice.gd).

Setup (once):
    pip install piper-tts soundfile
    python -m piper.download_voices en_GB-jenny_dioco-medium --data-dir C:/Users/joshu/piper-voices

Run from the project root:
    python Tools/Voice/gen_voice.py            # make missing lines only
    python Tools/Voice/gen_voice.py --force    # remake every generated line
    python Tools/Voice/gen_voice.py --list     # just print the lines

Existing files are kept unless --force, so a real recording saved over a
generated .ogg survives re-runs. Lines that disappear from the game are
deleted only if this script made them (tracked in lines.txt).
After running, import the new files: godot --headless --path . --import
"""
import glob
import os
import re
import sys

import numpy as np

VOICE_DIR = "Assets/Audio/Voice"
MANIFEST = os.path.join(VOICE_DIR, "lines.txt")
VOICES_DIR = os.environ.get("PIPER_VOICES", "C:/Users/joshu/piper-voices")
VOICE = "en_GB-jenny_dioco-medium"
LENGTH_SCALE = 1.12  # a little slower than normal, for small children
LEAD_SILENCE = 0.08

# Lines spoken from code rather than from a scene's text.
FIXED = [
    "Doodle Bee! Puzzle and Play!",
    "Who's playing?",
    "Hello! Let's make your player",
    "Tap Play to start!",
    "Stop playing?",
    "Well done!", "Great job!", "Amazing!",
    "Play again to win more stars and open the next world!",
    "This world is locked. Win more stars to open it!",
    "Play the wobbly games again to win more stars!",
    "You did it! You finished all the games!",
    "Keep going!",
    "Great!",
]
MAX_NUMBER = 20  # counting taps and "Yes, %d!" answers
# Letter tiles are read out as they're placed (spelling levels). Single letters
# are synthesised from their British names so they're never mispronounced.
LETTER_NAMES = dict(zip("ABCDEFGHIJKLMNOPQRSTUVWXYZ", [
    "ay", "bee", "see", "dee", "ee", "eff", "jee", "aitch", "eye", "jay", "kay", "el", "em",
    "en", "oh", "pee", "cue", "ar", "ess", "tee", "you", "vee", "double you", "ex", "why", "zed"]))

SCENE_KEYS = ("prompt_text", "prompt", "success_text", "try_again_text", "round_correct_text",
              "collect_first_text", "watch_text", "your_turn_text", "watch_again_text")


def slug(text):
    out, gap = "", False
    for c in text.lower():
        if "a" <= c <= "z" or "0" <= c <= "9":
            if gap and out:
                out += "_"
            out += c
            gap = False
        else:
            gap = True
    return out[:60]


def collect_lines():
    lines = list(FIXED)
    key_re = re.compile(r'^(%s) = "(.*)"$' % "|".join(SCENE_KEYS))
    for path in glob.glob("Scenes/**/*.tscn", recursive=True):
        text = open(path, encoding="utf-8").read()
        for line in text.splitlines():
            m = key_re.match(line)
            if m:
                lines.append(m.group(2))
        # Default question on each mechanic's PromptLabel.
        m = re.search(r'\[node name="PromptLabel"[^\]]*\]\n(?:[^\[]*?\n)?text = "(.*)"', text)
        if m and "Mechanics" in path:
            lines.append(m.group(1))
    export_re = re.compile(r'@export\S* var (\w+_text): String = "(.*)"')
    feedback_re = re.compile(r'show_feedback\("([^"]+)"')
    for path in glob.glob("Scenes/Mechanics/**/*.gd", recursive=True) + ["Scripts/MechanicLevel.gd"]:
        for line in open(path, encoding="utf-8"):
            for m in export_re.finditer(line):
                lines.append(m.group(2))
            for m in feedback_re.finditer(line):
                lines.append(m.group(1))
    out = []
    for line in lines:
        line = line.replace("\\n", " ").strip()
        if "%d" in line:
            out += [line % n for n in range(1, MAX_NUMBER + 1)]
        elif line:
            out.append(line)
    out += [str(n) for n in range(1, MAX_NUMBER + 1)]
    out += list(LETTER_NAMES)
    seen, unique = set(), []
    for line in out:
        if slug(line) and slug(line) not in seen:
            seen.add(slug(line))
            unique.append(line)
    return unique


def spoken_form(text):
    if text in LETTER_NAMES:
        return LETTER_NAMES[text]
    # Shouted words like "RED" or "BIGGEST" would be spelled out; say them normally.
    return re.sub(r"\b[A-Z]{2,}\b", lambda m: m.group(0).lower(), text)


def main():
    lines = collect_lines()
    if "--list" in sys.argv:
        for line in lines:
            print(f"{slug(line)}\t{line}")
        print(len(lines), "lines")
        return
    import soundfile
    from piper import PiperVoice, SynthesisConfig

    os.makedirs(VOICE_DIR, exist_ok=True)
    force = "--force" in sys.argv
    old = {}
    if os.path.exists(MANIFEST):
        for row in open(MANIFEST, encoding="utf-8"):
            if "\t" in row:
                s, t = row.rstrip("\n").split("\t", 1)
                old[s] = t
    voice = PiperVoice.load(os.path.join(VOICES_DIR, VOICE + ".onnx"))
    config = SynthesisConfig(length_scale=LENGTH_SCALE)
    made = 0
    for line in lines:
        path = os.path.join(VOICE_DIR, slug(line) + ".ogg")
        if os.path.exists(path) and not force:
            continue
        chunks = list(voice.synthesize(spoken_form(line), syn_config=config))
        rate = chunks[0].sample_rate
        audio = np.concatenate([np.zeros(int(rate * LEAD_SILENCE), dtype=np.int16)] +
                               [c.audio_int16_array for c in chunks])
        soundfile.write(path, audio, rate, format="OGG", subtype="VORBIS")
        made += 1
    keep = {slug(l) for l in lines}
    removed = 0
    for s in old:
        if s not in keep:
            for ext in (".ogg", ".ogg.import"):
                if os.path.exists(os.path.join(VOICE_DIR, s + ext)):
                    os.remove(os.path.join(VOICE_DIR, s + ext))
            removed += 1
    with open(MANIFEST, "w", encoding="utf-8", newline="\n") as f:
        for line in lines:
            f.write(f"{slug(line)}\t{line}\n")
    print(f"{len(lines)} lines, {made} generated, {removed} removed")


if __name__ == "__main__":
    main()
