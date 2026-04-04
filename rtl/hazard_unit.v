module hazard_unit (
    input  wire       id_ex_mem_read,
    input  wire [4:0] id_ex_rt,
    input  wire [4:0] if_id_rs,
    input  wire [4:0] if_id_rt,
    output wire       stall
);
    assign stall = id_ex_mem_read && ((id_ex_rt == if_id_rs) || (id_ex_rt == if_id_rt)) && (id_ex_rt != 5'd0);
endmodule
