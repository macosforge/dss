/*
 *
 * @APPLE_LICENSE_HEADER_START@
 * 
 * Copyright (c) 1999-2005 Apple Computer, Inc.  All Rights Reserved.
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
    File:       QTSSDemoODAuthModule.cpp

    Contains:   Implementation of QTSSDemoODAuthModule, a modified version of the QTSSAccessModule
                is sample code. 
                    


*/

#include "QTSSODAuthModule.h"
#include "defaultPaths.h"
#include "AccessCheck.h"
#include "StrPtrLen.h"
#include "QTSSModuleUtils.h"
#include "OSArrayObjectDeleter.h"
#include "SafeStdLib.h"
#include "QTSSMemoryDeleter.h"

// ATTRIBUTES

// STATIC DATA

const UInt32 kBuffLen = 512;


// FUNCTION PROTOTYPES

static QTSS_Error QTSSDemoODAuthModuleDispatch(QTSS_Role inRole, QTSS_RoleParamPtr inParams);
static QTSS_Error Register();
static QTSS_Error Initialize(QTSS_Initialize_Params* inParams);
static QTSS_Error Shutdown();
static QTSS_Error RereadPrefs();
static QTSS_Error AuthenticateRTSPRequest(QTSS_RTSPAuth_Params* inParams);
static QTSS_Error Authenticate(QTSS_StandardRTSP_Params* inParams);
static bool QTSSAccess(QTSS_StandardRTSP_Params* inParams, const char* pathBuff, const char* movieRootDir, char* ioRealmName);


// FUNCTION IMPLEMENTATIONS

QTSS_Error QTSSDemoODAuthModule_Main(void* inPrivateArgs)
{
     return _stublibrary_main(inPrivateArgs, QTSSDemoODAuthModuleDispatch);
}


QTSS_Error  QTSSDemoODAuthModuleDispatch(QTSS_Role inRole, QTSS_RoleParamPtr inParams)
{
   switch (inRole)
    {  
       case QTSS_Register_Role:
            return Register();
        case QTSS_Initialize_Role:
            return Initialize(&inParams->initParams);
        case QTSS_RereadPrefs_Role:
            return RereadPrefs();
		case QTSS_RTSPAuthenticate_Role:
			return AuthenticateRTSPRequest(&inParams->rtspAthnParams);
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
    (void)QTSS_AddRole(QTSS_RTSPAuthenticate_Role);
    (void)QTSS_AddRole(QTSS_RTSPAuthorize_Role);
	    
    return QTSS_NoErr;
}


QTSS_Error Initialize(QTSS_Initialize_Params* inParams)
{
	qtss_printf("QTSSDemoODAuthModule was just called in the QTSS_Initialize_Role\n");
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
    qtss_printf("QTSSDemoODAuthModule in QTSSAccess() - Pathbuff: %s. movierootdir: %s\n", pathBuff, movieRootDir);
    
    char passwordBuff[kBuffLen];
    StrPtrLen passwordStr(passwordBuff, kBuffLen);
    
    char nameBuff[kBuffLen];
    StrPtrLen nameStr(nameBuff, kBuffLen);
    
    char realmNameBuff[kBuffLen];
    StrPtrLen realmName(realmNameBuff, kBuffLen);
	
	// Look for a file called dsqtaccess for user and group access
    AccessChecker accessChecker(movieRootDir, "dsqtaccess", DEFAULTPATHS_ETC_DIR "QTSSUsers", DEFAULTPATHS_ETC_DIR "QTSSGroups");
    
    //If there are no access files, then allow world access
    if ( !accessChecker.GetAccessFile(pathBuff) )
	{
		qtss_printf("In QTSSDemoODAuthModule: Did not find access file\n");
        return true;
	}
    qtss_printf("In QTSSDemoODAuthModule: Found access file\n");
    ::strcpy(ioRealmName, accessChecker.GetRealmHeaderPtr());
	qtss_printf("In QTSSDemoODAuthModule: QTAccess() realm is %s\n", ioRealmName);
    //
    // If this RTSP request includes a user name and password, the server decodes
    // that information and stores it in these attributes. 
	/*
	QTSS_UserProfileObject theUserProfile = NULL;
    UInt32 len = sizeof(QTSS_UserProfileObject);
    theErr = QTSS_GetValue(inParams->inRTSPRequest, qtssRTSPReqUserProfile, 0, (void*)&theUserProfile, &len);
	if ( (QTSS_NoErr != theErr)) 
	{
		qtss_printf("In QTSSDemoODAuthModule: QTSSAccess() Userprofile Error - %ld\n", theErr);
    
		return false;    
	} 
	
	char*   usernameBuf = NULL;
    theErr = QTSS_GetValueAsString(theUserProfile, qtssUserName, 0, &usernameBuf);
    OSCharArrayDeleter usernameBufDeleter(usernameBuf);
	qtss_printf("In QTSSDemoODAuthModule: Username from user profile - %s\n", usernameBuf);
	*/
	theErr = QTSS_GetValue (inParams->inRTSPRequest,qtssRTSPReqUserName,0, (void *) nameStr.Ptr, &nameStr.Len);
    if ( (QTSS_NoErr != theErr) || (nameStr.Len >= kBuffLen) ) 
	{
		qtss_printf("In QTSSDemoODAuthModule: QTSSAccess() Username Error - %ld\n", theErr);
    
		return false;    
	}           
    theErr = QTSS_GetValue (inParams->inRTSPRequest,qtssRTSPReqUserPassword,0, (void *) passwordStr.Ptr, &passwordStr.Len);
    if ( (QTSS_NoErr != theErr) || (passwordStr.Len >= kBuffLen) )
	{
		qtss_printf("In QTSSDemoODAuthModule: QTSSAccess() Password Error - %ld\n", theErr);
		return false;        
	}
    nameBuff[nameStr.Len] = '\0';
    passwordBuff[passwordStr.Len] = '\0';
    
	qtss_printf("In QTSSDemoODAuthModule - QTAccess(): Username is %s before CheckAccess\n", nameBuff);
       	
    //
    // Use the name and password to check access
    if ( !accessChecker.CheckAccess(nameBuff, passwordBuff) )
    {
        qtss_printf("Access fail\n");
        return false;
    }
    qtss_printf("In QTAccess(): Access success\n");
    return true;
}

QTSS_Error AuthenticateRTSPRequest(QTSS_RTSPAuth_Params* inParams)
{
	QTSS_RTSPRequestObject  theRTSPRequest = inParams->inRTSPRequest;
	QTSS_AuthScheme authScheme = qtssAuthNone;
    
   // UInt32 fileErr;
    qtss_printf("In QTSSDemoODAuthModule: AuthenticateRTSPRequest start\n");
    //OSMutexLocker locker(sUserMutex);

    if  ( (NULL == inParams) || (NULL == inParams->inRTSPRequest) )
	{
		qtss_printf("In QTSSDemoODAuthModule: AuthenticateRTSPRequest inParams NULL\n");
		return QTSS_RequestFailed;
	}
	
    // Get the user profile object from the request object
    QTSS_UserProfileObject theUserProfile = NULL;
    UInt32 len = sizeof(QTSS_UserProfileObject);
    QTSS_Error theErr = QTSS_GetValue(theRTSPRequest, qtssRTSPReqUserProfile, 0, (void*)&theUserProfile, &len);
    Assert(len == sizeof(QTSS_UserProfileObject));
    if (theErr != QTSS_NoErr)
	{
		qtss_printf("In QTSSDemoODAuthModule: AuthenticateRTSPRequest - username error is %ld\n", theErr);
        return theErr;
	}	
	 // Get the username from the user profile object
	authScheme = qtssAuthBasic;
	//authScheme = qtssAuthDigest;
	 /*if (authScheme == qtssAuthNone)
        {
			qtss_printf("In QTSSDemoODAuthModule: AuthenticateRTSPRequest - get authScheme");
            len = sizeof(authScheme);
            theErr = QTSS_GetValue(theRTSPRequest, qtssRTSPReqAuthScheme, 0, (void*)&authScheme, &len);
			qtss_printf("In QTSSDemoODAuthModule: AuthenticateRTSPRequest - get authScheme");
            Assert(len == sizeof(authScheme));
            if (theErr != QTSS_NoErr)
				return theErr;
		}
        else
        {*/
            theErr = QTSS_SetValue(theRTSPRequest, qtssRTSPReqAuthScheme, 0, (void*)&authScheme, sizeof(authScheme));
            qtss_printf("In QTSSDemoODAuthModule: AuthenticateRTSPRequest - set authScheme\n");
			if (theErr != QTSS_NoErr)
				return theErr;
       // }
	
	char*   usernameBuf = NULL;
    theErr = QTSS_GetValueAsString(theUserProfile, qtssUserName, 0, &usernameBuf);
	qtss_printf("In QTSSDemoODAuthModule: AuthenticateRTSPRequest - username is %s\n", usernameBuf);
    OSCharArrayDeleter usernameBufDeleter(usernameBuf);
	if (theErr != QTSS_NoErr)
	{
		qtss_printf("In QTSSDemoODAuthModule: AuthenticateRTSPRequest - usernameBuf error is %ld\n", theErr);
        //return theErr;
	}	

	 
	return QTSS_NoErr;
	
}


QTSS_Error Authenticate(QTSS_StandardRTSP_Params* inParams)
{
    QTSS_RTSPRequestObject  theRTSPRequest = inParams->inRTSPRequest;
     qtss_printf("In QTSSDemoODAuthModule: Authenticate start\n");
    if  ( (NULL == inParams) || (NULL == inParams->inRTSPRequest) )
	{
		qtss_printf("In QTSSDemoODAuthModule - Authenticate inParams: Error");
        return QTSS_RequestFailed;
    }
		
    //get the local file path
    char*   pathBuffStr = NULL;
    QTSS_Error theErr = QTSS_GetValueAsString(theRTSPRequest, qtssRTSPReqLocalPath, 0, &pathBuffStr);
    QTSSCharArrayDeleter pathBuffDeleter(pathBuffStr);
    if (theErr != QTSS_NoErr)
	{
		qtss_printf("In QTSSDemoODAuthModule - Authenticate [QTSS_GetValueAsString]: Error %ld", theErr);
        return QTSS_RequestFailed;  
	}
    //get the root movie directory
    char*   movieRootDirStr = NULL;
    theErr = QTSS_GetValueAsString(theRTSPRequest,qtssRTSPReqRootDir, 0, &movieRootDirStr);
    OSCharArrayDeleter movieRootDeleter(movieRootDirStr);
    if (theErr != QTSS_NoErr)
	{
		qtss_printf("In QTSSDemoODAuthModule - Authenticate [QTSS_GetValueAsString]: Error %ld", theErr);
        return false;
	}
    //check if this user is allowed to see this movie
    char realmName[kBuffLen] = { 0 };
    //StrPtrLen   realmNameStr(realmName,kBuffLen -1);
	qtss_printf("In QTSSDemoODAuthModule: QTSSAccess movieRootDir is %s\n", movieRootDirStr);
    Bool16 allowRequest = ::QTSSAccess(inParams, pathBuffStr, movieRootDirStr, realmName);
	qtss_printf("In QTSSDemoODAuthModule: QTSSAccess just happened\n");

    if ( realmName[0] != '\0' )     //set the realm if we have one
    {
        (void) QTSS_SetValue(theRTSPRequest,qtssRTSPReqURLRealm, 0, realmName, strlen(realmName) );
		qtss_printf("QTSSDemoODAuthModule in Authenticate(): QTSSAccess realm name is %s\n", realmName);
    }
    

    if (allowRequest)
    {
		qtss_printf("In QTSSDemoODAuthModule: Should be no error.\n");
        return QTSS_NoErr;  //everything's kosher - let the request continue
    }
    else    //request denied
    {
         qtss_printf("In QTSSDemoODAuthModule: Auth error\n");
		// We are denying the request so pass false back to the server.
        theErr = QTSS_SetValue(theRTSPRequest,qtssRTSPReqUserAllowed, 0, &allowRequest, sizeof(allowRequest));
        if (theErr != QTSS_NoErr) 
		{	 qtss_printf("In QTSSDemoODAuthModule: Error %ld\n", theErr);
            return QTSS_RequestFailed; // Bail on the request. The Server will handle the error
        }
    }

    return QTSS_NoErr;
}





