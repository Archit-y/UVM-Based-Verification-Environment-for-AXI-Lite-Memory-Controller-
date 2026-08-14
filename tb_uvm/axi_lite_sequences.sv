// ============================================================================
// axi_lite_sequences.sv
// Sequence library: a base constrained-random sequence, plus directed
// sequences targeting specific corner cases the JD asks for (edge behavior,
// back-to-back transactions, partial-strobe writes).
// ============================================================================

// -------- Base constrained-random sequence --------
class axi_lite_rand_seq extends uvm_sequence #(axi_lite_txn);
  `uvm_object_utils(axi_lite_rand_seq)

  rand int unsigned num_txns = 20;
  constraint c_num_txns { num_txns inside {[10:50]}; }

  function new(string name = "axi_lite_rand_seq");
    super.new(name);
  endfunction

  task body();
    axi_lite_txn txn;
    repeat (num_txns) begin
      txn = axi_lite_txn::type_id::create("txn");
      start_item(txn);
      if (!txn.randomize())
        `uvm_error("SEQ", "Randomization failed")
      finish_item(txn);
    end
  endtask
endclass


// -------- Directed: write then read back same address --------
class axi_lite_write_read_seq extends uvm_sequence #(axi_lite_txn);
  `uvm_object_utils(axi_lite_write_read_seq)

  function new(string name = "axi_lite_write_read_seq");
    super.new(name);
  endfunction

  task body();
    axi_lite_txn wtxn, rtxn;
    // NOTE: loop counter must be wider than the 6-bit address field it's
    // driving into. A bit[5:0] counter here previously wrapped 60+4=64 -> 0
    // silently (6-bit overflow), causing an infinite loop back to address 0
    // instead of terminating after the 16th address. int is plenty wide.
    for (int unsigned a = 0; a <= 6'h3C; a += 4) begin
      wtxn = axi_lite_txn::type_id::create("wtxn");
      start_item(wtxn);
      if (!wtxn.randomize() with { op == axi_lite_txn::AXI_WRITE; addr == a[5:0]; strb == 4'b1111; })
        `uvm_error("SEQ", "Randomization failed")
      finish_item(wtxn);

      rtxn = axi_lite_txn::type_id::create("rtxn");
      start_item(rtxn);
      if (!rtxn.randomize() with { op == axi_lite_txn::AXI_READ; addr == a[5:0]; })
        `uvm_error("SEQ", "Randomization failed")
      finish_item(rtxn);
    end
  endtask
endclass


// -------- Directed: partial-strobe writes (byte-enable corner cases) --------
class axi_lite_strobe_seq extends uvm_sequence #(axi_lite_txn);
  `uvm_object_utils(axi_lite_strobe_seq)

  function new(string name = "axi_lite_strobe_seq");
    super.new(name);
  endfunction

  task body();
    axi_lite_txn txn, rtxn;
    bit [3:0] strobes[$] = '{4'b0001, 4'b0010, 4'b0100, 4'b1000,
                              4'b0011, 4'b1100, 4'b1111, 4'b0000};
    foreach (strobes[i]) begin
      txn = axi_lite_txn::type_id::create("txn");
      start_item(txn);
      if (!txn.randomize() with { op == axi_lite_txn::AXI_WRITE; addr == 6'h00; strb == strobes[i]; })
        `uvm_error("SEQ", "Randomization failed")
      finish_item(txn);

      // Read back after every strobe write so the scoreboard actually
      // checks the byte-level result against the golden model, not just
      // that BRESP came back OKAY. This is the real point of this test --
      // confirming WSTRB masking landed the right bytes, not just that
      // the handshake completed.
      rtxn = axi_lite_txn::type_id::create("rtxn");
      start_item(rtxn);
      if (!rtxn.randomize() with { op == axi_lite_txn::AXI_READ; addr == 6'h00; })
        `uvm_error("SEQ", "Randomization failed")
      finish_item(rtxn);
    end
  endtask
endclass


// -------- Directed: back-to-back transactions, no idle cycles --------
class axi_lite_back_to_back_seq extends uvm_sequence #(axi_lite_txn);
  `uvm_object_utils(axi_lite_back_to_back_seq)

  function new(string name = "axi_lite_back_to_back_seq");
    super.new(name);
  endfunction

  task body();
    axi_lite_txn txn;
    repeat (30) begin
      txn = axi_lite_txn::type_id::create("txn");
      start_item(txn);
      if (!txn.randomize())
        `uvm_error("SEQ", "Randomization failed")
      finish_item(txn);
    end
  endtask
endclass
