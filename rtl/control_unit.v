module control_unit (
    input  wire [5:0] opcode,
    input  wire [5:0] funct,
    output reg        reg_write,
    output reg        mem_read,
    output reg        mem_write,
    output reg        mem_to_reg,
    output reg        alu_src,
    output reg [3:0]  alu_ctrl,
    output reg        branch_eq,
    output reg        branch_ne,
    output reg        jump,
    output reg        valid_inst
);
    always @(*) begin
        reg_write = 1'b0;
        mem_read  = 1'b0;
        mem_write = 1'b0;
        mem_to_reg= 1'b0;
        alu_src   = 1'b0;
        alu_ctrl  = 4'b0000;
        branch_eq = 1'b0;
        branch_ne = 1'b0;
        jump      = 1'b0;
        valid_inst= 1'b1;

        case (opcode)
            6'b000000: begin
                reg_write = 1'b1;
                case (funct)
                    6'h20: alu_ctrl = 4'b0000; // add
                    6'h22: alu_ctrl = 4'b0001; // sub
                    6'h24: alu_ctrl = 4'b0010; // and
                    6'h25: alu_ctrl = 4'b0011; // or
                    6'h26: alu_ctrl = 4'b0100; // xor
                    6'h2a: alu_ctrl = 4'b0101; // slt
                    default: begin
                        reg_write = 1'b0;
                        valid_inst = 1'b0;
                    end
                endcase
            end
            6'h08: begin reg_write=1'b1; alu_src=1'b1; alu_ctrl=4'b0000; end // addi
            6'h0c: begin reg_write=1'b1; alu_src=1'b1; alu_ctrl=4'b0010; end // andi
            6'h0d: begin reg_write=1'b1; alu_src=1'b1; alu_ctrl=4'b0011; end // ori
            6'h23: begin reg_write=1'b1; mem_read=1'b1; mem_to_reg=1'b1; alu_src=1'b1; alu_ctrl=4'b0000; end // lw
            6'h2b: begin mem_write=1'b1; alu_src=1'b1; alu_ctrl=4'b0000; end // sw
            6'h04: begin branch_eq=1'b1; alu_ctrl=4'b0001; end // beq
            6'h05: begin branch_ne=1'b1; alu_ctrl=4'b0001; end // bne
            6'h02: begin jump=1'b1; end // j
            6'h00: begin end
            default: begin valid_inst = 1'b0; end
        endcase
    end
endmodule
