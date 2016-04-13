// Copyright (c) 2014 Quanta Research Cambridge, Inc.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import BuildVector::*;
import Clocks::*;
import ClientServer::*;
import Connectable::*;
import Gearbox::*;
import GetPut::*;
import RS232::*;
import Vector::*;

import Pipe::*;
import Portal::*;
import SharedMemoryPortal::*;

import SerialPortalIfc::*;
import Echo::*;
import EchoRequest::*;
import EchoIndication::*;

interface SerialPortalTest;
   interface SerialPortalRequest request;
   interface EchoIndication echoIndication;
   interface SerialPortalPins    pins;
endinterface

module mkSerialPortalTest#(SerialPortalIndication indication, EchoRequest echoRequest)(SerialPortalTest);

   let clock <- exposeCurrentClock();
   let reset <- exposeCurrentReset();

   // 250MHz clock
   //   9600 baud: divisor=26042
   // 115200 baud: divisor=134
   Reg#(Bit#(16)) divisor <- mkReg(134);
   UART#(16) uart <- mkUART(8, EVEN, STOP_1, divisor);

   SerialPortalPipeOut#(3) serialEchoRequestPipe <- mkSerialPortalPipeOut(); // why the asymmetry?
   let echoRequestInput <- mkEchoRequestInput();
   mkConnection(echoRequestInput.pipes, echoRequest);
   mkConnection(uart.tx, toPut(serialEchoRequestPipe.inputPipe));
   mkConnection(serialEchoRequestPipe.data, echoRequestInput.portalIfc.requests);

   let echoIndicationOutput <- mkEchoIndicationOutput;
   Vector#(2,PipeOut#(Bit#(32))) echoIndicationPipes <- genWithM(mkFramedIndicationPipe(echoIndicationOutput.portalIfc,
											getEchoIndicationMessageSize));
   PipeOut#(Bit#(8)) serialEchoIndicationPipe <- mkSerialPortalPipeIn(echoIndicationPipes);
   //mkConnection(toGet(serialEchoIndicationPipe), uart.rx);
   rule rl_rx;
      let char <- toGet(serialEchoIndicationPipe).get();
      uart.rx.put(char);
      indication.rx(char);
   endrule

   interface SerialPortalRequest request;
      method Action setDivisor(Bit#(16) d);
	 divisor <= d;
      endmethod
   endinterface
   interface EchoIndication echoIndication = echoIndicationOutput.ifc;
   interface SerialPortalPins pins;
      interface uart = uart.rs232;
      interface deleteme_unused_clock = clock;
   endinterface
endmodule