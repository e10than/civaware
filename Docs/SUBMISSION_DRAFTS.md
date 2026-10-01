# Congressional App Challenge: draft answers for CivAware

Each answer is under the 400-word limit (word counts shown). **Anything in [brackets] is something only you know. Fill it in and rewrite in your own voice.** Judges read many applications, and personal, specific stories win. Don't submit these word for word. The AI-use answer must describe what you actually did.

## Basics
- **App name:** CivAware (tagline: *Stay aware. Stay involved.*)
- **Languages:** Swift
- **Platform:** Mobile (iOS)
- **Video URL:** [public https link. YouTube Unlisted or Public]
- **Where you coded:** [At Home / At School / ...]
- **Date coding completed:** [m/d/Y]
- **Project link (optional):** [GitHub link]. Open-sourcing also qualifies you for the Hack Club Congressional Certification.
- **Cover photo:** `Docs/cover_600x800.jpg` (600x800 JPEG)

## What does your app do? (220 words)

CivAware helps students become aware, involved citizens. It teaches how government works and then gets them to take part in it.

Learn: seven short, nonpartisan units (14 lessons) cover how a bill becomes law, the three branches, federal vs. state vs. local government, elections, constitutional rights, staying informed, and getting involved. Each lesson ends with a quiz and links to official sources such as the National Archives, USA.gov and Congress.gov.

Simulate: three games teach by doing. Build a Bill takes a student's idea through committee, the House, the Senate and the President, and most attempts fail at a realistic step, like most real bills. Balance the City Budget makes them divide $10 million among competing needs and hear how residents react. Spot the Spin trains media literacy by having students sort fictional posts into trustworthy news, opinion, or "needs checking."

Act: students enter their ZIP code, and optionally a street address, to find their actual U.S. Senators and House member with photos, phone numbers and contact pages. They can draft a respectful message to a representative and follow a checklist of real civic actions, like checking voter registration or watching a local meeting.

Stay aware: a daily awareness question, streaks, XP and badges build a habit.

CivAware has no accounts, no ads and no tracking. Progress stays on the device.

## What inspired you? (WRITE THIS ONE YOURSELF) (122 words)

[Replace this with your own story, 150-300 words. Suggested structure:]

1. A specific moment: [a class, an election, a news story, or a time you realized you didn't understand something about how your government works].
2. The problem you noticed: many students turn 18 without ever having practiced contacting an official, reading a bill, or telling reliable information from spin.
3. What already exists, and what you wanted to add: I admire tools like iCivics and Khan Academy. I wanted something built for phones, personalized to each student's own representatives, and ending in real action.
4. Why "aware": [in your own words, what being an aware citizen means to you].
5. Who you built it for: [students like you and your friends].

## Technical difficulties (284 words)

[Edit to match what really happened. Draft:]

Finding representatives without an API key. Google retired its Representatives API, so I combined free public data: the open-source congress-legislators dataset for member information and contact details, a ZIP lookup for the state, and the U.S. Census Geocoder to turn a street address into a congressional district. A ZIP code alone can cover several districts, so the street address is optional and the app explains why it helps. When the address can't be matched, the app falls back gracefully to showing every House member for the state with a clear message. [Add what you actually struggled with.]

Privacy. I wanted students of any age to be able to use CivAware safely, so there are no accounts and progress is stored only on the device. The address is used for a single lookup and never stored. The app's privacy text names every service it contacts.

Making the simulations teach instead of just entertain. In Build a Bill I tuned the support scores and pass thresholds so that most attempts fail at a realistic stage but a thoughtful player can win. [Describe what you changed after playtesting.]

Content accuracy. Civics content has to be right, so every lesson cites official sources and I [checked each fact against its source / had a teacher review it]. I also verified every source link and replaced the ones that were broken.

Sound and feel. I wanted the app to feel rewarding without being annoying, so I synthesized all sound effects myself in code, kept wrong-answer sounds gentle, and added switches for sound and haptics. [Add your own detail.]

Offline behavior. The legislator data is cached so lookups still work without a connection.

## 2.0 improvements (114 words)

A Watch For feature that surfaces upcoming local elections, meetings and votes for the student's area. Lessons for individual states, cities and school districts, plus a lookup for local officials. A "track a real bill" feature connected to Congress.gov. Spanish and other languages so more families can use it. A Home Screen widget for the word of the day and the daily question. A classroom mode where teachers can see class progress without collecting personal data. More simulations, like running a campaign and amending a budget. Deeper accessibility, including a dyslexia-friendly font and full VoiceOver testing with real users. Finally, Android and web versions so every student can use it, not only iPhone owners.

## Did you use AI? (edit to match what you really did) (168 words)

Yes. I used Claude Code (from Anthropic) as an AI coding and design assistant. It helped me brainstorm the concept, compare it with existing apps, plan the design, write most of the first versions of the SwiftUI code, draft lesson text and simulation content, generate the sound effects and app icon with scripts, and draft parts of this application.

What I did myself: [keep only what is TRUE: chose the idea and audience; decided the "learn, simulate, act" structure and the name; reviewed, changed and tested the code; ran the app on my iPhone; fixed bugs; checked every lesson fact against official sources; tuned Build a Bill after playtesting; ran a test with [N] students and changed [thing] because of their feedback; wrote my inspiration and reflection answers; recorded the video].

AI made me faster, but the decisions, testing and accuracy checks were mine. I can explain how the app's code works. [Only write that last sentence if it's true, and make it true by reading the code.]

## What did you learn? (WRITE THIS ONE YOURSELF) (88 words)

[Replace with 150-250 words in your own voice. Prompts:]
- What surprised you about how government works while you built this?
- What did you learn about designing for real users, not just yourself (especially from the student test)?
- What was hardest to get right: accuracy, neutrality, or privacy?
- How did working with an AI assistant change how you code, and what did you decide to do yourself?
- What will you do next (share it with your school, contact your own representative, keep improving it)?
