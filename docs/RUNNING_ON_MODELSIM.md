# Running the AXI-Lite UVM Environment on ModelSim / Questa

Local testing in this sandbox was limited to Icarus Verilog, which:
- Successfully compiled, ran, and passed the **directed RTL sanity testbench**
  (`tb_directed/tb_axi_lite_directed.sv`) — 9/9 checks passing, lint-clean
  via Verilator.
- **Cannot compile the real UVM class library** (confirmed by direct attempt:
  fails on DPI-C import syntax deep in `uvm_svcmd_dpi.svh`) and **cannot even
  parse parameterized classes** (`class X #(type T = ...)`), which UVM's
  factory/registry pattern depends on throughout. This is a known Icarus
  limitation, not a bug in this code.

So the UVM environment (`tb_uvm/`) has been checked for structural balance
(class/endclass, function/endfunction, task/endtask, begin/end all verified
matched per file) but has **not been simulated**. Run it for real like this:

```tcsh
vlib work
vlog -sv +incdir+$UVM_HOME/src $UVM_HOME/src/uvm_pkg.sv \
     rtl/axi_lite_slave.sv \
     tb_uvm/axi_lite_if.sv \
     tb_uvm/axi_lite_pkg.sv \
     tb_uvm/tb_axi_lite_uvm_top.sv

vsim -c tb_axi_lite_uvm_top +UVM_TESTNAME=axi_lite_write_read_test -do "run -all; quit"
vsim -c tb_axi_lite_uvm_top +UVM_TESTNAME=axi_lite_strobe_test -do "run -all; quit"
vsim -c tb_axi_lite_uvm_top +UVM_TESTNAME=axi_lite_random_test -do "run -all; quit"
vsim -c tb_axi_lite_uvm_top +UVM_TESTNAME=axi_lite_back_to_back_test -do "run -all; quit"
```

`$UVM_HOME` should point at your IITG lab's installed UVM library
(usually bundled with Questa, e.g. `$QUESTA_HOME/verilog_src/uvm-1.2`).

## What to check when you run it
1. Does it elaborate at all? First real syntax check against genuine UVM.
2. `axi_lite_write_read_test` should show scoreboard MATCH for every address.
3. `axi_lite_strobe_test` specifically exercises WSTRB=4'b0000 (no-op write) —
   watch for that one; it's an edge case worth confirming the DUT handles
   
   as a true no-op.
5. Check `report_phase` output at the end for scoreboard error count and
   functional coverage percentage.
6. Please paste back any compile errors — likely candidates given this is
   fresh code: config_db type mismatches, clocking-block signal direction
   errors, or factory registration typos. I'll fix immediately.
