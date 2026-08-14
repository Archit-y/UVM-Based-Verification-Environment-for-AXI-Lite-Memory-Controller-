// ============================================================================
// axi_lite_scoreboard.sv
// Self-checking scoreboard: maintains a golden reference memory model,
// updates it on observed writes, and checks observed reads against it.
// Also checks BRESP/RRESP are always OKAY (this DUT never returns errors).
// ============================================================================

class axi_lite_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(axi_lite_scoreboard)

  uvm_analysis_imp #(axi_lite_txn, axi_lite_scoreboard) ap_imp;

  // Golden reference model: 16 words, reset to 0 (mirrors DUT's sync reset
  // behavior). NUM_REGS = 64 bytes / 4 bytes-per-word = 16.
  bit [31:0] ref_mem [0:15];

  int unsigned num_checked = 0;
  int unsigned num_errors  = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap_imp = new("ap_imp", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    foreach (ref_mem[i]) ref_mem[i] = 32'h0;
  endfunction

  // Called automatically whenever the monitor's analysis port writes a txn
  function void write(axi_lite_txn txn);
    int unsigned word_idx = txn.addr[5:2]; // ADDR_WIDTH=6, word offset=2

    if (txn.op == axi_lite_txn::AXI_WRITE) begin
      for (int b = 0; b < 4; b++)
        if (txn.strb[b])
          ref_mem[word_idx][b*8 +: 8] = txn.data[b*8 +: 8];

      if (txn.bresp !== 2'b00) begin
        `uvm_error("SB", $sformatf("Unexpected BRESP=%0d on write to addr=0x%0h", txn.bresp, txn.addr))
        num_errors++;
      end
    end else begin // AXI_READ
      num_checked++;
      if (txn.rdata !== ref_mem[word_idx]) begin
        `uvm_error("SB", $sformatf(
          "MISMATCH addr=0x%0h : DUT=0x%08h  EXPECTED=0x%08h",
          txn.addr, txn.rdata, ref_mem[word_idx]))
        num_errors++;
      end else begin
        `uvm_info("SB", $sformatf(
          "MATCH addr=0x%0h : 0x%08h", txn.addr, txn.rdata), UVM_HIGH)
      end

      if (txn.rresp !== 2'b00) begin
        `uvm_error("SB", $sformatf("Unexpected RRESP=%0d on read of addr=0x%0h", txn.rresp, txn.addr))
        num_errors++;
      end
    end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("SB", $sformatf(
      "SCOREBOARD SUMMARY: %0d reads checked, %0d errors", num_checked, num_errors), UVM_LOW)
    if (num_errors == 0)
      `uvm_info("SB", "*** SCOREBOARD: ALL CHECKS PASSED ***", UVM_LOW)
    else
      `uvm_error("SB", $sformatf("*** SCOREBOARD: %0d CHECKS FAILED ***", num_errors))
  endfunction

endclass
