# Running the AXI-Lite UVM Environment on Vivado (xsim)

Vivado's simulator (xsim) has bundled UVM support since ~2018.1. UVM source
usually lives inside the Vivado install tree, e.g.:
`<Vivado_install_path>/data/system_verilog/uvm_1.2/`

Confirm the path first:
```
find <Vivado_install_path> -iname "uvm_pkg.sv" 2>/dev/null
```

## 1. Compile (xvlog)
Run from the project root:
```
xvlog -sv -L uvm --relax \
  rtl/axi_lite_slave.sv \
  tb_uvm/axi_lite_if.sv \
  tb_uvm/axi_lite_pkg.sv \
  tb_uvm/tb_axi_lite_uvm_top.sv
```
`-L uvm` tells xvlog to link Vivado's bundled UVM library automatically —
you usually do NOT need to manually point at uvm_pkg.sv like you would for
Questa. If `-L uvm` isn't recognized by your Vivado version, fall back to
explicitly compiling uvm_pkg.sv first, same as the ModelSim flow, using the
path you found above.

## 2. Elaborate (xelab)
```
xelab -debug typical tb_axi_lite_uvm_top -s axi_lite_uvm_sim -L uvm
```

## 3. Run each test (xsim)
```
xsim axi_lite_uvm_sim -testplusarg UVM_TESTNAME=axi_lite_write_read_test -runall
xsim axi_lite_uvm_sim -testplusarg UVM_TESTNAME=axi_lite_strobe_test -runall
xsim axi_lite_uvm_sim -testplusarg UVM_TESTNAME=axi_lite_random_test -runall
xsim axi_lite_uvm_sim -testplusarg UVM_TESTNAME=axi_lite_back_to_back_test -runall
```

## Known xsim quirks to expect
- xsim's UVM support is generally considered less complete/robust than
  Questa or VCS — some UVM features (certain factory overrides, some
  advanced phasing) can behave inconsistently. If something errors that
  looks UVM-library-related rather than related to our code specifically,
  say so when you paste the log — that's a different class of problem than
  a bug in our testbench.
- If `-L uvm` fails to resolve, we compile uvm_pkg.sv explicitly instead,
  same pattern as the Questa flow in RUNNING_ON_MODELSIM.md.
- Save the full compile (xvlog/xelab) and run (xsim) output, same as the
  ModelSim instructions — paste it back here either way, pass or fail.
