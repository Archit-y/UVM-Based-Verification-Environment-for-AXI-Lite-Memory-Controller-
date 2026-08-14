// ============================================================================
// tb_axi_lite_uvm_top.sv
// Top-level module: generates clock/reset, instantiates the DUT and the
// virtual interface, binds the interface into config_db for the driver and
// monitor to pick up, and kicks off UVM via run_test().
//
// Run on ModelSim/Questa, e.g.:
//   vlog -sv +incdir+$UVM_HOME/src $UVM_HOME/src/uvm_pkg.sv \
//        rtl/axi_lite_slave.sv tb_uvm/axi_lite_if.sv tb_uvm/axi_lite_pkg.sv \
//        tb_uvm/tb_axi_lite_uvm_top.sv
//   vsim tb_axi_lite_uvm_top -c -do "run -all" +UVM_TESTNAME=axi_lite_write_read_test
// ============================================================================

`include "uvm_macros.svh"
import uvm_pkg::*;
import axi_lite_pkg::*;

module tb_axi_lite_uvm_top;

  localparam int ADDR_WIDTH = 6;
  localparam int DATA_WIDTH = 32;

  logic ACLK;
  logic ARESETn;

  // Clock generation
  initial ACLK = 0;
  always #5 ACLK = ~ACLK;

  // Reset generation
  initial begin
    ARESETn = 0;
    repeat (3) @(posedge ACLK);
    ARESETn = 1;
  end

  // Interface instance
  axi_lite_if #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) vif (
    .ACLK(ACLK), .ARESETn(ARESETn)
  );

  // DUT instance, connected to the interface's signals
  axi_lite_slave #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) dut (
    .ACLK    (ACLK),
    .ARESETn (ARESETn),
    .AWADDR  (vif.AWADDR),
    .AWVALID (vif.AWVALID),
    .AWREADY (vif.AWREADY),
    .WDATA   (vif.WDATA),
    .WSTRB   (vif.WSTRB),
    .WVALID  (vif.WVALID),
    .WREADY  (vif.WREADY),
    .BRESP   (vif.BRESP),
    .BVALID  (vif.BVALID),
    .BREADY  (vif.BREADY),
    .ARADDR  (vif.ARADDR),
    .ARVALID (vif.ARVALID),
    .ARREADY (vif.ARREADY),
    .RDATA   (vif.RDATA),
    .RRESP   (vif.RRESP),
    .RVALID  (vif.RVALID),
    .RREADY  (vif.RREADY)
  );

  initial begin
    uvm_config_db#(virtual axi_lite_if.DRIVER)::set(null, "*", "vif", vif);
    uvm_config_db#(virtual axi_lite_if.MONITOR)::set(null, "*", "vif", vif);
    run_test();
  end

  // Waveform dump for debug
  initial begin
    $dumpfile("axi_lite_uvm.vcd");
    $dumpvars(0, tb_axi_lite_uvm_top);
  end

  // Safety watchdog: force-finish if the UVM run hangs (e.g. a driver/monitor
  // task stuck waiting on a handshake that never completes), so a bad run
  // can't run forever under -runall / -all.
  initial begin
    #200000; // 200us -- generous for ~30-50 transactions at a 10ns clock
    $display("[WATCHDOG] Simulation did not finish within 200us -- likely a stuck handshake. Forcing $finish.");
    $finish;
  end

endmodule
