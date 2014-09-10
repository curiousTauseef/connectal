// bsv libraries
import SpecialFIFOs::*;
import Vector::*;
import StmtFSM::*;
import FIFO::*;

// portz libraries
import Directory::*;
import CtrlMux::*;
import Portal::*;
import Leds::*;
import PortalMemory::*;
import MemTypes::*;
import MemServer::*;
import MMU::*;

// generated by tool
import StrstrRequestWrapper::*;
import DmaDebugRequestWrapper::*;
import MMUConfigRequestWrapper::*;
import StrstrIndicationProxy::*;
import DmaDebugIndicationProxy::*;
import MMUConfigIndicationProxy::*;

// defined by user
import Strstr::*;

typedef enum {StrstrIndication, StrstrRequest, HostDmaDebugIndication, HostDmaDebugRequest, HostMMUConfigRequest, HostMMUConfigIndication} IfcNames deriving (Eq,Bits);
typedef 1 DegPar;


module mkPortalTop(StdPortalDmaTop#(PhysAddrWidth));

   StrstrIndicationProxy strstrIndicationProxy <- mkStrstrIndicationProxy(StrstrIndication);
   Strstr#(DegPar,64) strstr <- mkStrstr(strstrIndicationProxy.ifc);
   StrstrRequestWrapper strstrRequestWrapper <- mkStrstrRequestWrapper(StrstrRequest,strstr.request);
   
   let readClients = cons(strstr.config_read_client, cons(strstr.haystack_read_client,nil));
   MMUConfigIndicationProxy hostMMUConfigIndicationProxy <- mkMMUConfigIndicationProxy(HostMMUConfigIndication);
   MMU#(PhysAddrWidth) hostMMU <- mkMMU(0, True, hostMMUConfigIndicationProxy.ifc);
   MMUConfigRequestWrapper hostMMUConfigRequestWrapper <- mkMMUConfigRequestWrapper(HostMMUConfigRequest, hostMMU.request);

   DmaDebugIndicationProxy hostmemDmaDebugIndicationProxy <- mkDmaDebugIndicationProxy(HostDmaDebugIndication);
   MemServer#(PhysAddrWidth,64,1) dma <- mkMemServerR(hostmemDmaDebugIndicationProxy.ifc, readClients, cons(hostMMU,nil));
   DmaDebugRequestWrapper hostmemDmaDebugRequestWrapper <- mkDmaDebugRequestWrapper(HostDmaDebugRequest, dma.request);

   Vector#(6,StdPortal) portals;
   portals[0] = strstrRequestWrapper.portalIfc;
   portals[1] = strstrIndicationProxy.portalIfc; 
   portals[2] = hostmemDmaDebugRequestWrapper.portalIfc;
   portals[3] = hostmemDmaDebugIndicationProxy.portalIfc; 
   portals[4] = hostMMUConfigRequestWrapper.portalIfc;
   portals[5] = hostMMUConfigIndicationProxy.portalIfc;

   
   StdDirectory dir <- mkStdDirectory(portals);
   let ctrl_mux <- mkSlaveMux(dir,portals);
   
   interface interrupt = getInterruptVector(portals);
   interface slave = ctrl_mux;
   interface masters = dma.masters;
   interface leds = default_leds;
endmodule
