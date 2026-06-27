# Backgammon Gym

**Train the skills, not just the moves.**

A native iOS training app (iPhone + iPad) for serious backgammon players — dedicated entirely to structured practice of the underlying skills, not to playing matches.

The app is **free and ad-free**, and it will stay that way. The full source is here under an open licence. This is a community project, not a commercial one.

[→ Website](https://hape42.de/hape42/gym/) · [→ Discussions](https://github.com/hape42/BackgammonGym/discussions) · ✉️ BackgammonGym@hape42.de

---

## Status: on TestFlight

The first version is in TestFlight and I'm **looking for testers**. You don't need to be an expert — honest feedback on what feels clear, what feels clumsy, and what's missing is exactly what helps most right now. If you'd like to try it, get in touch via [Discussions](https://github.com/hape42/BackgammonGym/discussions) or email.

Two kinds of help are especially welcome:

- **A critical read of the texts.** English isn't my first language, so a second pair of eyes on anything awkward, unclear, or plain wrong makes a real difference.
- **Testing iCloud sync across two devices.** If you have both an iPhone and an iPad, just use the app on each and let me know whether your data stays in sync.

## Screenshots

| | | |
|:-:|:-:|:-:|
| ![Start screen](https://hape42.de/hape42/gym/screenshots/1.png?v=2) | ![Training](https://hape42.de/hape42/gym/screenshots/9.png?v=2) | ![Statistics](https://hape42.de/hape42/gym/screenshots/18.png?v=2) |

→ [See all screenshots on the website](https://hape42.de/hape42/gym/)

## Why I'm building this

I played a lot of tournament backgammon about 30 years ago and travelled internationally for it. Then family and career took over, and I stopped for roughly 25 years. A few years ago I came back — at first casually online, by now more seriously again, analysing my matches and playing tournaments.

Coming back, I quickly noticed how many skills I was missing to really play well. There are good tools for *playing*; there are far fewer for *practising* the skills that actually make you better — and almost nothing that feels at home on an iPhone and works offline. Since I'm retired, have the time, and can code, I'm building it myself.

## What the app does

- **Pip Count** — from guided, step-by-step counting to full-speed drills. Multiple methods, multiple levels.
- **Cluster Counting** — pattern-based counting for faster, more accurate results in real play.
- **Match Equity Table (MET)** — every match score has a known win probability. Train to recall the right figure instantly, or reconstruct it on the fly (Neil's Numbers, Janowski formula).
- **Progress tracking** — statistics, trends and achievements per module, so you can see where you're improving and where you're not.

Around each module sits the full training structure: several practice stages from guided learning to timed workouts, optional timing (speed matters at the real table too), and progress history.

One feature I particularly care about: below every board, the **GNU and XG position IDs** are shown and can be copied with a single tap. That lets you take any interesting position straight into XG, GNU Backgammon or BGBlitz for deeper analysis — and you can import positions by ID the other way around.

Deliberately **not** planned: a play feature. This is about training individual skills, not playing full matches.

## Getting involved

I'm developing this on my own, but I'd welcome advice from experienced players — for example which methods make the most sense to teach first, or which positions work especially well for practice. No deadlines, no commitments; just sharing knowledge with someone building something for the community. [GitHub Discussions](https://github.com/hape42/BackgammonGym/discussions) is the best place, or email.

Contributions of code, positions, or translations are welcome too — open an issue, start a discussion, or send a pull request. And if anyone wants to port the app to Android, they're welcome to, as long as it also stays free in the store.

## Technical

- **Platform:** iOS (iPhone + iPad, universal)
- **Language:** Objective-C (a little SwiftUI for the trend charts)
- **Minimum iOS:** 16.4
- **Storage:** Core Data + CloudKit (private container; your training data syncs across your own devices and is never shared)

## License

[GNU General Public License v3.0](LICENSE). In short: you're free to use, study, change and share the code — but any distributed fork must stay open under the same licence. That keeps the project free, in the spirit it was started.
