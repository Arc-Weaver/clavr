library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package avr_soc_types is



  subtype index_2048 is unsigned(10 downto 0);
  subtype Maybe_3 is std_logic_vector(24 downto 0);


  type StatusRegister is record
    StatusRegister_sel0_carry_flag : std_logic;
    StatusRegister_sel1_zero_flag : std_logic;
    StatusRegister_sel2_negative_flag : std_logic;
    StatusRegister_sel3_overflow_flag : std_logic;
    StatusRegister_sel4_sign_flag : std_logic;
    StatusRegister_sel5_half_carry : std_logic;
    StatusRegister_sel6_bit_copy : std_logic;
    StatusRegister_sel7_interrupt_flag : std_logic;
  end record;
  subtype rst_Dom10MHz is std_logic;
  subtype Maybe is std_logic_vector(16 downto 0);
  type array_of_Maybe is array (integer range <>) of Maybe;
  subtype clk_Dom10MHz is std_logic;
  type array_of_std_logic_vector_16 is array (integer range <>) of std_logic_vector(15 downto 0);
  type Tuple2_6 is record
    Tuple2_6_sel0_unsigned : unsigned(4 downto 0);
    Tuple2_6_sel1_boolean : boolean;
  end record;
  type Tuple2_5 is record
    Tuple2_5_sel0_unsigned_0 : unsigned(15 downto 0);
    Tuple2_5_sel1_unsigned_1 : unsigned(15 downto 0);
  end record;
  subtype en_Dom10MHz is boolean;
  type Tuple2_4 is record
    Tuple2_4_sel0_unsigned_0 : unsigned(23 downto 0);
    Tuple2_4_sel1_unsigned_1 : unsigned(7 downto 0);
  end record;
  subtype Maybe_0 is std_logic_vector(32 downto 0);
  type Tuple2 is record
    Tuple2_sel0_unsigned_0 : unsigned(7 downto 0);
    Tuple2_sel1_unsigned_1 : unsigned(7 downto 0);
  end record;
  type Tuple2_2 is record
    Tuple2_2_sel0_unsigned_0 : unsigned(15 downto 0);
    Tuple2_2_sel1_unsigned_1 : unsigned(7 downto 0);
  end record;
  subtype Maybe_1 is std_logic_vector(24 downto 0);
  type Tuple3_3 is record
    Tuple3_3_sel0_unsigned : unsigned(15 downto 0);
    Tuple3_3_sel1_Maybe : Maybe;
    Tuple3_3_sel2_Maybe_1 : Maybe_1;
  end record;
  type Tuple3_0 is record
    Tuple3_0_sel0_unsigned_0 : unsigned(7 downto 0);
    Tuple3_0_sel1_unsigned_1 : unsigned(7 downto 0);
    Tuple3_0_sel2_std_logic : std_logic;
  end record;
  type array_of_unsigned_8 is array (integer range <>) of unsigned(7 downto 0);
  subtype Maybe_2 is std_logic_vector(8 downto 0);
  type Tuple3 is record
    Tuple3_sel0_unsigned_0 : unsigned(7 downto 0);
    Tuple3_sel1_unsigned_1 : unsigned(7 downto 0);
    Tuple3_sel2_unsigned_2 : unsigned(7 downto 0);
  end record;
  type GPIOState is record
    GPIOState_sel0_gpioDdr : unsigned(7 downto 0);
    GPIOState_sel1_gpioPort : unsigned(7 downto 0);
  end record;
  type Tuple2_7 is record
    Tuple2_7_sel0_index_2048 : index_2048;
    Tuple2_7_sel1_unsigned : unsigned(7 downto 0);
  end record;
  subtype Maybe_4 is std_logic_vector(19 downto 0);
  type Tuple7 is record
    Tuple7_sel0_boolean : boolean;
    Tuple7_sel1_unsigned_0 : unsigned(7 downto 0);
    Tuple7_sel2_unsigned_1 : unsigned(7 downto 0);
    Tuple7_sel3_unsigned_2 : unsigned(7 downto 0);
    Tuple7_sel4_std_logic_0 : std_logic;
    Tuple7_sel5_std_logic_1 : std_logic;
    Tuple7_sel6_StatusRegister : StatusRegister;
  end record;
  type Tuple6 is record
    Tuple6_sel0_unsigned_0 : unsigned(7 downto 0);
    Tuple6_sel1_unsigned_1 : unsigned(7 downto 0);
    Tuple6_sel2_unsigned_2 : unsigned(7 downto 0);
    Tuple6_sel3_std_logic_0 : std_logic;
    Tuple6_sel4_std_logic_1 : std_logic;
    Tuple6_sel5_StatusRegister : StatusRegister;
  end record;
  subtype IndirectAddressingMode is std_logic_vector(9 downto 0);
  subtype Instruction is std_logic_vector(28 downto 0);
  subtype Stage is std_logic_vector(31 downto 0);
  type Tuple2_3 is record
    Tuple2_3_sel0_unsigned : unsigned(7 downto 0);
    Tuple2_3_sel1_StatusRegister : StatusRegister;
  end record;
  type Tuple2_1 is record
    Tuple2_1_sel0_signed_0 : signed(15 downto 0);
    Tuple2_1_sel1_signed_1 : signed(15 downto 0);
  end record;
  type CoreData is record
    CoreData_sel0_registers : array_of_unsigned_8(0 to 31);
    CoreData_sel1_sp : unsigned(15 downto 0);
    CoreData_sel2_pc : unsigned(15 downto 0);
    CoreData_sel3_rampd : unsigned(7 downto 0);
    CoreData_sel4_rampx : unsigned(7 downto 0);
    CoreData_sel5_rampy : unsigned(7 downto 0);
    CoreData_sel6_rampz : unsigned(7 downto 0);
    CoreData_sel7_eind : unsigned(7 downto 0);
    CoreData_sel8_status : StatusRegister;
  end record;
  type Tuple3_2 is record
    Tuple3_2_sel0_CoreData : CoreData;
    Tuple3_2_sel1_unsigned_0 : unsigned(4 downto 0);
    Tuple3_2_sel2_unsigned_1 : unsigned(15 downto 0);
  end record;
  type Tuple3_1 is record
    Tuple3_1_sel0_CoreData : CoreData;
    Tuple3_1_sel1_unsigned_0 : unsigned(4 downto 0);
    Tuple3_1_sel2_unsigned_1 : unsigned(7 downto 0);
  end record;
  type CPUState is record
    CPUState_sel0_cpuCore : CoreData;
    CPUState_sel1_cpuStage : Stage;
  end record;
  type Tuple2_0 is record
    Tuple2_0_sel0_CPUState : CPUState;
    Tuple2_0_sel1_Tuple3_3 : Tuple3_3;
  end record;
  function toSLV (u : in unsigned) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return unsigned;
  function toSLV (slv : in std_logic_vector) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return std_logic_vector;
  function toSLV (s : in signed) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return signed;
  function toSLV (b : in boolean) return std_logic_vector;
  function fromSLV (sl : in std_logic_vector) return boolean;
  function tagToEnum (s : in signed) return boolean;
  function dataToTag (b : in boolean) return signed;
  function toSLV (sl : in std_logic) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return std_logic;
  function toSLV (p : StatusRegister) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return StatusRegister;
  function toSLV (value :  array_of_Maybe) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return array_of_Maybe;
  function toSLV (value :  array_of_std_logic_vector_16) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return array_of_std_logic_vector_16;
  function toSLV (p : Tuple2_6) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return Tuple2_6;
  function toSLV (p : Tuple2_5) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return Tuple2_5;
  function toSLV (p : Tuple2_4) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return Tuple2_4;
  function toSLV (p : Tuple2) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return Tuple2;
  function toSLV (p : Tuple2_2) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return Tuple2_2;
  function toSLV (p : Tuple3_3) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return Tuple3_3;
  function toSLV (p : Tuple3_0) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return Tuple3_0;
  function toSLV (value :  array_of_unsigned_8) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return array_of_unsigned_8;
  function toSLV (p : Tuple3) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return Tuple3;
  function toSLV (p : GPIOState) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return GPIOState;
  function toSLV (p : Tuple2_7) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return Tuple2_7;
  function toSLV (p : Tuple7) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return Tuple7;
  function toSLV (p : Tuple6) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return Tuple6;
  function toSLV (p : Tuple2_3) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return Tuple2_3;
  function toSLV (p : Tuple2_1) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return Tuple2_1;
  function toSLV (p : CoreData) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return CoreData;
  function toSLV (p : Tuple3_2) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return Tuple3_2;
  function toSLV (p : Tuple3_1) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return Tuple3_1;
  function toSLV (p : CPUState) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return CPUState;
  function toSLV (p : Tuple2_0) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return Tuple2_0;
end;

package body avr_soc_types is
  function toSLV (u : in unsigned) return std_logic_vector is
  begin
    return std_logic_vector(u);
  end;
  function fromSLV (slv : in std_logic_vector) return unsigned is
    alias islv : std_logic_vector(0 to slv'length - 1) is slv;
  begin
    return unsigned(islv);
  end;
  function toSLV (slv : in std_logic_vector) return std_logic_vector is
  begin
    return slv;
  end;
  function fromSLV (slv : in std_logic_vector) return std_logic_vector is
  begin
    return slv;
  end;
  function toSLV (s : in signed) return std_logic_vector is
  begin
    return std_logic_vector(s);
  end;
  function fromSLV (slv : in std_logic_vector) return signed is
    alias islv : std_logic_vector(0 to slv'length - 1) is slv;
  begin
    return signed(islv);
  end;
  function toSLV (b : in boolean) return std_logic_vector is
  begin
    if b then
      return "1";
    else
      return "0";
    end if;
  end;
  function fromSLV (sl : in std_logic_vector) return boolean is
  begin
    if sl = "1" then
      return true;
    else
      return false;
    end if;
  end;
  function tagToEnum (s : in signed) return boolean is
  begin
    if s = to_signed(0,64) then
      return false;
    else
      return true;
    end if;
  end;
  function dataToTag (b : in boolean) return signed is
  begin
    if b then
      return to_signed(1,64);
    else
      return to_signed(0,64);
    end if;
  end;
  function toSLV (sl : in std_logic) return std_logic_vector is
  begin
    return std_logic_vector'(0 => sl);
  end;
  function fromSLV (slv : in std_logic_vector) return std_logic is
    alias islv : std_logic_vector (0 to slv'length - 1) is slv;
  begin
    return islv(0);
  end;
  function toSLV (p : StatusRegister) return std_logic_vector is
  begin
    return (toSLV(p.StatusRegister_sel0_carry_flag) & toSLV(p.StatusRegister_sel1_zero_flag) & toSLV(p.StatusRegister_sel2_negative_flag) & toSLV(p.StatusRegister_sel3_overflow_flag) & toSLV(p.StatusRegister_sel4_sign_flag) & toSLV(p.StatusRegister_sel5_half_carry) & toSLV(p.StatusRegister_sel6_bit_copy) & toSLV(p.StatusRegister_sel7_interrupt_flag));
  end;
  function fromSLV (slv : in std_logic_vector) return StatusRegister is
  alias islv : std_logic_vector(0 to slv'length - 1) is slv;
  begin
    return (fromSLV(islv(0 to 0)),fromSLV(islv(1 to 1)),fromSLV(islv(2 to 2)),fromSLV(islv(3 to 3)),fromSLV(islv(4 to 4)),fromSLV(islv(5 to 5)),fromSLV(islv(6 to 6)),fromSLV(islv(7 to 7)));
  end;
  function toSLV (value :  array_of_Maybe) return std_logic_vector is
    alias ivalue    : array_of_Maybe(1 to value'length) is value;
    variable result : std_logic_vector(1 to value'length * 17);
  begin
    for i in ivalue'range loop
      result(((i - 1) * 17) + 1 to i*17) := toSLV(ivalue(i));
    end loop;
    return result;
  end;
  function fromSLV (slv : in std_logic_vector) return array_of_Maybe is
    alias islv      : std_logic_vector(0 to slv'length - 1) is slv;
    variable result : array_of_Maybe(0 to slv'length / 17 - 1);
  begin
    for i in result'range loop
      result(i) := fromSLV(islv(i * 17 to (i+1) * 17 - 1));
    end loop;
    return result;
  end;
  function toSLV (value :  array_of_std_logic_vector_16) return std_logic_vector is
    alias ivalue    : array_of_std_logic_vector_16(1 to value'length) is value;
    variable result : std_logic_vector(1 to value'length * 16);
  begin
    for i in ivalue'range loop
      result(((i - 1) * 16) + 1 to i*16) := toSLV(ivalue(i));
    end loop;
    return result;
  end;
  function fromSLV (slv : in std_logic_vector) return array_of_std_logic_vector_16 is
    alias islv      : std_logic_vector(0 to slv'length - 1) is slv;
    variable result : array_of_std_logic_vector_16(0 to slv'length / 16 - 1);
  begin
    for i in result'range loop
      result(i) := islv(i * 16 to (i+1) * 16 - 1);
    end loop;
    return result;
  end;
  function toSLV (p : Tuple2_6) return std_logic_vector is
  begin
    return (toSLV(p.Tuple2_6_sel0_unsigned) & toSLV(p.Tuple2_6_sel1_boolean));
  end;
  function fromSLV (slv : in std_logic_vector) return Tuple2_6 is
  alias islv : std_logic_vector(0 to slv'length - 1) is slv;
  begin
    return (fromSLV(islv(0 to 4)),fromSLV(islv(5 to 5)));
  end;
  function toSLV (p : Tuple2_5) return std_logic_vector is
  begin
    return (toSLV(p.Tuple2_5_sel0_unsigned_0) & toSLV(p.Tuple2_5_sel1_unsigned_1));
  end;
  function fromSLV (slv : in std_logic_vector) return Tuple2_5 is
  alias islv : std_logic_vector(0 to slv'length - 1) is slv;
  begin
    return (fromSLV(islv(0 to 15)),fromSLV(islv(16 to 31)));
  end;
  function toSLV (p : Tuple2_4) return std_logic_vector is
  begin
    return (toSLV(p.Tuple2_4_sel0_unsigned_0) & toSLV(p.Tuple2_4_sel1_unsigned_1));
  end;
  function fromSLV (slv : in std_logic_vector) return Tuple2_4 is
  alias islv : std_logic_vector(0 to slv'length - 1) is slv;
  begin
    return (fromSLV(islv(0 to 23)),fromSLV(islv(24 to 31)));
  end;
  function toSLV (p : Tuple2) return std_logic_vector is
  begin
    return (toSLV(p.Tuple2_sel0_unsigned_0) & toSLV(p.Tuple2_sel1_unsigned_1));
  end;
  function fromSLV (slv : in std_logic_vector) return Tuple2 is
  alias islv : std_logic_vector(0 to slv'length - 1) is slv;
  begin
    return (fromSLV(islv(0 to 7)),fromSLV(islv(8 to 15)));
  end;
  function toSLV (p : Tuple2_2) return std_logic_vector is
  begin
    return (toSLV(p.Tuple2_2_sel0_unsigned_0) & toSLV(p.Tuple2_2_sel1_unsigned_1));
  end;
  function fromSLV (slv : in std_logic_vector) return Tuple2_2 is
  alias islv : std_logic_vector(0 to slv'length - 1) is slv;
  begin
    return (fromSLV(islv(0 to 15)),fromSLV(islv(16 to 23)));
  end;
  function toSLV (p : Tuple3_3) return std_logic_vector is
  begin
    return (toSLV(p.Tuple3_3_sel0_unsigned) & toSLV(p.Tuple3_3_sel1_Maybe) & toSLV(p.Tuple3_3_sel2_Maybe_1));
  end;
  function fromSLV (slv : in std_logic_vector) return Tuple3_3 is
  alias islv : std_logic_vector(0 to slv'length - 1) is slv;
  begin
    return (fromSLV(islv(0 to 15)),fromSLV(islv(16 to 32)),fromSLV(islv(33 to 57)));
  end;
  function toSLV (p : Tuple3_0) return std_logic_vector is
  begin
    return (toSLV(p.Tuple3_0_sel0_unsigned_0) & toSLV(p.Tuple3_0_sel1_unsigned_1) & toSLV(p.Tuple3_0_sel2_std_logic));
  end;
  function fromSLV (slv : in std_logic_vector) return Tuple3_0 is
  alias islv : std_logic_vector(0 to slv'length - 1) is slv;
  begin
    return (fromSLV(islv(0 to 7)),fromSLV(islv(8 to 15)),fromSLV(islv(16 to 16)));
  end;
  function toSLV (value :  array_of_unsigned_8) return std_logic_vector is
    alias ivalue    : array_of_unsigned_8(1 to value'length) is value;
    variable result : std_logic_vector(1 to value'length * 8);
  begin
    for i in ivalue'range loop
      result(((i - 1) * 8) + 1 to i*8) := toSLV(ivalue(i));
    end loop;
    return result;
  end;
  function fromSLV (slv : in std_logic_vector) return array_of_unsigned_8 is
    alias islv      : std_logic_vector(0 to slv'length - 1) is slv;
    variable result : array_of_unsigned_8(0 to slv'length / 8 - 1);
  begin
    for i in result'range loop
      result(i) := fromSLV(islv(i * 8 to (i+1) * 8 - 1));
    end loop;
    return result;
  end;
  function toSLV (p : Tuple3) return std_logic_vector is
  begin
    return (toSLV(p.Tuple3_sel0_unsigned_0) & toSLV(p.Tuple3_sel1_unsigned_1) & toSLV(p.Tuple3_sel2_unsigned_2));
  end;
  function fromSLV (slv : in std_logic_vector) return Tuple3 is
  alias islv : std_logic_vector(0 to slv'length - 1) is slv;
  begin
    return (fromSLV(islv(0 to 7)),fromSLV(islv(8 to 15)),fromSLV(islv(16 to 23)));
  end;
  function toSLV (p : GPIOState) return std_logic_vector is
  begin
    return (toSLV(p.GPIOState_sel0_gpioDdr) & toSLV(p.GPIOState_sel1_gpioPort));
  end;
  function fromSLV (slv : in std_logic_vector) return GPIOState is
  alias islv : std_logic_vector(0 to slv'length - 1) is slv;
  begin
    return (fromSLV(islv(0 to 7)),fromSLV(islv(8 to 15)));
  end;
  function toSLV (p : Tuple2_7) return std_logic_vector is
  begin
    return (toSLV(p.Tuple2_7_sel0_index_2048) & toSLV(p.Tuple2_7_sel1_unsigned));
  end;
  function fromSLV (slv : in std_logic_vector) return Tuple2_7 is
  alias islv : std_logic_vector(0 to slv'length - 1) is slv;
  begin
    return (fromSLV(islv(0 to 10)),fromSLV(islv(11 to 18)));
  end;
  function toSLV (p : Tuple7) return std_logic_vector is
  begin
    return (toSLV(p.Tuple7_sel0_boolean) & toSLV(p.Tuple7_sel1_unsigned_0) & toSLV(p.Tuple7_sel2_unsigned_1) & toSLV(p.Tuple7_sel3_unsigned_2) & toSLV(p.Tuple7_sel4_std_logic_0) & toSLV(p.Tuple7_sel5_std_logic_1) & toSLV(p.Tuple7_sel6_StatusRegister));
  end;
  function fromSLV (slv : in std_logic_vector) return Tuple7 is
  alias islv : std_logic_vector(0 to slv'length - 1) is slv;
  begin
    return (fromSLV(islv(0 to 0)),fromSLV(islv(1 to 8)),fromSLV(islv(9 to 16)),fromSLV(islv(17 to 24)),fromSLV(islv(25 to 25)),fromSLV(islv(26 to 26)),fromSLV(islv(27 to 34)));
  end;
  function toSLV (p : Tuple6) return std_logic_vector is
  begin
    return (toSLV(p.Tuple6_sel0_unsigned_0) & toSLV(p.Tuple6_sel1_unsigned_1) & toSLV(p.Tuple6_sel2_unsigned_2) & toSLV(p.Tuple6_sel3_std_logic_0) & toSLV(p.Tuple6_sel4_std_logic_1) & toSLV(p.Tuple6_sel5_StatusRegister));
  end;
  function fromSLV (slv : in std_logic_vector) return Tuple6 is
  alias islv : std_logic_vector(0 to slv'length - 1) is slv;
  begin
    return (fromSLV(islv(0 to 7)),fromSLV(islv(8 to 15)),fromSLV(islv(16 to 23)),fromSLV(islv(24 to 24)),fromSLV(islv(25 to 25)),fromSLV(islv(26 to 33)));
  end;
  function toSLV (p : Tuple2_3) return std_logic_vector is
  begin
    return (toSLV(p.Tuple2_3_sel0_unsigned) & toSLV(p.Tuple2_3_sel1_StatusRegister));
  end;
  function fromSLV (slv : in std_logic_vector) return Tuple2_3 is
  alias islv : std_logic_vector(0 to slv'length - 1) is slv;
  begin
    return (fromSLV(islv(0 to 7)),fromSLV(islv(8 to 15)));
  end;
  function toSLV (p : Tuple2_1) return std_logic_vector is
  begin
    return (toSLV(p.Tuple2_1_sel0_signed_0) & toSLV(p.Tuple2_1_sel1_signed_1));
  end;
  function fromSLV (slv : in std_logic_vector) return Tuple2_1 is
  alias islv : std_logic_vector(0 to slv'length - 1) is slv;
  begin
    return (fromSLV(islv(0 to 15)),fromSLV(islv(16 to 31)));
  end;
  function toSLV (p : CoreData) return std_logic_vector is
  begin
    return (toSLV(p.CoreData_sel0_registers) & toSLV(p.CoreData_sel1_sp) & toSLV(p.CoreData_sel2_pc) & toSLV(p.CoreData_sel3_rampd) & toSLV(p.CoreData_sel4_rampx) & toSLV(p.CoreData_sel5_rampy) & toSLV(p.CoreData_sel6_rampz) & toSLV(p.CoreData_sel7_eind) & toSLV(p.CoreData_sel8_status));
  end;
  function fromSLV (slv : in std_logic_vector) return CoreData is
  alias islv : std_logic_vector(0 to slv'length - 1) is slv;
  begin
    return (fromSLV(islv(0 to 255)),fromSLV(islv(256 to 271)),fromSLV(islv(272 to 287)),fromSLV(islv(288 to 295)),fromSLV(islv(296 to 303)),fromSLV(islv(304 to 311)),fromSLV(islv(312 to 319)),fromSLV(islv(320 to 327)),fromSLV(islv(328 to 335)));
  end;
  function toSLV (p : Tuple3_2) return std_logic_vector is
  begin
    return (toSLV(p.Tuple3_2_sel0_CoreData) & toSLV(p.Tuple3_2_sel1_unsigned_0) & toSLV(p.Tuple3_2_sel2_unsigned_1));
  end;
  function fromSLV (slv : in std_logic_vector) return Tuple3_2 is
  alias islv : std_logic_vector(0 to slv'length - 1) is slv;
  begin
    return (fromSLV(islv(0 to 335)),fromSLV(islv(336 to 340)),fromSLV(islv(341 to 356)));
  end;
  function toSLV (p : Tuple3_1) return std_logic_vector is
  begin
    return (toSLV(p.Tuple3_1_sel0_CoreData) & toSLV(p.Tuple3_1_sel1_unsigned_0) & toSLV(p.Tuple3_1_sel2_unsigned_1));
  end;
  function fromSLV (slv : in std_logic_vector) return Tuple3_1 is
  alias islv : std_logic_vector(0 to slv'length - 1) is slv;
  begin
    return (fromSLV(islv(0 to 335)),fromSLV(islv(336 to 340)),fromSLV(islv(341 to 348)));
  end;
  function toSLV (p : CPUState) return std_logic_vector is
  begin
    return (toSLV(p.CPUState_sel0_cpuCore) & toSLV(p.CPUState_sel1_cpuStage));
  end;
  function fromSLV (slv : in std_logic_vector) return CPUState is
  alias islv : std_logic_vector(0 to slv'length - 1) is slv;
  begin
    return (fromSLV(islv(0 to 335)),fromSLV(islv(336 to 367)));
  end;
  function toSLV (p : Tuple2_0) return std_logic_vector is
  begin
    return (toSLV(p.Tuple2_0_sel0_CPUState) & toSLV(p.Tuple2_0_sel1_Tuple3_3));
  end;
  function fromSLV (slv : in std_logic_vector) return Tuple2_0 is
  alias islv : std_logic_vector(0 to slv'length - 1) is slv;
  begin
    return (fromSLV(islv(0 to 367)),fromSLV(islv(368 to 425)));
  end;
end;

