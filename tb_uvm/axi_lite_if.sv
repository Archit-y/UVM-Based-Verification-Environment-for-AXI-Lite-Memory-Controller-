// ============================================================================
// axi_lite_if.sv
// Virtual interface wrapping the AXI-Lite signal bundle, used by both the
// UVM driver (drives stimulus) and UVM monitor (passively observes) so the
// testbench never touches DUT ports directly.
// ============================================================================

interface axi_lite_if #(
    parameter int ADDR_WIDTH = 6,
    parameter int DATA_WIDTH = 32
) (
    input logic ACLK,
    input logic ARESETn
);

  logic [ADDR_WIDTH-1:0]     AWADDR;
  logic                      AWVALID;
  logic                      AWREADY;

  logic [DATA_WIDTH-1:0]     WDATA;
  logic [(DATA_WIDTH/8)-1:0] WSTRB;
  logic                      WVALID;
  logic                      WREADY;

  logic [1:0]                BRESP;
  logic                      BVALID;
  logic                      BREADY;

  logic [ADDR_WIDTH-1:0]     ARADDR;
  logic                      ARVALID;
  logic                      ARREADY;

  logic [DATA_WIDTH-1:0]     RDATA;
  logic [1:0]                RRESP;
  logic                      RVALID;
  logic                      RREADY;

  // Driver clocking block: drives on posedge, samples with a small skew so
  // driven values are stable when the DUT samples them.
  clocking drv_cb @(posedge ACLK);
    output AWADDR, AWVALID, WDATA, WSTRB, WVALID, BREADY, ARADDR, ARVALID, RREADY;
    input  AWREADY, WREADY, BVALID, BRESP, ARREADY, RVALID, RDATA, RRESP;
  endclocking

  // Monitor clocking block: input-only, samples everything passively.
  clocking mon_cb @(posedge ACLK);
    input AWADDR, AWVALID, AWREADY, WDATA, WSTRB, WVALID, WREADY,
          BRESP, BVALID, BREADY, ARADDR, ARVALID, ARREADY,
          RDATA, RRESP, RVALID, RREADY;
  endclocking

  modport DRIVER  (clocking drv_cb, input ACLK, ARESETn);
  modport MONITOR (clocking mon_cb, input ACLK, ARESETn);

endinterface
