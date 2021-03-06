/* 
 * resample_codes.v
 * 
 * Copyright (c) 2007 Koen De Vleeschauwer. 
 * 
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND 
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE 
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS 
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY 
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF 
 * SUCH DAMAGE.
 */

/*
 * resample_codes - Resample codes. Used in fifo between resample_addr and resample_dta.
 */
  parameter [2:0]
    ROW_0_COL_0    = 3'b000,  // leftmost pixel on row 0 column 0 
    ROW_1_COL_0    = 3'b001,  // leftmost pixel on row 1 column 0
    ROW_X_COL_0    = 3'b010,  // leftmost pixel on column 0 on row > 1
    ROW_X_COL_X    = 3'b011,  // leftmost pixel on column > 1
    ROW_X_COL_LAST = 3'b100;  // rightmost pixel on last column

/* not truncated */
