library ieee;
use ieee.std_logic_1164.all;
use work.lib.all;
use ieee.numeric_std.all;

entity hazard_unit is
	generic (
		WIDTH : positive := 32
	);
	port (
		IFID_instruction : in std_logic_vector(WIDTH-1 downto 0);
		IDEX_instruction : in std_logic_vector(WIDTH-1 downto 0);
		EXMEM_instruction : in std_logic_vector(WIDTH-1 downto 0);
		MEMWB_instruction : in std_logic_vector(WIDTH-1 downto 0);
		EXMEM_reg_wr : in std_logic;
		MEMWB_reg_wr : in std_logic;
		
		-- Control signals
		EXMEM_rt_to_IDEX_rs : out std_logic;
		EXMEM_rt_to_IDEX_rt : out std_logic;
		MEMWB_rt_to_IDEX_rs : out std_logic;
		MEMWB_rt_to_IDEX_rt : out std_logic;
		EXMEM_rd_to_IDEX_rs : out std_logic;
		EXMEM_rd_to_IDEX_rt : out std_logic;
		MEMWB_rd_to_IDEX_rs : out std_logic;
		MEMWB_rd_to_IDEX_rt : out std_logic;
		EXMEM_alu_to_IDEX_rs : out std_logic;
		EXMEM_alu_to_IDEX_rt : out std_logic;
		MEMWB_alu_to_IDEX_rs : out std_logic;
		MEMWB_alu_to_IDEX_rt : out std_logic;
		PC_stall : out std_logic;
		IFID_stall : out std_logic;
		IDEX_stall : out std_logic;
		EXMEM_stall : out std_logic
	);
end entity;

architecture arch of hazard_unit is
	signal IFID_instr : std_logic_vector(WIDTH-1 downto 0);
	signal IDEX_instr : std_logic_vector(WIDTH-1 downto 0);
	signal EXMEM_instr : std_logic_vector(WIDTH-1 downto 0);
	signal MEMWB_instr : std_logic_vector(WIDTH-1 downto 0);
	signal IFID_reg_rs : std_logic_vector(get_log2(WIDTH)-1 downto 0);
	signal IDEX_reg_rs : std_logic_vector(get_log2(WIDTH)-1 downto 0);
	signal EXMEM_reg_rs : std_logic_vector(get_log2(WIDTH)-1 downto 0);
	signal IFID_reg_rt : std_logic_vector(get_log2(WIDTH)-1 downto 0);
	signal IDEX_reg_rt : std_logic_vector(get_log2(WIDTH)-1 downto 0);
	signal EXMEM_reg_rt : std_logic_vector(get_log2(WIDTH)-1 downto 0);
	signal MEMWB_reg_rt : std_logic_vector(get_log2(WIDTH)-1 downto 0);
	signal IDEX_reg_rd : std_logic_vector(get_log2(WIDTH)-1 downto 0);
	signal EXMEM_reg_rd : std_logic_vector(get_log2(WIDTH)-1 downto 0);
	signal MEMWB_reg_rd : std_logic_vector(get_log2(WIDTH)-1 downto 0);
begin
	
	-- Setup register definitions
	IFID_instr <= IFID_instruction;
	IDEX_instr <= IDEX_instruction;
	EXMEM_instr <= EXMEM_instruction;
	MEMWB_instr <= MEMWB_instruction;
	IFID_reg_rs <= IFID_instruction(RS_RANGE);
	IFID_reg_rt <= IFID_instruction(RT_RANGE);
	IDEX_reg_rs <= IDEX_instruction(RS_RANGE);
	IDEX_reg_rt <= IDEX_instruction(RT_RANGE);
	IDEX_reg_rd <= IDEX_instruction(RTYPE_RD_RANGE);
	EXMEM_reg_rs <= EXMEM_instruction(RS_RANGE);
	EXMEM_reg_rt <= EXMEM_instr(RT_RANGE);
	MEMWB_reg_rt <= MEMWB_instr(RT_RANGE);
	process(IFID_instr, IDEX_instr, EXMEM_instr, MEMWB_instr)
	begin
		EXMEM_reg_rd <= (others => '0');
		MEMWB_reg_rd <= (others => '0');
		if(is_rtype(EXMEM_instr) or is_jr(EXMEM_instr)) then
			-- Rtype destination is RD
			EXMEM_reg_rd <= EXMEM_instr(RTYPE_RD_RANGE);
		end if;
		
		if(is_rtype(MEMWB_instr) or is_jr(MEMWB_instr)) then
			-- Rtype destination is RD
			MEMWB_reg_rd <= MEMWB_instr(RTYPE_RD_RANGE);
		end if;
	end process;


	-- Perform checks
	process(IFID_instr, IDEX_instr, EXMEM_instr, MEMWB_instr,
			IFID_reg_rs, IFID_reg_rt,
			IDEX_reg_rs, IDEX_reg_rt, IDEX_reg_rd,
			EXMEM_reg_rs, EXMEM_reg_rt, EXMEM_reg_rd,
			MEMWB_reg_rt, MEMWB_reg_rd)
	begin
		EXMEM_rt_to_IDEX_rs <= '0';
		EXMEM_rt_to_IDEX_rt <= '0';
		MEMWB_rt_to_IDEX_rs <= '0';
		MEMWB_rt_to_IDEX_rt <= '0';
		EXMEM_rd_to_IDEX_rs <= '0';
		EXMEM_rd_to_IDEX_rt <= '0';
		MEMWB_rd_to_IDEX_rs <= '0';
		MEMWB_rd_to_IDEX_rt <= '0';
		EXMEM_alu_to_IDEX_rs <= '0';
		EXMEM_alu_to_IDEX_rt <= '0';
		MEMWB_alu_to_IDEX_rs <= '0';
		MEMWB_alu_to_IDEX_rt <= '0';
		PC_stall <= '0';
		IFID_stall <= '0';
		IDEX_stall <= '0';
		EXMEM_stall <= '0';
		
		------------------ ALU to RS if RD = RS ----------------------
			-- rtype followed by rtype
		if((is_rtype(IDEX_instr) and is_rtype(EXMEM_instr))
			or  (is_rtype(IDEX_instr) and is_rtype(MEMWB_instr))
			-- rtype followed by itype
			or (is_itype(IDEX_instr) and is_rtype(EXMEM_instr))
			or (is_itype(IDEX_instr) and is_rtype(MEMWB_instr))
			-- rtype followed by load
			or (is_load(IDEX_instr) and is_rtype(EXMEM_instr))
			or (is_load(IDEX_instr) and is_rtype(MEMWB_instr))
			-- rtype followed by store
			or (is_store(IDEX_instr) and is_rtype(EXMEM_instr))
			or (is_store(IDEX_instr) and is_rtype(MEMWB_instr))
		) then
			if(EXMEM_reg_wr <= '1' and EXMEM_reg_rd = IDEX_reg_rs) then
				EXMEM_alu_to_IDEX_rs <= '1';
			elsif(MEMWB_reg_wr <= '1' and MEMWB_reg_rd = IDEX_reg_rs) then
				MEMWB_alu_to_IDEX_rs <= '1';
			end if;
		end if;
		
		------------------ ALU to RT if RD = RT ----------------------
			-- rtype followed by rtype
		if((is_rtype(IDEX_instr) and is_rtype(EXMEM_instr))
			or  (is_rtype(IDEX_instr) and is_rtype(MEMWB_instr))
			-- rtype followed by store
			or (is_store(IDEX_instr) and is_rtype(EXMEM_instr))
			or (is_store(IDEX_instr) and is_rtype(MEMWB_instr))
		) then
			if(EXMEM_reg_wr <= '1' and EXMEM_reg_rd = IDEX_reg_rt) then
				EXMEM_alu_to_IDEX_rt <= '1';
			elsif(MEMWB_reg_wr <= '1' and MEMWB_reg_rd = IDEX_reg_rt) then
				MEMWB_alu_to_IDEX_rt <= '1';
			end if;
		end if;
		
		
		------------------ ALU to RS if RT = RS ----------------------
			-- itype followed by rtype
		if((is_rtype(IDEX_instr) and is_itype(EXMEM_instr))
			or (is_rtype(IDEX_instr) and is_itype(MEMWB_instr))
			-- itype followed by itype
			or (is_itype(IDEX_instr) and is_itype(EXMEM_instr))
			or (is_itype(IDEX_instr) and is_itype(MEMWB_instr))
			-- itype followed by load
			or (is_load(IDEX_instr) and is_itype(EXMEM_instr))
			or (is_load(IDEX_instr) and is_itype(MEMWB_instr))
			-- itype followed by store
			or (is_store(IDEX_instr) and is_itype(EXMEM_instr))
			or (is_store(IDEX_instr) and is_itype(MEMWB_instr))
		) then
			if(EXMEM_reg_wr <= '1' and EXMEM_reg_rt = IDEX_reg_rs) then
				EXMEM_alu_to_IDEX_rs <= '1';
			elsif(MEMWB_reg_wr <= '1' and MEMWB_reg_rt = IDEX_reg_rs) then
				MEMWB_alu_to_IDEX_rs <= '1';
			end if;
		end if;
		
		------------------ ALU to RS/RT if RT = RS/RT ----------------------
			-- load followed by rtype
		if((is_rtype(IDEX_instr) and is_load(MEMWB_instr))) then
			if(MEMWB_reg_wr <= '1' and MEMWB_reg_rt = IDEX_reg_rs) then
				MEMWB_rt_to_IDEX_rs <= '1';
			end if;
			if(MEMWB_reg_wr <= '1' and MEMWB_reg_rt = IDEX_reg_rt) then
				MEMWB_rt_to_IDEX_rt <= '1';
			end if;
		end if;
		
		------------------ STALL ON LOAD ----------------------
			-- load followed by rtype
		if(is_rtype(IDEX_instr) and is_load(EXMEM_instr)) then
			if(EXMEM_reg_rt = IDEX_reg_rs or EXMEM_reg_rt = IDEX_reg_rt) then
				PC_stall <= '1';
				IFID_stall <= '1';
				IDEX_stall <= '1';
			end if;
		end if;
		
		------------------ ALU to RT if RT = RT ----------------------
			-- itype followed by rtype
		if((is_rtype(IDEX_instr) and is_itype(EXMEM_instr))
			or (is_rtype(IDEX_instr) and is_itype(MEMWB_instr))
			-- itype followed by store
			or (is_store(IDEX_instr) and is_itype(EXMEM_instr))
			or (is_store(IDEX_instr) and is_itype(MEMWB_instr))
		) then
			if(EXMEM_reg_wr <= '1' and EXMEM_reg_rt = IDEX_reg_rt) then
				EXMEM_alu_to_IDEX_rt <= '1';
			elsif(MEMWB_reg_wr <= '1' and MEMWB_reg_rt = IDEX_reg_rt) then
				MEMWB_alu_to_IDEX_rt <= '1';
			end if;
		end if;
		
		
--------------------------------------------------------------------------------
		------- Check RD followed by RS
		--	-- rtype followed by rtype
		--if((is_rtype(IDEX_instr) and is_rtype(EXMEM_instr))
		--	or (is_rtype(IDEX_instr) and is_rtype(MEMWB_instr))
		--	or (is_rtype(EXMEM_instr) and is_rtype(MEMWB_instr))
		--	-- rtype followed by itype
		--	or (is_itype_all(IDEX_instr) and is_rtype(EXMEM_instr))
		--	or (is_itype_all(EXMEM_instr) and is_rtype(MEMWB_instr))
			
		--	-- itype followed by rtype
		--	or (is_rtype(IDEX_instr) and is_itype(EXMEM_instr))
		--	or (is_rtype(EXMEM_instr) and is_itype(MEMWB_instr))
		--	-- itype followed by itype
		--	or (is_itype(IDEX_instr) and is_itype(EXMEM_instr))
		--	or (is_itype(EXMEM_instr) and is_itype(MEMWB_instr))
		--	-- load followed by rtype
		--	or (is_rtype(EXMEM_instr) and is_load(MEMWB_instr))
		--	-- load followed by itype
		--	or (is_itype_all(EXMEM_instr) and is_load(MEMWB_instr))
		--) then
		--	if((is_rtype(EXMEM_instr) and EXMEM_reg_wr = '1' and not_zero(EXMEM_reg_rd) and compare(EXMEM_reg_rd, IDEX_reg_rs))
		--		or (is_itype_all(EXMEM_instr) and EXMEM_reg_wr = '1' and not_zero(EXMEM_reg_rt) and compare(EXMEM_reg_rt, IDEX_reg_rs))
		--	) then
		--		alu_input_A_sel <= "01";
		--	elsif((is_rtype(MEMWB_instr) and MEMWB_reg_wr = '1' and not_zero(MEMWB_reg_rd) and compare(MEMWB_reg_rd, IDEX_reg_rs))
		--			or (is_itype_all(MEMWB_instr) and MEMWB_reg_wr = '1' and not_zero(MEMWB_reg_rt) and compare(MEMWB_reg_rt, IDEX_reg_rs))
		--	) then
		--		alu_input_A_sel <= "10";
		--	end if;
		--end if;
		
		--------- Check RD followed by RT
		--	-- rtype followed by rtype
		--if((is_rtype(IDEX_instr) and is_rtype(EXMEM_instr))
		--	or (is_rtype(IDEX_instr) and is_rtype(MEMWB_instr))
		--	or (is_rtype(EXMEM_instr) and is_rtype(MEMWB_instr))
		--	-- rtype followed by itype
		--	or (is_itype(IDEX_instr) and is_rtype(EXMEM_instr))
		--	or (is_itype(EXMEM_instr) and is_rtype(MEMWB_instr))
		--	-- rtype followed by store
		--	or (is_store(IDEX_instr) and is_rtype(EXMEM_instr))
		--	or (is_store(EXMEM_instr) and is_rtype(MEMWB_instr))
		--	-- itype followed by rtype
		--	or (is_rtype(IDEX_instr) and is_itype(EXMEM_instr))
		--	or (is_rtype(EXMEM_instr) and is_itype(MEMWB_instr))
		--	-- itype followed by store
		--	or (is_store(IDEX_instr) and is_itype(EXMEM_instr))
		--	or (is_store(EXMEM_instr) and is_itype(MEMWB_instr))
		--	-- load followed by rtype
		--	or (is_rtype(EXMEM_instr) and is_load(MEMWB_instr))
		--	-- load followed by store
		--	or (is_store(EXMEM_instr) and is_load(MEMWB_instr))
		--	-- itype followed by lui
		--	or (is_lui(IDEX_instr) and is_itype_all(EXMEM_instr))
		--	or (is_lui(EXMEM_instr) and is_itype_all(MEMWB_instr))
		--) then
		--	if((is_rtype(EXMEM_instr) and EXMEM_reg_wr = '1' and not_zero(EXMEM_reg_rd) and compare(EXMEM_reg_rd, IDEX_reg_rt))
		--		or (is_itype_all(EXMEM_instr) and EXMEM_reg_wr = '1' and not_zero(EXMEM_reg_rt) and compare(EXMEM_reg_rt, IDEX_reg_rt))
		--	) then
		--		alu_input_B_sel <= "01";
		--	elsif((is_rtype(MEMWB_instr) and MEMWB_reg_wr = '1' and not_zero(MEMWB_reg_rd) and compare(MEMWB_reg_rd, IDEX_reg_rt))
		--			or (is_itype_all(MEMWB_instr) and MEMWB_reg_wr = '1' and not_zero(MEMWB_reg_rt) and compare(MEMWB_reg_rt, IDEX_reg_rt))
		--			or (is_itype_all(MEMWB_instr) and MEMWB_reg_wr = '1' and not_zero(MEMWB_reg_rt) and compare(MEMWB_reg_rt, IDEX_reg_rs))
		--	) then
		--		alu_input_B_sel <= "10";
		--	end if;
		--end if;
		
		--------------- STORE --------------
		--	-- store followed by rtype
		--if((is_rtype(IDEX_instr) and is_store(EXMEM_instr))
		--	-- store folowed by itype
		--	or (is_itype(IDEX_instr) and is_store(EXMEM_instr))
		--	-- store followed by store
		--	or (is_store(IDEX_instr) and is_store(EXMEM_instr))
		--	-- store followed by load
		--	or (is_load(IDEX_instr) and is_store(EXMEM_instr))
		--) then
		--	if((is_rtype(IDEX_instr) and (compare(EXMEM_reg_rt, IDEX_reg_rs) or compare(EXMEM_reg_rt, IDEX_reg_rt)))
		--		or ((is_itype(IDEX_instr) or is_load(IDEX_instr) or is_store(IDEX_instr)) and compare(EXMEM_reg_rt, IDEX_reg_rs))
		--	) then
		--		IFID_stall <= '1';
		--		IDEX_stall <= '1';
		--	end if;
		--end if;
			
		--	-- store followed by rtype
		--if((is_rtype(IDEX_instr) and is_store(EXMEM_instr))
		--	-- store folowed by itype
		--	or (is_itype(IDEX_instr) and is_store(EXMEM_instr))
		--	-- store followed by store
		--	or (is_store(IDEX_instr) and is_store(EXMEM_instr))
		--	-- store followed by load
		--	or (is_load(IDEX_instr) and is_store(EXMEM_instr))
		--) then
		--	if(compare(MEMWB_reg_rt, IDEX_reg_rs)) then
		--		alu_input_A_sel <= "10";
		--	end if;
		--	if(is_rtype(IDEX_instr) and compare(MEMWB_reg_rt, IDEX_reg_rt)) then
		--		alu_input_B_sel <= "10";
		--	end if;
		--end if;
		
		--------------- LUI --------------
		--	-- rtype followed by lui
		--if((is_lui(IDEX_instr) and is_rtype(EXMEM_instr))
		--	-- itype followed by lui
		--	or (is_lui(IDEX_instr) and is_itype_all(EXMEM_instr))
		--	-- lui followed by itype
		--	or (is_itype_all(IDEX_instr) and is_lui(EXMEM_instr))
		--) then
		--	--if(is_rtype(EXMEM_instr) and compare(EXMEM_reg_rt, IDEX_reg_rt)) then
		--	--	IDEX_ui_A_sel <= '1';
		--	--end if;
		--	if(((is_rtype(EXMEM_instr) or is_itype_all(EXMEM_instr)) and compare(EXMEM_reg_rt, IDEX_reg_rt))
		--		or (is_lui(MEMWB_instr) and compare(MEMWB_reg_rt, EXMEM_reg_rt))
		--	) then
		--		IDEX_ui_B_sel <= "01";
		--	elsif(((is_rtype(EXMEM_instr) or is_itype_all(EXMEM_instr)) and compare(EXMEM_reg_rt, IDEX_reg_rs))
		--		or ((is_rtype(MEMWB_instr) or is_itype_all(MEMWB_instr)) and compare(MEMWB_reg_rt, IDEX_reg_rs))
		--	) then
		--		IDEX_ui_B_sel <= "10";
		--	end if;
		--end if;
		--	-- lui followed by itype
		--if(is_itype_all(IDEX_instr) and is_lui(EXMEM_instr)) then
		--	if(compare(EXMEM_reg_rt, IDEX_reg_rs)) then
		--		IDEX_ui_A_sel <= "01";
		--	end if;
		--end if;
			
		
		--------------- JR --------------
		--	-- rtype followed by jr
		--if((is_jr(IFID_instr) and is_rtype(IDEX_instr))
		--	-- rtype followed by branch
		--	or (is_branch(IFID_instr) and is_rtype(IDEX_instr))
		--) then
		--	if(not_zero(IDEX_reg_rd) and compare(IDEX_reg_rd, IFID_reg_rs)) then
		--		IFID_stall <= '1';
		--	end if;
		--end if;
		
		--------------- BRANCH --------------
		--	-- rtype followed by branch
		--if((is_branch(IFID_instr) and is_rtype(IDEX_instr))
		--) then
		--	if(not_zero(IDEX_reg_rd) and compare(IDEX_reg_rd, IFID_reg_rt)) then
		--		IFID_stall <= '1';
		--	end if;
		--end if;
		
	end process;
	
	
end arch;