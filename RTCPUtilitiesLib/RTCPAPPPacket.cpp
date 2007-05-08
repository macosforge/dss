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
    File:       RTCPAPPPacket.cpp

    Contains:   RTCPAPPPacket de-packetizing classes

    
*/


#include "RTCPAPPPacket.h"
#include "MyAssert.h"
#include "OS.h"
#include "OSMemory.h"

Bool16 RTCPqtssPacket::ParseQTSSPacket(UInt8* inPacketBuffer, UInt32 inPacketLength)
{
    Bool16 ok = this->ParsePacket(inPacketBuffer, inPacketLength);
    if (!ok)
        return false;
    
    if (inPacketLength < (kRTCPPacketSizeInBytes + kQTSSDataOffset))
        return false;

    fRTCPAPPDataBuffer = inPacketBuffer+kRTCPPacketSizeInBytes;

    //figure out how many 32-bit words remain in the buffer
    UInt32 theMaxDataLen = (inPacketLength - kRTCPPacketSizeInBytes) - kQTSSDataOffset;
    theMaxDataLen /= 4;
    
    //if the number of 32 bit words reported in the packet is greater than the theoretical limit,
    //return an error
    if (this->GetAppPacketLength() > theMaxDataLen)
        return false;
        
    if (this->GetAppPacketVersion() != kSupportedQTSSVersion)
        return false;
    if (this->GetReportCount() > 0)
        return false;
        
    this->ParseAndStore();
    return true;
}



void RTCPqtssPacket::ParseAndStore()
{
    UInt8* qtssDataBuffer = fRTCPAPPDataBuffer+kQTSSDataOffset;
    
    int wordsRemaining = this->GetAppPacketLength();
    while ( wordsRemaining >= 2 )
    {
        UInt32 itemType = (UInt32) ntohl(*(UInt32*)&qtssDataBuffer[kQTSSItemTypeOffset]);
        qtssDataBuffer += sizeof(itemType);
        
        //UInt16 itemVersion = (UInt16) ( (ntohl(*(UInt32*)&qtssDataBuffer[kQTSSItemVersionOffset]) & kQTSSItemVersionMask) >> kQTSSItemVersionShift );
        UInt16 itemLengthInWords = (UInt16) ( (ntohl(*(UInt32*)&qtssDataBuffer[kQTSSItemLengthOffset]) & kQTSSItemLengthMask) );
        qtssDataBuffer += sizeof(UInt32);   //advance past the above UInt16's
        
        wordsRemaining -= (2 + itemLengthInWords ); //length of "item header" + length of data
        
        switch (itemType)
        {
            case FOUR_CHARS_TO_INT('r', 'r', 'c', 'v'): //rrcv
            {
                fReceiverBitRate = (UInt32) ntohl(*(UInt32*)&qtssDataBuffer);
                qtssDataBuffer += sizeof(fReceiverBitRate);
            }
            break;
            
            case FOUR_CHARS_TO_INT('l', 'a', 't', 'e'): //late
            {
                fAverageLateMilliseconds = (UInt32) ntohl(*(UInt32*)&qtssDataBuffer);
                qtssDataBuffer += sizeof(fAverageLateMilliseconds);
            }
            break;
            
            case FOUR_CHARS_TO_INT('l', 'o', 's', 's'): //loss
            {
                fPercentPacketsLost = (UInt32) ntohl(*(UInt32*)&qtssDataBuffer);
                qtssDataBuffer += sizeof(fPercentPacketsLost);
            }
            break;
            
            case FOUR_CHARS_TO_INT('b', 'd', 'l', 'y'): //bdly
            {
                fAverageBufferDelayMilliseconds = (UInt32) ntohl(*(UInt32*)&qtssDataBuffer);
                qtssDataBuffer += sizeof(fAverageBufferDelayMilliseconds);
            }
            break;
            
            case FOUR_CHARS_TO_INT(':', '|', ':', '('): //:|:(
            {
                fIsGettingBetter = true;
            }
            break;
            
            case FOUR_CHARS_TO_INT(':', '|', ':', ')'): //:|:)
            {
                fIsGettingWorse = true;
            }
            break;
            
            case FOUR_CHARS_TO_INT('e', 'y', 'e', 's'): //eyes
            {
                fNumEyes = (UInt32) ntohl(*(UInt32*)&qtssDataBuffer);
                qtssDataBuffer += sizeof(fNumEyes);
                if (itemLengthInWords >= 2)
                {
                    fNumEyesActive = (UInt32) ntohl(*(UInt32*)&qtssDataBuffer);
                    qtssDataBuffer += sizeof(fNumEyesActive);
                }
                if (itemLengthInWords >= 3)
                {
                    fNumEyesPaused = (UInt32) ntohl(*(UInt32*)&qtssDataBuffer);
                    qtssDataBuffer += sizeof(fNumEyesPaused);
                }
            }
            break;
            
            case FOUR_CHARS_TO_INT('p', 'r', 'c', 'v'): //prcv
            {
                fTotalPacketsReceived = (UInt32) ntohl(*(UInt32*)&qtssDataBuffer);
                qtssDataBuffer += sizeof(fTotalPacketsReceived);
            }
            break;
            
            case FOUR_CHARS_TO_INT('p', 'd', 'r', 'p'): //pdrp
            {
                fTotalPacketsDropped = (UInt32) ntohl(*(UInt32*)&qtssDataBuffer);
                qtssDataBuffer += sizeof(fTotalPacketsDropped);
            }
            break;
            
            
            case FOUR_CHARS_TO_INT('b', 'u', 'f', 'l'): //bufl
            {
                fClientBufferFill = (UInt32) ntohl(*(UInt32*)&qtssDataBuffer);
                qtssDataBuffer += sizeof(fClientBufferFill);
            }
            break;
            
            
            case FOUR_CHARS_TO_INT('f', 'r', 'a', 't'): //frat
            {
                fFrameRate = (UInt32) ntohl(*(UInt32*)&qtssDataBuffer);
                qtssDataBuffer += sizeof(fFrameRate);
            }
            break;
            
            
            case FOUR_CHARS_TO_INT('x', 'r', 'a', 't'): //xrat
            {
                fExpectedFrameRate = (UInt32) ntohl(*(UInt32*)&qtssDataBuffer);
                qtssDataBuffer += sizeof(fExpectedFrameRate);
            }
            break;
            
            
            case FOUR_CHARS_TO_INT('d', 'r', 'y', '#'): //dry#
            {
                fAudioDryCount = (UInt32) ntohl(*(UInt32*)&qtssDataBuffer);
                qtssDataBuffer += sizeof(fAudioDryCount);
            }
            break;
            
            default:
                //ASSERT?
            break;
        }
    }
}



RTCPCompressedQTSSPacket::RTCPCompressedQTSSPacket(Bool16 debug) :
    RTCPPacket(),
    mDumpArray(NULL),
    fDebug(debug),
    fRTCPAPPDataBuffer(NULL),
    
    fReceiverBitRate(0),
    fAverageLateMilliseconds(0),
    fPercentPacketsLost(0),
    fAverageBufferDelayMilliseconds(0),
    fIsGettingBetter(false),
    fIsGettingWorse(false),
    fNumEyes(0),
    fNumEyesActive(0),
    fNumEyesPaused(0),
	fOverbufferWindowSize(kUInt32_Max),
    
    //Proposed - are these there yet?
    fTotalPacketsReceived(0),
    fTotalPacketsDropped(0),
    fTotalPacketsLost(0),
    fClientBufferFill(0),
    fFrameRate(0),
    fExpectedFrameRate(0),
    fAudioDryCount(0)
{
    if (fDebug)
    {
       mDumpArray = NEW char[1024];
       mDumpArray[0] = '\0';
       mDumpArrayStrDeleter.Set(mDumpArray);
    }
}

Bool16 RTCPCompressedQTSSPacket::ParseCompressedQTSSPacket(UInt8* inPacketBuffer, UInt32 inPacketLength)
{
    if (!this->ParsePacket(inPacketBuffer, inPacketLength))
        return false;
    
    if (inPacketLength < (kRTCPPacketSizeInBytes + kQTSSDataOffset))
        return false;

    fRTCPAPPDataBuffer = inPacketBuffer+kRTCPPacketSizeInBytes;

    //figure out how many 32-bit words remain in the buffer
    UInt32 theMaxDataLen = (inPacketLength - kRTCPPacketSizeInBytes) - kQTSSDataOffset;
    theMaxDataLen /= 4;
    
    //if the number of 32 bit words reported in the packet is greater than the theoretical limit,
    //return an error
    if (this->GetAppPacketLength() > theMaxDataLen)
        return false;
        
    if (this->GetAppPacketVersion() != kSupportedCompressedQTSSVersion)
        return false;
        
    if (this->GetReportCount() > 0)
        return false;
        
    this->ParseAndStore();
    return true;
}


void RTCPCompressedQTSSPacket::ParseAndStore()
{
#define APPEND_TO_DUMP_ARRAY(f, v) {if (fDebug) (void)qtss_sprintf(&mDumpArray[strlen(mDumpArray)], f, v);}

    FourCharCode appName = this->GetAppPacketName();
    APPEND_TO_DUMP_ARRAY("       H_app_packet_name = %.4s, ", (char*)&appName);
    APPEND_TO_DUMP_ARRAY("H_src_ID = %lu, ", this->GetReportSourceID());
    APPEND_TO_DUMP_ARRAY("H_vers=%d, ", this->GetAppPacketVersion());
    APPEND_TO_DUMP_ARRAY("H_packt_len=%d", this->GetAppPacketLength());

    UInt8* qtssDataBuffer = fRTCPAPPDataBuffer+kQTSSDataOffset;
    
    //packet length is given in words
    UInt32 bytesRemaining = this->GetAppPacketLength() * 4;
    while ( bytesRemaining >= 4 ) //items must be at least 32 bits
    {
        // DMS - There is no guarentee that qtssDataBuffer will be 4 byte aligned, because
        // individual APP packet fields can be 6 bytes or 4 bytes or 8 bytes. So we have to
        // use the 4-byte align protection functions. Sparc and MIPS processors will crash otherwise
        UInt32 theHeader = ntohl(OS::GetUInt32FromMemory((UInt32*)&qtssDataBuffer[kQTSSItemTypeOffset]));
        UInt16 itemType = (UInt16)((theHeader & kQTSSItemTypeMask) >> kQTSSItemTypeShift);
        UInt8 itemLengthInBytes = (UInt8)(theHeader & kQTSSItemLengthMask);

        APPEND_TO_DUMP_ARRAY("\n       H_type=%.2s(", (char*)&itemType);
//      APPEND_TO_DUMP_ARRAY("vers=%u", itemVersion);
        APPEND_TO_DUMP_ARRAY(", H_size=%u", itemLengthInBytes);

        qtssDataBuffer += sizeof(UInt32);   //advance past the above UInt16's & UInt8's (point it at the actual item data)
        
        //Update bytesRemaining (move it past current item)
        //This itemLengthInBytes is part of the packet and could therefore be bogus.
        //Make sure not to overstep the end of the buffer!
        bytesRemaining -= sizeof(UInt32);
        if (itemLengthInBytes > bytesRemaining)
            break; //don't walk off the end of the buffer
            //itemLengthInBytes = bytesRemaining;
        bytesRemaining -= itemLengthInBytes;
        
        switch (itemType)
        {
            case  TW0_CHARS_TO_INT( 'r', 'r' ): //'rr': //'rrcv':
            {
                fReceiverBitRate = ntohl(OS::GetUInt32FromMemory((UInt32*)qtssDataBuffer));
                qtssDataBuffer += sizeof(fReceiverBitRate);
                APPEND_TO_DUMP_ARRAY(", rcvr_bit_rate=%lu", fReceiverBitRate);
            }
            break;
            
            case TW0_CHARS_TO_INT('l', 't'): //'lt':    //'late':
            {
                fAverageLateMilliseconds = ntohs(*(UInt16*)qtssDataBuffer);
                qtssDataBuffer += sizeof(fAverageLateMilliseconds);
                APPEND_TO_DUMP_ARRAY(", avg_late=%u", fAverageLateMilliseconds);
            }
            break;
            
            case TW0_CHARS_TO_INT('l', 's'): // 'ls':   //'loss':
            {
                fPercentPacketsLost = ntohs(*(UInt16*)qtssDataBuffer);
                qtssDataBuffer += sizeof(fPercentPacketsLost);
                APPEND_TO_DUMP_ARRAY(", percent_loss=%u", fPercentPacketsLost);
            }
            break;
            
            case TW0_CHARS_TO_INT('d', 'l'): //'dl':    //'bdly':
            {
                fAverageBufferDelayMilliseconds = ntohs(*(UInt16*)qtssDataBuffer);
                qtssDataBuffer += sizeof(fAverageBufferDelayMilliseconds);
                APPEND_TO_DUMP_ARRAY(", avg_buf_delay=%u", fAverageBufferDelayMilliseconds);
            }
            break;
            
            case TW0_CHARS_TO_INT(':', ')' ): //':)':   //':|:(':
            {
                fIsGettingBetter = true;
                APPEND_TO_DUMP_ARRAY(", :|:(=%s","yes");
            }
            break;
            
            case TW0_CHARS_TO_INT(':', '(' ): // ':(':  //':|:)':
            {
                fIsGettingWorse = true;
                APPEND_TO_DUMP_ARRAY(", :|:)=%s","yes");
            }
            break;
            
            case TW0_CHARS_TO_INT('e', 'y' ): //'ey':   //'eyes':
            {
                fNumEyes = ntohl(OS::GetUInt32FromMemory((UInt32*)qtssDataBuffer));
                qtssDataBuffer += sizeof(fNumEyes);             
                APPEND_TO_DUMP_ARRAY(", eyes=%lu", fNumEyes);

                if (itemLengthInBytes >= 2)
                {
                    fNumEyesActive = ntohl(OS::GetUInt32FromMemory((UInt32*)qtssDataBuffer));
                    qtssDataBuffer += sizeof(fNumEyesActive);
                    APPEND_TO_DUMP_ARRAY(", eyes_actv=%lu", fNumEyesActive);
                }
                if (itemLengthInBytes >= 3)
                {
                    fNumEyesPaused = ntohl(OS::GetUInt32FromMemory((UInt32*)qtssDataBuffer));
                    qtssDataBuffer += sizeof(fNumEyesPaused);
                    APPEND_TO_DUMP_ARRAY(", eyes_pausd=%lu", fNumEyesPaused);
                }
            }
            break;
            
            case TW0_CHARS_TO_INT('p', 'r' ): // 'pr':  //'prcv':
            {
                fTotalPacketsReceived = ntohl(OS::GetUInt32FromMemory((UInt32*)qtssDataBuffer));
                qtssDataBuffer += sizeof(fTotalPacketsReceived);
                APPEND_TO_DUMP_ARRAY(", pckts_rcvd=%lu", fTotalPacketsReceived);
            }
            break;
            
            case TW0_CHARS_TO_INT('p', 'd'): //'pd':    //'pdrp':
            {
                fTotalPacketsDropped = ntohs(*(UInt16*)qtssDataBuffer);
                qtssDataBuffer += sizeof(fTotalPacketsDropped);
                APPEND_TO_DUMP_ARRAY(", pckts_drppd=%u", fTotalPacketsDropped);
            }
            break;
            
            case TW0_CHARS_TO_INT('p', 'l'): //'pl':    //'p???':
            {
                fTotalPacketsLost = ntohs(*(UInt16*)qtssDataBuffer);
                qtssDataBuffer += sizeof(fTotalPacketsLost);
                APPEND_TO_DUMP_ARRAY(", ttl_pckts_lost=%u", fTotalPacketsLost);
            }
            break;
            
            
            case TW0_CHARS_TO_INT('b', 'l'): //'bl':    //'bufl':
            {
                fClientBufferFill = ntohs(*(UInt16*)qtssDataBuffer);
                qtssDataBuffer += sizeof(fClientBufferFill);
                APPEND_TO_DUMP_ARRAY(", buffr_fill=%u", fClientBufferFill);
            }
            break;
            
            
            case TW0_CHARS_TO_INT('f', 'r'): //'fr':    //'frat':
            {
                fFrameRate = ntohs(*(UInt16*)qtssDataBuffer);
                qtssDataBuffer += sizeof(fFrameRate);
                APPEND_TO_DUMP_ARRAY(", frame_rate=%u", fFrameRate);
            }
            break;
            
            
            case TW0_CHARS_TO_INT('x', 'r'): //'xr':    //'xrat':
            {
                fExpectedFrameRate = ntohs(*(UInt16*)qtssDataBuffer);
                qtssDataBuffer += sizeof(fExpectedFrameRate);
                APPEND_TO_DUMP_ARRAY(", xpectd_frame_rate=%u", fExpectedFrameRate);
            }
            break;
            
            
            case TW0_CHARS_TO_INT('d', '#'): //'d#':    //'dry#':
            {
                fAudioDryCount = ntohs(*(UInt16*)qtssDataBuffer);
                qtssDataBuffer += sizeof(fAudioDryCount);
                APPEND_TO_DUMP_ARRAY(", aud_dry_count=%u", fAudioDryCount);
            }
            break;
            
            case TW0_CHARS_TO_INT('o', 'b'): //'ob': // overbuffer window size
            {
                fOverbufferWindowSize = ntohl(OS::GetUInt32FromMemory((UInt32*)qtssDataBuffer));
                qtssDataBuffer += sizeof(fOverbufferWindowSize);
                APPEND_TO_DUMP_ARRAY(", ovr_buffr_windw_siz=%lu", fOverbufferWindowSize);
            }
            break;
            
            default:
            {
                if (fDebug)
		{
		   char s[12] = "";
                   qtss_sprintf(s, "  [%.2s]", (char*)&itemType);
                   WarnV(false, "Unknown APP('QTSS') item type");
                   WarnV(false, s);
            	}
	    }

            break;
        }   //      switch (itemType)

        
        APPEND_TO_DUMP_ARRAY("%s", "),  ");

    }   //while ( bytesRemaining >= 4 )

}

void RTCPCompressedQTSSPacket::Dump()//Override
{
    RTCPPacket::Dump();

    qtss_printf("%s \n", mDumpArray);
}



