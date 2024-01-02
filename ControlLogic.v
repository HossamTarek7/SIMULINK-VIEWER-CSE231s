
module ControlLogic(
     input  Icw1,
     input  Icw2,
     input  Icw3,
     input  Icw4,
     
     input  Ocw1,
     input  Ocw2,
     input  Ocw3,
     input  read,
     input sp_en, //master or slave PIC
     input ACK,
     
     input [7:0] highest_level_in_service,
     output reg [7:0] end_of_interrupt,
     input wire [2:0]CasIn,
     output reg[2:0] CasOut,
     
     input wire [7:0] ISR,
     
     input INTACK,  
     input reg[7:0] internal_data_bus,
     output reg CascedeMode,
     output reg [7:0]Slave,
     output reg [7:0]interrupt_vector_address,
     output reg [7:0]interrupt_vector_address,    
     output reg level_or_edge_triggered, //0-->edge triggered     1-->level triggered //LTIM
     output reg call_address_interval, //1-->interval of 4     0-->interval of 8 //ADI
     output reg single_cascade,  //1-->single     0-->cascade  //SNGL 
     output reg icw4_needed, //IC4
     output reg special_fully_nested, //1-->special fully nested mode     0-->not special fully nested mode //SFNM
     output reg buffered_mode, //0-->non buffered mode / 1-->buffered mode //BUF
     output reg buffered_mode_slave_or_master, //0-->slave / 1-->master //M/S
     output reg automatic_end_of_interrupt, //1-->automatic end of interrupt / 0-->normal end of interrupt //AEOI
     output reg auto_rotate_mode, //Auto rotate mode
     output reg non_specific_end_of_interrupt, //Auto rotate mode
     output reg u8086_or_u8085_mode, //1-->8086/8088 mode / 0-->MCS.80/85 mode // uPM
     output reg [7:0] MASK_REGSTER,
     output reg Special_mask_mode, // ESMM / SMM // 10-->RESET special mask mode   /   11-->SET special mask mode
     output reg Poll_command ,//POLL COMMAND //  1-->POLL COMMAND   /   0-->NO POLL COMMAND
     output reg READ_IS_REG, // RR/RIS
     output reg READ_IR_REG 
     
);
// State
    typedef enum {CTL_READY, ACK1, ACK2, ACK3, POLL}   control_state_t;   



/**intialization*****/

reg [3:0] ICW1;
reg [4:0] ICW2;
reg [7:0] ICW3;
reg [4:0] ICW4;

reg [7:0] OCW1;
reg [7:0] OCW2;
reg [7:0] OCW3;

always @(*)
 begin
    if(Icw1) ICW1<=internal_data_bus[3:0]; 
    if(Icw2) ICW2<=internal_data_bus[7:3];
    if(Icw3)
    begin
      if(sp_en)
         ICW3<=internal_data_bus;
      else 
         ICW3[2:0]<=internal_data_bus[2:0];
        
    end 
    if(Icw4) ICW4<=internal_data_bus[4:0];
   
end

always @(*)
begin
  if(Ocw1) OCW1<=internal_data_bus;
  if(Ocw2) OCW2<= internal_data_bus; 
  if(Ocw3) OCW3<=internal_data_bus;
end

//CASCADE Mode****************/
always @(*)
begin
  if(ICW1[1]==1'b1)
    CascedeMode <= 1'b0;
  else
    CascedeMode<=1'b1;
end


//Slave
always @(*)
  begin
    if(sp_en)
        begin
    
       if(!CascedeMode)
          Slave=8'b0;
        else
          Slave= ICW3;
        end
    end
reg [7:0] dataBus;
reg[2:0] SlaveID;
reg [7:0] X; 
always @(*)
begin
if(sp_en)
  begin
    if(CascedeMode)
      begin
        X =Slave & ISR;
        if(!X)
          begin
         SlaveID = bit2num(X);
         CasOut= SlaveID; 
         end
      end
  end
else
   begin
     if(CasIn == ICW3[2:0])
     begin
       // dataBus= RoutinAddress from ACKs(hossam - yousry);
       end
       
    end 
end





    // Service control state
    control_state_t next_control_state;
    control_state_t control_state;


// State machine
    always@(*) 
    begin
        case (control_state)
            
            CTL_READY: 
            begin
                if ((Ocw3 == 1'b1) && (internal_data_bus[2] == 1'b1))
                    next_control_state = POLL;
                else if (Ocw2 == 1'b1)
                    next_control_state = CTL_READY;
                else if (nedge_interrupt_acknowledge == 1'b0)
                    next_control_state = CTL_READY;
                else
                    next_control_state = ACK1;
            end
            ACK1: 
            begin
                if (pedge_interrupt_acknowledge == 1'b0)
                    next_control_state = ACK1;
                else
                    next_control_state = ACK2;
            end
            ACK2: 
            begin
                if (pedge_interrupt_acknowledge == 1'b0)
                    next_control_state = ACK2;
                else if (u8086_or_u8085_mode == 1'b0)
                    next_control_state = ACK3;
                else
                    next_control_state = CTL_READY;
            end
            ACK3: 
            begin
                if (pedge_interrupt_acknowledge == 1'b0)
                    next_control_state = ACK3;
                else
                    next_control_state = CTL_READY;
            end
            POLL: begin
                if (nedge_read_signal == 1'b0)
                    next_control_state = POLL;
                else
                    next_control_state = CTL_READY;
            end
            default: begin
                next_control_state = CTL_READY;
            end
        endcase
    end

    always@(*) 
    begin
        if (Icw1== 1'b1)
            control_state <= CTL_READY;
        else
            control_state <= next_control_state;
    end


    // Latch in service register signal
    always@(*) 
    begin
        if (Icw1 == 1'b1)
            latch_in_service = 1'b0;
        else if ((control_state == CTL_READY) && (next_control_state == POLL))
            latch_in_service = 1'b1;
        else if (cascade_slave == 1'b0)
            latch_in_service = (control_state == CTL_READY) & (next_control_state != CTL_READY);
        else
            latch_in_service = (control_state == ACK2) & (cascade_slave_enable == 1'b1) & (nedge_interrupt_acknowledge == 1'b1);
    end
    
    
    // End of acknowledge sequence
    wire    end_of_acknowledge_sequence =  (control_state != POLL) & (control_state != CTL_READY) & (next_control_state == CTL_READY);
    wire    end_of_poll_command         =  (control_state == POLL) & (control_state != CTL_READY) & (next_control_state == CTL_READY);

// Detect ACK edge
    logic   prev_interrupt_acknowledge;

    always@(*) 
    begin
            prev_interrupt_acknowledge <= interrupt_acknowledge;
    end
    
    wire    nedge_interrupt_acknowledge =  prev_interrupt_acknowledge & ~interrupt_acknowledge;
    wire    pedge_interrupt_acknowledge = ~prev_interrupt_acknowledge &  interrupt_acknowledge;
    
    // Detect read signal edge
  logic   prev_read_signal;

    always@(*) 
    begin
            prev_read_signal <= read;
    end
    wire    nedge_read_signal = prev_read_signal & ~read;
    
    
    



//-----------------------------------------//
//ICW1 ELEMENTS INITIALIZATION
//-----------------------------------------//

always@(*)
begin
if(Icw1==1'b1)  
  interrupt_vector_address[2:0]<=internal_data_bus[7:5];
 else 
  interrupt_vector_address[2:0]<=interrupt_vector_address[2:0];
end


/************************************************************************/
//        ACKNOLADGEMENT                          //
/************************************************************************/
always @(*)
begin

end 

/***********************************************************************/


//LTIM

always@(*)
begin
  if(Icw1==1'b1)
    level_or_edge_triggered<=internal_data_bus[3];
  else
    level_or_edge_triggered<=level_or_edge_triggered;
end




//ADI
always@(*)
begin
  if(Icw1==1'b1)
   call_address_interval<=internal_data_bus[2];
  else
  call_address_interval<=call_address_interval;
end



//SNGL

always@(*)
begin
  if(Icw1==1'b1)
   single_cascade<=internal_data_bus[1];
  else
    single_cascade<=single_cascade;
end

//IC4

always@(*)
begin
  if(Icw1==1'b1)
   icw4_needed<=internal_data_bus[0];
  else
    icw4_needed<=icw4_needed;
end




//-----------------------------------------//
//ICW2 ELEMENTS INITIALIZATION
//-----------------------------------------//

always@(*)
begin
  if(Icw1==1'b1)
    interrupt_vector_address[7:3]<= 5'b00000 ;
  else if(Icw2==1'b1)
   interrupt_vector_address[7:3]<=internal_data_bus[7:3];
  else
    interrupt_vector_address[7:3]<=interrupt_vector_address[7:3];
end


//-----------------------------------------//
//ICW3 ELEMENTS INITIALIZATION
//-----------------------------------------//

reg [7:0]cascade_device;
 always@(*) 
 begin
        if (Icw1 == 1'b1)
            cascade_device <= 8'b00000000;
        else if (Icw3 == 1'b1)
            cascade_device <= internal_data_bus;
        else
            cascade_device <= cascade_device;
    end

//-----------------------------------------//
//ICW4 ELEMENTS INITIALIZATION
//-----------------------------------------//


//SFNM
always@(*)
begin
  if((Icw1==1'b1) && (ICW1[0]==1'b0))
    special_fully_nested<=1'b0;
  else if(Icw4==1'b1)
   special_fully_nested<=internal_data_bus[4];
  else
    special_fully_nested<=special_fully_nested;
end


//BUF

always@(*)
begin
  if((Icw1==1'b1) && (ICW1[0]==1'b0))
    buffered_mode<=1'b0;
  else if(Icw4==1'b1)
    buffered_mode<=internal_data_bus[3];
  else
    buffered_mode<=buffered_mode;
end



//M/S

always@(*)
begin
  if((Icw1==1'b1) && (ICW1[0]==1'b0))
    buffered_mode_slave_or_master<=1'b0;
  else if(Icw4==1'b1)
    buffered_mode_slave_or_master<=internal_data_bus[2];
  else
    buffered_mode_slave_or_master<=buffered_mode_slave_or_master;
end




//AEOI

always@(*)
begin
  if((Icw1==1'b1) && (ICW1[0]==1'b0))
    automatic_end_of_interrupt<=1'b0;
  else if(Icw4==1'b1)
    automatic_end_of_interrupt<=internal_data_bus[1];
  else
    automatic_end_of_interrupt<=automatic_end_of_interrupt;
end


// uPM
always @(*) 
begin
  
   if((Icw1==1'b1) && (ICW1[0]==1'b0))
        u8086_or_u8085_mode <= 1'b0;
   else if (Icw4 == 1'b1)
        u8086_or_u8085_mode <= internal_data_bus[0];
   else
        u8086_or_u8085_mode <= u8086_or_u8085_mode;
        
end

//-----------------------------------------//
//OCW2 ELEMENTS INITIALIZATION
//-----------------------------------------//
always @ (*)
begin
  if (Icw1 == 1'b1)     //in initialization
    end_of_interrupt <= 8'b11111111;
  else if (Ocw2 == 1'b1)
  begin
    if (OCW2[7:5] == 3'b001)
      end_of_interrupt[7:0] <= highest_level_in_service[7:0];
    else
      end_of_interrupt[7:0] <= 8'b00000000;
  end
end




//Auto rotate mode

always@(*)
begin 
  if(Icw1==1'b1)
    auto_rotate_mode<=1'b0;
  else if(Ocw2==1'b1)
   begin
    case(OCW2[7:5])
  
    3'b000: auto_rotate_mode<=1'b0;
  
    3'b100: auto_rotate_mode<=1'b1;
    
    3'b101: non_specific_end_of_interrupt<=1'b1;
   
    default: auto_rotate_mode<=auto_rotate_mode;
    
   endcase
   end  
 else 
          auto_rotate_mode<=auto_rotate_mode;
end  


//-----------------------------------------//
//OCW1 ELEMENTS INITIALIZATION
//-----------------------------------------//

always@(*)
begin
  if(Icw1==1'b1)     
  MASK_REGSTER<=8'b11111111;
  else if(Ocw1==1'b1)
  MASK_REGSTER<=internal_data_bus;
end  



//-----------------------------------------//
//OCW3 ELEMENTS INITIALIZATION
//-----------------------------------------//



// ESMM / SMM 
// 10-->special_mask_mode==0  /  11-->special_mask_mode==1
//reg special_mask_mode;
//always@(*)
//begin
    //if(Icw1==1'b1)
     // special_mask_mode<=1'b0;
    //else if(Ocw1==1'b1 && OCW[6:5]==2'b10)
     // special_mask_mode<=1'b0;
    //else if(Ocw1==1'b1 && OCW[6:5]==2'b11) 
     // special_mask_mode<=1'b1;
    //else
  //    special_mask_mode<=special_mask_mode;
//end



// ESMM / SMM 
always@(*)
begin
   if(Ocw3==1'b1)
    begin
    if(OCW3[6:5]==2'b01) 
      Special_mask_mode<=OCW3[6:5];
    
  else if(OCW3[6:5]==2'b11)
      Special_mask_mode<=Special_mask_mode;
    end
end




//POLL COMMAND
always@(*)
begin
    if(Icw1==1'b1)
      Poll_command<=1'b0;
    else if(Ocw3==1'b1)
      Poll_command<=OCW3[2];
    else
      Poll_command<=Poll_command;
end




// RR/RIS

always@(*) 
begin
    if (Icw1 == 1'b1) 
    begin
        READ_IS_REG<= 1'b0;
        READ_IR_REG <=1'b1;
    end
    else if (Ocw3 == 1'b1) 
    begin
        READ_IS_REG<= OCW3[1];
        READ_IR_REG <= OCW3[0];
    end
    else 
    begin
        READ_IS_REG<= READ_IS_REG;
        READ_IR_REG<=READ_IR_REG;
    end
  end
  
  //
    // Cascade signals
    //
    // Select master/slave
    reg cascade_slave;
    reg cascade_slave_enable;
    always_comb begin
        if (single_or_cascade == 1'b1)
            cascade_slave = 1'b0;
        else if (buffered_mode == 1'b0)
            cascade_slave = ~slave_program_n;
        else
            cascade_slave = ~buffered_mode_slave_or_master;
    end

    // Cascade port I/O
    assign cascade_io = cascade_slave;

    //
    // Cascade signals (slave)
    //
    always_comb begin
        if (cascade_slave == 1'b0)
            cascade_slave_enable = 1'b0;
        else if (cascade_device[2:0] != cascade_in)
            cascade_slave_enable = 1'b0;
        else
            cascade_slave_enable = 1'b1;
    end

    //
    // Cascade signals (master)
    //
    wire    interrupt_from_slave_device = (acknowledge_interrupt & cascade_device_config) != 8'b00000000;


//-----------------------------------------//
//      LATCH
//-----------------------------------------//
  
  
  
reg LATCH ;
always@(*)
begin
    if (Icw1 == 1'b1)
        LATCH = 1'b0;
    else if ((CTL_STATE == CTL_READY))
        LATCH = 1'b1;
    else if (CASCADE_MODE == 1'b0)
        LATCH = (CTL_STATE == CTL_READY) & (NEXT_CTL_STATE != CTL_READY);
    else
        LATCH = (CTL_STATE == ACK2) & (SLAVE_MATCH == 1'b1) & (NEG_EDGE_ACK == 1'b1);
end

    
    // output ACK2 and ACK3
    reg cascade_output_ack_2_3;
     always@(*) 
     begin
        if (single_or_cascade == 1'b1)
            cascade_output_ack_2_3 = 1'b1;
        else if (cascade_slave_enable == 1'b1)
            cascade_output_ack_2_3 = 1'b1;
        else if ((cascade_slave == 1'b0) && (interrupt_from_slave_device == 1'b0))
            cascade_output_ack_2_3 = 1'b1;
        else
            cascade_output_ack_2_3 = 1'b0;
    end

  
  // control_logic_data
     reg out_control_logic_data;
     reg [7:0] control_logic_data;
    always@(*) 
    begin
        if (interrupt_acknowledge == 1'b0) 
        begin
            // Acknowledge
            case (control_state)
                CTL_READY: begin
                    if (cascade_slave == 1'b0) 
                    begin
                        if (u8086_or_u8085_mode == 1'b0) 
                        begin
                            out_control_logic_data = 1'b1;
                            control_logic_data     = 8'b11001101;
                        end
                        else 
                        begin
                            out_control_logic_data = 1'b0;
                            control_logic_data     = 8'b00000000;
                        end
                    end
                    else 
                    begin
                        out_control_logic_data = 1'b0;
                        control_logic_data     = 8'b00000000;
                    end
                end
                ACK1: 
                begin
                    if (cascade_slave == 1'b0) 
                    begin
                        if (u8086_or_u8085_mode == 1'b0) 
                        begin
                            out_control_logic_data = 1'b1;
                            control_logic_data     = 8'b11001101;
                        end
                        else 
                        begin
                            out_control_logic_data = 1'b0;
                            control_logic_data     = 8'b00000000;
                        end
                    end
                    else 
                    begin
                        out_control_logic_data = 1'b0;
                        control_logic_data     = 8'b00000000;
                    end
                end
                ACK2: 
                begin
                    if (cascade_output_ack_2_3 == 1'b1) 
                    begin
                        out_control_logic_data = 1'b1;

                        if (cascade_slave == 1'b1)
                            control_logic_data[2:0] = bit2num(interrupt_when_ack1);
                        else
                            control_logic_data[2:0] = bit2num(acknowledge_interrupt);

                        if (u8086_or_u8085_mode == 1'b0) begin
                            if (call_address_interval == 1'b0)
                                control_logic_data = {interrupt_vector_address[2:1], control_logic_data[2:0], 3'b000};
                            else
                                control_logic_data = {interrupt_vector_address[2:0], control_logic_data[2:0], 2'b00};
                        end
                        else 
                        begin
                            control_logic_data = {interrupt_vector_address[10:6], control_logic_data[2:0]};
                        end
                    end
                    else 
                    begin
                        out_control_logic_data = 1'b0;
                        control_logic_data     = 8'b00000000;
                    end
                end
                ACK3: 
                begin
                    if (cascade_output_ack_2_3 == 1'b1) 
                    begin
                        out_control_logic_data = 1'b1;
                        control_logic_data     = interrupt_vector_address[10:3];
                    end
                    else 
                    begin
                        out_control_logic_data = 1'b0;
                        control_logic_data     = 8'b00000000;
                    end
                end
                default: 
                begin
                    out_control_logic_data = 1'b0;
                    control_logic_data     = 8'b00000000;
                end
            endcase
        end
        else if ((control_state == POLL) && (read == 1'b1)) 
        begin
            // Poll command
            out_control_logic_data = 1'b1;
            if (acknowledge_interrupt == 8'b00000000)
                control_logic_data = 8'b000000000;
            else 
            begin
                control_logic_data[7:3] = 5'b10000;
                control_logic_data[2:0] = bit2num(acknowledge_interrupt);
            end
        end
        else 
        begin
            // Nothing
            out_control_logic_data = 1'b0;
            control_logic_data     = 8'b00000000;
        end
    end

endmodule