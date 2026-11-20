"""Convert the shared Canon MIDI into a readable MusicXML score."""

import argparse
from pathlib import Path

from music21 import converter, key, metadata


def main():
    here = Path(__file__).resolve().parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=here / "canon.musicxml")
    args = parser.parse_args()
    score = converter.parse(here / "score.mid", format="midi", quarterLengthDivisors=(4,))
    score.metadata = metadata.Metadata(title="Canon in D", composer="Johann Pachelbel")
    for part, title in zip(score.parts, ("Piano (left)", "Piano (right)", "Cello", "Viola", "Violin"), strict=True):
        part.partName = title
        for signature in part.recurse().getElementsByClass(key.KeySignature):
            signature.activeSite.remove(signature)
        part.measure(1).insert(0, key.Key("D"))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    score.write("musicxml", fp=args.output)
    print(f"Wrote {args.output}")


if __name__ == "__main__":
    main()
