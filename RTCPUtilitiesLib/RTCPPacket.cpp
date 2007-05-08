/*
 *
 * @APPLE_LICENSE_HEADER_START@
 * 
 * Copyright (c) 1999-2003 Apple Computer, Inc.  All Rights Reserved.
 * 
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this
 * file.
 * 
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 * 
 * @APPLE_LICENSE_HEADER_END@
 *
 */
/*
    File:       RTCPPacket.cpp

    Contains:   RTCPReceiverPacket de-packetizing classes
    
*/


#include "RTCPPacket.h"
#include "RTCPAckPacket.h"
#include "OS.h"
#include <stdio.h>


//returns true if successful, false otherwise
Bool16 RTCPPacket::ParsePacket(UInt8* inPacketBuffer, UInt32 inPacketLen)
{
    if (inPacketLen < kRTCPPacketSizeInBytes)
        return false;
    fReceiverPacketBuffer = inPacketBuffer;

    //the length of this packet can be no less than the advertised length (which is
    //in 32-bit words, so we must multiply) plus the size of the header (4 bytes)
    if (inPacketLen < (UInt32)((this->GetPacketLength() * 4) + kRTCPHeaderSizeInBytes))
        return false;
    
    //do some basic validation on the packet
    if (this->GetVersion() != kSupportedRTCPVersion)
        return false;
        
    return true;
}

void RTCPReceiverPacket::Dump()//Override
{
    RTCPPacket::Dump();
    
    for (int i = 0;i<this->GetReportCount(); i++)
    {
        qtss_printf( "   [%d] H_ssrc=%lu, H_frac_lost=%d, H_tot_lost=%lu, H_high_seq=%lu H_jit=%lu, H_last_sr_time=%lu, H_last_sr_delay=%lu \n",
                             i,
                             this->GetReportSourceID(i),
                             this->GetFractionLostPackets(i),
                             this->GetTotalLostPackets(i),
                             this->GetHighestSeqNumReceived(i),
                             this->GetJitter(i),
                             this->GetLastSenderReportTime(i),
                             this->GetLastSenderReportDelay(i) );
    }


}


Bool16 RTCPReceiverPacket::ParseReceiverReport(UInt8* inPacketBuffer, UInt32 inPacketLength)
{
    Bool16 ok = this->ParsePacket(inPacketBuffer, inPacketLength);
    if (!ok)
        return false;
    
    fRTCPReceiverReportArray = inPacketBuffer + kRTCPPacketSizeInBytes;
    
    //this is the maximum number of reports there could possibly be
    int theNumReports = (inPacketLength - kRTCPPacketSizeInBytes) / kReportBlockOffsetSizeInBytes;

    //if the number of receiver reports is greater than the theoretical limit, return an error.
    if (this->GetReportCount() > theNumReports)
        return false;
        
    return true;
}

UInt32 RTCPReceiverPacket::GetCumulativeFractionLostPackets()
{
    float avgFractionLost = 0;
    for (short i = 0; i < this->GetReportCount(); i++)
    {
        avgFractionLost += this->GetFractionLostPackets(i);
        avgFractionLost /= (i+1);
    }
    
    return (UInt32)avgFractionLost;
}


UInt32 RTCPReceiverPacket::GetCumulativeJitter()
{
    float avgJitter = 0;
    for (short i = 0; i < this->GetReportCount(); i++)
    {
        avgJitter += this->GetJitter(i);
        avgJitter /= (i + 1);
    }
    
    return (UInt32)avgJitter;
}


UInt32 RTCPReceiverPacket::GetCumulativeTotalLostPackets()
{
    UInt32 totalLostPackets = 0;
    for (short i = 0; i < this->GetReportCount(); i++)
    {
        totalLostPackets += this->GetTotalLostPackets(i);
    }
    
    return totalLostPackets;
}




void RTCPPacket::Dump()
{  
    qtss_printf( "H_vers=%d, H_pad=%d, H_rprt_count=%d, H_type=%d, H_length=%d, H_ssrc=%ld\n",
             this->GetVersion(),
             (int)this->GetHasPadding(),
             this->GetReportCount(),
             (int)this->GetPacketType(),
             (int)this->GetPacketLength(),
             this->GetPacketSSRC() );
}


