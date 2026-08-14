# AXI-Lite Memory Controller — UVM Verification Environment

A SystemVerilog/UVM verification environment for an AXI4-Lite compliant slave (16 x 32-bit memory-mapped register file), built and verified as part of a Design Verification portfolio.

## Results

Full UVM regression run on Xilinx Vivado (xsim, UVM-1.2), 4 tests, 46 total checked transactions:

| Test | Functional Coverage | Reads Checked | Scoreboard Errors |
|---|---|---|---|
| `axi_lite_write_read_test` | 85.42% | 16 | 0 |
| `axi_lite_strobe_test` | 77.78% | 8 | 0 |
| `axi_lite_random_test` | 95.83% | 9 | 0 |
| `axi_lite_back_to_back_test` | **100.00%** | 13 | 0 |

**0 scoreboard errors, 0 UVM_ERROR/UVM_WARNING across all four tests.**

## What's here

- **`rtl/axi_lite_slave.sv`** — DUT: AXI4-Lite slave, word-aligned register file, byte-strobe (WSTRB) writes supported.
- **`tb_directed/`** — Directed, self-checking sanity testbench (Icarus Verilog compatible) used to validate the DUT logic before building the full UVM environment. 9/9 checks pass, lint-clean via Verilator.
- **`tb_uvm/`** — Full UVM-1.2 environment: virtual interface, transaction class, 4 sequences (directed write/read sweep, WSTRB corner-case, constrained-random, back-to-back stress), driver, monitor, self-checking scoreboard (golden reference model), functional coverage (with cross-coverage), agent, env, 4 test classes.
- **`docs/RUNNING_ON_MODELSIM.md`** / **`docs/RUNNING_ON_VIVADO.md`** — exact compile/elaborate/run commands for ModelSim/Questa and Vivado (xsim), including GUI steps.
- **`docs/interview_narrative.md`** — full write-up of the verification approach, debug process, and results.

## Why two testbenches

Icarus Verilog (free, fast for RTL iteration) cannot compile the real UVM class library — confirmed directly by attempting to compile Accellera's UVM source against it, which fails on DPI import syntax, and separately confirmed Icarus doesn't support parameterized classes at all, which UVM's factory pattern depends on throughout. So the DUT was validated first on a directed testbench in Icarus, then the full UVM environment was written against the real UVM API and run on Xilinx Vivado (xsim).

## Bugs found and fixed along the way

1. **RTL bug (reset):** the register file wasn't cleared on `ARESETn`, so unwritten locations read back as `X`. Found by the directed testbench's reset-behavior check.
2. **Testbench bug (loop-counter overflow):** the directed write/read UVM sequence used a 6-bit loop counter to sweep 16 word-aligned addresses. After the last address, incrementing by 4 overflowed the 6-bit variable and silently wrapped to 0, causing an infinite loop instead of terminating. Fixed by widening the counter to a 32-bit `int`.
3. **Testbench bug (constraint conflict):** the transaction class's `dist` constraint for the write-strobe field didn't include `4'b0000` (the no-op strobe case). When the strobe corner-case sequence tried to force that value, the solver hit a genuine contradiction and `randomize()` failed. Fixed by adding `4'b0000` to the legal distribution.
4. **Verification gap (not a bug, a coverage hole):** the WSTRB corner-case test originally only wrote data and checked the response code (`BRESP == OKAY`), without reading back to confirm the correct bytes actually landed in memory — so it wasn't really verifying byte-lane masking, just that the bus handshake completed. Added a readback after every write so the scoreboard actually checks data correctness (went from 0 reads checked to 8).

## Quick local re-run (directed sanity test, Icarus Verilog)

```bash
cd tb_directed
iverilog -g2012 -o sim ../rtl/axi_lite_slave.sv tb_axi_lite_directed.sv
vvp sim
```

## Running the UVM environment

See `docs/RUNNING_ON_VIVADO.md` (Xilinx Vivado / xsim) or `docs/RUNNING_ON_MODELSIM.md` (ModelSim/Questa) for exact compile/elaborate/run commands, including GUI steps.

## Next steps

- SVA protocol assertions (handshake timing, address/data phase legality, illegal-transition checks).
