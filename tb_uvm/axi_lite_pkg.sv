// ============================================================================
// axi_lite_pkg.sv
// Package wrapper -- includes every UVM class in dependency order so the
// whole environment compiles as a single `import axi_lite_pkg::*;`
// ============================================================================

package axi_lite_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "axi_lite_txn.sv"
  `include "axi_lite_sequences.sv"
  `include "axi_lite_driver.sv"
  `include "axi_lite_monitor.sv"
  `include "axi_lite_scoreboard.sv"
  `include "axi_lite_coverage.sv"
  `include "axi_lite_agent_env_test.sv"

endpackage
