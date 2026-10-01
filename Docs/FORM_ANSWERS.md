# CivAware: Congressional App Challenge form, field by field

Go down the form in order. Everything under a heading is ready to paste, except things in [brackets], which only you can supply. **Do not submit until the brackets are gone and you've read every answer and confirmed it's true.**

## About Your App

| Field | Answer |
|---|---|
| What is your app called? | CivAware |
| Programming languages | Swift |
| Platform | Mobile (iOS) |
| Video demonstration link | [paste your public https video link. YouTube "Unlisted" or "Public"] |
| Cover photo | Upload `Docs/cover_600x800.jpg` |
| Link to your project | [your GitHub repo URL] |
| Congressional Certification checkbox | Check "Yes, I'd like to learn more" (needs the public GitHub repo) |

### What does your app do?  (248 words, limit 400)

CivAware is an iPhone app that teaches students how government works and then pushes them to actually do something with it.

There are lessons on how a bill becomes law, the three branches, federal vs. state vs. local government, elections, your rights, and how to tell if news is trustworthy. Each lesson is short, ends with a quiz, and links to the real sources like the National Archives and USA.gov.

There are also three games. In Build a Bill you take an idea through committee, the House, the Senate and the President, and most of the time it dies somewhere, which is how it goes in real life. In Balance the City Budget you split $10 million between things like roads, parks and libraries, and then residents tell you how they feel about it. In Spot the Spin you look at made-up posts and decide if they're trustworthy, just opinion, or need checking.

The part I care about most is the Act tab. You type in your ZIP code (and your street address if you want your exact district) and it shows your two Senators and your House member with their photos and phone numbers. It can help you write a message to them, and there's a checklist of real things you can do, like checking your voter registration.

There's a daily question, streaks and badges to keep people coming back. There are no accounts, no ads, and nothing gets tracked. Your progress just stays on your phone.

### What inspired you to create this app?  (18 words, limit 400)

[Waiting on your answers. Reply to my questions in chat and I'll write this one in your words.]

### What technical difficulties did you face?  (303 words, limit 400)

The hardest part was the "find your representatives" feature. Most tutorials use Google's civic API, but the part that looks up representatives got shut down, so I had to piece it together from free stuff instead. I ended up using an open-source list of everyone currently in Congress, a ZIP code lookup to get the state, and the Census Bureau's address tool to figure out which congressional district an address is in. A ZIP code alone can cover more than one district, which is why the street address is optional. If the address can't be matched, the app says so and shows every House member from the state instead of just breaking.

Privacy was another thing I thought about a lot. I didn't want a student to need an account or hand over data just to learn civics, so nothing is stored except your progress on your own phone. The app also tells you which websites it talks to when you use the lookup.

Making the games feel right took a lot of tweaking. In Build a Bill I wanted most attempts to fail at a believable point, but not be impossible, so I kept adjusting the numbers until a good strategy could win.

I also wanted to make sure the lessons were correct, since it would be embarrassing for a civics app to get facts wrong. Every lesson links to an official source, and I checked the links and replaced ones that were broken. [Add here if you had a teacher or anyone check the facts.]

Smaller things: making the sound effects feel good and not annoying (I made them in code instead of using downloaded ones), and making the app work with dark mode and people who have reduce motion turned on. [Add anything else that was actually hard for you.]

### What improvements would you make in a 2.0 version?  (138 words, limit 400)

First, I'd add local stuff. Right now it covers Congress, but most of what affects students happens at the city and school board level, so I'd want it to show upcoming local meetings and votes for where you live.

I'd also add more languages, starting with Spanish, because a lot of families would use it. A home screen widget with the daily question would help people keep their streaks. I'd like a way to follow a real bill from Congress.gov as it moves along.

For schools, I'd add a teacher mode so a class can see progress without collecting anyone's personal info. I'd make more games, like running a campaign. I also want to test it properly with people who use VoiceOver and improve accessibility from there. Last, an Android version, since not every student has an iPhone.

### Did you use AI? How?  (218 words, limit 400)

Yes, a lot. I used Claude Code, an AI coding assistant made by Anthropic.

What the AI did: it wrote most of the Swift code, the first version of the lesson text, the sound effects and app icon (both made with scripts), and rough drafts of parts of this application. I asked it to research other apps, plan the design, and compare ideas.

What I did: I chose the idea (a government literacy app for students), decided it should be about being an aware citizen and ending in real action, picked the name CivAware, and told the AI what to change, like the look, the colors, the sound effects and adding the awareness theme. [Add only what is true for you, for example: I ran the app on my iPhone and fixed bugs I found. I checked the lessons against the sources. I tested it with ___ students and changed ___ because of what they said. I read through the code so I can explain how it works. I rewrote these answers in my own words.]

I don't want to overstate my part. The AI wrote most of the code, and I'm being upfront about that. My contribution was the idea, the direction, the decisions about what the app should be, and [the testing and checking I did].

### What did you learn or take away?  (18 words, limit 400)

[Waiting on your answers. Reply to my questions in chat and I'll write this one in your words.]

## About Your Process

| Field | Answer |
|---|---|
| Where did you do most of the coding? | At Home |
| Date you completed the coding | [m/d/Y: use the real date you finish] |
| Created as part of a school/club project? | No |
| School/organization, teacher name, teacher email | Leave blank |
| App Challenge Ambassador email | [only if someone referred you; otherwise blank] |

## Final Confirmation

| Application Ready to Submit | Choose **Yes** only when you're truly done. You are the only one who can press this. |
