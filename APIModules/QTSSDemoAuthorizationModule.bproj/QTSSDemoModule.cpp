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
    File:       QTSSDemoModule.cpp

    Contains:   Implementation of QTSSDemoModule, a modified version of the QTSSAccessModule
                for demoing at QuickTime Live! and distributing as sample code. 
                    


*/

#include "QTSSDemoModule.h"
#include "defaultPaths.h"
#include "AccessCheck.h"
#include "StrPtrLen.h"
#include "QTSSModuleUtils.h"
#include "OSArrayObjectDeleter.h"
#include "SafeStdLib.h"
#include "QTSSMemoryDeleter.h"

// ATTRIBUTES

// STATIC DATA


static StrPtrLen sRedirect("RTSP/1.0 302 Found\r\nServer: QTSS/2.0\r\nCSeq: 2\r\nLocation: rtsp://");
static StrPtrLen sRedirectEnd("/error/errormovie.mov\r\n\r\n");

const UInt32 kBuffLen = 512;


// FUNCTION PROTOTYPES

static QTSS_Error QTSSDemoModuleDispatch(QTSS_Role inRole, QTSS_RoleParamPtr inParams);
static QTSS_Error Register();
static QTSS_Error Initialize(QTSS_Initialize_Params* inParams);
static QTSS_Error Shutdown();
static QTSS_Error RereadPrefs();
static QTSS_Error Authenticate(QTSS_StandardRTSP_Params* inParams);
static bool QTSSAccess(QTSS_StandardRTSP_Params* inParams, const char* pathBuff, const char* movieRootDir, char* ioRealmName);


// FUNCTION IMPLEMENTATIONS

QTSS_Error QTSSDemoAuthorizationModule_Main(void* inPrivateArgs)
{
     return _stublibrary_main(inPrivateArgs, QTSSDemoModuleDispatch);
}


QTSS_Error  QTSSDemoModuleDispatch(QTSS_Role inRole, QTSS_RoleParamPtr inParams)
{
   switch (inRole)
    {  
       case QTSS_Register_Role:
            return Register();
        case QTSS_Initialize_Role:
            return Initialize(&inParams->initParams);
        case QTSS_RereadPrefs_Role:
            return RereadPrefs();
        case QTSS_RTSPAuthorize_Role:
            return Authenticate(&inParams->rtspRequestParams);
        case QTSS_Shutdown_Role:
            return Shutdown();
    }
    return QTSS_NoErr;
}


QTSS_Error Register()
{
    // Do role & attribute setup
    (void)QTSS_AddRole(QTSS_Initialize_Role);
    (void)QTSS_AddRole(QTSS_RereadPrefs_Role);
    (void)QTSS_AddRole(QTSS_RTSPAuthorize_Role);
        
    return QTSS_NoErr;
}


QTSS_Error Initialize(QTSS_Initialize_Params* inParams)
{
//  qtss_printf("QTSSDemoModule was just called in the QTSS_Initialize_Role\n");
    // Setup module utils
    QTSSModuleUtils::Initialize(inParams->inMessages, inParams->inServer, inParams->inErrorLogStream);

    RereadPrefs();
    return QTSS_NoErr;
}

QTSS_Error Shutdown()
{
    return QTSS_NoErr;
}

QTSS_Error RereadPrefs()
{
    return QTSS_NoErr;
}

bool QTSSAccess(QTSS_StandardRTSP_Params* inParams, 
                const char* pathBuff, 
                const char* movieRootDir,
                char* ioRealmName)
{
    QTSS_Error theErr = QTSS_NoErr;
    qtss_printf("In QTSSAccess. Pathbuff: %s. movierootdir: %s\n", pathBuff, movieRootDir);
    
    char passwordBuff[kBuffLen];
    StrPtrLen passwordStr(passwordBuff, kBuffLen);
    
    char nameBuff[kBuffLen];
    StrPtrLen nameStr(nameBuff, kBuffLen);
    
    char realmNameBuff[kBuffLen];
    StrPtrLen realmName(realmNameBuff, kBuffLen);

    AccessChecker accessChecker(movieRootDir, "qtaccess", DEFAULTPATHS_ETC_DIR "QTSSUsers", DEFAULTPATHS_ETC_DIR "QTSSGroups");
    
    //If there are no access files, then allow world access
    if ( !accessChecker.GetAccessFile(pathBuff) ) 
        return true;

    qtss_printf("Found access file\n");
    ::strcpy(ioRealmName, accessChecker.GetRealmHeaderPtr());

    //
    // If this RTSP request includes a user name and password, the server decodes
    // that information and stores it in these attributes. 
    theErr = QTSS_GetValue (inParams->inRTSPRequest,qtssRTSPReqUserName,0, (void *) nameStr.Ptr, &nameStr.Len);
    if ( (QTSS_NoErr != theErr) || (nameStr.Len >= kBuffLen) ) return false;    
                
    theErr = QTSS_GetValue (inParams->inRTSPRequest,qtssRTSPReqUserPassword,0, (void *) passwordStr.Ptr, &passwordStr.Len);
    if ( (QTSS_NoErr != theErr) || (passwordStr.Len >= kBuffLen) ) return false;        

    nameBuff[nameStr.Len] = '\0';
    passwordBuff[passwordStr.Len] = '\0';
    
    //
    // Use the name and password to check access
    if ( !accessChecker.CheckAccess(nameBuff, passwordBuff) )
    {
#if 0
        if (nameStr.Len > 0)
        {
            //
            // If the user HAS provided a username, and that username is incorrect, redirect them to
            // an error movie.
            
            //
            // Get the local IP addr as a string so we can properly construct a complete
            // rtsp:// URL.
            char* theLocalAddrStr = NULL;
            UInt32 theAddrLen = 0;

            theErr = QTSS_GetValuePtr(inParams->inRTSPSession, qtssRTSPSesLocalAddrStr, 0,
                                        (void**)&theLocalAddrStr, &theAddrLen);         
            if ( QTSS_NoErr != theErr )
                return false;

            //
            // In order to send the redirect, we need to get a QTSS_StreamRef
            // so we can send data to the client. Get the QTSS_StreamRef out of the request.
            QTSS_StreamRef* theStreamRef = NULL;
            UInt32 strRefLen = 0;
        
            theErr = QTSS_GetValuePtr(inParams->inRTSPRequest, qtssRTSPReqStreamRef, 0,
                                                        (void**)&theStreamRef, &strRefLen);
            if (( QTSS_NoErr != theErr ) || ( sizeof(QTSS_StreamRef) != strRefLen) )
                return false;
        
            //
            // Now that we have the QTSS_StreamRef, send the 302 Moved Temporarily response to the client.
            // Because this is a simple demo, we have a hard-coded location for the error movie.
            UInt32 theLenWritten = 0;
            (void)QTSS_Write(*theStreamRef, sRedirect.Ptr, sRedirect.Len, &theLenWritten, 0);
            (void)QTSS_Write(*theStreamRef, theLocalAddrStr, theAddrLen, &theLenWritten, 0);
            (void)QTSS_Write(*theStreamRef, sRedirectEnd.Ptr, sRedirectEnd.Len, &theLenWritten, 0);
        }
#endif
        qtss_printf("Access fail\n");
        return false;
    }
    qtss_printf("Access success\n");
    return true;
}

#if 0
QTSS_Error Authenticate(QTSS_StandardRTSP_Params* inParams)
{
    QTSS_Error              theErr = QTSS_NoErr;
    UInt32                  buffLen = 0;
    QTSS_RTSPRequestObject  theRTSPRequest = inParams->inRTSPRequest;
    
    buffLen = kBuffLen - 1;
    char pathBuff[kBuffLen] = {};
    
    theErr = QTSS_GetValue (theRTSPRequest,qtssRTSPReqLocalPath,0,
                                (void *) &pathBuff[0], &buffLen);
    if ( (theErr != QTSS_NoErr) || (0 == buffLen) )
        return theErr; // Bail on the request. The Server will handle the error
    
    pathBuff[buffLen] = '\0';
#if 0
    qtss_printf("QTSSDemoModule was just called in the QTSS_Authorize_Role.\n");
    qtss_printf("The full path to the file specified by this request is: %s\n",  pathBuff);
#endif

    buffLen = kBuffLen -1;
    char* movieRootDir = NULL;
    theErr = QTSS_GetValuePtr(theRTSPRequest, qtssRTSPReqRootDir, 0,
                                (void**)&movieRootDir, &buffLen );
    if ( (theErr != QTSS_NoErr) || (0 == buffLen) )
        return theErr; // Bail on the request. The Server will handle the error

    char realmName[kBuffLen];
    Bool16 allowRequest = ::QTSSAccess(inParams, pathBuff, movieRootDir, realmName);
    if (allowRequest) 
        return theErr; // Bail on the request. The Server will handle the error
    //  
    // We are denying the request so pass false back to the server.
    //
    theErr = QTSS_SetValue(theRTSPRequest,qtssRTSPReqUserAllowed, 0, &allowRequest, sizeof(allowRequest));
    if (theErr != QTSS_NoErr) 
        return theErr; // Bail on the request. The Server will handle the error
    
    theErr = QTSS_SetValue(theRTSPRequest,qtssRTSPReqURLRealm, 0, realmName, strlen(realmName) );
    if (theErr != QTSS_NoErr) 
        return theErr; // Bail on the request. The Server will handle the error

    return theErr;
}
#endif

QTSS_Error Authenticate(QTSS_StandardRTSP_Params* inParams)
{
    QTSS_RTSPRequestObject  theRTSPRequest = inParams->inRTSPRequest;
    
    if  ( (NULL == inParams) || (NULL == inParams->inRTSPRequest) )
        return QTSS_RequestFailed;
    
    //get the local file path
    char*   pathBuffStr = NULL;
    QTSS_Error theErr = QTSS_GetValueAsString(theRTSPRequest, qtssRTSPReqLocalPath, 0, &pathBuffStr);
    QTSSCharArrayDeleter pathBuffDeleter(pathBuffStr);
    if (theErr != QTSS_NoErr)
        return QTSS_RequestFailed;  

    //get the root movie directory
    char*   movieRootDirStr = NULL;
    theErr = QTSS_GetValueAsString(theRTSPRequest,qtssRTSPReqRootDir, 0, &movieRootDirStr);
    OSCharArrayDeleter movieRootDeleter(movieRootDirStr);
    if (theErr != QTSS_NoErr)
        return false;

    //check if this user is allowed to see this movie
    char realmName[kBuffLen] = { 0 };
    StrPtrLen   realmNameStr(realmName,kBuffLen -1);
    Bool16 allowRequest = ::QTSSAccess(inParams, pathBuffStr, movieRootDirStr, realmName);


    if ( realmName[0] != '\0' )     //set the realm if we have one
    {
        (void) QTSS_SetValue(theRTSPRequest,qtssRTSPReqURLRealm, 0, realmName, strlen(realmName) );
    }
    

    if (allowRequest)
    {
        return QTSS_NoErr;  //everything's kosher - let the request continue
    }
    else    //request denied
    {
        // We are denying the request so pass false back to the server.
        theErr = QTSS_SetValue(theRTSPRequest,qtssRTSPReqUserAllowed, 0, &allowRequest, sizeof(allowRequest));
        if (theErr != QTSS_NoErr) 
            return QTSS_RequestFailed; // Bail on the request. The Server will handle the error
        
    }

    return QTSS_NoErr;
}





