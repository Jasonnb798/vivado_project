`timescale 1ns/1ps

module tb_vending_machine;

    reg clk;
    reg rst;
    reg [3:0] btn;
    reg [3:0] sw;
    wire [7:0] led;
    wire [7:0] seg;
    wire [7:0] an;
    wire [7:0] total_price;
    wire [7:0] paid_amount;
    wire [7:0] change_amount;

    // ʵ��������ģ��
    vending_machine uut (
        .clk(clk),
        .rst(rst),
        .btn(btn),
        .sw(sw),
        .led(led),
        .seg(seg),
        .an(an),
        .total_price(total_price),
        .paid_amount(paid_amount),
        .change_amount(change_amount)
    );

    // --------------------------
    // ʱ������ 50MHz
    // --------------------------
    initial clk = 0;
    always #10 clk = ~clk; // 20ns���� -> 50MHz

    // --------------------------
    // ������������
    // --------------------------
    task press_btn(input [3:0] b, input integer cycles);
        integer i;
        begin
            btn = b;
            for(i=0;i<cycles;i=i+1) @(posedge clk);
            btn = 4'b0000;
            for(i=0;i<5;i=i+1) @(posedge clk); // �ɿ���ʱ
        end
    endtask

task press_two_btns(input [3:0] btn1_mask, input [3:0] btn2_mask, input integer cycles);
    integer i;
    begin
        // ͬʱ����������ť����λ�������
        btn = btn1_mask | btn2_mask;
        for(i=0;i<cycles;i=i+1) @(posedge clk);
        btn = 4'b0000;                // �ɿ����а���
        for(i=0;i<5;i=i+1) @(posedge clk); // �ɿ���ʱ
    end
endtask

    // --------------------------
    // ��ʼ��
    // --------------------------
    initial begin
        rst = 1;
        btn = 0;
        sw  = 0;
        @(posedge clk);
        @(posedge clk);
        rst = 0;

        // ----------------------
        // 1. ������Ʒ1ѡ�� -> A11
        // ----------------------
        press_btn(4'b0001, 2); // NEXT -> ���� PROD1_SEL
        sw = 4'h0;              // A11
        press_btn(4'b0010, 2); // ENTER -> ������Ʒ1

        // ----------------------
        // 2. ѡ������ 1��
        // ----------------------
        press_btn(4'b0001, 2); // NEXT -> ���� QTY1_SEL
        sw = 4'b01;             // ���� 1
        press_btn(4'b0010, 2); // ENTER -> ��������1

        // ----------------------
        // 3. ѡ����Ʒ2 -> A34
        // ----------------------
        press_two_btns(4'b0001,4'b0010,2);
        //press_btn(4'b0001, 2); // NEXT -> PROD2_SEL
        //sw = 4'h3;              // A34
        //press_btn(4'b0010, 2); // ENTER -> ������Ʒ2

        // ----------------------
        // 4. ѡ������ 2��
        // ----------------------
       // press_btn(4'b0001, 2); // NEXT -> QTY2_SEL
       // sw = 4'b10;             // ���� 2
       // press_btn(4'b0010, 2); // ENTER -> ��������2

        // ----------------------
        // 5. ���� -> Ͷ��5Ԫ
        // ----------------------
        press_btn(4'b0001, 2); // NEXT -> PAYMENT
        sw = 4'b001;            // Ͷ��20Ԫ (sw[2:1]=10)
        press_btn(4'b0010, 1);  // ENTER -> �����Ѹ����

        // ----------------------
        // 6. ���� -> 1Ԫ
        // ----------------------
        press_btn(4'b0001, 2); // NEXT -> CHANGE
        press_btn(4'b1000, 1); // CHANGE BTN ���£���������1Ԫ
        press_btn(4'b1000, 1);

        // ----------------------
        // 7. �ص���ʼ״̬
        // ----------------------
        @(posedge clk);
        $stop;
    end

endmodule
