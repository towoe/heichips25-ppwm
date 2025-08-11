module serial_in #(
    parameter int WIDTH = 8
) (
    input logic clk,
    input logic rst_n,
    input logic data_i,
    output logic [WIDTH-1:0] data_o,
    output logic done_o
);

  typedef enum logic [1:0] {
    IDLE  = 2'b00,
    SHIFT = 2'b01,
    DONE  = 2'b10
  } state_t;

  state_t state, next_state;

  logic [WIDTH-1:0] shift_reg;
  logic [$clog2(WIDTH)-1:0] bit_count;

  // State register
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state <= IDLE;
    end else begin
      state <= next_state;
    end
  end

  // Counter and shift register
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      shift_reg <= '0;
      bit_count <= '0;
    end else begin
      case (state)
        IDLE: begin
          bit_count <= '0;
        end
        SHIFT: begin
          shift_reg <= {data_i, shift_reg[WIDTH-1:1]};
          bit_count <= bit_count + 1;
        end
        DONE: begin
        end
        default: begin
        end
      endcase
    end
  end

  // Next state logic
  always_comb begin
    case (state)
      IDLE: begin
        if (data_i) begin
          next_state = SHIFT;
        end else begin
          next_state = IDLE;
        end
      end
      SHIFT: begin
        if (bit_count == $clog2(WIDTH)'(WIDTH - 1)) begin
          next_state = DONE;
        end else begin
          next_state = SHIFT;
        end
      end
      DONE: begin
        next_state = IDLE;
      end
      default: begin
        next_state = IDLE;
      end
    endcase
  end

  assign data_o = shift_reg;
  assign done_o = (state == DONE);
endmodule
