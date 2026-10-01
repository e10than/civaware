#!/usr/bin/env python3
"""Summarizes the student test results CSV into numbers you can quote."""
import csv, sys, statistics as st

path = sys.argv[1] if len(sys.argv) > 1 else "Docs/StudentTest/04_RESULTS_TEMPLATE.csv"
rows = [r for r in csv.DictReader(open(path)) if r.get("pre_score") and r.get("post_score")]
if not rows:
    sys.exit("No complete rows yet (need pre_score and post_score).")

def nums(key):
    out = []
    for r in rows:
        try: out.append(float(r[key]))
        except (ValueError, KeyError, TypeError): pass
    return out

pre, post = nums("pre_score"), nums("post_score")
gain = [b - a for a, b in zip(pre, post)]
print(f"Participants with both scores: {len(rows)}")
print(f"Average pre-quiz score:  {st.mean(pre):.1f} / 10")
print(f"Average post-quiz score: {st.mean(post):.1f} / 10")
print(f"Average improvement:     {st.mean(gain):+.1f} points ({st.mean(post)/max(st.mean(pre),1e-9)*100-100:+.0f}% relative)")
print(f"Improved: {sum(g > 0 for g in gain)}  Same: {sum(g == 0 for g in gain)}  Lower: {sum(g < 0 for g in gain)}")
found = [r["found_reps"].strip().lower() for r in rows if r.get("found_reps")]
if found:
    print(f"Found their representatives: {sum(f.startswith('y') for f in found)}/{len(found)}")
for key, label in [("easy_to_use", "Easy to use"), ("learned_new", "Learned something new"), ("would_use_again", "Would use again")]:
    v = nums(key)
    if v: print(f"{label} (1-5): {st.mean(v):.1f}")
