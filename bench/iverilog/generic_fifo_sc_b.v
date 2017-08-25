/////////////////////////////////////////////////////////////////////
////                                                             ////
////  Universal FIFO Single Clock                                ////
////                                                             ////
////                                                             ////
////  Author: Rudolf Usselmann                                   ////
////          rudi@asics.ws                                      ////
////                                                             ////
////                                                             ////
////  D/L from: http://www.opencores.org/cores/generic_fifos/    ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2000-2002 Rudolf Usselmann                    ////
////                         www.asics.ws                        ////
////                         rudi@asics.ws                       ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

//  CVS Log
//
//  $Id: generic_fifo_sc_b.v,v 1.1.1.1 2002/09/25 05:42:04 rudi Exp $
//
//  $Date: 2002/09/25 05:42:04 $
//  $Revision: 1.1.1.1 $
//  $Author: rudi $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               $Log: generic_fifo_sc_b.v,v $
//               Revision 1.1.1.1  2002/09/25 05:42:04  rudi
//               Initial Checkin
//
//
//
//
//
//
//
//
//
//
//

`include "timescale.v"

/*

Description
===========

I/Os
----
rst	low active, either sync. or async. master reset (see below how to select)
clr	synchronous clear (just like reset but always synchronous), high active
re	read enable, synchronous, high active
we	read enable, synchronous, high active
din	Data Input
dout	Data Output

full	Indicates the FIFO is full (combinatorial output)
full_r	same as above, but registered output (see note below)
empty	Indicates the FIFO is empty
empty_r	same as above, but registered output (see note below)

full_n		Indicates if the FIFO has space for N entries (combinatorial output)
full_n_r	same as above, but registered output (see note below)
empty_n		Indicates the FIFO has at least N entries (combinatorial output)
empty_n_r	same as above, but registered output (see note below)

level		indicates the FIFO level:
		2'b00	0-25%	 full
		2'b01	25-50%	 full
		2'b10	50-75%	 full
		2'b11	%75-100% full

combinatorial vs. registered status outputs
-------------------------------------------
Both the combinatorial and registered status outputs have the same
basic functionality. The registered outputs are de-asserted with a
1 cycle delay for full_r and empty_r, and a 2 cycle delay for full_n_r
and empty_n_r.
The combinatorial outputs however, pass through several levels of
logic before they are output. The registered status outputs are
direct outputs of a flip-flop. The reason both are provided, is
that the registered outputs require additional logic inside the
FIFO. If you can meet timing of your device with the combinatorial
outputs, use them ! The FIFO will be smaller. If the status signals
are in the critical pass, use the registered outputs, they have a
much smaller output delay (actually only Tcq).

Parameters
----------
The FIFO takes 3 parameters:
dw	Data bus width
aw	Address bus width (Determines the FIFO size by evaluating 2^aw)
n	N is a second status threshold constant for full_n and empty_n
	If you have no need for the second status threshold, do not
	connect the outputs and the logic should be removed by your
	synthesis tool.

Synthesis Results
-----------------
In a Spartan 2e a 8 bit wide, 8 entries deep FIFO, takes 85 LUTs and runs
at about 116 MHz (IO insertion disabled). The registered status outputs
are valid after 2.1NS, the combinatorial once take out to 6.5 NS to be
available.


Misc
----
This design assumes you will do appropriate status checking externally.

IMPORTANT ! writing while the FIFO is full or reading while the FIFO is
empty will place the FIFO in an undefined state.

*/


// Selecting Sync. or Async Reset
// ------------------------------
// Uncomment one of the two lines below. The first line for
// synchronous reset, the second for asynchronous reset

`define SC_FIFO_ASYNC_RESET				// Uncomment for Syncr. reset
//`define SC_FIFO_ASYNC_RESET	or negedge rst		// Uncomment for Async. reset


module generic_fifo_sc_b(clk, rst, clr, din, we, dout, re,
			full, empty, full_r, empty_r,
			full_n, empty_n, full_n_r, empty_n_r,
			level);

parameter dw=8;
parameter aw=8;
parameter n=32;
parameter max_size = 1<<aw;

input			clk, rst, clr;
input	[dw-1:0]	din;
input			we;
output	[dw-1:0]	dout;
input			re;
output			full, full_r;
output			empty, empty_r;
output			full_n, full_n_r;
output			empty_n, empty_n_r;
output	[1:0]		level;

////////////////////////////////////////////////////////////////////
//
// Local Wires
//

reg	[aw:0]	wp;
wire	[aw:0]	wp_pl1;
reg	[aw:0]	rp;
wire	[aw:0]	rp_pl1;
reg		full_r;
reg		empty_r;
wire	[aw:0]	diff;
reg	[aw:0]	diff_r;
reg		re_r, we_r;
wire		full_n, empty_n;
reg		full_n_r, empty_n_r;
reg	[1:0]	level;

////////////////////////////////////////////////////////////////////
//
// Memory Block
//

generic_dpram  #(aw,dw) u0(
	.rclk(		clk		),
	.rrst(		!rst		),
	.rce(		1'b1		),
	.oe(		1'b1		),
	.raddr(		rp[aw-1:0]	),
	.do(		dout		),
	.wclk(		clk		),
	.wrst(		!rst		),
	.wce(		1'b1		),
	.we(		we		),
	.waddr(		wp[aw-1:0]	),
	.di(		din		)
	);

////////////////////////////////////////////////////////////////////
//
// Misc Logic
//

always @(posedge clk `SC_FIFO_ASYNC_RESET)
	if(!rst)	wp <= #1 {aw+1{1'b0}};
	else
	if(clr)		wp <= #1 {aw+1{1'b0}};
	else
	if(we)		wp <= #1 wp_pl1;

assign wp_pl1 = wp + { {aw{1'b0}}, 1'b1};

always @(posedge clk `SC_FIFO_ASYNC_RESET)
	if(!rst)	rp <= #1 {aw+1{1'b0}};
	else
	if(clr)		rp <= #1 {aw+1{1'b0}};
	else
	if(re)		rp <= #1 rp_pl1;

assign rp_pl1 = rp + { {aw{1'b0}}, 1'b1};

////////////////////////////////////////////////////////////////////
//
// Combinatorial Full & Empty Flags
//

assign empty = (wp == rp);
assign full  = (wp[aw-1:0] == rp[aw-1:0]) & (wp[aw] != rp[aw]);

////////////////////////////////////////////////////////////////////
//
// Registered Full & Empty Flags
//

always @(posedge clk)
	empty_r <= #1 (wp == rp) | (re & (wp == rp_pl1));

always @(posedge clk)
	full_r <= #1 ((wp[aw-1:0] == rp[aw-1:0]) & (wp[aw] != rp[aw])) |
	(we & (wp_pl1[aw-1:0] == rp[aw-1:0]) & (wp_pl1[aw] != rp[aw]));

////////////////////////////////////////////////////////////////////
//
// Combinatorial Full_n & Empty_n Flags
//

assign diff = wp-rp;
assign empty_n = diff < n;
assign full_n  = !(diff < (max_size-n+1));

always @(posedge clk)
	level <= #1 {2{diff[aw]}} | diff[aw-1:aw-2];

////////////////////////////////////////////////////////////////////
//
// Registered Full_n & Empty_n Flags
//

always @(posedge clk)
	re_r <= #1 re;

always @(posedge clk)
	diff_r <= #1 diff;

always @(posedge clk)
	empty_n_r <= #1 (diff_r < n) | ((diff_r==n) & (re | re_r));

always @(posedge clk)
	we_r <= #1 we;

always @(posedge clk)
	full_n_r <= #1 (diff_r > max_size-n) | ((diff_r==max_size-n) & (we | we_r));

////////////////////////////////////////////////////////////////////
//
// Sanity Check
//

// synopsys translate_off
always @(posedge clk)
	if(we & full)
		$display("%m WARNING: Writing while fifo is FULL (%t)",$time);

always @(posedge clk)
	if(re & empty)
		$display("%m WARNING: Reading while fifo is EMPTY (%t)",$time);
// synopsys translate_on

endmodule

