`include "../reference_model/defines.sv"

module ref_model_top
(
	input clk,
	input reset
);
	`include "../reference_model/structs.sv"
	
	// Constant parametes - opcodes for each instruction type
	parameter[6:0] instruction_R_type_opcode = `TYPE_R;
	parameter[6:0] instruction_I_type_opcode = `TYPE_I;
	parameter[6:0] instruction_L_type_opcode = `TYPE_L;
	parameter[6:0] instruction_S_type_opcode = `TYPE_S;
	parameter[6:0] instruction_B_type_opcode = `TYPE_B;
	parameter[6:0] instruction_U_type_opcode = `TYPE_U;
	parameter[6:0] instruction_J_type_opcode = `TYPE_J;
	
	// Free variables
	logic [31:0] fvar_specific_addr, fvar_specific_addr_q, fvar_specific_addr_q_neg;
		
	logic [31:0] gb_data_from_L1_cpu1_q_neg, gb_data_from_L1_cpu2_q_neg;
	logic [31:0] gb_data_from_L2_1, gb_data_from_L2_2;
	logic gb_stall1, gb_stall2;
	logic flush_ref1, flush_ref2, flush_ref3, flush_ref4, flush_ref5;
	logic [8:0] past_index;
	logic [31:0] past_tag_L2, past_data_L2;
	logic set_full;
	logic [1:0] gb_cache_hit_out_pos, gb_cache_hit_out_neg;
	
	logic [31:0] address_on_miss;
	
	struct_instruction_R   struct_assignment_R1, struct_assignment_R2;
	struct_instruction_I_L struct_assignment_I1, struct_assignment_I2;
	struct_instruction_I_L struct_assignment_L1, struct_assignment_L2;
	struct_instruction_S_B struct_assignment_S1, struct_assignment_S2;
	struct_instruction_S_B struct_assignment_B1, struct_assignment_B2;
	struct_instruction_U_J struct_assignment_U1, struct_assignment_U2;
	struct_instruction_U_J struct_assignment_J1, struct_assignment_J2;
	
	// ================= ASSUMES SECTION ================// 
	// Every assume has its "clone" - due to using both positive and negative edge of clock signal
	// Assumptions for instructions for CPU1 and CPU2- which opcodes will tool feed 
	`include "properties_for_assumes.sv"
	
	//===============================================================================================================================================================================================================================
	// Assumptions for instructions - which opcodes will tool feed
	all_types_active_cpu1      : assume property(assume_opcodes_cpu1);
	all_types_active_cpu2      : assume property(assume_opcodes_cpu2);
	all_types_active_neg_cpu1  : assume property(assume_opcodes_neg_cpu1);
	all_types_active_neg_cpu2  : assume property(assume_opcodes_neg_cpu2);
	
	// Cant load into x0 register
	load_rs2_not_NULL_cpu1     : assume property(assume_load_rs2_not_NULL_cpu1);
	load_rs2_not_NULL_cpu2     : assume property(assume_load_rs2_not_NULL_cpu2);
	load_rs2_not_NULL_neg_cpu1 : assume property(assume_load_rs2_not_NULL_neg_cpu1);
	load_rs2_not_NULL_neg_cpu2 : assume property(assume_load_rs2_not_NULL_neg_cpu2);
	
	// When R or I of U type are active, you cant write in the x0 register
	cant_write_to_x0_cpu1      : assume property (assume_cant_write_to_x0_cpu1);
	cant_write_to_x0_cpu2      : assume property (assume_cant_write_to_x0_cpu1);
	cant_write_to_x0_neg_cpu1  : assume property (assume_cant_write_to_x0_neg_cpu1);
	cant_write_to_x0_neg_cpu2  : assume property (assume_cant_write_to_x0_neg_cpu2);
	
	// Stabilize the free variable and set it accordingly to memory limitations
	asm_fvar_stable            : assume property (assume_fvar_stable);
	asm_fvar_stable_neg        : assume property (assume_fvar_stable_neg);
	
	//If stall is ONE keep same operation as long as stall is ONE
	asm_if_stall_not_null_load_from_cpu2_to_cpu1	 : assume property (assume_if_stall_not_null_load_from_cpu2_to_cpu1);
	asm_if_stall_not_null_load_from_cpu1_to_cpu2	 : assume property (assume_if_stall_not_null_load_from_cpu1_to_cpu2);
	asm_if_stall_not_null_load_from_cpu2_to_cpu1_neg : assume property (assume_if_stall_not_null_load_from_cpu2_to_cpu1_neg);
	asm_if_stall_not_null_load_from_cpu1_to_cpu2_neg : assume property (assume_if_stall_not_null_load_from_cpu1_to_cpu2_neg);
	
	// If opcode is STORE, then keep mask value inside limit
	asm_funct3_S_type_opcode_cpu1     : assume property (assume_funct3_S_type_opcode_cpu1);
	asm_funct3_S_type_opcode_cpu2     : assume property (assume_funct3_S_type_opcode_cpu2);
	asm_funct3_S_type_opcode_neg_cpu1 : assume property (assume_funct3_S_type_opcode_neg_cpu1);
	asm_funct3_S_type_opcode_neg_cpu2 : assume property (assume_funct3_S_type_opcode_neg_cpu2);
	
	// If opcode is LOAD, then keep mask value inside limit
	asm_funct3_L_type_opcode_cpu1     : assume property (assume_funct3_L_type_opcode_cpu1);
	asm_funct3_L_type_opcode_cpu2     : assume property (assume_funct3_L_type_opcode_cpu2);
	asm_funct3_L_type_opcode_neg_cpu1 : assume property (assume_funct3_L_type_opcode_neg_cpu1);
	asm_funct3_L_type_opcode_neg_cpu2 : assume property (assume_funct3_L_type_opcode_neg_cpu2);
	//===============================================================================================================================================================================================================================

	assign struct_assignment_R1 = top.cpu1.instruction; 
	assign struct_assignment_I1 = top.cpu1.instruction;  
	assign struct_assignment_L1 = top.cpu1.instruction; 
	assign struct_assignment_S1 = '{{top.cpu1.instruction[31:25],top.cpu1.instruction[11:7]},top.cpu1.instruction[24:20],top.cpu1.instruction[19:15],top.cpu1.instruction[14:12],top.cpu1.instruction[6:0]}; 
	assign struct_assignment_B1 = '{{top.cpu1.instruction[31], top.cpu1.instruction[7], top.cpu1.instruction[30:25], top.cpu1.instruction[11:8]}, top.cpu1.instruction[24:20], top.cpu1.instruction[19:15],
					top.cpu1.instruction[14:12], top.cpu1.instruction[6:0]}; 
	assign struct_assignment_U1 = top.cpu1.instruction;
	assign struct_assignment_J1 = '{{top.cpu1.instruction[31] , top.cpu1.instruction[19:12] , top.cpu1.instruction[20] , top.cpu1.instruction[30:21]} , top.cpu1.instruction[11:7] , top.cpu1.instruction[6:0]};
	
	assign struct_assignment_R2 = top.cpu2.instruction; 
	assign struct_assignment_I2 = top.cpu2.instruction;  
	assign struct_assignment_L2 = top.cpu2.instruction; 
	assign struct_assignment_S2 = '{{top.cpu2.instruction[31:25],top.cpu2.instruction[11:7]},top.cpu2.instruction[24:20],top.cpu2.instruction[19:15],top.cpu2.instruction[14:12],top.cpu2.instruction[6:0]}; 
	assign struct_assignment_B2 = '{{top.cpu2.instruction[31], top.cpu2.instruction[7], top.cpu2.instruction[30:25], top.cpu2.instruction[11:8]}, top.cpu2.instruction[24:20], top.cpu2.instruction[19:15],
					top.cpu2.instruction[14:12], top.cpu2.instruction[6:0]}; 
	assign struct_assignment_U2 = top.cpu2.instruction;
	assign struct_assignment_J2 = '{{top.cpu2.instruction[31] , top.cpu2.instruction[19:12] , top.cpu2.instruction[20] , top.cpu2.instruction[30:21]} , top.cpu2.instruction[11:7] , top.cpu2.instruction[6:0]};
	
	assign gb_stall1 = top.cpu1.stall;
	assign gb_stall2 = top.cpu2.stall;
	
	
	typedef enum logic [1:0] {IDLE, WAIT, HIT} state_t;
    state_t state, next_state;
	logic [31:0] flopped_data_from_dmem[3:0];

	always_ff @(negedge clk) begin
		if(reset) begin
			flopped_data_from_dmem[0] = 0;
			flopped_data_from_dmem[1] = 0;
			flopped_data_from_dmem[2] = 0;
			flopped_data_from_dmem[3] = 0;
		end
		else begin 
			if(top.cpu1.controller_and_cache.cache_hit == 2'b01 && top.bus_ctrl.cache_hit_out1 == 2'b11 && top.cpu1.controller_and_cache.mask_in == 3'b010 && top.cache_L2.flush == 0) begin 
				flopped_data_from_dmem[0] <= top.dmem.memory[top.dmem.addr];
			end
			else begin
				flopped_data_from_dmem[0] <= flopped_data_from_dmem[0];
			end	

			flopped_data_from_dmem[1] <= flopped_data_from_dmem[0];
        	flopped_data_from_dmem[2] <= flopped_data_from_dmem[1];
        	flopped_data_from_dmem[3] <= flopped_data_from_dmem[2];		

		end
	end 

	logic [3:0] cnt;
	logic [1:0] idle_cnt;
	logic [4:0] flopped_rf_for_load_miss;
    // AUX State machine for load miss in both L1 and L2
    always_ff @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
			flopped_rf_for_load_miss <= 'b0;
			cnt <= 0;
			idle_cnt <= 0;
        end else begin
            state <= next_state;
			if(top.cpu1.controller_and_cache.cache_hit == 2'b01 && top.bus_ctrl.cache_hit_out1 == 2'b11 && top.cpu1.controller_and_cache.mask_in == 3'b010 && top.cache_L2.flush == 0) begin 
				flopped_rf_for_load_miss <= top.cpu1.instruction[11:7];
			end
			else begin 
				flopped_rf_for_load_miss <= flopped_rf_for_load_miss;
			end

			if(state == WAIT && top.cache_L2.flush == 0) begin
				cnt <= cnt + 1; 
			end 
			else if(state == HIT) begin
				cnt <= 0;
				idle_cnt <= 0;
			end
			else if(state == IDLE && top.cache_L2.flush == 0) begin
				idle_cnt <= idle_cnt + 1;
			end
			else begin 
				cnt <= cnt;
			end
        end
    end


    always_comb begin
    	next_state = IDLE;
        case (state)
            IDLE: begin
                if(top.cpu1.controller_and_cache.cache_hit == 2'b01 && top.bus_ctrl.cache_hit_out1 == 2'b11 && top.cpu1.controller_and_cache.mask_in == 3'b010 && top.cache_L2.flush == 0) begin   // MISS in L1 and L2
                    next_state = WAIT;
                end         
                else begin                       
                    next_state = IDLE;
                end           
            end

            WAIT : begin
			if(idle_cnt == 1) begin 
				if(top.cache_L2.flush == 0) begin
		            if(top.cpu1.controller_and_cache.cache_hit == 2'b10) begin 
		                next_state = HIT;
		            end
		            else begin 
		                next_state = WAIT;
		            end
				end
				else begin
					  next_state = WAIT;
				end
			end 
			else begin
				next_state = IDLE; 
			end

            end

			HIT : begin
				 next_state = IDLE;
			end

      endcase    
    end


	always_ff @(negedge clk) begin
		if(reset) begin
			fvar_specific_addr_q_neg   <= 'b0;
			gb_data_from_L1_cpu1_q_neg <= 'b0;
			gb_data_from_L1_cpu2_q_neg <= 'b0;
			gb_data_from_L2_1          <= 'b0;
			gb_data_from_L2_2          <= 'b0;
			gb_cache_hit_out_neg 	   <= 'b0;
		end 
		else begin
			fvar_specific_addr_q_neg <= fvar_specific_addr;
			gb_cache_hit_out_neg 	 <= top.cache_L2.cache_hit_out;
			
			if(top.cpu1.controller_and_cache.state == 2'b01 && top.cpu1.controller_and_cache.cache_hit == 2'b01 && top.bus_ctrl.cache_hit_out1 == 2'b01 && top.cpu1.controller_and_cache.mask_in == 3'b010) begin
				gb_data_from_L1_cpu2_q_neg <= top.cpu2.controller_and_cache.cache_memory_L1[top.cpu2.controller_and_cache.bus_address_in[7:2]].data;
			end
			else if(top.cpu2.controller_and_cache.state == 2'b01 && top.cpu2.controller_and_cache.cache_hit == 2'b01 && top.bus_ctrl.cache_hit_out2 == 2'b01 && top.cpu2.controller_and_cache.mask_in == 3'b010) begin
				gb_data_from_L1_cpu1_q_neg <= top.cpu1.controller_and_cache.cache_memory_L1[top.cpu1.controller_and_cache.bus_address_in[7:2]].data;
			end
			else if(top.cpu1.controller_and_cache.state == 2'b01 && top.cpu1.controller_and_cache.cache_hit == 2'b01 && top.bus_ctrl.cache_hit_out1 == 2'b10 && top.cpu1.controller_and_cache.mask_in == 3'b010) begin
				gb_data_from_L2_1 <= top.cache_L2.data_from_L2;
			end
			else if(top.cpu2.controller_and_cache.state == 2'b01 && top.cpu2.controller_and_cache.cache_hit == 2'b01 && top.bus_ctrl.cache_hit_out2 == 2'b10 && top.cpu2.controller_and_cache.mask_in == 3'b010) begin
				gb_data_from_L2_2 <= top.cache_L2.data_from_L2;
			end
			else begin
				gb_data_from_L1_cpu1_q_neg <= gb_data_from_L1_cpu1_q_neg;
				gb_data_from_L1_cpu2_q_neg <= gb_data_from_L1_cpu2_q_neg;
				gb_data_from_L2_1 	   <= gb_data_from_L2_1;
				gb_data_from_L2_2 	   <= gb_data_from_L2_2;
			end
		
		end
	end
	
	logic [31:0] past_bus_data_in_pos;
	logic [31:0] past_bus_data_in_neg;

	always_ff @(posedge clk) begin
		if(reset) begin
			fvar_specific_addr_q <= 'b0;
		end 
		else begin
			fvar_specific_addr_q <= fvar_specific_addr;	
		end
	end
	
	logic flush_way0_tag_match;
	logic flush_way1_tag_match;
	logic flush_tag_missmatch_way0_lru;
	logic flush_tag_missmatch_way1_lru;
	logic comb_flush_way0_tag_match;
	logic comb_flush_way1_tag_match;
	logic comb_flush_tag_missmatch_way0_lru;
	logic comb_flush_tag_missmatch_way1_lru;

	always_comb begin
		comb_flush_way0_tag_match = 0;
		comb_flush_way1_tag_match = 0;
		comb_flush_tag_missmatch_way0_lru = 0;
		comb_flush_tag_missmatch_way1_lru = 0;
		
		if(flush_way0_tag_match && top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][0].tag == top.cache_L2.bus_tag_in[23:1]) begin 
			comb_flush_way0_tag_match = 1;
		end
		else if(flush_way1_tag_match && top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][1].tag == top.cache_L2.bus_tag_in[23:1]) begin
			comb_flush_way1_tag_match = 1;
		end
		else if(flush_tag_missmatch_way0_lru) begin
			comb_flush_tag_missmatch_way0_lru = 1;
		end
		else if(flush_tag_missmatch_way1_lru) begin
			comb_flush_tag_missmatch_way1_lru = 1;
		end
	end

	always_ff @(negedge clk) begin
		if(reset) begin
			set_full <= 'b0; 
			flush_way0_tag_match <= 'b0;
			flush_way1_tag_match <= 'b0;
			past_bus_data_in_neg <= 'b0;
			flush_tag_missmatch_way0_lru <= 'b0;
			flush_tag_missmatch_way1_lru <= 'b0;
		end 
		else begin
			if(top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][0].valid == 1'b1 && top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][1].valid == 1'b1 && top.cache_L2.set_index == fvar_specific_addr[8:0]) begin 
				set_full <= 1;
				past_bus_data_in_neg <= top.cache_L2.bus_data_in;
					if(set_full && top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][0].tag == top.cache_L2.bus_tag_in[23:1] && top.cache_L2.flush) begin
						flush_way0_tag_match <= 1;
						flush_way1_tag_match <= 0;
						flush_tag_missmatch_way0_lru <= 0;
						flush_tag_missmatch_way1_lru <= 0;
					end
					else if(set_full && top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][1].tag == top.cache_L2.bus_tag_in[23:1] && top.cache_L2.flush) begin
						flush_way0_tag_match <= 0;
						flush_way1_tag_match <= 1;	
						flush_tag_missmatch_way0_lru <= 0;
						flush_tag_missmatch_way1_lru <= 0;					 
					end
					else if(set_full && top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][0].tag != top.cache_L2.bus_tag_in[23:1] && top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][1].tag != top.cache_L2.bus_tag_in[23:1] && top.cache_L2.flush) begin
						if(top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][0].lru) begin
							flush_way0_tag_match <= 0;
							flush_way1_tag_match <= 0;
							flush_tag_missmatch_way0_lru <= 1;	
							flush_tag_missmatch_way1_lru <= 0;
						end
						else if(top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][1].lru) begin
							flush_way0_tag_match <= 0;
							flush_way1_tag_match <= 0;
							flush_tag_missmatch_way0_lru <= 0;
							flush_tag_missmatch_way1_lru <= 1;
						end
						else begin
							flush_way0_tag_match <= 0;
							flush_way1_tag_match <= 0;
							flush_tag_missmatch_way0_lru <= 0;
							flush_tag_missmatch_way1_lru <= 0;
						end
					
					end
					else begin 
						flush_way0_tag_match <= 0;
						flush_way1_tag_match <= 0;
						flush_tag_missmatch_way0_lru <= 0;
						flush_tag_missmatch_way1_lru <= 0;
					end
		
			end
			else begin
				set_full <= 'b0;
				flush_way0_tag_match <= 0;
				flush_way1_tag_match <= 0;
				flush_tag_missmatch_way0_lru <= 0;
				flush_tag_missmatch_way1_lru <= 0;
			end 
		end
	end

	logic [31:0] flopped_lru_data;
	logic [22:0] flopped_lru_tag;
	always_ff @(negedge clk) begin
		if(reset) begin 
			flopped_lru_data <= 'b0;
			flopped_lru_tag  <= 'b0;
		end
		else begin 
			if(set_full) begin
		    	flopped_lru_data <= top.cache_L2.bus_data_in;
				flopped_lru_tag  <= top.cache_L2.bus_tag_in[23:1]; 
			end
			else begin 
				flopped_lru_data <= flopped_lru_data;
				flopped_lru_tag  <= flopped_lru_tag;
			end
		end 
	end


	always_ff @(negedge clk) begin
		if(reset) begin
			flush_ref1   <= 1'b0;
			flush_ref2   <= 1'b0;
			past_index   <= 'b0;
			past_data_L2 <= 'b0;
			past_tag_L2  <= 'b0;
		end
		if(top.cache_L2.flush == 1'b1 && top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][0].valid == 1'b1 && 
		   top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][1].valid == 1'b0 && top.cache_L2.set_index == fvar_specific_addr[8:0]) begin
			if(top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][0].tag != top.cache_L2.bus_tag_in[23:1]) begin
				flush_ref1   <= 1'b1;
				flush_ref2   <= 1'b0;
				past_index   <= top.cache_L2.set_index;
				past_data_L2 <= top.cache_L2.bus_data_in;
				past_tag_L2  <= top.cache_L2.bus_tag_in[23:1];
			end
			else begin
				flush_ref1   <= 1'b0;
				flush_ref2   <= 1'b1;
				past_index   <= top.cache_L2.set_index;
				past_data_L2 <= top.cache_L2.bus_data_in;
				past_tag_L2  <= top.cache_L2.bus_tag_in[23:1];
			end
		end
		else if(top.cache_L2.flush == 1'b1 && top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][0].valid == 1'b1 && 
			top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][1].valid == 1'b1 && top.cache_L2.set_index == fvar_specific_addr[8:0]) begin
			if(top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][0].tag == top.cache_L2.bus_tag_in[23:1]) begin
				flush_ref1   <= 1'b0;
				flush_ref2   <= 1'b0;
				past_index   <= top.cache_L2.set_index;
				past_data_L2 <= top.cache_L2.bus_data_in;
				past_tag_L2  <= top.cache_L2.bus_tag_in[23:1];
			end
			else begin
				flush_ref1   <= 1'b0;
				flush_ref2   <= 1'b0;
			end
		end
		else begin
			flush_ref1 <= 1'b0;
			flush_ref2 <= 1'b0;
			past_index <= 'b0;
			past_data_L2 <= 'b0;
			past_tag_L2  <= past_tag_L2;
		end
	end
	

	logic [31:0] flopped_dmem_data_lru0,flopped_dmem_data_lru1;
	logic [22:0] flopped_dmem_tag_lru0, flopped_dmem_tag_lru1;
	logic dmem_flag1, dmem_flag2;
	
	always_ff @(negedge clk) begin
		if(reset) begin
			flopped_dmem_data_lru0 <= 'b0;
			flopped_dmem_tag_lru0  <= 'b0;
			flopped_dmem_data_lru1 <= 'b0;
			flopped_dmem_tag_lru1  <= 'b0;
			dmem_flag1 <= 0;
			dmem_flag2 <= 0;
		end
		else begin
			if(top.cache_L2.cache_memory_L2[top.cache_L2.set_index][0].lru == 1 && top.cache_L2.cache_memory_L2[top.cache_L2.set_index][1].lru == 0 && top.cache_L2.state == 2'b01 &&
			   top.cache_L2.set_index == fvar_specific_addr[8:0] && top.cache_L2.flush == 0) begin
				flopped_dmem_data_lru0 <= top.dmem.data_from_dmem;
				flopped_dmem_tag_lru0  <= top.cache_L2.tag;  
				dmem_flag1 <= 1;
			end
			else if(top.cache_L2.cache_memory_L2[top.cache_L2.set_index][0].lru == 0 && top.cache_L2.cache_memory_L2[top.cache_L2.set_index][1].lru == 1 && top.cache_L2.state == 2'b01 && 
				top.cache_L2.set_index == fvar_specific_addr[8:0] && top.cache_L2.flush == 0) begin
				flopped_dmem_data_lru1 <= top.dmem.data_from_dmem;
				flopped_dmem_tag_lru1  <= top.cache_L2.tag;
				dmem_flag2 <= 1;
			end
			else begin
				flopped_dmem_data_lru0 <= flopped_dmem_data_lru0;
				flopped_dmem_tag_lru0  <= flopped_dmem_tag_lru0; 
				flopped_dmem_data_lru1 <= flopped_dmem_data_lru1;
				flopped_dmem_tag_lru1  <= flopped_dmem_tag_lru1;
				dmem_flag1 <= 0;
				dmem_flag2 <= 0;
			end
		end
	end

	// =============== PROPERTIES SECTION ================ 	
	
	// --------- BUS CONTROLLER - PROPERTIES ---------
	// When both of requests are HIGH and stall of CPU2 is LOW then chech grants for both CPU
	property check_toggle_when_both_req_grant2;
		(top.bus_ctrl.req_core1 && top.bus_ctrl.req_core2) && top.bus_ctrl.grant_core_toggle && top.bus_ctrl.stall_core2 == 1'b0 |-> 
		top.bus_ctrl.grant_core1 == 1'b0 && top.bus_ctrl.grant_core2 == 1'b1 && top.bus_ctrl.grant_core_toggle_next != top.bus_ctrl.grant_core_toggle ;   
	endproperty

	// When both of requests are HIGH and stall of CPU1 is LOW then chech grants for both CPU
	property check_toggle_when_both_req_grant1;
		(top.bus_ctrl.req_core1 && top.bus_ctrl.req_core2) && !top.bus_ctrl.grant_core_toggle && top.bus_ctrl.stall_core1 == 1'b0 |-> 
		top.bus_ctrl.grant_core1 == 1'b1 && top.bus_ctrl.grant_core2 == 1'b0 && top.bus_ctrl.grant_core_toggle_next != top.bus_ctrl.grant_core_toggle ;   
	endproperty

	property chech_when_reqs_are_not_high;
		!(top.bus_ctrl.req_core1 && top.bus_ctrl.req_core2) |-> top.bus_ctrl.grant_core1 == 1'b1 && top.bus_ctrl.grant_core2 == 1'b1;
	endproperty	
	//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	property data_forwarding_from_cpu1_to_cpu2;
		top.bus_ctrl.req_core1 && top.bus_ctrl.grant_core1 && top.bus_ctrl.bus_operation_in1 != 2'b11 && top.bus_ctrl.cache_hit_in2 |-> 
		top.bus_ctrl.bus_data_out1 == top.bus_ctrl.bus_data_in2 && top.bus_ctrl.cache_hit_out1 == 2'b01 &&  
		top.bus_ctrl.bus_operation_out2 == top.bus_ctrl.bus_operation_in1 && 
		top.bus_ctrl.bus_address_out2   == top.bus_ctrl.bus_address_in1   && 
		top.bus_ctrl.address_to_L2 	== top.bus_ctrl.bus_address_in1   && 
		top.bus_ctrl.opcode_out 	== top.bus_ctrl.opcode_in1;  
	endproperty	

	property data_forwarding_from_L2_to_cpu1;
		top.bus_ctrl.req_core1 && top.bus_ctrl.grant_core1 && top.bus_ctrl.bus_operation_in1 != 2'b11 && top.bus_ctrl.cache_hit_L2 == 2'b10 && !top.bus_ctrl.cache_hit_in2 |-> 
		top.bus_ctrl.bus_data_out1 == top.bus_ctrl.data_from_L2 && top.bus_ctrl.cache_hit_out1 == 2'b10;
	endproperty
	
	property data_forwarding_no_operation1;
		(top.bus_ctrl.req_core1 && top.bus_ctrl.grant_core1) && top.bus_ctrl.bus_operation_in1 != 2'b11 && !top.bus_ctrl.cache_hit_in2 && top.bus_ctrl.cache_hit_L2 != 2'b10  |->
		top.bus_ctrl.bus_data_out1 == 'b0 && top.bus_ctrl.cache_hit_out1 == 2'b11;
	endproperty
	//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	property data_forwarding_from_cpu2_to_cpu1;
		top.bus_ctrl.req_core2 && top.bus_ctrl.grant_core2 && top.bus_ctrl.bus_operation_in2 != 2'b11 && top.bus_ctrl.cache_hit_in1 |-> 
		top.bus_ctrl.bus_data_out2 	== top.bus_ctrl.bus_data_in1 	  && top.bus_ctrl.cache_hit_out2 == 2'b01 &&  
		top.bus_ctrl.bus_operation_out1 == top.bus_ctrl.bus_operation_in2 && 
		top.bus_ctrl.bus_address_out1   == top.bus_ctrl.bus_address_in2   && 
		top.bus_ctrl.address_to_L2 	== top.bus_ctrl.bus_address_in2   && 
		top.bus_ctrl.opcode_out 	== top.bus_ctrl.opcode_in2;  
	endproperty
	
	property data_forwarding_from_L2_to_cpu2;
		top.bus_ctrl.req_core2 && top.bus_ctrl.grant_core2 && top.bus_ctrl.bus_operation_in2 != 2'b11 && top.bus_ctrl.cache_hit_L2 == 2'b10 && !top.bus_ctrl.cache_hit_in1 |-> 
		top.bus_ctrl.bus_data_out2 == top.bus_ctrl.data_from_L2 && top.bus_ctrl.cache_hit_out2 == 2'b10;
	endproperty
	
	property data_forwarding_no_operation2;
		(top.bus_ctrl.req_core2 && top.bus_ctrl.grant_core2) && top.bus_ctrl.bus_operation_in2 != 2'b11 && !top.bus_ctrl.cache_hit_in1 && top.bus_ctrl.cache_hit_L2 != 2'b10  |->
		top.bus_ctrl.bus_data_out2 == 'b0 && top.bus_ctrl.cache_hit_out2 == 2'b11;
	endproperty
	//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	property forwaring_data_when_flush_happens;
		top.bus_ctrl.flush_in1 || top.bus_ctrl.flush_in2 |->
		top.bus_ctrl.flush_out 	    == 1'b1 && 
		top.bus_ctrl.data_to_L2_out == top.bus_ctrl.data_to_L2_input && 
		top.bus_ctrl.tag_to_L2_out  == top.bus_ctrl.tag_to_L2_in;
	endproperty
	
	property not_forwaring_data_when_flush_doesnt_happens;
		!top.bus_ctrl.flush_in1 && !top.bus_ctrl.flush_in2 |->
		top.bus_ctrl.flush_out      == 1'b0 && 
		top.bus_ctrl.data_to_L2_out == 'b0 && 
		top.bus_ctrl.tag_to_L2_out  == 'b0;
	endproperty
	//==================================================================================================================================================================================
	
	// --------- L2 CACHE CONTROLLER AND L2 MEMORY - PROPERTIES ---------
	property checking_transition_from_IDLE_to_DMEM_WRITE;
		top.cache_L2.state == 2'b00 && top.cache_L2.cache_hit_out == 2'b01 |=> 
		top.cache_L2.state == 2'b01; 
	endproperty
	
	property checking_transition_from_DMEM_WRITE_to_IDLE;
		top.cache_L2.state == 2'b01 && top.cache_L2.cache_hit_out == 2'b10 |=> 
		top.cache_L2.state == 2'b00;
	endproperty
	//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	property checking_way0_hit;
		top.cache_L2.cache_memory_L2[top.cache_L2.set_index][0].valid && (top.cache_L2.cache_memory_L2[top.cache_L2.set_index][0].tag == top.cache_L2.tag) |->
		top.cache_L2.way0_hit == 1'b1;
	endproperty
	
	property checking_way1_hit;
		top.cache_L2.cache_memory_L2[top.cache_L2.set_index][1].valid && (top.cache_L2.cache_memory_L2[top.cache_L2.set_index][1].tag == top.cache_L2.tag) |->
		top.cache_L2.way1_hit == 1'b1;
	endproperty
	//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	property load_word_from_cpu2_to_cpu1;
		top.opcode_out1 == 7'b0000011 && top.bus_ctrl.cache_hit_out1 == 2'b01 && top.cpu1.controller_and_cache.mask_in == 3'b010 && 
		top.cpu1.controller_and_cache.cache_hit == 2'b01 ##1 top.cpu1.controller_and_cache.cache_hit == 2'b10|-> 
		top.cpu1.controller_and_cache.cache_memory_L1[$past(top.cpu1.controller_and_cache.index_in[7:2])].data       == gb_data_from_L1_cpu2_q_neg &&
		top.cpu1.controller_and_cache.cache_memory_L1[$past(top.cpu1.controller_and_cache.index_in[7:2])].mesi_state == 2'b10;
	endproperty

	property load_word_from_cpu1_to_cpu2;
		top.opcode_out2 == 7'b0000011 && top.bus_ctrl.cache_hit_out2 == 2'b01 && top.cpu2.controller_and_cache.mask_in == 3'b010 &&
		top.cpu2.controller_and_cache.cache_hit == 2'b01 ##1 top.cpu2.controller_and_cache.cache_hit == 2'b10|-> 
		top.cpu2.controller_and_cache.cache_memory_L1[$past(top.cpu2.controller_and_cache.index_in[7:2])].data == gb_data_from_L1_cpu1_q_neg &&
		top.cpu2.controller_and_cache.cache_memory_L1[$past(top.cpu2.controller_and_cache.index_in[7:2])].mesi_state == 2'b10;
	endproperty
	//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	property load_word_from_cache_to_rf_on_miss_cpu1;
		top.cpu1.controller_and_cache.state == 2'b01 && top.cpu1.instruction[14:12] == 3'b010 && top.cpu1.stall == 1 ##1 top.cpu1.stall == 0 |->
		top.cpu1.controller_and_cache.cache_memory_L1[$past(top.cpu1.controller_and_cache.index_in[7:2])].data == top.cpu1.rf.registerfile[$past(top.cpu1.instruction[11:7])];		
	endproperty
	
	property load_word_from_cache_to_rf_on_miss_cpu2;
		top.cpu2.controller_and_cache.state == 2'b01 && top.cpu2.instruction[14:12] == 3'b010 && top.cpu2.stall == 1 ##1 top.cpu2.stall == 0 |->
		top.cpu2.controller_and_cache.cache_memory_L1[$past(top.cpu2.controller_and_cache.index_in[7:2])].data == top.cpu2.rf.registerfile[$past(top.cpu2.instruction[11:7])];		
	endproperty
	//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	property load_word_from_L2_to_cpu1_way0_hit;
		top.opcode_out1 == 7'b0000011 && top.bus_ctrl.cache_hit_out1 == 2'b10 && top.cpu1.controller_and_cache.mask_in == 3'b010 && top.cache_L2.way0_hit &&
		top.cpu1.controller_and_cache.cache_hit == 2'b01 ##1 top.cpu1.controller_and_cache.cache_hit == 2'b10|-> 
		top.cpu1.controller_and_cache.cache_memory_L1[$past(top.cpu1.controller_and_cache.index_in[7:2])].data == gb_data_from_L2_1;
	endproperty
	
	property load_word_from_L2_to_cpu1_way1_hit;
		top.opcode_out1 == 7'b0000011 && top.bus_ctrl.cache_hit_out1 == 2'b10 && top.cpu1.controller_and_cache.mask_in == 3'b010 && top.cache_L2.way1_hit &&
		top.cpu1.controller_and_cache.cache_hit == 2'b01 ##1 top.cpu1.controller_and_cache.cache_hit == 2'b10|-> 
		top.cpu1.controller_and_cache.cache_memory_L1[$past(top.cpu1.controller_and_cache.index_in[7:2])].data == gb_data_from_L2_1;
	endproperty
	
	property load_word_from_L2_to_cpu2_way0_hit;
		top.opcode_out2 == 7'b0000011 && top.bus_ctrl.cache_hit_out2 == 2'b10 && top.cpu2.controller_and_cache.mask_in == 3'b010 && top.cache_L2.way0_hit &&
		top.cpu2.controller_and_cache.cache_hit == 2'b01 ##1 top.cpu2.controller_and_cache.cache_hit == 2'b10|-> 
		top.cpu2.controller_and_cache.cache_memory_L1[$past(top.cpu2.controller_and_cache.index_in[7:2])].data == gb_data_from_L2_2;
	endproperty
	
	property load_word_from_L2_to_cpu2_way1_hit;
		top.opcode_out2 == 7'b0000011 && top.bus_ctrl.cache_hit_out2 == 2'b10 && top.cpu2.controller_and_cache.mask_in == 3'b010 && top.cache_L2.way1_hit &&
		top.cpu2.controller_and_cache.cache_hit == 2'b01 ##1 top.cpu2.controller_and_cache.cache_hit == 2'b10|-> 
		top.cpu2.controller_and_cache.cache_memory_L1[$past(top.cpu2.controller_and_cache.index_in[7:2])].data == gb_data_from_L2_2;
	endproperty
	//==================================================================================================================================================================================
	// WHEN FLUSH HAPPENS CHECK DOES DATA IS STORED CORRECTLY IN L2-CACHE
	property flushing_data_to_L2_both_ways_free; 
		top.cache_L2.flush == 1'b1 && top.cache_L2.cache_memory_L2[top.cache_L2.set_index][0].valid == 0 && top.cache_L2.cache_memory_L2[top.cache_L2.set_index][1].valid == 0 |=>
		top.cache_L2.cache_memory_L2[$past(top.cache_L2.set_index)][0].valid == 1 &&
		top.cache_L2.cache_memory_L2[$past(top.cache_L2.set_index)][0].lru   == 0 &&
		top.cache_L2.cache_memory_L2[$past(top.cache_L2.set_index)][1].lru   == 1 &&
		top.cache_L2.cache_memory_L2[$past(top.cache_L2.set_index)][0].data  == $past(top.cache_L2.bus_data_in) &&
		top.cache_L2.cache_memory_L2[$past(top.cache_L2.set_index)][0].tag   == $past(top.cache_L2.bus_tag_in[23:1]); 
	endproperty
	
	property flushing_data_to_L2_second_available_first_not_tag_missmatch;
		flush_ref1 |->
		top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][1].valid == 1 &&
                top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][1].lru   == 0 && 
                top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][0].lru   == 1 &&   
                top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][1].data  == past_data_L2 &&
                top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][1].tag   == past_tag_L2; 
	endproperty
	
	property flushing_data_to_L2_second_available_first_not_tag_match;
		flush_ref2 |->
		top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][0].valid == 1 &&
                top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][0].lru   == 0 && 
                top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][1].lru   == 1 &&   
                top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][0].data  == past_data_L2 &&
                top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][0].tag   == past_tag_L2; 
	endproperty
	
	property flushing_data_to_L2_when_both_lines_are_not_free_way0_tag_match;
		comb_flush_way0_tag_match |-> 
		top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][0].lru   == 0 && 
	  	top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][1].lru   == 1 &&   
		top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][0].data  == past_bus_data_in_neg;
	endproperty

	property flushing_data_to_L2_when_both_lines_are_not_free_way1_tag_match;
		comb_flush_way1_tag_match |-> 
		top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][1].lru   == 0 && 
	  	top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][0].lru   == 1 &&   
		top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][1].data  == past_bus_data_in_neg;
	endproperty
	
	property flushing_data_to_L2_when_both_lines_are_not_free_tag_missmatch_way0_lru;
		comb_flush_tag_missmatch_way0_lru && top.cache_L2.state == 2'b00 |->
		top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][1].lru   == 1 && 
	  	top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][0].lru   == 0 &&   
		top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][0].data  == flopped_lru_data && 
		top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][0].tag   == flopped_lru_tag;
	endproperty
	
	property flushing_data_to_L2_when_both_lines_are_not_free_tag_missmatch_way1_lru;
		comb_flush_tag_missmatch_way1_lru && top.cache_L2.state == 2'b00 |->
		top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][1].lru   == 0 && 
	  	top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][0].lru   == 1 && 
		top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][1].data  == flopped_lru_data && 
		top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][1].tag   == flopped_lru_tag;
	endproperty
	
	
	property loading_data_from_DMEM_to_L2_both_lru_zero;
		top.cache_L2.cache_memory_L2[top.cache_L2.set_index][0].lru == 0 && 
		top.cache_L2.cache_memory_L2[top.cache_L2.set_index][1].lru == 0 &&
		top.cache_L2.state == 2'b01 && top.cache_L2.set_index == fvar_specific_addr[8:0] && top.cache_L2.flush == 0 |=>
		top.cache_L2.cache_memory_L2[$past(top.cache_L2.set_index)][0].valid == 1 &&
		top.cache_L2.cache_memory_L2[$past(top.cache_L2.set_index)][0].tag   == $past(top.cache_L2.tag) &&
		top.cache_L2.cache_memory_L2[$past(top.cache_L2.set_index)][0].data  == $past(top.cache_L2.data_from_dmem)   &&
		top.cache_L2.cache_memory_L2[$past(top.cache_L2.set_index)][0].lru   == 0  &&
		top.cache_L2.cache_memory_L2[$past(top.cache_L2.set_index)][1].lru   == 1;
	endproperty
	
	property loading_data_from_DMEM_to_L2_both_lru0;
		top.cache_L2.cache_memory_L2[top.cache_L2.set_index][0].lru == 1 && 
		top.cache_L2.cache_memory_L2[top.cache_L2.set_index][1].lru == 0 &&
		top.cache_L2.state == 2'b01 && top.cache_L2.set_index == fvar_specific_addr[8:0] && top.cache_L2.flush == 0 |=>
		top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][0].valid == 1 &&
		top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][0].tag   == flopped_dmem_tag_lru0  &&
		top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][0].data  == flopped_dmem_data_lru0 &&
		top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][0].lru   == 0  &&
		top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][1].lru   == 1;
	endproperty

	property loading_data_from_DMEM_to_L2_both_lru1;
		top.cache_L2.cache_memory_L2[top.cache_L2.set_index][0].lru == 0 && 
		top.cache_L2.cache_memory_L2[top.cache_L2.set_index][1].lru == 1 &&
		top.cache_L2.state == 2'b01 && top.cache_L2.set_index == fvar_specific_addr[8:0] && top.cache_L2.flush == 0 |=>
		top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][1].valid == 1 &&
		top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][1].tag   == flopped_dmem_tag_lru1  &&
		top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][1].data  == flopped_dmem_data_lru1 &&
		top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][1].lru   == 0  &&
		top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][0].lru   == 1;
	endproperty
	//==================================================================================================================================================================================
	// WHEN FLUSH HAPPENS CHECK DOES DATA IS STORED CORRECTLY FROM L2 TO DMEM
	property data_eviction_from_L2_to_DMEM_way1_free_way0_not;
		flush_ref2 == 1'b1 && top.cache_L2.opcode_out == 7'b0100011 && top.cache_L2.set_index == fvar_specific_addr[8:0] && 
		{top.cache_L2.cache_memory_L2[top.cache_L2.set_index][1].tag, top.cache_L2.set_index} < 1024 |=>
		top.dmem.memory[{$past(top.dmem.addr[31:2]),2'b00}] == $past(top.cache_L2.data_to_dmem);
	endproperty
	
	property data_eviction_from_L2_to_DMEM_both_full_way0_match;
		comb_flush_way0_tag_match == 1'b1 && top.cache_L2.opcode_out == 7'b0100011 && top.cache_L2.set_index == fvar_specific_addr[8:0] && 
		{top.cache_L2.cache_memory_L2[top.cache_L2.set_index][0].tag, top.cache_L2.set_index} < 1024 |=>
		top.dmem.memory[{$past(top.dmem.addr[31:2]),2'b00}] == $past(top.cache_L2.data_to_dmem);
	endproperty

	property data_eviction_from_L2_to_DMEM_both_full_way1_match;
		comb_flush_way1_tag_match == 1'b1 && top.cache_L2.opcode_out == 7'b0100011 && top.cache_L2.set_index == fvar_specific_addr[8:0] && 
		{top.cache_L2.cache_memory_L2[top.cache_L2.set_index][1].tag, top.cache_L2.set_index} < 1024 |=>
		top.dmem.memory[{$past(top.dmem.addr[31:2]),2'b00}] == $past(top.cache_L2.data_to_dmem);
	endproperty
	
	property data_eviction_from_L2_to_DMEM_both_full_both_ways_missmatch_way0;
		comb_flush_tag_missmatch_way0_lru == 1'b1 && top.cache_L2.state == 2'b00 && top.cache_L2.opcode_out == 7'b0100011 && 
		top.cache_L2.set_index == fvar_specific_addr[8:0] && {top.dmem.addr[31:2],2'b00} < 1024 |=>
		top.dmem.memory[{$past(top.dmem.addr[31:2]),2'b00}] == $past(top.cache_L2.data_to_dmem);	
	endproperty
	
	property data_eviction_from_L2_to_DMEM_both_full_both_ways_missmatch_way1;
		comb_flush_tag_missmatch_way1_lru == 1'b1 && top.cache_L2.state == 2'b00 && top.cache_L2.opcode_out == 7'b0100011 && 
		top.cache_L2.set_index == fvar_specific_addr[8:0] && {top.dmem.addr[31:2],2'b00} < 1024 |=>
		top.dmem.memory[{$past(top.dmem.addr[31:2]),2'b00}] == $past(top.cache_L2.data_to_dmem);	
	endproperty

	property data_eviction_from_L2_to_DMEM_on_cache_MISS_lru0;
		dmem_flag1 && {top.dmem.addr[31:2],2'b00} < 1024 |=>
		top.dmem.memory[{$past(top.dmem.addr[31:2]),2'b00}] == $past(top.cache_L2.data_to_dmem);	
	endproperty
	
	property data_eviction_from_L2_to_DMEM_on_cache_MISS_lru1;
		dmem_flag2 && {top.dmem.addr[31:2],2'b00} < 1024 |=>
		top.dmem.memory[{$past(top.dmem.addr[31:2]),2'b00}] == $past(top.cache_L2.data_to_dmem);	
	endproperty
	
/*
	property load_from_dmem_to_core;
		load_from_dmem_flag |=> flopped_data_from_dmem[2] == top.cpu1.rf.registerfile[flopped_rf_for_load_miss];
	endproperty
*/

	property load_from_dmem_to_core;
		state == HIT && cnt == 2|-> flopped_data_from_dmem[2] == top.cpu1.rf.registerfile[flopped_rf_for_load_miss];
	endproperty

	property lru_check;
		top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][0].valid == 1 && top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][1].valid == 1 |->
		top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][0].lru ^ top.cache_L2.cache_memory_L2[fvar_specific_addr[8:0]][1].lru; 
	endproperty


	// ===================== ASSERTIONS SECTION ======================
	// --------- BUS CONTROLLER --------- ALL PASSED 
	assert_check_toggle_when_both_req_grant2 : assert property (@(posedge clk) check_toggle_when_both_req_grant2);
	assert_check_toggle_when_both_req_grant1 : assert property (@(posedge clk) check_toggle_when_both_req_grant1); 
	assert_data_forwarding_from_cpu1_to_cpu2 : assert property (@(posedge clk) data_forwarding_from_cpu1_to_cpu2);
	assert_data_forwarding_from_L2_to_cpu1   : assert property (@(posedge clk) data_forwarding_from_L2_to_cpu1);
	assert_data_forwarding_no_operation1  	 : assert property (@(posedge clk) data_forwarding_no_operation1);
	assert_data_forwarding_from_cpu2_to_cpu1 : assert property (@(posedge clk) data_forwarding_from_cpu2_to_cpu1);
	assert_data_forwarding_from_L2_to_cpu2   : assert property (@(posedge clk) data_forwarding_from_L2_to_cpu2);
	assert_data_forwarding_no_operation2     : assert property (@(posedge clk) data_forwarding_no_operation2);
	assert_forwaring_data_when_flush_happens : assert property (@(posedge clk) forwaring_data_when_flush_happens);
	assert_not_forwaring_data_when_flush_doesnt_happens : assert property (@(posedge clk) not_forwaring_data_when_flush_doesnt_happens);
	
	// --------- ONLY ONE LRU INSIDE SET CAN BE HIGH - ALL PASSED
	assert_lru_check : assert property (@(posedge clk) lru_check);
	
	// --------- L2 CACHE CONTROLLER AND L2 MEMORY --------- ALL PASSED
	assert_checking_transition_from_IDLE_to_DMEM_WRITE : assert property (@(posedge clk) checking_transition_from_IDLE_to_DMEM_WRITE);
	assert_checking_transition_from_DMEM_WRITE_to_IDLE : assert property (@(posedge clk) checking_transition_from_DMEM_WRITE_to_IDLE);
	
	// --------- CHECKING DOES HIT HAPPENS IN BOTH WAYS --------- ALL PASSED
	assert_checking_way0_hit : assert property (@(posedge clk) checking_way0_hit);
	assert_checking_way1_hit : assert property (@(posedge clk) checking_way1_hit);
	
	// --------- LOADING DATA FROM ONE CPU TO ANOTHER  --------- ALL PASSED
	assert_load_word_from_cpu2_to_cpu1 : assert property (@(posedge clk) load_word_from_cpu2_to_cpu1);
	assert_load_word_from_cpu1_to_cpu2 : assert property (@(posedge clk) load_word_from_cpu1_to_cpu2);
	
	// --------- LOADING DATA FROM L2 FROM BOTH WAYS IN BOTH CPUs --------- ALL PASSED
	assert_load_word_from_L2_to_cpu1_way0_hit : assert property (@(posedge clk) load_word_from_L2_to_cpu1_way0_hit);
	assert_load_word_from_L2_to_cpu1_way1_hit : assert property (@(posedge clk) load_word_from_L2_to_cpu1_way1_hit); // THIS TAKES TOOOOO LONG
	
	// These pass but take too long - Just these 2 at a time - ALL PASSED
	assert_load_word_from_L2_to_cpu2_way0_hit : assert property (@(posedge clk) load_word_from_L2_to_cpu2_way0_hit);
	assert_load_word_from_L2_to_cpu2_way1_hit : assert property (@(posedge clk) load_word_from_L2_to_cpu2_way1_hit);
	
	// --------- LOADING DATA FROM L1 TO RF WHEN MISS HAPPENS - ALL PASSED
	assert_load_word_from_cache_to_rf_on_miss_cpu1 : assert property (@(posedge clk) load_word_from_cache_to_rf_on_miss_cpu1);
	assert_load_word_from_cache_to_rf_on_miss_cpu2 : assert property (@(posedge clk) load_word_from_cache_to_rf_on_miss_cpu2);
	
	// --------- FLUSHING DATA FROM CPUs TO L2 - ALL PASSED
	assert_flushing_data_to_L2_both_ways_free : assert property (@(negedge clk) flushing_data_to_L2_both_ways_free);
	assert_flushing_data_to_L2_second_available_first_not_tag_missmatch : assert property (@(posedge clk) flushing_data_to_L2_second_available_first_not_tag_missmatch);
	assert_flushing_data_to_L2_second_available_first_not_tag_match : assert property (@(posedge clk) flushing_data_to_L2_second_available_first_not_tag_match);
	assert_flushing_data_to_L2_when_both_lines_are_not_free_way0_tag_match : assert property (@(posedge clk) flushing_data_to_L2_when_both_lines_are_not_free_way0_tag_match);
	assert_flushing_data_to_L2_when_both_lines_are_not_free_way1_tag_match : assert property (@(posedge clk) flushing_data_to_L2_when_both_lines_are_not_free_way1_tag_match);
	assert_flushing_data_to_L2_when_both_lines_are_not_free_tag_missmatch_way0_lru : assert property (@(negedge clk) flushing_data_to_L2_when_both_lines_are_not_free_tag_missmatch_way0_lru);
	assert_flushing_data_to_L2_when_both_lines_are_not_free_tag_missmatch_way1_lru : assert property (@(negedge clk) flushing_data_to_L2_when_both_lines_are_not_free_tag_missmatch_way1_lru);
	
	// --------- LOAD MISS IN L2 - LOADING DATA FROM DMEM - ALL PASSED
	assert_loading_data_from_DMEM_to_L2_both_lru_zero : assert property (@(negedge clk) loading_data_from_DMEM_to_L2_both_lru_zero);
	assert_loading_data_from_DMEM_to_L2_both_lru0 : assert property (@(negedge clk) loading_data_from_DMEM_to_L2_both_lru0);
	assert_loading_data_from_DMEM_to_L2_both_lru1 : assert property (@(negedge clk) loading_data_from_DMEM_to_L2_both_lru1);
	
	// --------- FLUSHING DATA FROM L2 TO DMEM - ALL PASSED
	assert_data_eviction_from_L2_to_DMEM_way1_free_way0_not : assert property (@(posedge clk) data_eviction_from_L2_to_DMEM_way1_free_way0_not);
	assert_data_eviction_from_L2_to_DMEM_both_full_way0_match : assert property (@(posedge clk) data_eviction_from_L2_to_DMEM_both_full_way0_match);
	assert_data_eviction_from_L2_to_DMEM_both_full_way1_match : assert property (@(posedge clk) data_eviction_from_L2_to_DMEM_both_full_way1_match);
	assert_data_eviction_from_L2_to_DMEM_both_full_both_ways_missmatch_way0 : assert property (@(posedge clk) data_eviction_from_L2_to_DMEM_both_full_both_ways_missmatch_way0);
	assert_data_eviction_from_L2_to_DMEM_both_full_both_ways_missmatch_way1 : assert property (@(posedge clk) data_eviction_from_L2_to_DMEM_both_full_both_ways_missmatch_way1);
	assert_data_eviction_from_L2_to_DMEM_on_cache_MISS_lru0 : assert property (@(posedge clk) data_eviction_from_L2_to_DMEM_on_cache_MISS_lru0);
	assert_data_eviction_from_L2_to_DMEM_on_cache_MISS_lru1 : assert property (@(posedge clk) data_eviction_from_L2_to_DMEM_on_cache_MISS_lru1);
	//assert_load_from_dmem_to_core : assert property (@(posedge clk) load_from_dmem_to_core);

	//cover_load_from_dmem_flag : cover property (@(posedge clk) state == HIT);

	//cover_help : cover property (@(negedge clk) top.cache_L2.cache_memory_L2[top.cache_L2.set_index][0].lru == 1 && top.cache_L2.cache_memory_L2[top.cache_L2.set_index][1].lru == 0 &&
	//top.cache_L2.state == 2'b01 && top.cache_L2.set_index == fvar_specific_addr[8:0] && top.cache_L2.flush == 0);

	//cover_flush_cache_hit_neg : cover property(@(negedge clk) top.cache_L2.opcode_in == 7'b0000011 && top.cache_L2.flush == 0 && top.cache_L2.cache_hit_out == 2'b01 && 
	//top.cache_L2.cache_memory_L2[top.cache_L2.set_index][0].lru == 1 && top.cache_L2.cache_memory_L2[top.cache_L2.set_index][1].lru == 0 ##1 top.cache_L2.cache_hit_out == 2'b10);

	//cover_flush_cache_hit_pos : cover property(@(posedge clk) top.cache_L2.opcode_in == 7'b0000011 && top.cache_L2.flush == 0 && top.cache_L2.cache_hit_out == 2'b01 && 
	//top.cache_L2.cache_memory_L2[top.cache_L2.set_index][0].lru == 1 && top.cache_L2.cache_memory_L2[top.cache_L2.set_index][1].lru == 0 ##1 top.cache_L2.cache_hit_out == 2'b10);

	//COVER PASSED//cover_flush_way0_tag_match : cover property (@(negedge clk) flush_way0_tag_match == 1);
	//COVER PASSED//cover_comb_flush_way0_tag_match : cover property (@(negedge clk) comb_flush_way0_tag_match == 1);	
	//cover_flushing_data_to_L2_when_both_lines_are_not_free_tag_missmatch_way0_lru : cover property (@(negedge clk) comb_flush_way0_tag_match == 1 && {top.dmem.addr[31:2],2'b00} < 1024);
	
	//cover_way0_flag1 : cover property (@(posedge clk) flush_tag_missmatch_way0_lru ##1 flush_tag_missmatch_way0_lru == 0 ##1 flush_tag_missmatch_way0_lru);
	//cover_way0_flag2 : cover property (@(negedge clk) flush_tag_missmatch_way0_lru ##1 flush_tag_missmatch_way0_lru == 0 ##1 flush_tag_missmatch_way0_lru);

	//cover_bus_hit : cover property (@(negedge clk) top.opcode_out1 == 7'b0000011 && top.bus_ctrl.cache_hit_out1 == 2'b01 && top.cpu1.controller_and_cache.mask_in == 3'b010 && top.cpu1.controller_and_cache.cache_hit == 2'b01 ##1 
	//top.cpu1.controller_and_cache.cache_hit == 2'b10 && top.cpu1.stall_out == 1'b0);
endmodule
