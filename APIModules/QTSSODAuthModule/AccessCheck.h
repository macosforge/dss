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
	File:       AccessCheck.h

	Contains:   Class definition for access checking via Open Directory

	Created By: Dan Sinema

	Created: Jan 14, 2005
*/

#ifndef _QTSSACCESSCHECK_H_
#define _QTSSACCESSCHECK_H_

// STL Headers
#include <cstdio>	// for struct FILE
#include <string>

class AccessChecker
{
/*
    Access check logic:
    
    If "modAccess_enabled" == "enabled,
    Starting at URL dir, walk up directories to Movie Folder until a "qtaccess" file is found
        If not found, 
            allow access
        If found, 
            send a challenge to the client
            verify user against QTSSPasswd
            verify that user or member group is in the lowest ".qtacess"
            walk up directories until a ".qtaccess" is found
            If found,
                allow access
            If not found, 
                deny access
                
    ToDo:
        would probably be a good idea to do some caching of ".qtaccess" data to avoid
        multiple directory walks
*/

public:
	AccessChecker(const char* inMovieRootDir, const char* inQTAccessFileName, const char* inDefaultUsersFilePath, const char* inDefaultGroupsFilePath);
	virtual ~AccessChecker();
	bool CheckAccess(const char* inUsername, const char* inPassword);
	bool CheckPassword(const char* inUsername, const char* inPassword);
	void GetPassword(const char* inUsername, char* ioPassword);
	bool CheckUserAccess(const char* inUsername);
	bool CheckGroupMembership(const char* inUsername, const char* inGroupName);
	bool GetAccessFile(const char* dirPath);

	inline const char* GetRealmHeaderPtr() {return fRealmHeader.c_str();}


protected:
	std::string fRealmHeader;
	std::string fMovieRootDir;
	std::string fQTAccessFileName;
	std::string fGroupsFilePath;
	std::string fUsersFilePath;
	FILE*  fAccessFile;
	FILE*  fUsersFile;
	FILE*  fGroupsFile;

	static const char* kDefaultUsersFilePath;
	static const char* kDefaultGroupsFilePath;
	static const char* kDefaultAccessFileName;
	static const char* kDefaultRealmHeader;

	void GetAccessFileInfo(const  char* inQTAccessDir);
};

#endif //_QTSSACCESSCHECK_H_
