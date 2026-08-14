// ============================================================================
// axi_lite_coverage.sv
// Functional coverage collector: subscribes to the monitor's analysis port
// and samples covergroups over address ranges, strobe patterns, op type,
// and response codes -- the "write all types of coverage measures" ask.
// ============================================================================

class axi_lite_coverage extends uvm_subscriber #(axi_lite_txn);
  `uvm_component_utils(axi_lite_coverage)

  axi_lite_txn txn_cg;

  covergroup cg_axi_lite;
    option.per_instance = 1;

    cp_op: coverpoint txn_cg.op {
      bins write = {axi_lite_txn::AXI_WRITE};
      bins read  = {axi_lite_txn::AXI_READ};
    }

    cp_addr: coverpoint txn_cg.addr {
      bins low_addr  = {[6'h00 : 6'h0C]};
      bins mid_addr  = {[6'h10 : 6'h2C]};
      bins high_addr = {[6'h30 : 6'h3C]};
    }

    cp_strb: coverpoint txn_cg.strb iff (txn_cg.op == axi_lite_txn::AXI_WRITE) {
      bins full_word    = {4'b1111};
      bins single_byte[] = {4'b0001, 4'b0010, 4'b0100, 4'b1000};
      bins half_word[]   = {4'b0011, 4'b1100};
      bins no_bytes      = {4'b0000};
    }

    cp_bresp: coverpoint txn_cg.bresp iff (txn_cg.op == axi_lite_txn::AXI_WRITE) {
      bins okay = {2'b00};
    }

    cp_rresp: coverpoint txn_cg.rresp iff (txn_cg.op == axi_lite_txn::AXI_READ) {
      bins okay = {2'b00};
    }

    // Cross-coverage: op type against address region, to make sure we
    // exercise reads and writes across the full address map, not just
    // one region.
    cx_op_addr: cross cp_op, cp_addr;

  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_axi_lite = new();
  endfunction

  function void write(axi_lite_txn t);
    txn_cg = t;
    cg_axi_lite.sample();
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf("Functional coverage: %0.2f%%", cg_axi_lite.get_coverage()), UVM_LOW)
  endfunction

endclass
