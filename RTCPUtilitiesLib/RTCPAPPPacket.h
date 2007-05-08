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
    File:       RTCPAPPPacket.h

    Contains:   RTCPAPPPacket de-packetizing classes


    
*/

#ifndef _RTCPAPPPACKET_H_
#define _RTCPAPPPACKET_H_

#include "RTCPPacket.h"
#include "StrPtrLen.h"


/****** RTCPCompressedQTSSPacket is the packet type that the client actually sends ******/
class RTCPCompressedQTSSPacket : public RTCPPacket
{
public:

    RTCPCompressedQTSSPacket(Bool16 debug = false);
    virtual ~RTCPCompressedQTSSPacket() {}
    
    //Call this before any accessor method. Returns true if successful, false otherwise
    Bool16 ParseCompressedQTSSPacket(UInt8* inPacketBuffer, UInt32 inPacketLength);

    inline UInt32 GetReportSourceID();
    inline UInt16 GetAppPacketVersion();
    inline UInt16 GetAppPacketLength(); //In 'UInt32's
    inline FourCharCode GetAppPacketName();
    
    inline UInt32 GetReceiverBitRate() {return fReceiverBitRate;}
    inline UInt16 GetAverageLateMilliseconds()  {return fAverageLateMilliseconds;}
    inline UInt16 GetPercentPacketsLost()   {return fPercentPacketsLost;}
    inline UInt16 GetAverageBufferDelayMilliseconds()   {return fAverageBufferDelayMilliseconds;}
    inline Bool16 GetIsGettingBetter()  {return fIsGettingBetter;}
    inline Bool16 GetIsGettingWorse()   {return fIsGettingWorse;}
    inline UInt32 GetNumEyes()  {return fNumEyes;}
    inline UInt32 GetNumEyesActive()    {return fNumEyesActive;}
    inline UInt32 GetNumEyesPaused()    {return fNumEyesPaused;}
    inline UInt32 GetOverbufferWindowSize() {return fOverbufferWindowSize;}
    
    //Proposed - are these there yet?
    inline UInt32 GetTotalPacketReceived()  {return fTotalPacketsReceived;}
    inline UInt16 GetTotalPacketsDropped()  {return fTotalPacketsDropped;}
    inline UInt16 GetTotalPacketsLost() {return fTotalPacketsLost;}
    inline UInt16 GetClientBufferFill() {return fClientBufferFill;}
    inline UInt16 GetFrameRate()    {return fFrameRate;}
    inline UInt16 GetExpectedFrameRate()    {return fExpectedFrameRate;}
    inline UInt16 GetAudioDryCount()    {return fAudioDryCount;}
    
    virtual void Dump(); //Override
    inline UInt8* GetRTCPAPPDataBuffer()    {return fRTCPAPPDataBuffer;}

private:
    char*           mDumpArray;
    StrPtrLenDel    mDumpArrayStrDeleter; 
    Bool16 fDebug;
    UInt8* fRTCPAPPDataBuffer;  //points into fReceiverPacketBuffer

    void ParseAndStore();
    
    UInt32 fReceiverBitRate;
    UInt16 fAverageLateMilliseconds;
    UInt16 fPercentPacketsLost;
    UInt16 fAverageBufferDelayMilliseconds;
    Bool16 fIsGettingBetter;
    Bool16 fIsGettingWorse;
    UInt32 fNumEyes;
    UInt32 fNumEyesActive;
    UInt32 fNumEyesPaused;
    UInt32 fOverbufferWindowSize;
    
    //Proposed - are these there yet?
    UInt32 fTotalPacketsReceived;
    UInt16 fTotalPacketsDropped;
    UInt16 fTotalPacketsLost;
    UInt16 fClientBufferFill;
    UInt16 fFrameRate;
    UInt16 fExpectedFrameRate;
    UInt16 fAudioDryCount;
    
    enum
    {
        kAppNameOffset = 0, //four App identifier               //All are UInt32
        kReportSourceIDOffset = 4,  //SSRC for this report
        kAppPacketVersionOffset = 8,
            kAppPacketVersionMask = 0xFFFF0000UL,
            kAppPacketVersionShift = 16,
        kAppPacketLengthOffset = 8,
            kAppPacketLengthMask = 0x0000FFFFUL,
        kQTSSDataOffset = 12,
    
    //Individual item offsets/masks
        kQTSSItemTypeOffset = 0,    //SSRC for this report
            kQTSSItemTypeMask = 0xFFFF0000UL,
            kQTSSItemTypeShift = 16,
        kQTSSItemVersionOffset = 0,
            kQTSSItemVersionMas = 0x0000FF00UL,
            kQTSSItemVersionShift = 8,
        kQTSSItemLengthOffset = 0,
            kQTSSItemLengthMask = 0x000000FFUL,
        kQTSSItemDataOffset = 4,
    
        kSupportedCompressedQTSSVersion = 0
    };
    
    //version we support currently


};

/****** RTCPqtssPacket is apparently no longer sent by the client ******/
class RTCPqtssPacket : public RTCPPacket
{
public:
    
    RTCPqtssPacket() : RTCPPacket(), fRTCPAPPDataBuffer(NULL) {}
    virtual ~RTCPqtssPacket() {}
    
    //Call this before any accessor method. Returns true if successful, false otherwise
    Bool16 ParseQTSSPacket(UInt8* inPacketBuffer, UInt32 inPacketLength);

    inline UInt32 GetReportSourceID();
    inline UInt16 GetAppPacketVersion();
    inline UInt16 GetAppPacketLength(); //In 'UInt32's
    
    inline UInt32 GetReceiverBitRate() {return fReceiverBitRate;}
    inline UInt32 GetAverageLateMilliseconds()  {return fAverageLateMilliseconds;}
    inline UInt32 GetPercentPacketsLost()   {return fPercentPacketsLost;}
    inline UInt32 GetAverageBufferDelayMilliseconds()   {return fAverageBufferDelayMilliseconds;}
    inline Bool16 GetIsGettingBetter()  {return fIsGettingBetter;}
    inline Bool16 GetIsGettingWorse()   {return fIsGettingWorse;}
    inline UInt32 GetNumEyes()  {return fNumEyes;}
    inline UInt32 GetNumEyesActive()    {return fNumEyesActive;}
    inline UInt32 GetNumEyesPaused()    {return fNumEyesPaused;}
    
    //Proposed - are these there yet?
    inline UInt32 GetTotalPacketReceived()  {return fTotalPacketsReceived;}
    inline UInt32 GetTotalPacketsDropped()  {return fTotalPacketsDropped;}
    inline UInt32 GetClientBufferFill() {return fClientBufferFill;}
    inline UInt32 GetFrameRate()    {return fFrameRate;}
    inline UInt32 GetExpectedFrameRate()    {return fExpectedFrameRate;}
    inline UInt32 GetAudioDryCount()    {return fAudioDryCount;}

    
private:
    UInt8* fRTCPAPPDataBuffer;  //points into fReceiverPacketBuffer

    void ParseAndStore();

    UInt32 fReportSourceID;
    UInt16 fAppPacketVersion;
    UInt16 fAppPacketLength;    //In 'UInt32's
    
    UInt32 fReceiverBitRate;
    UInt32 fAverageLateMilliseconds;
    UInt32 fPercentPacketsLost;
    UInt32 fAverageBufferDelayMilliseconds;
    Bool16 fIsGettingBetter;
    Bool16 fIsGettingWorse;
    UInt32 fNumEyes;
    UInt32 fNumEyesActive;
    UInt32 fNumEyesPaused;
    
    //Proposed - are these there yet?
    UInt32 fTotalPacketsReceived;
    UInt32 fTotalPacketsDropped;
    UInt32 fClientBufferFill;
    UInt32 fFrameRate;
    UInt32 fExpectedFrameRate;
    UInt32 fAudioDryCount;
    
    enum
    {
        //THESE SHIFTS DO NOT WORK ON LITTLE-ENDIAN PLATFORMS! I HAVEN'T FIXED
        //THIS BECAUSE THIS PACKET IS NO LONGER USED...
        
        kAppNameOffset = 0, //four App identifier           //All are UInt32s
        kReportSourceIDOffset = 4,  //SSRC for this report
        kAppPacketVersionOffset = 8,
            kAppPacketVersionMask = 0xFFFF0000UL,
            kAppPacketVersionShift = 16,
        kAppPacketLengthOffset = 8,
            kAppPacketLengthMask = 0x0000FFFFUL,
        kQTSSDataOffset = 12,
    
        //Individual item offsets/masks
        kQTSSItemTypeOffset = 0,    //SSRC for this report
        kQTSSItemVersionOffset = 4,
            kQTSSItemVersionMask = 0xFFFF0000UL,
            kQTSSItemVersionShift = 16,
        kQTSSItemLengthOffset = 4,
            kQTSSItemLengthMask = 0x0000FFFFUL,
        kQTSSItemDataOffset = 8,

        //version we support currently
        kSupportedQTSSVersion = 0
    };
    

};


/****************  RTCPCompressedQTSSPacket inlines *******************************/
inline UInt32 RTCPCompressedQTSSPacket::GetReportSourceID()
{
 return (UInt32) ntohl(*(UInt32*)&fRTCPAPPDataBuffer[kReportSourceIDOffset]) ;
}


inline UInt16 RTCPCompressedQTSSPacket::GetAppPacketVersion()
{
 return (UInt16) ( (ntohl(*(UInt32*)&fRTCPAPPDataBuffer[kAppPacketVersionOffset]) & kAppPacketVersionMask) >> kAppPacketVersionShift );
}

inline FourCharCode RTCPCompressedQTSSPacket::GetAppPacketName()
{
 return (UInt32) ntohl(*(UInt32*)&fRTCPAPPDataBuffer[kAppNameOffset]) ;
}


inline UInt16 RTCPCompressedQTSSPacket::GetAppPacketLength()
{
    return (UInt16) (ntohl(*(UInt32*)&fRTCPAPPDataBuffer[kAppPacketLengthOffset]) & kAppPacketLengthMask);
}

/****************  RTCPqtssPacket inlines *******************************/
inline UInt32 RTCPqtssPacket::GetReportSourceID()
{
 return (UInt32) ntohl(*(UInt32*)&fRTCPAPPDataBuffer[kReportSourceIDOffset]) ;
}


inline UInt16 RTCPqtssPacket::GetAppPacketVersion()
{
 return (UInt16) ( (ntohl(*(UInt32*)&fRTCPAPPDataBuffer[kAppPacketVersionOffset]) & kAppPacketVersionMask) >> kAppPacketVersionShift );
}

inline UInt16 RTCPqtssPacket::GetAppPacketLength()
{
    return (UInt16) (ntohl(*(UInt32*)&fRTCPAPPDataBuffer[kAppPacketLengthOffset]) & kAppPacketLengthMask);
}

/*
6.6 APP: Application-defined RTCP packet

    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |V=2|P| subtype |   PT=APP=204  |             length            |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                           SSRC/CSRC                           |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                          name (ASCII)                         |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                   application-dependent data                  |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   
 */

#endif //_RTCPAPPPACKET_H_
