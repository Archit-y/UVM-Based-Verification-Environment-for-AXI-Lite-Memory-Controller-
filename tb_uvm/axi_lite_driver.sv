// ============================================================================
// axi_lite_driver.sv
// Drives axi_lite_txn items onto the DUT via the driver clocking block.
// Handles the AXI-Lite handshake (VALID/READY) for both write and read
// channels, including the write-response channel.
// ============================================================================

class axi_lite_driver extends uvm_driver #(axi_lite_txn);
  `uvm_component_utils(axi_lite_driver)

  virtual axi_lite_if.DRIVER vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_lite_if.DRIVER)::get(this, "", "vif", vif))
      `uvm_fatal("DRV", "Virtual interface not set in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    reset_signals();
    `uvm_info("DRV", "Waiting for ARESETn to deassert...", UVM_LOW)
    wait (vif.ARESETn === 1'b1);
    `uvm_info("DRV", "Reset released, driver starting", UVM_LOW)

    forever begin
      axi_lite_txn txn;
      seq_item_port.get_next_item(txn);
      if (txn.op == axi_lite_txn::AXI_WRITE)
        do_write(txn);
      else
        do_read(txn);
      seq_item_port.item_done();
    end
  endtask

  task reset_signals();
    vif.drv_cb.AWADDR  <= '0;
    vif.drv_cb.AWVALID <= 1'b0;
    vif.drv_cb.WDATA   <= '0;
    vif.drv_cb.WSTRB   <= '0;
    vif.drv_cb.WVALID  <= 1'b0;
    vif.drv_cb.BREADY  <= 1'b0;
    vif.drv_cb.ARADDR  <= '0;
    vif.drv_cb.ARVALID <= 1'b0;
    vif.drv_cb.RREADY  <= 1'b0;
  endtask

  task do_write(axi_lite_txn txn);
    `uvm_info("DRV", $sformatf("do_write: addr=0x%0h data=0x%0h strb=%0b -- starting",
              txn.addr, txn.data, txn.strb), UVM_MEDIUM)
    vif.drv_cb.AWADDR  <= txn.addr;
    vif.drv_cb.AWVALID <= 1'b1;
    vif.drv_cb.WDATA   <= txn.data;
    vif.drv_cb.WSTRB   <= txn.strb;
    vif.drv_cb.WVALID  <= 1'b1;
    vif.drv_cb.BREADY  <= 1'b1;

    do @(vif.drv_cb); while (!(vif.drv_cb.AWREADY && vif.drv_cb.WREADY));
    `uvm_info("DRV", "do_write: AW/W handshake done", UVM_MEDIUM)
    vif.drv_cb.AWVALID <= 1'b0;
    vif.drv_cb.WVALID  <= 1'b0;

    do @(vif.drv_cb); while (!vif.drv_cb.BVALID);
    `uvm_info("DRV", "do_write: BVALID seen, write complete", UVM_MEDIUM)
    txn.bresp = vif.drv_cb.BRESP;
    @(vif.drv_cb);
    vif.drv_cb.BREADY <= 1'b0;
  endtask

  task do_read(axi_lite_txn txn);
    `uvm_info("DRV", $sformatf("do_read: addr=0x%0h -- starting", txn.addr), UVM_MEDIUM)
    vif.drv_cb.ARADDR  <= txn.addr;
    vif.drv_cb.ARVALID <= 1'b1;
    vif.drv_cb.RREADY  <= 1'b1;

    do @(vif.drv_cb); while (!vif.drv_cb.ARREADY);
    `uvm_info("DRV", "do_read: AR handshake done", UVM_MEDIUM)
    vif.drv_cb.ARVALID <= 1'b0;

    do @(vif.drv_cb); while (!vif.drv_cb.RVALID);
    `uvm_info("DRV", "do_read: RVALID seen, read complete", UVM_MEDIUM)
    txn.rdata = vif.drv_cb.RDATA;
    txn.rresp = vif.drv_cb.RRESP;
    @(vif.drv_cb);
    vif.drv_cb.RREADY <= 1'b0;
  endtask

endclass
