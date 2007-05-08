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
    File:       ClientSession.h

    
*/

#ifndef __CLIENT_SESSION__
#define __CLIENT_SESSION__

#include "Task.h"
#include "TimeoutTask.h"

#include "RTSPClient.h"
#include "ClientSocket.h"
#include "SDPSourceInfo.h"
#include "UDPSocket.h"

class ClientSession : public Task
{
    public:
    
        enum
        {
            kRTSPUDPClientType          = 0,
            kRTSPTCPClientType          = 1,
            kRTSPHTTPClientType         = 2,
            kRTSPHTTPDropPostClientType = 3,
            kRTSPReliableUDPClientType  = 4
        };
        typedef UInt32 ClientType;
    
        ClientSession(  UInt32 inAddr, UInt16 inPort, char* inURL,
                        ClientType inClientType,
                        UInt32 inDurationInSec, UInt32 inStartPlayTimeInSec,
                        UInt32 inRTCPIntervalInSec, UInt32 inOptionsIntervalInSec,
                        UInt32 inHTTPCookie, Bool16 inAppendJunkData, UInt32 inReadInterval,
                        UInt32 inSockRcvBufSize, Float32 inLateTolerance, char* inMetaInfoFields,
                        Float32 inSpeed, Bool16 inVerbosePrinting, char* inPacketRangePlayHeader, UInt32 inOverbufferWindowSizeInK,
                        Bool16 sendOptions, Bool16 requestRandomData, SInt32 randomDataSize);

        virtual ~ClientSession();
        
        //
        // Signals.
        //
        // Send a kKillEvent to delete this object.
        // Send a kTeardownEvent to tell the object to send a TEARDOWN and abort
        
        enum
        {
            kTeardownEvent = 0x00000100
        };
        
        virtual SInt64 Run();
        
        //
        // States. Find out what the object is currently doing
        enum
        {
            kSendingOptions     = 0,
            kSendingDescribe    = 1,
            kSendingSetup       = 2,
            kSendingPlay        = 3,
            kPlaying            = 4,
            kSendingTeardown    = 5,
            kDone               = 6
        };
        //
        // Why did this session die?
        enum
        {
            kDiedNormally       = 0,    // Session went fine
            kTeardownFailed     = 1,    // Teardown failed, but session stats are all valid
            kRequestFailed      = 2,    // Session couldn't be setup because the server returned an error
            kBadSDP             = 3,    // Server sent back some bad SDP
            kSessionTimedout    = 4,    // Server not responding
            kConnectionFailed   = 5,    // Couldn't connect at all.
            kDiedWhilePlaying   = 6     // Connection was forceably closed while playing the movie
        };
        
        //
        // Once this client session is completely done with the TEARDOWN and ready to be
        // destructed, this will return true. Until it returns true, this object should not
        // be deleted. When it does return true, this object should be deleted.
        Bool16  IsDone()        { return fState == kDone; }
        
        //
        // ACCESSORS
    
        RTSPClient*             GetClient()         { return fClient; }
        ClientSocket*           GetSocket()         { return fSocket; }
        SDPSourceInfo*          GetSDPInfo()        { return &fSDPParser; }
        UInt32                  GetState()          { return fState; }
        
        // When this object is in the kDone state, this will tell you why the session died.
        UInt32                  GetReasonForDying() { return fDeathReason; }
        UInt32                  GetRequestStatus()  { return fClient->GetStatus(); }
        
        // Tells you the total time we were receiving packets. You can use this
        // for computing bit rate
        SInt64                  GetTotalPlayTimeInMsec() { return fTotalPlayTime; }
        
        QTSS_RTPPayloadType     GetTrackType(UInt32 inTrackIndex)
                                    { return fSDPParser.GetStreamInfo(inTrackIndex)->fPayloadType; }
        UInt32                  GetNumPacketsReceived(UInt32 inTrackIndex)
                                    { return fStats[inTrackIndex].fNumPacketsReceived; }
        UInt32                  GetNumBytesReceived(UInt32 inTrackIndex)
                                    { return fStats[inTrackIndex].fNumBytesReceived; }
        UInt32                  GetNumPacketsLost(UInt32 inTrackIndex)
                                    { return fStats[inTrackIndex].fNumLostPackets; }
        UInt32                  GetNumPacketsOutOfOrder(UInt32 inTrackIndex)
                                    { return fStats[inTrackIndex].fNumOutOfOrderPackets; }
        UInt32                  GetNumDuplicates(UInt32 inTrackIndex)
                                    { return fStats[inTrackIndex].fNumDuplicates; }
        UInt32                  GetNumAcks(UInt32 inTrackIndex)
                                    { return fStats[inTrackIndex].fNumAcks; }
                
        UInt32   GetSessionPacketsReceived()  { UInt32 result = fNumPacketsReceived; fNumPacketsReceived = 0; return result; }
        //
        // Global stats
        static UInt32   GetActiveConnections()          { return sActiveConnections; }
        static UInt32   GetPlayingConnections()         { return sPlayingConnections; }
        static UInt32   GetConnectionAttempts()         { return sTotalConnectionAttempts; }
        static UInt32   GetConnectionBytesReceived()    { UInt32 result = sBytesReceived; sBytesReceived = 0; return result; }
        static UInt32   GetConnectionPacketsReceived()  { UInt32 result = sPacketsReceived; sPacketsReceived = 0; return result; }
        
        
    private:
    
        enum
        {
            kRawRTSPControlType         = 0,
            kRTSPHTTPControlType        = 1,
            kRTSPHTTPDropPostControlType= 2
        };
        typedef UInt32 ControlType;
        
        enum
        {
            kUDPTransportType           = 0,
            kReliableUDPTransportType   = 1,
            kTCPTransportType           = 2
        };
        typedef UInt32 TransportType;
        
        ClientSocket*   fSocket;    // Connection object
        RTSPClient*     fClient;    // Manages the client connection
        SDPSourceInfo   fSDPParser; // Parses the SDP in the DESCRIBE response
        TimeoutTask     fTimeoutTask; // Kills this connection in the event the server isn't responding
        
        ControlType     fControlType;
        TransportType   fTransportType;
        UInt32          fDurationInSec;
        UInt32          fStartPlayTimeInSec;
        UInt32          fRTCPIntervalInSec;
        UInt32          fOptionsIntervalInSec;
        
        Bool16          fOptions;
        Bool16          fOptionsRequestRandomData;
        SInt32          fOptionsRandomDataSize;
        SInt64          fTransactionStartTimeMilli;

        UInt32          fState;     // For managing the state machine
        UInt32          fDeathReason;
        UInt32          fNumSetups;
        UDPSocket**     fUDPSocketArray;
        
        SInt64          fPlayTime;
        SInt64          fTotalPlayTime;
        SInt64          fLastRTCPTime;
        
        Bool16          fTeardownImmediately;
        Bool16          fAppendJunk;
        UInt32          fReadInterval;
        UInt32          fSockRcvBufSize;
        
        Float32         fSpeed;
        char*           fPacketRangePlayHeader;
        
        //
        // Client stats
        struct TrackStats
        {
            enum
            {
                kSeqNumMapSize = 100,
                kHalfSeqNumMap = 50
            };
        
            UInt16          fDestRTCPPort;
            UInt32          fNumPacketsReceived;
            UInt32          fNumBytesReceived;
            UInt32          fNumLostPackets;
            UInt32          fNumOutOfOrderPackets;
            UInt32          fNumThrownAwayPackets;
            UInt8           fSequenceNumberMap[kSeqNumMapSize];
            UInt16          fWrapSeqNum;
            UInt16          fLastSeqNum;
            UInt32          fSSRC;
            Bool16          fIsSSRCValid;
            
            UInt16          fHighestSeqNum;
            UInt16          fLastAckedSeqNum;
            Bool16          fHighestSeqNumValid;
            
            UInt32          fNumAcks;
            UInt32          fNumDuplicates;
            
        };
        TrackStats*         fStats;
        UInt32              fOverbufferWindowSizeInK;
        UInt32              fCurRTCPTrack;
        UInt32              fNumPacketsReceived;
        //
        // Global stats
        static UInt32           sActiveConnections;
        static UInt32           sPlayingConnections;
        static UInt32           sTotalConnectionAttempts;
        static UInt32           sBytesReceived;
        static UInt32           sPacketsReceived;
        //
        // Helper functions for Run()
        void    SetupUDPSockets();
        void    ProcessMediaPacket(char* inPacket, UInt32 inLength, UInt32 inTrackID, Bool16 isRTCP);
        OS_Error    ReadMediaData();
        OS_Error    SendReceiverReport(UInt32 inTrackID);
        void    AckPackets(UInt32 inTrackIndex, UInt16 inCurSeqNum, Bool16 inCurSeqNumValid);
};

#endif //__CLIENT_SESSION__
