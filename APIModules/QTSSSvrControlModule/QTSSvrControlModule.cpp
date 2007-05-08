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
    File:       QTSSvrControlModule.cpp

    Contains:   Implementation of module described in QTSSvrControlModule.h

    
*/

#include <stdlib.h>
#include "SafeStdLib.h"
#include <string.h>
#include <stdio.h>
#include <time.h>

extern "C" {
#import <mach/mach.h>
#import <mach/cthreads.h>
#import <mach/message.h>
#import <servers/bootstrap.h>
#import <mach/mach_error.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <unistd.h>
#import "QTSCRPI.h"
}

#include "ServerControlAPI.h"
#include "QTSSvrControlModule.h"
#include "QTSSModuleUtils.h"

#include "SCRPITypes.h"
#include "OSMutex.h"
#include "OSMemory.h"
#include "MyAssert.h"
#include "StrPtrLen.h"
#include "StringParser.h"

// SERVER CONTROL THREAD CLASS DEFINITION

class QTSSvrControlThread
{
    public:

        QTSSvrControlThread();
        virtual ~QTSSvrControlThread();
        
        //This thread can encounter errors as it starts up.
        //Check this after calling the constructor
        Bool16  HasErrorOccurred() { return fErrorOccurred; }
    
    private:
    
        void Entry();
        void HistoryEntry();
        static void _Entry(QTSSvrControlThread *thread);
        static void _HistoryEntry(QTSSvrControlThread *thread);
        
        port_t fMessagePort;
        
        //thread related
        cthread_t       fThreadID;
        cthread_t       fHistoryThreadID;
        Bool16          fDone;
        Bool16          fErrorOccurred;
        Bool16          fDoneStartingUp;
        Bool16          fThreadsAllocated;
};


// STATIC DATA

static OSMutex*             sHistoryMutex = NULL;
static QTSSvrControlThread* sThread = NULL;
static UInt32               sCursor = 0;//where do we write next into the history array?
        
//for Server History stuff.
static long                 sBandwidthLo = -1;
static long                 sBandwidthHi = 0;
static long                 sBandwidthAvg = 0;
static long                 sConnectionLo = -1;
static long                 sConnectionHi = 0;
static long                 sConnectionAvg = 0;
static long                 sSampleIndex = 0;
static QTSServerHistoryRec  sHistoryArray = {};
        
static time_t               sStartupTime = 0;
static Bool16                   sGracefulShutdownInProgress = false;

static UInt32               sHistoryIntervalInSecs = 0;
static UInt32               sDefaultHistoryIntervalInSecs = 120;
    
static char*                sAttributeBuffer = NULL;

// DICTIONARIES
static QTSS_ServerObject            sServer = NULL;
static QTSS_ModulePrefsObject       sPrefs = NULL;

// SERVICES
static QTSS_ServiceID           sRereadPreferences  = qtssIllegalServiceID;
static QTSS_ServiceID           sRollAccessLog      = qtssIllegalServiceID;
static QTSS_ServiceID           sRollErrorLog       = qtssIllegalServiceID;

// ATTRIBUTES
static QTSS_AttributeID         sCantRegisterErr        = qtssIllegalAttrID;
static QTSS_AttributeID         sCantAllocateErr        = qtssIllegalAttrID;
static QTSS_AttributeID         sFatalErr               = qtssIllegalAttrID;

static const UInt32             kNumSamplesPerEntry = 30;


// FUNCTIONS
static QTSS_Error   QTSSvrControlModuleDispatch(QTSS_Role inRole, QTSS_RoleParamPtr inParams);
static QTSS_Error   Register(QTSS_Register_Params* inParams);
static QTSS_Error Initialize(QTSS_Initialize_Params* inParams);
static QTSS_Error Shutdown();
static kern_return_t StopServer(int inMinutes);
static kern_return_t CancelStopServer();
static void CheckShutdown();
static kern_return_t SetServerAttribute(AttributeType attrib, UInt32 /*tagSize*/,
                                            void* /*tags*/, unsigned int bufSize, void* buffer);
static kern_return_t GetServerAttribute(AttributeType attrib, UInt32 /*tagSize*/,
                                            void* /*tags*/, unsigned int bufSize,
                                            unsigned int* attribSize, void** buffer);
static kern_return_t RereadPreferences();
static kern_return_t RollLogNow(QTSLogRollRec* theRollLogRec);
static kern_return_t GetProcessInfo(QTSProcessInfoRec* inProcessInfo);
static kern_return_t GetServerName(QTSServerDNSName* outServerName);
static kern_return_t GetServerVersion(QTSServerVersionRec* outServerVersion);
static kern_return_t GetServerStatusRec(QTSServerStatusRec* outServerStatus);
static kern_return_t GetRefuseConnections(QTSRefuseConnectionsRec* outRefuseConnections);
static kern_return_t SetRefuseConnections(QTSRefuseConnectionsRec* inRefuseConnections);
static kern_return_t GetHistory(QTSServerHistoryRec* outHistory);
static void AddHistorySample();
static void UpdateHistoryArray();


// FUNCTION IMPLEMENTATIONS

QTSS_Error QTSSvrControlModule_Main(void* inPrivateArgs)
{
    return _stublibrary_main(inPrivateArgs, QTSSvrControlModuleDispatch);
}

QTSS_Error  QTSSvrControlModuleDispatch(QTSS_Role inRole, QTSS_RoleParamPtr inParams)
{
    switch (inRole)
    {
        case QTSS_Register_Role:
            return Register(&inParams->regParams);
        case QTSS_Initialize_Role:
            return Initialize(&inParams->initParams);
        case QTSS_Shutdown_Role:
            return Shutdown();
    }
    return QTSS_NoErr;
}

QTSS_Error Register(QTSS_Register_Params* inParams)
{
    // Do attribute setup
    static char*        sCantRegisterName   = "QTSSvrControlModuleCantRegisterMachPort";
    static char*        sCantAllocateName   = "QTSSvrControlModuleCantAllocateMachPort";
    static char*        sFatalName          = "QTSSvrControlModuleServerControlFatalErr";
    
    (void)QTSS_AddStaticAttribute(qtssTextMessagesObjectType, sCantRegisterName, NULL, qtssAttrDataTypeCharArray, qtssAttrModeRead | qtssAttrModePreempSafe);
    (void)QTSS_IDForAttr(qtssTextMessagesObjectType, sCantRegisterName, &sCantRegisterErr);

    (void)QTSS_AddStaticAttribute(qtssTextMessagesObjectType, sCantAllocateName, NULL, qtssAttrDataTypeCharArray, qtssAttrModeRead | qtssAttrModePreempSafe);
    (void)QTSS_IDForAttr(qtssTextMessagesObjectType, sCantAllocateName, &sCantAllocateErr);

    (void)QTSS_AddStaticAttribute(qtssTextMessagesObjectType, sFatalName, NULL, qtssAttrDataTypeCharArray, qtssAttrModeRead | qtssAttrModePreempSafe);
    (void)QTSS_IDForAttr(qtssTextMessagesObjectType, sFatalName, &sFatalErr);

    // Add roles
    (void)QTSS_AddRole(QTSS_Initialize_Role);
    (void)QTSS_AddRole(QTSS_Shutdown_Role);

    // Tell the server our name!
    static char* sModuleName = "QTSSvrControlModule";
    ::strcpy(inParams->outModuleName, sModuleName);

    return QTSS_NoErr;
}

QTSS_Error Initialize(QTSS_Initialize_Params* inParams)
{
    // Get global dictionaries
    sServer = inParams->inServer;
    sPrefs = QTSSModuleUtils::GetModulePrefsObject(inParams->inModule);

    // Setup module utils
    QTSSModuleUtils::Initialize(inParams->inMessages, inParams->inServer, inParams->inErrorLogStream);
    
    // Get service IDs
    (void)QTSS_IDForService(QTSS_REREAD_PREFS_SERVICE, &sRereadPreferences);
    (void)QTSS_IDForService("RollAccessLog", &sRollAccessLog);
    (void)QTSS_IDForService("RollErrorLog", &sRollErrorLog);
    
    sHistoryMutex = NEW OSMutex();
    sStartupTime = ::time(NULL);//store time_t value for startup of the server

    //allocate enough space to store the largest attribute possible
    sAttributeBuffer = NEW char[sizeof(QTSServerHistoryRec)];   
    sThread = NEW QTSSvrControlThread();
    if (sThread->HasErrorOccurred())
    {
        delete sThread;
        sThread = NULL;
        return QTSS_RequestFailed;
    }
    return QTSS_NoErr;

}

QTSS_Error Shutdown()
{
    if (sThread != NULL)
        delete sThread;
    return QTSS_NoErr;
}



kern_return_t StopServer(int inMinutes)
{
    //if time is -1, we're supposed to wait until all clients have disconnected
    if (inMinutes == -1)
    {
        QTSS_ServerState theState = qtssRefusingConnectionsState;
        (void)QTSS_SetValue(sServer, qtssSvrState, 0, &theState, sizeof(theState));
        sGracefulShutdownInProgress = true;
    }
    else
    {
        //just set the server state to shutting down
        QTSS_ServerState theShutDownState = qtssShuttingDownState;
        (void)QTSS_SetValue(sServer, qtssSvrState, 0, &theShutDownState, sizeof(theShutDownState));
    }
    return SCNoError;
}

kern_return_t CancelStopServer()
{
    //Not yet implemented
    return SCNoError;
}

void CheckShutdown()
{
    if (sGracefulShutdownInProgress)
    {
        QTSServerStatusRec theServerStatus;
        kern_return_t theErr = GetServerStatusRec(&theServerStatus);
        if ((theErr == SCNoError) && (theServerStatus.numCurrentConnections == 0))
            theErr = StopServer(0);
    }
}   

kern_return_t SetServerAttribute(AttributeType attrib, UInt32 /*tagSize*/,
                                            void* /*tags*/, unsigned int bufSize, void* buffer)
{
    if ((attrib.attribClass != kServerAttr) || (attrib.version != kCurrentVersion))
    {
        //because the buffer is being passed out of line, make sure to free it up
        vm_deallocate(task_self(), (unsigned int)buffer, bufSize);
        return SCNoError;
    }

    kern_return_t theError = SCNoError;
        
    switch (attrib.attribKind)
    {
        case kRefuseConnectionsAttr:
        {
            if ((buffer != NULL) && (bufSize == sizeof(QTSRefuseConnectionsRec)))
                theError = SetRefuseConnections((QTSRefuseConnectionsRec*)buffer);
            else
                theError = SCBufferToSmall;
            break;
        }
        case kRereadPreferencesAttr:
        {
            theError = RereadPreferences();
            break;
        }
        case kLogRollAttr:
        {
            if ((buffer != NULL) && (bufSize == sizeof(QTSLogRollRec)))
                theError = RollLogNow((QTSLogRollRec*)buffer);
            else
                theError = SCBufferToSmall;
            break;
        }
        default:
            theError = SCUnsupportedAttrib;
    }

    vm_deallocate(task_self(), (unsigned int)buffer, bufSize);
    return theError;    
}

kern_return_t GetServerAttribute(AttributeType attrib, UInt32 /*tagSize*/,
                                            void* /*tags*/, unsigned int bufSize,
                                            unsigned int* attribSize, void** buffer)
{
    Assert(buffer != NULL);
    Assert(sAttributeBuffer != NULL);
    
    if ((attribSize == NULL) || (buffer == NULL))
        return SCParamErr;
    
    *attribSize = 0;
    //use the sAttributeBuffer memory to store the attribute. This buffer
    //should be big enough to store the largest attribute
    *buffer = sAttributeBuffer;
        
    if ((attrib.attribClass != kServerAttr) || (attrib.version != kCurrentVersion))
        return SCUnsupportedAttrib;
    
    kern_return_t theError = SCNoError;
        
    switch (attrib.attribKind)
    {
        case kDNSNameAttr:
        {
            if (bufSize >= sizeof(QTSServerDNSName))
            {
                *attribSize = sizeof(QTSServerDNSName);
                theError = GetServerName((QTSServerDNSName*)sAttributeBuffer);
            }
            else
                theError = SCBufferToSmall;
            break;
        }   
        case kProcessInfoAttr:
        {
            if (bufSize >= sizeof(QTSProcessInfoRec))
            {
                *attribSize = sizeof(QTSProcessInfoRec);
                theError = GetProcessInfo((QTSProcessInfoRec*)sAttributeBuffer);
            }
            else
                theError = SCBufferToSmall;
            break;
        }
        case kVersionAttr:
        {
            if (bufSize >= sizeof(QTSServerVersionRec))
            {
                *attribSize = sizeof(QTSServerVersionRec);
                theError = GetServerVersion((QTSServerVersionRec*)sAttributeBuffer);
            }
            else
                theError = SCBufferToSmall;
            break;
        }   
        case kStatusAttr:
        {
            if (bufSize >= sizeof(QTSServerStatusRec))
            {
                *attribSize = sizeof(QTSServerStatusRec);
                theError = GetServerStatusRec((QTSServerStatusRec*)sAttributeBuffer);
            }
            else
                theError = SCBufferToSmall;
            break;
        }   
        case kRefuseConnectionsAttr:
        {
            if (bufSize >= sizeof(QTSRefuseConnectionsRec))
            {
                *attribSize = sizeof(QTSRefuseConnectionsRec);
                theError = GetRefuseConnections((QTSRefuseConnectionsRec*)sAttributeBuffer);
            }
            else
                theError = SCBufferToSmall;
            break;
        }   
        case kHistoryAttr:
        {
            if (bufSize >= sizeof(QTSServerHistoryRec))
            {
                *attribSize = sizeof(QTSServerHistoryRec);
                theError = GetHistory((QTSServerHistoryRec*)sAttributeBuffer);
            }
            else
                theError = SCBufferToSmall;
            break;
        }
        default:
            theError = SCUnsupportedAttrib;
    }
    return theError;
}

kern_return_t RereadPreferences()
{
    //Just tell the prefs object to reread. This is totally thread safe.
    (void)QTSS_DoService(sRereadPreferences, NULL);
    return SCNoError;
}

kern_return_t RollLogNow(QTSLogRollRec* theRollLogRec)
{
    if (theRollLogRec->rollTransferLog)
        (void)QTSS_DoService(sRollAccessLog, NULL);
    if (theRollLogRec->rollErrorLog)
        (void)QTSS_DoService(sRollErrorLog, NULL);
    return SCNoError;
}

kern_return_t GetProcessInfo(QTSProcessInfoRec* inProcessInfo)
{
    Assert(NULL != inProcessInfo);
    inProcessInfo->processID = getpid();
    inProcessInfo->startupTime = sStartupTime;
    return SCNoError;
}

kern_return_t GetServerName(QTSServerDNSName* outServerName)
{
    StrPtrLen theDNSName;
    (void)QTSS_GetValuePtr(sServer, qtssSvrDefaultDNSName, 0, (void**)&theDNSName.Ptr, &theDNSName.Len);
    if (theDNSName.Ptr != NULL)
        ::strncpy(outServerName->dnsName, theDNSName.Ptr, kDNSNameSize);
    outServerName->dnsName[kDNSNameSize-1] = '\0';
    
    return SCNoError;
}

kern_return_t GetServerVersion(QTSServerVersionRec* outServerVersion)
{
    Assert(outServerVersion != NULL);

    outServerVersion->serverVersion = 0x00000000;
    outServerVersion->serverControlAPIVersion = 0x00000000;

    StrPtrLen theServerVersion;
    
    (void)QTSS_GetValuePtr(sServer, qtssSvrServerVersion, 0, (void**)&theServerVersion.Ptr, &theServerVersion.Len);
    
    Assert(theServerVersion.Ptr != NULL);
    Assert(theServerVersion.Len > 0);
    
    if ((theServerVersion.Ptr != NULL) && (theServerVersion.Len > 0))
    {
        //
        // Convert the server version string to a long. Look for and extract major, minor, very minor
        // revision number
        StringParser theVersionParser(&theServerVersion);
        outServerVersion->serverVersion = theVersionParser.ConsumeInteger(NULL);
        outServerVersion->serverVersion <<= 8;
        
        theVersionParser.ConsumeUntil(NULL, StringParser::sDigitMask);
        outServerVersion->serverVersion += theVersionParser.ConsumeInteger(NULL);
        outServerVersion->serverVersion <<= 8;
        
        theVersionParser.ConsumeUntil(NULL, StringParser::sDigitMask);
        outServerVersion->serverVersion += theVersionParser.ConsumeInteger(NULL);
    }
    
    // Get the API version out of the server as well
    UInt32 theVersionLen = sizeof(outServerVersion->serverControlAPIVersion);
    (void)QTSS_GetValue(sServer, qtssServerAPIVersion, 0,  &outServerVersion->serverControlAPIVersion, &theVersionLen);

    return SCNoError;
}

kern_return_t GetServerStatusRec(QTSServerStatusRec* outServerStatus)
{
    Assert(outServerStatus != NULL);
    ::memset(outServerStatus, 0, sizeof(QTSServerStatusRec));
    
    QTSS_ServerState theState = qtssRunningState;
    UInt32 theSize = sizeof(theState);
    
    (void)QTSS_GetValue(sServer, qtssSvrState, 0, &theState, &theSize);
    
    //Convert the RTPServerInterface state to the server control's state
    if (sGracefulShutdownInProgress)
        outServerStatus->serverState = kSCGoingToShutDown;
    else if (theState == qtssRefusingConnectionsState)
        outServerStatus->serverState = kSCRefusingConnections;
    else if (theState == qtssStartingUpState)
        outServerStatus->serverState = kSCStartingUp;
    else if (theState == qtssShuttingDownState)
        outServerStatus->serverState = kSCShuttingDown;
    else
        outServerStatus->serverState = kSCRunning;
        
    outServerStatus->numCurrentConnections = 0;
    outServerStatus->connectionsSinceStartup = 0;
    outServerStatus->currentBandwidth = 0;
    outServerStatus->bytesSinceStartup = 0;
    
    //get the 4 key stats out of the RTP server
    theSize = sizeof(outServerStatus->numCurrentConnections);
    (void)QTSS_GetValue(sServer, qtssRTPSvrCurConn, 0, &outServerStatus->numCurrentConnections, &theSize);

    theSize = sizeof(outServerStatus->connectionsSinceStartup);
    (void)QTSS_GetValue(sServer, qtssRTPSvrTotalConn, 0, &outServerStatus->connectionsSinceStartup, &theSize);

    theSize = sizeof(outServerStatus->currentBandwidth);
    (void)QTSS_GetValue(sServer, qtssRTPSvrCurBandwidth, 0, &outServerStatus->currentBandwidth, &theSize);

    theSize = sizeof(outServerStatus->bytesSinceStartup);
    (void)QTSS_GetValue(sServer, qtssRTPSvrTotalBytes, 0, &outServerStatus->bytesSinceStartup, &theSize);
    return SCNoError;
}

kern_return_t GetRefuseConnections(QTSRefuseConnectionsRec* outRefuseConnections)
{
    QTSS_ServerState theState = qtssRunningState;
    UInt32 theSize = sizeof(theState);
    
    (void)QTSS_GetValue(sServer, qtssSvrState, 0, &theState, &theSize);

    if (theState == qtssRefusingConnectionsState)
        outRefuseConnections->refuseConnections = true;
    else
        outRefuseConnections->refuseConnections = false;
    return SCNoError;
}

kern_return_t SetRefuseConnections(QTSRefuseConnectionsRec* inRefuseConnections)
{
    //make sure not to allow people to stop the server from refusing connections when it
    //is in the process of a graceful shutdown. The only way to stop this is to call
    //CancelStopServer
    if (sGracefulShutdownInProgress)
        return SCServerShuttingDown;

    QTSS_ServerState theState = qtssRunningState;
    UInt32 theSize = sizeof(theState);

    if (inRefuseConnections->refuseConnections != 0)
        theState = qtssRefusingConnectionsState;

    (void)QTSS_SetValue(sServer, qtssSvrState, 0, &theState, theSize);
    return SCNoError;
}

kern_return_t GetHistory(QTSServerHistoryRec* outHistory)
{
    OSMutexLocker locker(sHistoryMutex);
    Assert(outHistory != NULL);
    //copy the current state of the array into this parameter

#if DEBUG
    //if we haven't filled up the array yet, make sure that the cursor is
    //one ahead of the size
    if (sHistoryArray.numEntries < kQTSHistoryArraySize)
        Assert(sCursor == (UInt32)sHistoryArray.numEntries);
#endif
    
    UInt32 theDestinationIndex = 0;//marker for where to write into the array next
    
    //if we have filled up the array, we will have to do 2 separate copies to fill outHistory.
    //Start by copying from fCursor to kMaxArraySize
    if (sHistoryArray.numEntries == kQTSHistoryArraySize)
    {
        ::memcpy(outHistory->historyArray, &sHistoryArray.historyArray[sCursor],
                    (kQTSHistoryArraySize - sCursor) * sizeof(QTSHistoryEntryRec));
        theDestinationIndex += kQTSHistoryArraySize - sCursor;
    }
    
    //There is ALWAYS valid data between 0 -> fCursor - 1. So copy that now
    ::memcpy(&outHistory->historyArray[theDestinationIndex], sHistoryArray.historyArray,
                sCursor * sizeof(QTSHistoryEntryRec));

#if DEBUG
    //we should always write out the same number of entries as is in the fHistoryArray!
    theDestinationIndex += sCursor;
    Assert(theDestinationIndex == (UInt32)sHistoryArray.numEntries);
#endif

    //ok, now set the size of the output array
    outHistory->numEntries = sHistoryArray.numEntries;
    outHistory->entryInterval = sHistoryIntervalInSecs;

    return SCNoError;
}

void AddHistorySample()
{
    // Retrieve the bandwidth & session count parameters from the server
    UInt32 theCurrentSessions = 0;
    UInt32 theSize = sizeof(theCurrentSessions);
    (void)QTSS_GetValue(sServer, qtssRTPSvrCurConn, 0, &theCurrentSessions, &theSize);

    UInt32 theCurrentBandwidth = 0;
    theSize = sizeof(theCurrentBandwidth);
    (void)QTSS_GetValue(sServer, qtssRTPSvrCurBandwidth, 0, &theCurrentBandwidth, &theSize);

    OSMutexLocker locker(sHistoryMutex);
    
    //keep track of maximums.
    if ((long)theCurrentBandwidth > sBandwidthHi)
        sBandwidthHi = theCurrentBandwidth;
    if ((long)theCurrentSessions > sConnectionHi)
        sConnectionHi = theCurrentSessions;
        
    //keep track of minimums.
    if (((long)theCurrentBandwidth < sBandwidthLo) || (sBandwidthLo == -1))
        sBandwidthLo = theCurrentBandwidth;
    if (((long)theCurrentSessions < sConnectionLo) || (sConnectionLo == -1))
        sConnectionLo = theCurrentSessions;
        
    //keep track of sum for eventual average
    //fBandwidthAvg += theCurrentBandwidth;     <---this was overflowing at high bitrates
    //fConnectionAvg += theCurrentSessions;
    
    // fBandwidthAvg was overflowing, 
    // so now we do it the ugly way
    sBandwidthAvg =(theCurrentBandwidth+(sBandwidthAvg*sSampleIndex))/(sSampleIndex+1);
    sConnectionAvg =(theCurrentSessions+(sConnectionAvg*sSampleIndex))/(sSampleIndex+1);
        
    sSampleIndex++;
}

void UpdateHistoryArray()
{
    OSMutexLocker locker(sHistoryMutex);

    if (sSampleIndex == 0)
    {
        Assert(false);
        return;
    }
    
    //figure out min, max, average over this period
    sHistoryArray.historyArray[sCursor].bandwidthAvg = sBandwidthAvg;
    sHistoryArray.historyArray[sCursor].numClientsAvg = sConnectionAvg;
    
    sHistoryArray.historyArray[sCursor].bandwidthHi = sBandwidthHi;
    sHistoryArray.historyArray[sCursor].numClientsHi = sConnectionHi;

    sHistoryArray.historyArray[sCursor].bandwidthLo = sBandwidthLo;
    sHistoryArray.historyArray[sCursor].numClientsLo = sConnectionLo;
    
    //ok, increment the cursor for the next write (make sure to reset it if we've hit
    //the array boundary)
    sCursor++;
    if (sCursor == kQTSHistoryArraySize)
        sCursor = 0;
    
    //also update the array size. This only increments until the array is full, of course.
    if (sHistoryArray.numEntries < kQTSHistoryArraySize)
        sHistoryArray.numEntries++;
        
    //reset the sample index & related variables. We're moving onto a new entry now.
    sBandwidthLo = -1;
    sConnectionLo = -1;
    sBandwidthHi = 0;
    sConnectionHi = 0;
    sBandwidthAvg = 0;
    sConnectionAvg = 0;

    sSampleIndex = 0;
}


QTSSvrControlThread::QTSSvrControlThread()
:   fMessagePort(0),
    fDone(false), fErrorOccurred(false), fDoneStartingUp(false), fThreadsAllocated(false)
{
    kern_return_t r;
    
    r = ::port_allocate(task_self(), &fMessagePort);
    if (r != SCNoError)
    {
        QTSSModuleUtils::LogError(qtssFatalVerbosity, sCantAllocateErr, 0);
        fErrorOccurred = true;
        fDoneStartingUp = true;
        return;
    }
    
    for (int x = 0; x < 5; x++)
    {
        r = ::bootstrap_register(bootstrap_port, "QuickTimeStreamingServer", fMessagePort);
        //sometimes when restarting the server right after the server has gone away,
        //this can fail... so let's retry a couple of times
        if (r != SCNoError)
            thread_switch(THREAD_NULL, SWITCH_OPTION_WAIT, 1000);
        else    
            break;          
    }

    if (r != SCNoError)
    {
        QTSSModuleUtils::LogError(qtssFatalVerbosity, sCantRegisterErr, 0);
        fErrorOccurred = true;
        fDoneStartingUp = true;
        return;
    }
    
    //I'm just assuming this always succeeds cause the mach documentation doesn't say
    //anything about it failing!
    fThreadID = ::cthread_fork((cthread_fn_t)_Entry, (any_t)this);
    fHistoryThreadID = ::cthread_fork((cthread_fn_t)_HistoryEntry, (any_t)this);
    fThreadsAllocated = true;
    
    while (!fDoneStartingUp)
        ::cthread_yield();
}

QTSSvrControlThread::~QTSSvrControlThread()
{
    fDone = true;
    port_deallocate(task_self(), fMessagePort);//force SC thread to wakeup
    fMessagePort = 0;
    //wait for thread to terminate... these mach prototypes are very strange...
    //why, for instance, does thread_resume take an INT????
    if (fThreadsAllocated)
    {
        thread_resume((unsigned int)fThreadID);//force a wakeup.    
        cthread_join(fThreadID);
        thread_resume((unsigned int)fHistoryThreadID);  
        cthread_join(fHistoryThreadID);
    }
}

void QTSSvrControlThread::_Entry(QTSSvrControlThread *thread)  //static
{
    thread->Entry();
}
void QTSSvrControlThread::_HistoryEntry(QTSSvrControlThread *thread)  //static
{
    thread->HistoryEntry();
}

void QTSSvrControlThread::HistoryEntry()
{
    //compute how often to run this thread.
    QTSSModuleUtils::GetAttribute(sPrefs, "history_update_interval", qtssAttrDataTypeUInt32,
                                &sHistoryIntervalInSecs, &sDefaultHistoryIntervalInSecs, sizeof(sHistoryIntervalInSecs));
    UInt32 theSampleInterval = (sHistoryIntervalInSecs * 1000) / kNumSamplesPerEntry;
    UInt32 theEntryInterval = sHistoryIntervalInSecs * 1000;
    
    //use local time to figure out when we need move onto a new entry. This
    //will eliminate the possibility that we drift off time.
    
    SInt64 theStartTime = QTSS_Milliseconds();
    Assert(theStartTime > 0);
    
    while (!fDone)
    {
        //sleep for the kHistoryUpdateInterval
        //kHistoryUpdateInterval is in minutes. Convert to msec.
        thread_switch(THREAD_NULL, SWITCH_OPTION_WAIT, theSampleInterval);
        
        //if server is doing a graceful shutdown, this thread is used to periodically
        //poll, checking if all connections are complete
        CheckShutdown();
        
        //every time we wake up, first thing we want to do is sample the
        //current state of the server for the history
        AddHistorySample();
    
        SInt64 theCurrentTime = QTSS_Milliseconds();
        Assert(theCurrentTime > 0);

        if ((theCurrentTime - theStartTime) > theEntryInterval)
        {
            UpdateHistoryArray();
            theStartTime += theEntryInterval;
        }
    }
}

void QTSSvrControlThread::Entry()
{
    kern_return_t r;
        
    msg_header_t* msg = (msg_header_t*)new char[100];
    msg_header_t* reply = (msg_header_t*)new char[1000];    
    //signal 
    fDoneStartingUp = true;

    while(!fDone)
    {
        msg->msg_local_port = fMessagePort;
        msg->msg_size = 100;
        
        r = msg_receive(msg, MSG_OPTION_NONE, 0);
        
        if (r == RCV_INVALID_PORT)
            break;  //break because there's no more port to receive from
        if (r != SCNoError)
        {
            QTSSModuleUtils::LogError(qtssFatalVerbosity, sFatalErr, 0);
            
            //attempt to stop the server
            StopServer(0);
            break;
        }

        QTSCRPI_server(msg, reply);
        
        reply->msg_local_port = fMessagePort;
        r = msg_send(reply, MSG_OPTION_NONE, 0);
    }

    if (fMessagePort != 0)
        port_deallocate(task_self(), fMessagePort);
}



//The following are the "modern" server control RPCs that map directly to server
//control interface calls.

kern_return_t _SCRPIStopServer(port_t /*server*/, int numMinutes)
{
    return StopServer(numMinutes);
}

kern_return_t _SCRPICancelStopServer(port_t /*server*/)
{
    return CancelStopServer();
}


kern_return_t _SCRPIGetServerAttribute( port_t /*server*/, AttributeType attr, int bufSize,
                                        AttributeValue* buffer, unsigned int* actualSize)
{
    return GetServerAttribute(attr, 0, NULL, (unsigned int)bufSize, actualSize, buffer);
}

kern_return_t _SCRPISetServerAttribute( port_t /*server*/, AttributeType attr,
                                        AttributeValue buffer, unsigned int size)
{
    return SetServerAttribute(attr, 0, NULL, size, buffer);
}

