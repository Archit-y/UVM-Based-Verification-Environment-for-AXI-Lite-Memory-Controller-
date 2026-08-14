// ============================================================================
// axi_lite_monitor.sv
// Passively watches the AXI-Lite bus and reconstructs completed write/read
// transactions, broadcasting them on an analysis port to the scoreboard and
// the coverage collector.
// ============================================================================

class axi_lite_monitor extends uvm_monitor;
  `uvm_component_utils(axi_lite_monitor)

  virtual axi_lite_if.MONITOR vif;
  uvm_analysis_port #(axi_lite_txn) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_lite_if.MONITOR)::get(this, "", "vif", vif))
      `uvm_fatal("MON", "Virtual interface not set in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    fork
      watch_writes();
      watch_reads();
    join
  endtask

  task watch_writes();
    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.AWVALID && vif.mon_cb.AWREADY &&
          vif.mon_cb.WVALID  && vif.mon_cb.WREADY) begin
        axi_lite_txn txn = axi_lite_txn::type_id::create("txn");
        txn.op   = axi_lite_txn::AXI_WRITE;
        txn.addr = vif.mon_cb.AWADDR;
        txn.data = vif.mon_cb.WDATA;
        txn.strb = vif.mon_cb.WSTRB;

        // wait for the response to capture BRESP
        do @(vif.mon_cb); while (!vif.mon_cb.BVALID);
        txn.bresp = vif.mon_cb.BRESP;

        ap.write(txn);
      end
    end
  endtask

  task watch_reads();
    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.ARVALID && vif.mon_cb.ARREADY) begin
        axi_lite_txn txn = axi_lite_txn::type_id::create("txn");
        txn.op   = axi_lite_txn::AXI_READ;
        txn.addr = vif.mon_cb.ARADDR;

        do @(vif.mon_cb); while (!vif.mon_cb.RVALID);
        txn.rdata = vif.mon_cb.RDATA;
        txn.rresp = vif.mon_cb.RRESP;

        ap.write(txn);
      end
    end
  endtask

endclass
