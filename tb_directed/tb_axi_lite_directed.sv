// ============================================================================
// tb_axi_lite_directed.sv
// Directed, self-checking sanity testbench for axi_lite_slave.
// Purpose: fast local regression on Icarus Verilog before the real UVM env
// (which needs ModelSim/Questa/VCS) is run. Not a substitute for the UVM
// environment -- this only exercises directed scenarios + a few checks.
// ============================================================================

`timescale 1ns/1ps

module tb_axi_lite_directed;

  localparam int ADDR_WIDTH = 6;
  localparam int DATA_WIDTH = 32;

  logic ACLK, ARESETn;
  logic [ADDR_WIDTH-1:0] AWADDR;
  logic AWVALID, AWREADY;
  logic [DATA_WIDTH-1:0] WDATA;
  logic [(DATA_WIDTH/8)-1:0] WSTRB;
  logic WVALID, WREADY;
  logic [1:0] BRESP;
  logic BVALID, BREADY;
  logic [ADDR_WIDTH-1:0] ARADDR;
  logic ARVALID, ARREADY;
  logic [DATA_WIDTH-1:0] RDATA;
  logic [1:0] RRESP;
  logic RVALID, RREADY;

  int pass_count = 0;
  int fail_count = 0;

  axi_lite_slave #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) dut (.*);

  // Clock: 10ns period
  initial ACLK = 0;
  always #5 ACLK = ~ACLK;

  // ---------------- Tasks ----------------
  task automatic reset_dut();
    ARESETn = 0;
    AWADDR = 0; AWVALID = 0;
    WDATA = 0; WSTRB = 0; WVALID = 0;
    BREADY = 0;
    ARADDR = 0; ARVALID = 0;
    RREADY = 0;
    repeat (3) @(posedge ACLK);
    ARESETn = 1;
    @(posedge ACLK);
  endtask

  task automatic axi_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data,
                            input [(DATA_WIDTH/8)-1:0] strb = 4'b1111);
    @(posedge ACLK);
    AWADDR  <= addr;
    AWVALID <= 1;
    WDATA   <= data;
    WSTRB   <= strb;
    WVALID  <= 1;
    BREADY  <= 1;

    // wait for both address and data to be accepted
    do @(posedge ACLK); while (!(AWREADY && WREADY));
    AWVALID <= 0;
    WVALID  <= 0;

    // wait for write response
    do @(posedge ACLK); while (!BVALID);
    if (BRESP !== 2'b00) begin
      $display("[FAIL] axi_write addr=%0h : BRESP=%0d, expected OKAY", addr, BRESP);
      fail_count++;
    end
    @(posedge ACLK);
    BREADY <= 0;
  endtask

  task automatic axi_read(input [ADDR_WIDTH-1:0] addr, output [DATA_WIDTH-1:0] data);
    @(posedge ACLK);
    ARADDR  <= addr;
    ARVALID <= 1;
    RREADY  <= 1;

    do @(posedge ACLK); while (!ARREADY);
    ARVALID <= 0;

    do @(posedge ACLK); while (!RVALID);
    data = RDATA;
    if (RRESP !== 2'b00) begin
      $display("[FAIL] axi_read addr=%0h : RRESP=%0d, expected OKAY", addr, RRESP);
      fail_count++;
    end
    @(posedge ACLK);
    RREADY <= 0;
  endtask

  task automatic check_eq(string name, logic [DATA_WIDTH-1:0] got, logic [DATA_WIDTH-1:0] exp);
    if (got === exp) begin
      $display("[PASS] %s : got=%0h exp=%0h", name, got, exp);
      pass_count++;
    end else begin
      $display("[FAIL] %s : got=%0h exp=%0h", name, got, exp);
      fail_count++;
    end
  endtask

  // ---------------- Test sequence ----------------
  logic [DATA_WIDTH-1:0] rdata;

  initial begin
    $display("=== AXI-Lite Slave Directed Sanity Test ===");
    reset_dut();

    // Test 1: basic write-then-read on address 0
    axi_write(6'h00, 32'hDEADBEEF);
    axi_read(6'h00, rdata);
    check_eq("T1 write/read addr0", rdata, 32'hDEADBEEF);

    // Test 2: different address, different data
    axi_write(6'h04, 32'hCAFEF00D);
    axi_read(6'h04, rdata);
    check_eq("T2 write/read addr4", rdata, 32'hCAFEF00D);

    // Test 3: last valid address (addr 0x3C = word 15)
    axi_write(6'h3C, 32'h12345678);
    axi_read(6'h3C, rdata);
    check_eq("T3 write/read last word", rdata, 32'h12345678);

    // Test 4: partial write using WSTRB (only lower byte)
    axi_write(6'h08, 32'hAAAAAAAA);          // baseline
    axi_write(6'h08, 32'h000000FF, 4'b0001); // overwrite byte 0 only
    axi_read(6'h08, rdata);
    check_eq("T4 WSTRB partial write", rdata, 32'hAAAAAAFF);

    // Test 5: back-to-back writes to different addresses, then read both back
    axi_write(6'h10, 32'h11111111);
    axi_write(6'h14, 32'h22222222);
    axi_read(6'h10, rdata);
    check_eq("T5a back-to-back addr0x10", rdata, 32'h11111111);
    axi_read(6'h14, rdata);
    check_eq("T5b back-to-back addr0x14", rdata, 32'h22222222);

    // Test 6: read of untouched register returns 0 after reset
    axi_read(6'h20, rdata);
    check_eq("T6 read untouched reg is 0", rdata, 32'h00000000);

    // Test 7: overwrite existing address
    axi_write(6'h00, 32'h99999999);
    axi_read(6'h00, rdata);
    check_eq("T7 overwrite addr0", rdata, 32'h99999999);

    // Test 8: reset mid-test clears memory
    reset_dut();
    axi_read(6'h00, rdata);
    check_eq("T8 read after reset is 0", rdata, 32'h00000000);

    $display("=============================================");
    $display("TOTAL: %0d PASS, %0d FAIL", pass_count, fail_count);
    if (fail_count == 0)
      $display("RESULT: ALL TESTS PASSED");
    else
      $display("RESULT: TESTS FAILED");
    $display("=============================================");

    $finish;
  end

  // Safety timeout
  initial begin
    #10000;
    $display("[ERROR] Testbench timeout - a task likely hung");
    $finish;
  end

endmodule
