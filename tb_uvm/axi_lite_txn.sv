// ============================================================================
// axi_lite_txn.sv
// UVM sequence item representing one AXI-Lite transaction (read or write).
// ============================================================================

class axi_lite_txn extends uvm_sequence_item;

  typedef enum { AXI_WRITE, AXI_READ } axi_op_e;

  rand axi_op_e            op;
  rand bit [5:0]            addr;      // ADDR_WIDTH = 6
  rand bit [31:0]           data;      // write data (ignored for reads)
  rand bit [3:0]            strb;      // write strobe (ignored for reads)

  // Response fields, filled in by the monitor / DUT
  bit [31:0]  rdata;
  bit [1:0]   bresp;
  bit [1:0]   rresp;

  `uvm_object_utils_begin(axi_lite_txn)
    `uvm_field_enum(axi_op_e, op, UVM_ALL_ON)
    `uvm_field_int(addr,  UVM_ALL_ON)
    `uvm_field_int(data,  UVM_ALL_ON)
    `uvm_field_int(strb,  UVM_ALL_ON)
    `uvm_field_int(rdata, UVM_ALL_ON)
    `uvm_field_int(bresp, UVM_ALL_ON)
    `uvm_field_int(rresp, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "axi_lite_txn");
    super.new(name);
  endfunction

  // Constraints: word-aligned address (bottom 2 bits = 0), full range,
  // and a mix of full-word and partial-byte writes.
  constraint c_addr_aligned { addr[1:0] == 2'b00; }
  constraint c_addr_range   { addr inside {[6'h00 : 6'h3C]}; }
  constraint c_strb_dist {
    strb dist { 4'b1111 := 7, 4'b0001 := 1, 4'b0010 := 1,
                4'b0100 := 1, 4'b1000 := 1, 4'b0011 := 1, 4'b1100 := 1,
                4'b0000 := 1 };
  }

endclass
