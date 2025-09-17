`timescale 1ns/1ps
module vending_machine(
    input  wire clk,
    input  wire rst,
    input  wire [3:0] btn,     // BTN0=�л�(next) BTN1=ȷ��(enter) BTN2=ȡ�� BTN3=����
    input  wire [3:0] sw,
    output reg  [7:0] led,
    output wire [7:0] seg,
    output wire [7:0] an,
    output reg  [7:0] total_price,
    output reg  [7:0] paid_amount,
    output reg  [7:0] change_amount
);

    // ------------------------
    // 1?? ��������
    // ------------------------
     /*   wire btn[0], btn[1], btn[2], btn[3]; // ���������ź�

    debounce db0(.clk(clk), .rst(rst), .btn_in(btn[0]), .btn_out(), .btn_pulse(btn[0])); // .btn_out ���Բ�����
    debounce db1(.clk(clk), .rst(rst), .btn_in(btn[1]), .btn_out(), .btn_pulse(btn[1]));
    debounce db2(.clk(clk), .rst(rst), .btn_in(btn[2]), .btn_out(), .btn_pulse(btn[2]));
    debounce db3(.clk(clk), .rst(rst), .btn_in(btn[3]), .btn_out(), .btn_pulse(btn[3]));
*/

    // ------------------------
    // 2?? ״̬��
    // ------------------------
    localparam IDLE=3'd0, PROD1_SEL=3'd1, QTY1_SEL=3'd2,
               PROD2_SEL=3'd3, QTY2_SEL=3'd4, PAYMENT=3'd5, CHANGE=3'd6;
    reg [2:0] state, next_state;

    // ------------------------
    // 3?? ��Ʒѡ�������    
    // ------------------------
    reg [3:0] prod1_id, prod2_id;
    reg [1:0] qty1, qty2;
    reg prod1_locked, qty1_locked;
    reg prod2_locked, qty2_locked;

    reg [15:0] computed_total;

    // ------------------------
    // ״̬ת��
    // ------------------------
        always @(*) begin
        next_state = state; // Ĭ�ϱ��ֵ�ǰ״̬
        case(state)
            IDLE: if(btn[0]) next_state=PROD1_SEL;
            PROD1_SEL: if(btn[2]) next_state=IDLE;
                       else if(prod1_locked && btn[0]) next_state=QTY1_SEL; // ��������������Ʒ�������������ѡ��
            QTY1_SEL: if(btn[2]) next_state=IDLE;
                      else if(qty1_locked && btn[0]) next_state=PROD2_SEL; // �������������������������ڶ�����Ʒѡ��
            PROD2_SEL: if(btn[2]) next_state=IDLE;
                       else if(prod2_locked&&btn[0]) next_state=QTY2_SEL; // ѡ���˵ڶ�����Ʒ����������ѡ��
                       else if(btn[1]&&btn[0]) next_state=PAYMENT; // ��ѡ��ڶ�����Ʒ��ֱ�ӽ���֧��
            QTY2_SEL: if(btn[2]) next_state=IDLE;
                      else if(qty2_locked && btn[0]) next_state=PAYMENT; // �����˵ڶ�����Ʒ����������֧��
            PAYMENT: if(btn[2]) next_state=IDLE;
                     else if((paid_amount >= total_price) && btn[0]) next_state=CHANGE; // ֧���㹻�Ұ��л����Ž�������
                     else if(btn[3]) next_state = IDLE; // ��֧���ڼ䰴�������ȡ��������
            CHANGE: if(change_amount == 0 && btn[3]) next_state=IDLE; // ������Ϊ0�����ٴΰ������ (��ʾ������ɻ����)���ص�IDLE
                                                                        // ���ߣ���ֱ��һ�㣬��change_amount����0ʱ�Զ���IDLE
                                                                        // ������������� "�������ֶ������"������btn[3]�Ǳ����
                                                                        // ���ԣ���change_amount==0ʱ����btn[3]�Ż�IDLE������
                                                                        // ��������������1Ԫ���û���û���֣������̻�IDLE�ˡ�
            default: next_state=IDLE;
        endcase
    end
    // ------------------------
    // ��Ʒ�۸���
    // ------------------------
    function [7:0] get_price;
        input [3:0] pid;
        begin
            case(pid)
                4'h0: get_price=3; 4'h1: get_price=4; 4'h2: get_price=6; 4'h3: get_price=3;
                4'h4: get_price=10;4'h5: get_price=8; 4'h6: get_price=9; 4'h7: get_price=7;
                4'h8: get_price=4; 4'h9: get_price=6; 4'hA: get_price=15;4'hB: get_price=8;
                4'hC: get_price=9; 4'hD: get_price=4; 4'hE: get_price=5; 4'hF: get_price=5;
                default: get_price=0;
            endcase
        end
    endfunction

    // ------------------------
    // �ܼۼ���
    // ------------------------
    always @(*) begin
        computed_total = 0;
        if(prod1_locked && qty1_locked) computed_total = computed_total + get_price(prod1_id)*qty1;
        if(prod2_locked && qty2_locked) computed_total = computed_total + get_price(prod2_id)*qty2;
    end

    // ------------------------
    // ״̬�Ĵ����ͽ����߼�
    // ------------------------
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            state <= IDLE;
            next_state<=IDLE;
            prod1_id<=0; prod2_id<=0;
            qty1<=0; qty2<=0;
            prod1_locked<=0; qty1_locked<=0;
            prod2_locked<=0; qty2_locked<=0;
            total_price<=0; paid_amount<=0; change_amount<=128;
            led<=8'b00000001;
        end else begin
            state <= next_state;

            if(btn[2]) begin
                prod1_id<=0; prod2_id<=0;
                qty1<=0; qty2<=0;
                prod1_locked<=0; qty1_locked<=0;
                prod2_locked<=0; qty2_locked<=0;
                total_price<=0; paid_amount<=0; change_amount<=0;
                led<=8'b00000001;
            end else begin
                case(state)
                    PROD1_SEL: if(btn[1]) begin prod1_id<=sw[3:0]; prod1_locked<=1'b1; end
                    QTY1_SEL:  if(btn[1] && sw[1:0]!=0) begin qty1<=sw[1:0]; qty1_locked<=1'b1; end
                    PROD2_SEL: if(btn[1]) begin prod2_id<=sw[3:0]; prod2_locked<=1'b1; end
                               //else if(!prod2_locked && enter_btn) begin qty2<=0; qty2_locked<=0; prod2_locked<=0; end
                    QTY2_SEL:  if(btn[1] && sw[1:0]!=0) begin qty2<=sw[1:0]; qty2_locked<=1'b1; end
                    PAYMENT:   if(btn[1]) begin
                                    if(sw[0]==0) paid_amount<=paid_amount+1;
                                    else case(sw[2:1])
                                        2'b00: paid_amount<=paid_amount+5;
                                        2'b01: paid_amount<=paid_amount+10;
                                        2'b10: paid_amount<=paid_amount+20;
                                        2'b11: paid_amount<=paid_amount+50;
                                    endcase
                               end
                    CHANGE:    if(change_amount==128 && paid_amount>=total_price)
                                    change_amount<=paid_amount-total_price;
                               else if(btn[3] && change_amount>0)
                                    change_amount<=change_amount-1;
                endcase
                if(state!=QTY2_SEL) total_price <= computed_total[7:0];
            end
        end
    end

    // ------------------------
    // LED ״ָ̬ʾ
    // ------------------------
    always @(*) begin
        case(state)
            IDLE: led=8'b00000001;
            PROD1_SEL: led=8'b00000010;
            QTY1_SEL: led=8'b00000100;
            PROD2_SEL: led=8'b00001000;
            QTY2_SEL: led=8'b00010000;
            PAYMENT: led=8'b00100000;
            CHANGE: led=8'b01000000;
            default: led=8'b00000000;
        endcase
    end

    // ------------------------
    // 4?? 7-Segment ��ʾ
    // ------------------------
    // ---------------------
// seg_buffer[0] -> ��λ
// seg_buffer[1] -> ʮλ
// seg_buffer[2] -> ���� (һ������)
// seg_buffer[3] -> ���� (һ������)
// ---------------------
reg [3:0] seg_buffer [5:0];

always @(*) begin
    case(state)
        PROD1_SEL: begin
            // ��ʾ��Ʒ���(��λ) + ����(��λ)
            seg_buffer[1] = prod1_id / 10; // ��ƷIDʮλ
            seg_buffer[0] = prod1_id % 10; // ��ƷID��λ
            end
            
         QTY1_SEL:begin
         seg_buffer[1] = prod1_id / 10; // ��ƷIDʮλ
            seg_buffer[0] = prod1_id % 10; // ��ƷID��λ
            seg_buffer[2] = 4'd0;        
            seg_buffer[3] = 4'd0;        
            seg_buffer[5]=qty1/10;
            seg_buffer[4]=qty1%10;
        end
        
        PROD2_SEL:begin
        seg_buffer[1] = prod2_id / 10; // ��ƷIDʮλ
            seg_buffer[0] = prod2_id % 10; // ��ƷID��λ
            end
            
            QTY2_SEL:begin
             seg_buffer[1] = prod2_id / 10; // ��ƷIDʮλ
            seg_buffer[0] = prod2_id % 10; // ��ƷID��λ
            seg_buffer[2] = 4'd0;        
            seg_buffer[3] = 4'd0;        
            seg_buffer[5]=qty2/10;
            seg_buffer[4]=qty2%10;
            end

        PAYMENT: begin
            // ��ʾ �Ѹ���� + �ܼ� ������λ��
            seg_buffer[3] = paid_amount / 10;
            seg_buffer[2] = paid_amount % 10;
            seg_buffer[1] = total_price / 10;
            seg_buffer[0] = total_price % 10;
        end

        CHANGE: begin
            // ��ʾ���㣨��λ��������99��
            seg_buffer[3] = 4'd0;
            seg_buffer[2] = 4'd0;
            seg_buffer[1] = change_amount / 10;
            seg_buffer[0] = change_amount % 10;
        end

        default: begin
            seg_buffer[3] = 4'd0;
            seg_buffer[2] = 4'd0;
            seg_buffer[1] = 4'd0;
            seg_buffer[0] = 4'd0;
        end
    endcase
end


    // ------------------------
    // 7-seg ɨ�����
    // ------------------------
    reg [2:0] scan_idx;
    reg [7:0] seg_out, an_out;
    always @(posedge clk or posedge rst) begin
        if(rst) scan_idx<=0;
        else scan_idx<=scan_idx+1;
    end

    always @(*) begin
        an_out=8'hFF;
        seg_out=bcd2seg(seg_buffer[scan_idx]);
        an_out[scan_idx]=0; // ����ɨ��
    end
    assign seg=seg_out;
    assign an=an_out;

    // ------------------------
    // BCD->7-seg ӳ��
    // ------------------------
    function [7:0] bcd2seg;
        input [3:0] bcd;
        begin
            case(bcd)
                4'd0: bcd2seg=8'b11000000;
                4'd1: bcd2seg=8'b11111001;
                4'd2: bcd2seg=8'b10100100;
                4'd3: bcd2seg=8'b10110000;
                4'd4: bcd2seg=8'b10011001;
                4'd5: bcd2seg=8'b10010010;
                4'd6: bcd2seg=8'b10000010;
                4'd7: bcd2seg=8'b11111000;
                4'd8: bcd2seg=8'b10000000;
                4'd9: bcd2seg=8'b10010000;
                default: bcd2seg=8'b11111111;
            endcase
        end
    endfunction

endmodule

// ------------------------
// ��������
// ------------------------
module debounce(
    input  wire clk,
    input  wire rst,
    input  wire btn_in,
    output reg  btn_out,
    output wire btn_pulse   // �������������������
);

    reg [20:0] cnt;      // �ĳ� 21 λ������ (~20 ms @ 100MHz)
    reg btn_sync0, btn_sync1;
    reg btn_out_d;

    // ����ͬ��
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            btn_sync0 <= 0;
            btn_sync1 <= 0;
        end else begin
            btn_sync0 <= btn_in;
            btn_sync1 <= btn_sync0;
        end
    end

    // ��������
   always @(posedge clk or posedge rst) begin
        if(rst) begin
            cnt <= 0;
            btn_out <= 0;
        end else if(btn_sync1 == btn_out) begin
            cnt <= 0;  // ��������һ�£�����������
        end else begin
            cnt <= cnt + 1;
            if(&cnt) btn_out <= btn_sync1; // ������ȫ 1 �� ��ת���
        end
    end

    // ���ؼ�⣬��������������
    always @(posedge clk or posedge rst) begin
        if(rst) btn_out_d <= 0;
        else    btn_out_d <= btn_out;
    end

    assign btn_pulse = btn_out & ~btn_out_d;  // ����������

endmodule

