// ============================================================================
// axi_lite_agent.sv / axi_lite_env.sv / axi_lite_test.sv
// Agent bundles sequencer+driver+monitor. Env bundles agent+scoreboard+
// coverage. Tests select which sequence(s) run.
// ============================================================================

// -------- Agent --------
class axi_lite_agent extends uvm_agent;
  `uvm_component_utils(axi_lite_agent)

  axi_lite_driver    driver;
  uvm_sequencer #(axi_lite_txn) sequencer;
  axi_lite_monitor   monitor;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitor = axi_lite_monitor::type_id::create("monitor", this);
    if (get_is_active() == UVM_ACTIVE) begin
      driver    = axi_lite_driver::type_id::create("driver", this);
      sequencer = uvm_sequencer#(axi_lite_txn)::type_id::create("sequencer", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE)
      driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction

endclass


// -------- Environment --------
class axi_lite_env extends uvm_env;
  `uvm_component_utils(axi_lite_env)

  axi_lite_agent       agent;
  axi_lite_scoreboard  scoreboard;
  axi_lite_coverage    coverage;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent      = axi_lite_agent::type_id::create("agent", this);
    scoreboard = axi_lite_scoreboard::type_id::create("scoreboard", this);
    coverage   = axi_lite_coverage::type_id::create("coverage", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.monitor.ap.connect(scoreboard.ap_imp);
    agent.monitor.ap.connect(coverage.analysis_export);
  endfunction

endclass


// -------- Base test --------
class axi_lite_base_test extends uvm_test;
  `uvm_component_utils(axi_lite_base_test)

  axi_lite_env env;

  function new(string name = "axi_lite_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi_lite_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction

endclass


// -------- Directed test: write-then-read-back sweep --------
class axi_lite_write_read_test extends axi_lite_base_test;
  `uvm_component_utils(axi_lite_write_read_test)

  function new(string name = "axi_lite_write_read_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    axi_lite_write_read_seq seq = axi_lite_write_read_seq::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agent.sequencer);
    phase.drop_objection(this);
  endtask

endclass


// -------- Directed test: strobe corner cases --------
class axi_lite_strobe_test extends axi_lite_base_test;
  `uvm_component_utils(axi_lite_strobe_test)

  function new(string name = "axi_lite_strobe_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    axi_lite_strobe_seq seq = axi_lite_strobe_seq::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agent.sequencer);
    phase.drop_objection(this);
  endtask

endclass


// -------- Random regression test --------
class axi_lite_random_test extends axi_lite_base_test;
  `uvm_component_utils(axi_lite_random_test)

  function new(string name = "axi_lite_random_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    axi_lite_rand_seq seq = axi_lite_rand_seq::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agent.sequencer);
    phase.drop_objection(this);
  endtask

endclass


// -------- Back-to-back stress test --------
class axi_lite_back_to_back_test extends axi_lite_base_test;
  `uvm_component_utils(axi_lite_back_to_back_test)

  function new(string name = "axi_lite_back_to_back_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    axi_lite_back_to_back_seq seq = axi_lite_back_to_back_seq::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agent.sequencer);
    phase.drop_objection(this);
  endtask

endclass
