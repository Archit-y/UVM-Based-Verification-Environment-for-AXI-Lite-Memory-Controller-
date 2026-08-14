# How to Talk About This Project in an Interview
### AXI-Lite Memory Controller — UVM Verification Environment

This is written as a spoken narrative — the way you'd actually walk an interviewer through it if they said "tell me about a verification project you've done." Read it a few times rather than memorizing it word for word; you want it to sound like you're explaining your own work, not reciting a script.

---

## 1. Set up why you built this

"I was preparing for design verification roles — specifically ones working on things like AI/ML accelerators — and I noticed a gap in my background. I had strong RTL design experience — FIFOs, arbiters — but verification methodology was mostly theoretical for me at that point. So I picked a project that would force me to build real verification skills end-to-end: not just writing a testbench, but planning verification, building a constrained-random UVM environment, doing assertion-based checking, and measuring coverage — the full verification lifecycle, not just 'does it work once.'

I chose an AXI-Lite memory controller specifically because AMBA protocols show up everywhere in SoC and accelerator verification — it's a realistic, industry-relevant target rather than a toy example, and it's complex enough to have genuine corner cases: partial writes, back-to-back transactions, address boundaries."

## 2. What the DUT actually is

"The design under test is a 16-register, 32-bit memory-mapped slave that implements the AXI4-Lite protocol — single-beat reads and writes, with proper handshaking on all five channels: write address, write data, write response, read address, and read data. It supports byte-level write strobes, so you can write to individual bytes within a word without disturbing the others — that's actually one of the trickier parts of the protocol to get right, and it became one of my main verification targets."

## 3. Your verification strategy — plan before you code

"Before writing any testbench code, I planned what I actually needed to verify: correct read-after-write behavior across the whole address range, correct handling of partial-strobe writes, back-to-back transactions with no idle cycles between them, response codes always being OKAY since this DUT never errors, and behavior across reset. That list became the backbone of both my directed tests and later my UVM sequences and coverage model — I didn't want coverage to be an afterthought bolted on at the end."

## 4. Phase 1 — directed testbench, and the bugs it actually caught

*This part matters — don't just say "I wrote a testbench and it passed." Bugs found are what interviewers actually want to hear.*

"I started with a directed, self-checking testbench rather than jumping straight to UVM, because I wanted to validate the DUT logic itself first, on a fast, simple simulation loop, before adding the complexity of a full verification methodology on top. I wrote nine directed checks: basic write-then-read, different addresses, boundary addresses, partial-strobe writes, back-to-back transactions, reads of untouched locations, overwrites, and behavior after a mid-test reset.

The first run failed — seven out of nine checks. That was actually useful, not embarrassing. I found two real issues:

First, the register file wasn't being reset — unwritten locations came back as X instead of 0, because I'd written the reset logic for the AXI control signals but forgotten to reset the actual memory array itself. Easy to miss, and exactly the kind of bug a directed reset-behavior test is supposed to catch.

Second — and this one taught me something about tool behavior, not just my design — I'd used a SystemVerilog default argument value of `'1` for the write-strobe parameter, expecting it to fill all four bits. Icarus Verilog only set the least significant bit, so every 'default' write was silently only writing one byte instead of the full word. I isolated that with a three-line reproduction case before fixing it, which confirmed it was a real default-value handling quirk, not a DUT bug — and I switched to always writing explicit literal values rather than relying on that shorthand, since implicit width-extension is exactly the kind of thing that behaves differently across simulators.

After fixing both, all nine checks passed. I also ran the DUT through Verilator's linter — that flagged two 'unused signal' warnings on the bottom two address bits of my latched addresses, which I annotated with lint waivers and a comment, since they're deliberately unused — the register file is word-aligned, so byte-within-word address bits don't select anything. That's the kind of thing I wanted to be able to explain rather than just suppress silently."

## 5. Phase 2 — building the actual UVM environment

"With the DUT logic validated, I moved to the actual UVM environment, which is the part that maps to how verification is really done in industry.

I built it with the standard UVM structure: a virtual interface with separate driver and monitor clocking blocks, so the driver actively pushes signals and the monitor passively observes without ever driving anything itself — that separation matters because it keeps the monitor honest as a reference of what actually happened on the bus, independent of what the driver intended.

On top of that: a sequence item representing one AXI transaction — read or write, with randomizable address, data, and strobe fields, plus alignment and range constraints so random stimulus stays legal. A driver that handles the handshake protocol for both channels. A monitor that reconstructs completed transactions from the bus and publishes them on an analysis port. A self-checking scoreboard that maintains its own golden reference memory model in software, updates it on every observed write, and checks every observed read against it — that's the actual verification judgment call, not just 'did the simulation finish without crashing.' And a functional coverage model sampling operation type, address region, strobe patterns, response codes, and a cross-coverage between operation type and address region, so I could tell whether random testing was actually reaching every part of the design, not just running a lot of cycles.

For stimulus, I wrote four sequences: a constrained-random sequence for broad coverage, and three directed sequences targeting specific things I cared about — a full write-then-read sweep across every address, an explicit sweep through every strobe pattern including the all-zero no-op case, and a back-to-back sequence with no idle cycles between transactions, to stress the handshake timing specifically."

## 6. Be honest about tooling — this is a strength, not a weakness

*Don't skip this part or try to hide it — a good interviewer will ask about your environment anyway, and how you reasoned about tool limitations is genuinely a good signal.*

"One thing worth mentioning: I did this development without a commercial simulator license on hand day-to-day, so I used Icarus Verilog for the DUT and directed testbench, which is free and fast for RTL-level iteration. But Icarus can't compile the actual UVM class library — I actually confirmed that directly rather than assuming it, by trying to compile the real Accellera UVM source and hitting a parser failure on DPI import syntax, and separately confirming Icarus doesn't support parameterized classes at all, which UVM's factory pattern depends on throughout. So I wrote the UVM environment against the real, standard UVM API — the same code that runs on Questa or VCS — and did what local verification I could: structural checks on every file for balanced class/function/task blocks, and a syntax-shim exercise to catch typos early, before running the full environment on [ModelSim/Questa via my institute's license].

I'd rather be upfront about exactly what was validated locally versus what's pending a real UVM run, than imply everything passed cleanly in an environment that can't actually execute it."

## 7. What you'd say about results

"When I ran the full UVM environment on Xilinx Vivado's simulator with UVM-1.2, all four tests came back clean — zero UVM_ERROR, zero UVM_WARNING across every run. The directed write-then-read sweep across all sixteen registers hit 85% functional coverage with all sixteen reads matching the reference model. The WSTRB corner-case test — which specifically exercises every byte-strobe pattern including the all-zero no-op case — came back at 78% coverage with all eight reads matching. The constrained-random test pushed coverage up to 96%, and the back-to-back stress test, which removes all idle cycles between transactions, actually hit 100% functional coverage with thirteen reads checked and zero errors. Across all four tests combined, that's forty-six read-and-compare checks against the golden reference model, zero mismatches.

What I'd actually highlight, though, isn't the clean pass — it's the debugging that got me there, because none of these passed on the first try, and I think that's the more honest and more useful thing to talk about."

## 7a. The bugs — this is the strongest part of the story, lead with it if asked "what went wrong"

"Three real issues came up while bringing the UVM environment up, and each taught me something different:

First, a stimulus-generation bug in my own testbench, not the DUT. My directed write-then-read sequence used a 6-bit loop counter to sweep through sixteen word-aligned addresses. When the counter reached the last address and incremented by four, the arithmetic result overflowed the 6-bit variable and silently wrapped back to zero — so instead of terminating after sixteen iterations, the test just kept looping forever, restarting from address zero. I caught it by noticing the simulation was taking a suspiciously long time and refusing to finish, then confirming from the log that address zero was appearing a second time after the sequence should have ended. The fix was to widen the loop counter to a proper 32-bit int and only slice it down to six bits when assigning into the address field. It's exactly the kind of bug that's easy to introduce and easy to miss, because the RTL underneath was completely correct the whole time — this was purely a testbench stimulus bug.

Second, a constraint conflict. My transaction class had a `dist` constraint restricting the write-strobe field to a specific weighted set of legal values for general random testing. But my directed strobe-corner-case sequence needed to explicitly force the all-zero, no-byte-written strobe pattern — which wasn't in that legal set. So the moment that test tried to randomize a transaction with `strobe == 4'b0000`, the solver had two contradictory constraints and randomization failed outright, which is exactly the kind of failure a solver is supposed to catch rather than silently ignore. The fix was adding 4'b0000 to the distribution with a low weight, so it's a legal value everywhere but still rare in general random testing.

Third — and this one was really a testbench design gap rather than a bug — I realized partway through that my WSTRB corner-case test only issued writes and checked that the bus returned an OKAY response. It never actually read the data back and verified the correct bytes had landed in memory. That meant if the byte-lane masking logic in the DUT had a subtle bug, this test wouldn't have caught it — it was checking that the protocol handshake completed, not that the design was correct. I added a readback after every strobe write, which is what turned that test from 0 reads checked into 8 reads checked with real pass/fail data, not just a clean bus transaction."

## 7b. What this shows about your process

"None of these were RTL bugs — the DUT itself, once I fixed the reset issue in the directed testbench phase, was solid. What this phase found were verification-methodology bugs: a loop counter, a constraint distribution, and a coverage gap in my own test intent. I think that's actually a good thing to be able to say in an interview — it shows the verification environment is doing its job of catching problems, even when the problems are in the verification code itself, not just the design."

## 8. If asked "what would you do differently" or "what's next"

"I'd add SVA-based protocol assertions on top of this — things like 'no data-phase activity without a valid preceding address phase,' handshake timing rules, and illegal-transition checks — so protocol violations get caught structurally rather than only by the scoreboard noticing wrong data after the fact. I'm also extending the same methodology to a second project, a UVM environment for a small systolic-array MAC unit, specifically because that's closer to the AI/ML accelerator verification work I'm targeting — this AXI-Lite project was deliberately the 'get the methodology right' project before applying it to something domain-specific."

---

## Quick-reference: likely follow-up questions

- **"Why UVM over a plain directed testbench?"** — Scalability and reuse: constrained-random stimulus finds cases you wouldn't think to write by hand, the driver/monitor/scoreboard split is reusable across tests, and coverage tells you objectively when you're done rather than "I think I tested enough."
- **"Why a scoreboard instead of just checking against expected values inline?"** — A scoreboard with an independent reference model catches bugs even when you didn't anticipate the exact failure mode; inline checks only catch what you explicitly wrote a check for.
- **"What's the hardest bug you found?"** — The loop-counter overflow in my own sequence, not the DUT. It silently wrapped a 6-bit counter after the last address, causing an infinite loop that looked like a "hung simulation" rather than an obvious failure — I had to notice the run was taking far too long and trace back through the log to find address zero repeating. That's the dangerous category of bug: nothing complains, it just quietly never finishes.
- **"How do you know your coverage model is actually good?"** — Cross-coverage between operation type and address region specifically, so I'm not just confirming reads and writes happen, but that they happen across the full address map, not clustered in one region random testing happened to favor.
