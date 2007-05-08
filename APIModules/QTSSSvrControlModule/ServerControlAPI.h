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

#ifndef SERVERCONTROLAPI_H
#define SERVERCONTROLAPI_H

#include <stdio.h>
#include <stdlib.h>
#include "SafeStdLib.h"
#ifndef MAC
#include <sys/types.h>
#include <sys/time.h>
#include <sys/attr.h>
//#include <vol.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif


typedef long SCErr;



enum // errors  (?? What kind of values should these have ??) should fit SCRef type - CNR 4/20
{
    SCNoError = 0,
    SCWrongLibraryVersion = -10000,
    SCBufferToSmall = -10001,
    SCUnsupportedAttrib = -10002,
    SCNoMoreItems = -10003,
    SCObjectNotFound = -10004,
    SCServerRunning = -10005,
    SCTagParamError = -10006,
    SCVolumeBusy = -10007,
    SCBadServerRef = -10008,
    SCUnsupportedCall = -10009, //this server doesn't support this SC call
    SCServerNotRunning = -10010,
    SCParamErr = -10011,
    SCParameterUnavailable = -10012,
    SCMemAllocFailed = -10013,
    SCServerShuttingDown = -10014,
    SCObjectAlreadyExists = -10015,
    
    SCOSError               = -10050,
    SCRegisterationError    = -10051,
    SCNoServerName          = -10052,
    SCNoHFSVolumes          = -10053,
    SCGeneralAgentError     = -10054,
    SCGeneralNetWorkError   = -10055
};


enum // warnings (?? What kind of values should these have ??)
{
    kNumStartUpWarnings     = 10,
    SCNoSharePoints         = -10100,
    SharePointInfoError     = -10101
};

enum // ServerTypes
{
    kAFPServer = 'afps',
    kQTSServer = 'qtss',
    kAllServers = 'alls'
};

enum // Attribute classes
{
    kServerAttr = 'srva',
    kConnectionAttr = 'cona',
    kSharePointAttr = 'shpa'
};

enum // server attribute types
{
    kNameAttr = 'name',
    kStatusAttr = 'stat',
    kActivityHistory = 'hist',
    kActivitySampleTime = 'samt',
    kWarningAttr = 'warn',
    kCancelShutdownAttr = 'csdn',
    kRefuseConnectionsAttr = 'refc',
    kHistoryAttr = 'hist',
    kDNSNameAttr = 'dnsn',
    kRereadPreferencesAttr = 'rprf',
    kProcessInfoAttr = 'pinf',
    kLogRollAttr = 'logr',
    kVersionAttr = 'vers'
};

enum // connection attribute types
{
    kSCUserID = 'uid ',
    kConnectTime = 'cinf'
};

enum
{
    kCurrentVersion = 1
};

enum //Session States
{
    kConnected = 1,
    kLoggedIn = 2,
    kDisconnecting = 3,
    kLoggedOut = 4,
    kTerminated = 5
};

enum //Server States
{
    kSCServerNotRunning = 0,
    kSCStartingUp = 1,
    kSCRunning = 2,
    kSCGoingToShutDown = 3,
    kSCShuttingDown = 4,
    kSCRefusingConnections = 5
};

/*
 * AFP SERVER
 */
 
enum { kMaxDataPoints = 1024};

enum
{
    kSharePointCountProp = 'info'
};

typedef struct SharePointInfo
{
    u_long              volumeID;
    u_char              name[512];
    struct timespec     creationDate;
    u_long              dirID;
}SharePointInfo;

typedef struct SharePointSpec
{
    u_long              volumeID;
    u_long              dirID;
    char                filename[512];
}SharePointSpec;

typedef struct HistoryData{
    u_int8_t        dpMin;
    u_int8_t        dpMax;
    u_int8_t        dpAverage;
    u_int8_t        filler;
} HistoryData;

typedef struct ServerHistoryRec{
    u_int32_t       historySyncCount;
    u_int32_t       historyLastSample;
    u_int16_t       historySampleTime;
    u_int16_t       numDataPoints;
    HistoryData dataPoint[kMaxDataPoints];
} ServerHistoryRec;


typedef struct AttributeType
{
    u_int attribClass;
    u_int attribKind;
    int version;
}AttributeType;

typedef struct ServerStatusRec
{
    long serverVersion;
    long serverState;
    long secondsToShutdown;
    long currentActivity;
}ServerStatusRec;

typedef struct UserAttributeRec
{
    unsigned long startTime;
    unsigned long idleTime;
    int           connectionType;
    unsigned long address;
    unsigned long disconnectID;
}UserAttributeRec;

enum    // sharePointTypes
{
    kSCSuperUser = 0,
    kSCNormalUser = 1,
    kSCSharePointRec
};

/*
 * QTS SERVER
 */
 
 enum //History attribute stuff
{
    kQTSHistoryArraySize = 720
};

typedef struct QTSServerVersionRec
{
    long serverVersion;             //public vershun of the server: 0x00010001 = 1.0.1
    long serverControlAPIVersion;   //vershun of server control API supported by server
} QTSServerVersionRec;

typedef struct QTSServerStatusRec
{
    long serverState;
    long numCurrentConnections;
    long currentBandwidth;
    long connectionsSinceStartup;
    long long bytesSinceStartup;
}QTSServerStatusRec;

typedef struct QTSHistoryEntryRec
{
    long numClientsAvg;
    long numClientsHi;
    long numClientsLo;
    long bandwidthAvg;
    long bandwidthHi;
    long bandwidthLo;
}QTSHistoryEntryRec;

typedef struct QTSRefuseConnectionsRec
{
    long refuseConnections;
}QTSRefuseConnectionsRec;


typedef struct QTSServerHistoryRec
{
    QTSHistoryEntryRec historyArray[kQTSHistoryArraySize];
    long numEntries;
    long entryInterval;//in seconds
}QTSServerHistoryRec;

enum
{
    kDNSNameSize = 60
};

typedef struct QTSServerDNSName
{
    char    dnsName[kDNSNameSize];
}QTSServerDNSName;

typedef struct QTSProcessInfoRec
{
    time_t      startupTime;
    pid_t       processID;
}QTSProcessInfoRec;

typedef struct QTSLogRollRec
{
    long        rollTransferLog;
    long        rollErrorLog;
}QTSLogRollRec;


typedef unsigned long SCRef;
typedef SCRef SessionRef;
typedef SCRef ConnectionIterRef;
typedef SCRef ConnectionRef;
typedef SCRef SharePointIterRef;
typedef SCRef SharePointRef;
typedef SCRef ServerRef;
typedef SCRef WarningsIterRef;
typedef SCRef WarningsRef;

//Iterator IDs
enum
{
    kConnectionIterID = 1,
    kSharePointIterID,
    kWarningsIterID
};


extern const AttributeType kServerNBPName;
extern const AttributeType kServerStatus;
extern const AttributeType kServerHistory;
extern const AttributeType kCancelShutdown;

extern const AttributeType kConnectionName;
extern const AttributeType kConnectionID;
extern const AttributeType kConnectionInfo;

extern const AttributeType kSharePointName;
extern const AttributeType kWarnings;

//new attributes added for QTSS

extern const AttributeType kServerRefuseConnections;//tells the server to stop accepting conn.
extern const AttributeType kServerRereadPreferences;//set: reread preferences now!
extern const AttributeType kServerDNSName;//get primary dns name of server
extern const AttributeType kServerProcessInfo;//info on the server process
extern const AttributeType kServerLogRoll;//set this: roll the log now
extern const AttributeType kServerVersion;


SCErr SCGetServer(u_int serverType, ServerRef* server);

SCErr SCStartServer(ServerRef server);
SCErr SCStopServer(ServerRef server, int numMinutes,  void* buffer, unsigned int bufferLength);//passing a -1 to QTSS (for numminutes)
                                                    //tells it to quit when all connections are done
SCErr SCCancelStopServer(ServerRef server);         

SCErr SCAddVolume(fsvolid_t hfsVolID);
SCErr SCForgetVolume(fsvolid_t hfsVolID);

//SCErr GetSimpleServerAttribute(ServerRef server, AttributeType attrib, long* value);
SCErr GetServerAttribute(ServerRef server, AttributeType attrib, u_int32_t tagSize, void* tags, int bufSize, int* attribSize, void* buffer);

//SCErr SetSimpleServerAttribute(ServerRef server, AttributeType attrib, long value);
//SCErr SetServerAttribute(ServerRef server, AttributeType attrib, int attribSize, void* buffer);
SCErr SetServerAttribute(ServerRef server, AttributeType attrib, u_int32_t tagSize, void* tags, int bufSize, void* buffer);

SCErr CreateConnectionIter(ServerRef server, ConnectionIterRef* iter);
SCErr DeleteConnectionIter(ConnectionIterRef iter);
SCErr GetNextConnection(ConnectionIterRef iter, ConnectionRef* con);

//SCErr GetSimpleConnectionAttribute(ConnectionRef con, AttributeType attrib, long* value);
SCErr GetConnectionAttribute(ConnectionRef con, AttributeType attrib, int bufSize, int* attribSize, void* buffer);

SCErr CreateSharePointIter(ServerRef server, int sharePointType, SharePointIterRef* iter);
SCErr DeleteSharePointIter(SharePointIterRef iter);
SCErr GetNextSharePoint(SharePointIterRef iter, SharePointRef* con);

//SCErr GetSimpleSharePointAttribute(SharePointRef con, AttributeType attrib, long* value);
SCErr GetSharePointAttribute(SharePointRef con, AttributeType attrib, int bufSize, int* attribSize, void* buffer);

SCErr CreateWarningsIter(ServerRef server, WarningsIterRef* iter);
SCErr DeleteWarningsIter(WarningsIterRef iter);
SCErr GetNextWarning(WarningsIterRef iter, WarningsRef* warning);
SCErr GetWarningAttribute(WarningsRef warning, AttributeType attrib, int bufSize, int* attribSize, void* buffer);

SCErr DisconnectSessions(ServerRef server, int numMinutes, unsigned int* buffer, unsigned int bufferLength, char* message, int* stopTaskID);
SCErr CancelStopTask(ServerRef server, int id);

SCErr AddSharePoint(ServerRef server, SharePointSpec* spRecBuffer);
SCErr RemoveSharePoint(ServerRef server, SharePointSpec* spRecBuffer);

SCErr SendMessage(ServerRef server, unsigned int* buffer, unsigned int bufferCnt, char* message);

SCErr RegisterForEvents(ServerRef server, long events, long eventRecVersion, port_t receiverPort);

#ifdef __cplusplus
}
#endif

#endif /*SERVERCONTROLAPI_H*/
