module sap3_audio_synth (
    input  wire        clk,
    input  wire        rst,
    
    // Control Registers from CPU
    input  wire [15:0] pitch_step,  // From 0xC010 and 0xC011
    input  wire [7:0]  volume,      // From 0xC012
    input  wire        gate_en,     // From 0xC013
    
    // Hardware Sequencer Mode
    input  wire        seq_en,      // From 0xC014
    input  wire [7:0]  seq_addr,    // Offset into 0x6400-0x64FF
    input  wire [7:0]  seq_data_in,
    input  wire        seq_we,
    
    // Memory Bus for CPU to write wavetables (1KB max)
    input  wire [9:0]  cpu_addr,    // Offset into 0x6000-0x63FF space
    input  wire [7:0]  cpu_data_in,
    input  wire        cpu_we,
    
    // Physical output (6-bit PCM)
    output reg  [5:0]  audio_out
);

    // 1KB Wavetable RAM (2^10 = 1024 bytes)
    // In a real FPGA implementation, this will infer a single Block RAM.
    reg [7:0] wavetable_ram [0:1023];
    
    // DDS Phase Accumulator
    // 24-bit accumulator allows for fine frequency resolution
    reg [23:0] phase_accum;
    
    // ----------------------------------------------------
    // Hardware Music Sequencer
    // ----------------------------------------------------
    // 64 steps x 32-bits (4 bytes: PitchL, PitchH, Vol, Duration)
    reg [31:0] seq_ram [0:63];
    reg [31:0] current_step;

    localparam SEQ_IDLE  = 2'd0;
    localparam SEQ_FETCH = 2'd1;
    localparam SEQ_LOAD  = 2'd2;
    localparam SEQ_PLAY  = 2'd3;

    reg [1:0]  seq_state;
    reg [5:0]  seq_ptr;
    reg [7:0]  note_timer;
    reg [18:0] tick_div;
    
    reg [15:0] hw_pitch;
    reg [7:0]  hw_vol;
    reg        hw_gate;

    // Dual-Port logic for Sequencer memory
    always @(posedge clk) begin
        if (seq_we) begin
            case (seq_addr[1:0])
                2'b00: seq_ram[seq_addr[7:2]][7:0]   <= seq_data_in;
                2'b01: seq_ram[seq_addr[7:2]][15:8]  <= seq_data_in;
                2'b10: seq_ram[seq_addr[7:2]][23:16] <= seq_data_in;
                2'b11: seq_ram[seq_addr[7:2]][31:24] <= seq_data_in;
            endcase
        end
        current_step <= seq_ram[seq_ptr]; // Synchronous read
    end

    always @(posedge clk) begin
        if (rst || !seq_en) begin
            seq_state <= SEQ_IDLE;
            seq_ptr <= 6'd0;
            note_timer <= 8'd0;
            tick_div <= 19'd0;
            hw_pitch <= 16'd0;
            hw_vol <= 8'd0;
            hw_gate <= 1'b0;
        end else begin
            case (seq_state)
                SEQ_IDLE: begin
                    seq_ptr <= 6'd0;
                    seq_state <= SEQ_FETCH;
                end
                SEQ_FETCH: begin
                    seq_state <= SEQ_LOAD; // Wait 1 cycle for RAM read
                end
                SEQ_LOAD: begin
                    if (current_step[31:24] == 8'd0) begin
                        seq_ptr <= 6'd0; // End Marker (Duration=0), Loop!
                        seq_state <= SEQ_FETCH;
                    end else begin
                        hw_pitch   <= current_step[15:0];
                        hw_vol     <= current_step[23:16];
                        note_timer <= current_step[31:24];
                        hw_gate    <= (current_step[23:16] > 0);
                        seq_ptr    <= seq_ptr + 1;
                        tick_div   <= 19'd0;
                        seq_state  <= SEQ_PLAY;
                    end
                end
                SEQ_PLAY: begin
                    if (tick_div >= 19'd357954) begin // 60Hz tick based on 21.477MHz
                        tick_div <= 19'd0;
                        if (note_timer == 8'd1) seq_state <= SEQ_FETCH;
                        else note_timer <= note_timer - 1;
                    end else begin
                        tick_div <= tick_div + 1;
                    end
                end
            endcase
        end
    end

    // ----------------------------------------------------
    // Multiplexer: Manual CPU Mode vs Hardware Sequencer Mode
    // ----------------------------------------------------
    wire [15:0] active_pitch = seq_en ? hw_pitch : pitch_step;
    wire [7:0]  active_vol   = seq_en ? hw_vol   : volume;
    wire        active_gate  = seq_en ? hw_gate  : gate_en;
    
    // Internal signals
    wire [9:0] wave_addr;
    reg  [7:0] current_sample;
    
    // Synthesizer Engine (DDS)
    always @(posedge clk) begin
        if (rst) begin
            phase_accum <= 24'd0;
        end else if (active_gate) begin
            phase_accum <= phase_accum + {8'b0, active_pitch};
        end else begin
            // Reset phase when note is released
            phase_accum <= 24'd0;
        end
    end
    
    // Use the top 10 bits of the accumulator to address the 1KB RAM
    assign wave_addr = phase_accum[23:14];
    
    // Dual-Port RAM Logic: CPU writes, Synth reads
    always @(posedge clk) begin
        if (cpu_we) begin
            wavetable_ram[cpu_addr] <= cpu_data_in;
        end
        // Fetch the sample (pipeline delay of 1 cycle is fine for audio)
        current_sample <= wavetable_ram[wave_addr];
    end

    // Volume scaling (simplified: using higher 8 bits of a 16 bit multiply)
    // A full implementation might use DSP blocks depending on the FPGA.
    wire [15:0] scaled_sample_wire;
    assign scaled_sample_wire = current_sample * active_vol;
    
    reg [7:0] final_sample;
    always @(posedge clk) begin
        if (rst) final_sample <= 8'd0;
        else     final_sample <= scaled_sample_wire[15:8];
    end

    // 6-bit PCM Output
    always @(posedge clk) begin
        if (rst) begin
            audio_out <= 6'd0;
        end else begin
            // Output top 6 bits of the 8-bit scaled sample
            audio_out <= final_sample[7:2];
        end
    end

endmodule