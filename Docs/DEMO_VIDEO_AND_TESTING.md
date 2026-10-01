# Demo video and student testing

## Demo video (aim for 2 to 3 minutes, public/unlisted https link)
Record the iOS simulator screen (Cmd+R in QuickTime > New Screen Recording, or `xcrun simctl io booted recordVideo demo.mov`) and add your voiceover.

| Time | Show | Say |
|---|---|---|
| 0:00 | You, or a title card | The hook: "[X]% of teens don't feel prepared to vote. I built CivAware to change that." (Find a real, sourced statistic before you use one.) |
| 0:15 | Home tab | "CivAware is a free iOS app that teaches government and gets students to take part." |
| 0:30 | Learn: open a lesson, answer a quiz question, show Sources | "Short nonpartisan lessons, each with official sources." |
| 1:00 | Simulate > Build a Bill: play one run, let it fail at committee, then win | "Most real bills die in committee. Here's what happens when you compromise." |
| 1:40 | City Budget (quick), then Spot the Spin: sort one fake post | "No budget makes everyone happy, and spotting spin is a skill you can learn." |
| 2:05 | Act: type a ZIP + address, reps appear, open the message composer | "This is what makes CivAware different: it's about *your* representatives." |
| 2:35 | Me tab: badges, streak. Then privacy line | "No account, no ads, no tracking." |
| 2:50 | Impact: [N students tested it, score improved from X to Y] | The proof. |

Tips: use a clean simulator state (Me > Reset all progress); keep the pace brisk; add captions; test that the link works while logged out.

## Student test (this is what separates finalists from everyone else)
Goal: get 10-20 students (ages 12-18) and real numbers you can quote.

1. **Pre-quiz** (5 questions, no help): e.g. How many votes to override a veto? Who can introduce a bill? What are the three branches? Who runs your school district? Can you name a rep?
2. **Use CivAware for 15 minutes** (2 lessons + 1 simulation + find reps). Watch silently; note where they get stuck.
3. **Post-quiz** (same questions) plus 3 survey items (1-5): "It was easy to use", "I learned something new", "I'd use it again". Ask: "What was confusing? What would you change?"
4. **Record**: average pre and post score, % who found their reps, quotes.
5. **Change something** based on feedback, then write it down. "I changed X because 4 of 12 testers said Y" is gold for the technical-difficulties and learning answers.

Get consent from parents/guardians for anyone under 18 and keep results anonymous. Don't publish names.

## Pre-submission checklist
- [ ] Verify each lesson fact against its cited source (or have a social-studies teacher review)
- [ ] Test on a real iPhone (Xcode > your device > Run)
- [ ] Add an app icon (1024x1024) in Assets.xcassets
- [ ] Push code to a public GitHub repo with a README + screenshots, and opt in to Congressional Certification
- [ ] Student testing done and results recorded
- [ ] Video uploaded as public/unlisted https link
- [ ] Cover photo 600x800 JPEG
- [ ] Every form answer rewritten in your voice, AI disclosure accurate
- [ ] Check the official rules/eligibility and your district's deadline on congressionalappchallenge.us


> The full student-testing kit (quiz, parent letter, survey, session script and a results summarizer) is in `Docs/StudentTest/`. Run `python3 Docs/tools/summarize_results.py <your.csv>` to get the numbers to quote.
