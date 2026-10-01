# CivAware: one-page summary

**Tagline:** Stay aware. Stay involved.
**Platform:** iPhone (iOS), built with Swift and SwiftUI. **Builder:** Ethan Lee.

## The problem
Many students reach voting age without ever having practiced how government actually works: reading a bill, telling reliable information from spin, or contacting an official. Existing civics resources are excellent (iCivics, Khan Academy) but mostly built for classrooms and computers, and they rarely connect students to *their own* representatives.

## The solution
A phone-first app that goes from **knowing** to **doing**:
1. **Learn:** 14 short, nonpartisan lessons across 7 units, each with a quiz and official sources.
2. **Simulate:** *Build a Bill* (most bills die, just like real life), *Balance the City Budget* (no perfect answer), and *Spot the Spin* (media literacy with fictional posts).
3. **Act:** enter a ZIP code (and optionally an address) to find your real Senators and House member, with phone and contact links, then draft a respectful message and check off real civic actions.
4. **Stay aware:** a daily awareness question, streaks, XP and badges.

## What makes it different
- Personalized to the student's own representatives, not just the abstract system.
- Ends in real-world action, not just facts.
- Teaches *awareness* skills (spotting spin, checking sources) alongside civics facts.
- Private by design: no accounts, no ads, no tracking, progress stays on the device.

## Technical highlights
- SwiftUI + Observation; lessons are bundled JSON so content is easy to update.
- Representative lookup built from free public data (congress-legislators dataset, Census Geocoder, ZIP lookup), no API keys, with offline cache and graceful fallbacks.
- Original design system, synthesized sound effects, haptics, confetti, dark mode, Reduce Motion support.

## Impact (fill in after your student test)
- [N] students tested. Average quiz score rose from [X] to [Y] out of 10.
- [%] found their representatives on the first try.
- One change made from feedback: [describe].

## Try it
[GitHub link] · [Demo video link]
