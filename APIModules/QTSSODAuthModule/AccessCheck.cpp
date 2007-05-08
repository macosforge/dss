/*
 *
 * Copyright (c) 1999-2005 Apple Computer, Inc.  All Rights Reserved.
 * 
 * @APPLE_LICENSE_HEADER_START@
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
	File:   	AccessCheck.cpp

	Contains:   Class definition for access checking via Open Directory
  
	Created By: Dan Sinema
  
	Created: Jan 14, 2005
  
*/

/*
 *	Directory Service code added by Dan Sinema
 *	
 *	Jan 14, 2005 - Cleaned up code and added more comments.
 *	Nov 8, 2004 - Finsihed final code. Added group support.
 *	
*/


// ANSI / POSIX Headers
#ifndef __MW_
	#include <signal.h>
	#ifndef __USE_XOPEN
		#define __USE_XOPEN 1
	#endif
	#include <unistd.h>
#endif

#if __solaris__ || __sgi__
#include <crypt.h>
#endif

// STL Headers
#include <cstdio>
#include <cstdlib>
#include <cstring>

// Framework Headers
#include <DirectoryService/DirectoryService.h>

// Project Headers
#include "SafeStdLib.h"	// for qtss_printf()
#include "StrPtrLen.h"
#include "StringParser.h"

#include "AccessCheck.h"


#pragma mark AccessChecker class implementation

AccessChecker::AccessChecker(const char* inMovieRootDir, const char* inQTAccessFileName, const char* inUsersFilePath, const char* inGroupsFilePath) :
	fRealmHeader(NULL),
	fMovieRootDir(inMovieRootDir),
	fQTAccessFileName(inQTAccessFileName),
	fGroupsFilePath(inGroupsFilePath),
	fUsersFilePath(inUsersFilePath),
	fAccessFile(NULL),
	fUsersFile(NULL),
	fGroupsFile(NULL)
{
	Assert(inMovieRootDir != NULL);
	Assert(inQTAccessFileName != NULL);
	Assert(inUsersFilePath != NULL);
	Assert(inGroupsFilePath != NULL);
}

AccessChecker::~AccessChecker()
{
	if ( fUsersFile != NULL )
		std::fclose(fUsersFile);
	if ( fGroupsFile != NULL )
		std::fclose(fGroupsFile);
	if ( fAccessFile != NULL )
		std::fclose(fAccessFile);
}

bool AccessChecker::CheckAccess(const char* inUsername, const char* inPassword)
{
	::qtss_printf("In QTSSDemoODAuthModule: Check Access\n");
	// password's cool, check if this guy has dir access
	if ( this->CheckPassword(inUsername, inPassword) &&
	 	this->CheckUserAccess(inUsername) )
	{
		::qtss_printf("QTSSDemoODAuthModule: Check Access - access successful\n");
		return true;
	}
	::qtss_printf("QTSSDemoODAuthModule: Check Access - access failed\n");
	return false;
}


bool AccessChecker::CheckPassword(const char* inUsername, const char* inPassword)
{
	//char						*domain				= NULL;
	tDirReference				dsRef				= 0;
	tDataBuffer					*tDataBuff			= NULL;
	tDirNodeReference			nodeRef				= 0;
	long					 	status				= eDSNoErr;
	tContextData				context				= NULL;
	unsigned long				nodeCount			= 0;
	unsigned long				attrIndex			= 0;
	tDataList					*nodeName			= NULL;
	tAttributeEntryPtr			pAttrEntry			= NULL;
	tDataList					*pRecName			= NULL;
	tDataList					*pRecType			= NULL;
	tDataList					*pAttrType			= NULL;
	unsigned long				recCount			= 0;
	tRecordEntry		  	 	*pRecEntry			= NULL;
	tAttributeListRef			attrListRef			= 0;
	char						*pUserLocation		= NULL;
	tAttributeValueListRef		valueRef			= 0;
	tAttributeValueEntry		*pValueEntry		= NULL;
	tDataList					*pUserNode			= NULL;
	tDirNodeReference			userNodeRef			= 0;
	tDataBuffer					*pStepBuff			= NULL;
	tDataNode					*pAuthType			= NULL;
	unsigned long				uiCurr				= 0;
	unsigned long				uiLen				= 0;
	bool						result				= false;

	// A Username and Password is needed, if either one is not present then bail!
	if ( inUsername == NULL )
	{
		::qtss_printf("QTSSDemoODAuthModule: Username required");
		return false;
	}
	if ( inPassword == NULL )
	{
		::qtss_printf("QTSSDemoODAuthModule: Password required");
		return false;
	}

	do
	{
		status = ::dsOpenDirService( &dsRef );
		if ( status != eDSNoErr )
		{	
			// Some DS error, tell the admin what the error is and bail. Error can be found in DirectoryService man page
			::qtss_printf("QTSSDemoODAuthModule: Could not open Directory Services - error: %ld", status);
			break;
		}

		tDataBuff = ::dsDataBufferAllocate( dsRef, 4096 );
		if (tDataBuff == NULL)
		{   
			// We need the buffer for locating the node for which the user object resides
			::qtss_printf("QTSSDemoODAuthModule: Buffer did not allocate");
			break;
		}

		// Debug, help for admin when running QTSS in debug mode this will display the username
		// ::qtss_printf("QTSSDemoODAuthModule: Username is %s\n", inUsername);

		// See if there is a domain specified, although the dsqtaccess files does not allow for specifing of domains, allows for future growth if needed
		// Commeted for the time being...
		/*
		if ( domain != NULL )
		{
			// Parse a node name
			nodeName = dsBuildFromPath( dsRef, domain, "/" );

			// if the node name is null, then we need to bail
			if ( nodeName == NULL ) break;

				// Look for the user on the specified node, remember you cannot specify a node currently in the dsqtaccess file.
			status = dsFindDirNodes( dsRef, tDataBuff, nodeName, eDSiExact, &nodeCount, &context );
		}
		else
		{
			// This is the default action, make it easy for the admin. We will look up the user on the Search node, so the domain does not need to be specified.
			status = dsFindDirNodes( dsRef, tDataBuff, NULL, eDSSearchNodeName, &nodeCount, &context );
		}
		*/
		// Since we are not passing nodes (domains) right now, we will cut to the chase and set the Search Node
		status = ::dsFindDirNodes( dsRef, tDataBuff, NULL, eDSSearchNodeName, &nodeCount, &context );

		// Check for failure of the dsFindDirNodes
		// Node count less than 1 means no node found...doh! 
		if ( ( status != eDSNoErr ) || ( nodeCount < 1 ) )
		{
			break;
		}

		// So the node found, grab the name...
		status = ::dsGetDirNodeName( dsRef, tDataBuff, 1, &nodeName );
		if (status != eDSNoErr)
		{
			break;
		}

		// Open the node so we can do the DS magic
		status = ::dsOpenDirNode( dsRef, nodeName, &nodeRef );
		::dsDataListDeallocate( dsRef, nodeName );
		std::free( nodeName );
		nodeName = NULL;

		if (status != eDSNoErr)
		{	
			// Bail if we cannot open the node.
			::qtss_printf("QTSSDemoODAuthModule: Could not open node - error: %ld",  status);
			break;
		}

		// Now time to specify what we are looking for...
		// pRecName: the <username>
		// pRecordType: we are looking for user records (kDSStdRecordTypeUsers)
		// pAttrType: The attributes we want back are the user node location (kDSNAttrMetaNodeLocation) and the user object record (kDSNAttrRecordName)
		pRecName = ::dsBuildListFromStrings( dsRef, inUsername, NULL );
		pRecType = ::dsBuildListFromStrings( dsRef, kDSStdRecordTypeUsers, NULL );
		pAttrType = ::dsBuildListFromStrings( dsRef, kDSNAttrMetaNodeLocation, NULL );

		recCount = 1;

		// Find the record that matchs the above criteria
		status = ::dsGetRecordList( nodeRef, tDataBuff, pRecName, eDSExact, pRecType, pAttrType, 0, &recCount, &context );
		if ( status != eDSNoErr || recCount == 0 )
		{
			break;
		}

		// Get the record entry out of the list, there should only be one record!

		status = ::dsGetRecordEntry( nodeRef, tDataBuff, 1, &attrListRef, &pRecEntry );
		if ( status != eDSNoErr )
		{
			break;
		}

		// Now loop through attributes of the entry...looking for kDSNAttrMetaNodeLocation and kDSNAttrRecordName
		for ( attrIndex = 1; (attrIndex <= pRecEntry->fRecordAttributeCount) && (status == eDSNoErr); attrIndex++ )
		{
			status = ::dsGetAttributeEntry( nodeRef, tDataBuff, attrListRef, attrIndex, &valueRef, &pAttrEntry );
			if ( status == eDSNoErr && pAttrEntry != NULL )
			{
				// Test for kDSNAttrMetaNodeLocation
				if ( std::strcmp( pAttrEntry->fAttributeSignature.fBufferData, kDSNAttrMetaNodeLocation ) == 0 )
				{
					// If it matches then get the value of the attribute
					status = ::dsGetAttributeValue( nodeRef, tDataBuff, 1, valueRef, &pValueEntry );
					if ( status == eDSNoErr && pValueEntry != NULL )
					{
						// Store the node location in pUserLocation
						pUserLocation = (char *) std::calloc( pValueEntry->fAttributeValueData.fBufferLength + 1, sizeof(char) );
						std::memcpy( pUserLocation, pValueEntry->fAttributeValueData.fBufferData, pValueEntry->fAttributeValueData.fBufferLength );
					}
				}

				// Clean up...
				if ( pValueEntry != NULL )
				{
					::dsDeallocAttributeValueEntry( dsRef, pValueEntry );
					pValueEntry = NULL;
				}

				::dsDeallocAttributeEntry( dsRef, pAttrEntry );
				pAttrEntry = NULL;
				::dsCloseAttributeValueList( valueRef );
				valueRef = 0;
			}
		}

		// Now that we know the node location of the user object, lets open that node.
		pUserNode = ::dsBuildFromPath( dsRef, pUserLocation, "/" );
		status = ::dsOpenDirNode( dsRef, pUserNode, &userNodeRef );
		if ( status != eDSNoErr )
		{
			break;
		}
		pStepBuff = ::dsDataBufferAllocate( dsRef, 128 );

		pAuthType = ::dsDataNodeAllocateString( dsRef, kDSStdAuthNodeNativeClearTextOK );
		uiCurr = 0;

		// Copy username (that is passed into this function) into buffer for dsDoDirNodeAuth()
		uiLen = strlen( inUsername );
		std::memcpy( &(tDataBuff->fBufferData[ uiCurr ]), &uiLen, sizeof( unsigned long ) );
		uiCurr += sizeof( unsigned long );
		std::memcpy( &(tDataBuff->fBufferData[ uiCurr ]), inUsername, uiLen );
		uiCurr += uiLen;

		// Copy password into a buffer for dsDoDirNodeAuth()
		uiLen = strlen( inPassword );
		std::memcpy( &(tDataBuff->fBufferData[ uiCurr ]), &uiLen, sizeof( unsigned long ) );
		uiCurr += sizeof( unsigned long );
		std::memcpy( &(tDataBuff->fBufferData[ uiCurr ]), inPassword, uiLen );
		uiCurr += uiLen;

		tDataBuff->fBufferLength = uiCurr;

		// Do the actual authentication here
		status = ::dsDoDirNodeAuth( userNodeRef, pAuthType, 1, tDataBuff, pStepBuff, NULL );

		if( status == eDSNoErr )
		{
			// For admins running QTSS in debug
			::qtss_printf("QTSSDemoODAuthModule: Authentication is good\n");
			result = true;
		}
	}
	while ( 0 );

	// Clean up...
	if (tDataBuff != NULL)
	{
		std::memset(tDataBuff, 0, tDataBuff->fBufferSize);
		::dsDataBufferDeAllocate( dsRef, tDataBuff );
		tDataBuff = NULL;
	}

	if (pStepBuff != NULL)
	{
		::dsDataBufferDeAllocate( dsRef, pStepBuff );
		pStepBuff = NULL;
	}
	if (pUserLocation != NULL )
	{
		std::free(pUserLocation);
		pUserLocation = NULL;
	}
	if (pRecName != NULL)
	{
		::dsDataListDeallocate( dsRef, pRecName );
		std::free( pRecName );
		pRecName = NULL;
	}
	if (pRecType != NULL)
	{
		::dsDataListDeallocate( dsRef, pRecType );
		std::free( pRecType );
		pRecType = NULL;
	}
	if (pAttrType != NULL)
	{
		::dsDataListDeallocate( dsRef, pAttrType );
		std::free( pAttrType );
		pAttrType = NULL;
	}
	if (nodeRef != 0)
	{
		::dsCloseDirNode(nodeRef);
		nodeRef = 0;
	}
	if (dsRef != 0)
	{
		::dsCloseDirService(dsRef);
		dsRef = 0;
	}

	// If the Authentication failed then return false, which boots the user...
	return result;
}

bool AccessChecker::CheckUserAccess(const char* inUsername)
{
	::qtss_printf("In QTSSDemoODAuthModule: Check User Access - start\n");

	const int kBufLen = 2048;
	char buf[kBufLen];
	StrPtrLen bufLine;

	if ( fAccessFile == NULL )
		return false;

	std::rewind(fAccessFile);
	while ( std::fgets(buf, kBufLen, fAccessFile) != NULL )
	{
		bufLine.Set(buf, strlen(buf));
		StringParser bufParser(&bufLine);

		//skip over leading whitespace
		bufParser.ConsumeUntil(NULL, StringParser::sWhitespaceMask);

		//skip over comments and blank lines...
		if ((bufParser.GetDataRemaining() == 0) || (bufParser[0] == '#') || (bufParser[0] == '\0') )
			continue;

		StrPtrLen word;
		bufParser.ConsumeWord(&word);
		if ( word.Equal("require") )
		{
			bufParser.ConsumeWhitespace();
			bufParser.ConsumeWord(&word);

			if ( word.Equal("user") )
			{
				while (word.Len != 0)
				{
					bufParser.ConsumeWhitespace();
					bufParser.ConsumeWord(&word);

					if (word.Equal(inUsername)) 
					{
						 ::qtss_printf("QTSSDemoODAuthModule in CheckUserAccess() : user %s found\n", inUsername);
						return true;
					}
				}
			}
			else if (word.Equal("valid-user"))
			{   
				::qtss_printf("QTSSDemoODAuthModule in CheckUserAccess(): valid-user\n");
				return true;
			}
			else if ( word.Equal("group") )
			{
				while (word.Len != 0)
				{
					bufParser.ConsumeWhitespace();
					bufParser.ConsumeWord(&word);
					if ( this->CheckGroupMembership(inUsername, word.GetAsCString()) )
					{
						::qtss_printf("QTSSDemoODAuthModule in CheckUserAccess(): user is part of %s group\n", word.GetAsCString());
						return true;
					}
				}
			}
		}
	}

	return false;
}

bool AccessChecker::CheckGroupMembership(const char* inUsername, const char* inGroupName)
{   
	bool						retVal				= false;
	long						dirStatus			= eDSNoErr;
	tDirReference				dsRef				= 0;
	tDirNodeReference			nodeRef				= 0;
	tDataListPtr				nodePath			= NULL;
	tRecordReference			recRef				= 0;
	tDataNodePtr				recName				= NULL;
	tDataNodePtr				recType				= NULL;
	tDataListPtr				recTypeList			= NULL;
	tDataNodePtr				attrType			= NULL;
	tDataNodePtr				searchValue			= NULL;
	tDataNodePtr				groupMember			= NULL;
	tDataList					searchAttrs;
	dsBool						attrInfoOnly		= 0; //false

	unsigned long				bufferSize			= 10 * 1024;
	tDataBufferPtr				dataBuffer			= NULL;

	unsigned long				recordCount			= 0;
	unsigned long				recordIndex			= 0;
	tRecordEntryPtr				recordEntry			= NULL;
	tContextData				*currentContextData = NULL;
	unsigned long				attributeIndex		= 0;
	tAttributeListRef			attributeList		= 0;
	tAttributeEntryPtr			attributeEntry		= NULL;

	unsigned long				valueIndex			= 0;
	tAttributeValueEntryPtr		valueEntry			= NULL;
	tAttributeValueListRef		valueList			= 0;

	//Search Node Stuff
	tDataBuffer					*tDataBuff			= NULL;
	long					 	status				= eDSNoErr;
	tContextData				context				= NULL;
	unsigned long				nodeCount			= 0;
	unsigned long				attrIndex			= 0;
	tDataList					*nodeName			= NULL;
	tAttributeEntryPtr			pAttrEntry			= NULL;
	tDataList					*pRecName			= NULL;
	tDataList					*pRecType			= NULL;
	tDataList					*pAttrType			= NULL;
	unsigned long				recCount			= 0;
	tRecordEntry		  	 	*pRecEntry			= NULL;
	tAttributeListRef			attrListRef			= 0;
	char						*pGroupLocation		= NULL;
	char						*pGroupName			= NULL;
	tAttributeValueListRef		valueRef			= 0;
	tAttributeValueEntry		*pValueEntry		= NULL;
	tDataList					*pGroupNode			= NULL;
	tDirNodeReference			groupNodeRef		= 0;
	//tDataBuffer					*pStepBuff			= NULL;

	//open DS
	if (inUsername == NULL) 
	{
	  ::qtss_printf( "ds_check_group() error: no username");
	  return retVal;
	}
	::qtss_printf( "ds_check_group(): username is %s\n", inUsername);
	if ( inGroupName == NULL )
	{
	  ::qtss_printf( "ds_check_group() error: no group");
	  return retVal;
	}
	::qtss_printf( "ds_check_group(): Group name is %s\n", inGroupName);

	dirStatus = ::dsOpenDirService( &dsRef );

	if ( dirStatus != eDSNoErr )
	{
	  ::qtss_printf( "ds_check_group() error: dsOpenDirService = %ld\n", dirStatus);
	  return retVal;
	}
	::qtss_printf( "ds_check_group() info: dsOpenDirService = %lu\n", (unsigned long)dsRef);

	/*//open Node
	nodePath = dsBuildFromPath( dsRef, domain, "/" );
	if ( nodePath != NULL )
	{
		::qtss_printf( "ds_check_group() info: nodePath is not NULL\n");
		dirStatus = dsOpenDirNode( dsRef, nodePath, &nodeRef );

		if ( dirStatus == eDSNoErr )
		{
			::qtss_printf(  "Open succeeded. Node Reference = %lu\n", (unsigned long)nodeRef );
		}
		else
		{
			::qtss_printf(  "Open node failed. Err = %ld\n", dirStatus );
			return retVal;
		}
	}*/

	recName = ::dsDataNodeAllocateString( dsRef, inGroupName );
	dataBuffer = ::dsDataBufferAllocate(dsRef, bufferSize);

	//Search lookup
	tDataBuff = ::dsDataBufferAllocate( dsRef, 4096 );
	if (tDataBuff == NULL)
	{
		::qtss_printf("QTSSDemoODAuthModule: Buffer did not allocate");
		return false;
	}

	dirStatus = ::dsFindDirNodes( dsRef, tDataBuff, NULL, eDSSearchNodeName, &nodeCount, &context );

	if ( dirStatus != eDSNoErr )
	{
		::qtss_printf( "Error opening Search node: %ld\n", status);	
		return false;
	}

	if ( nodeCount < 1 )
	{
		return false;
	}

	dirStatus = ::dsGetDirNodeName( dsRef, tDataBuff, 1, &nodeName );
	if (dirStatus != eDSNoErr)
	{
	  return false;
	}
	dirStatus = ::dsOpenDirNode( dsRef, nodeName, &nodeRef );
	::dsDataListDeallocate( dsRef, nodeName );
	std::free( nodeName );
	nodeName = NULL;
	if (dirStatus != eDSNoErr)
	{
		return false;
	}

	pRecName = ::dsBuildListFromStrings( dsRef, inGroupName, NULL );
	pRecType = ::dsBuildListFromStrings( dsRef, kDSStdRecordTypeGroups, NULL );
	pAttrType = ::dsBuildListFromStrings( dsRef, kDSNAttrMetaNodeLocation, kDSNAttrRecordName, NULL );

	recCount = 1;
	dirStatus = ::dsGetRecordList( nodeRef, tDataBuff, pRecName, eDSExact, pRecType, pAttrType, 0, &recCount, &context );
	if ( dirStatus != eDSNoErr || recCount == 0 )
	{
		return false;
	}
	::qtss_printf( "Record Count is  %ld\n", recCount);	
	dirStatus = ::dsGetRecordEntry( nodeRef, tDataBuff, 1, &attrListRef, &pRecEntry );
	if ( dirStatus != eDSNoErr )
		return false;


	for ( attrIndex = 1; (attrIndex <= pRecEntry->fRecordAttributeCount) && (dirStatus == eDSNoErr); attrIndex++ )
	{
		dirStatus = ::dsGetAttributeEntry( nodeRef, tDataBuff, attrListRef, attrIndex, &valueRef, &pAttrEntry );
		if ( dirStatus == eDSNoErr && pAttrEntry != NULL )
		{
			if ( std::strcmp( pAttrEntry->fAttributeSignature.fBufferData, kDSNAttrMetaNodeLocation ) == 0 )
			{
				dirStatus = ::dsGetAttributeValue( nodeRef, tDataBuff, 1, valueRef, &pValueEntry );
				if ( dirStatus == eDSNoErr && pValueEntry != NULL )
				{
					pGroupLocation = (char *) std::calloc( pValueEntry->fAttributeValueData.fBufferLength + 1, sizeof(char) );
					std::memcpy( pGroupLocation, pValueEntry->fAttributeValueData.fBufferData, pValueEntry->fAttributeValueData.fBufferLength );
				}
			}
			else 
			if ( strcmp( pAttrEntry->fAttributeSignature.fBufferData, kDSNAttrRecordName ) == 0 )
			{
				dirStatus = ::dsGetAttributeValue( nodeRef, tDataBuff, 1, valueRef, &pValueEntry );
				if ( dirStatus == eDSNoErr && pValueEntry != NULL )
				{
					pGroupName = (char *) std::calloc( pValueEntry->fAttributeValueData.fBufferLength + 1, sizeof(char) );
					std::memcpy( pGroupName, pValueEntry->fAttributeValueData.fBufferData, pValueEntry->fAttributeValueData.fBufferLength );
				}
			}

			if ( pValueEntry != NULL )
				::dsDeallocAttributeValueEntry( dsRef, pValueEntry );
			pValueEntry = NULL;

			::dsDeallocAttributeEntry( dsRef, pAttrEntry );
			pAttrEntry = NULL;
			::dsCloseAttributeValueList( valueRef );
			valueRef = 0;
		}
	}

	pGroupNode = ::dsBuildFromPath( dsRef, pGroupLocation, "/" );
	::qtss_printf( "ds_check_group(): Node location of %s is %s\n", pGroupName, pGroupLocation);
	dirStatus = ::dsOpenDirNode( dsRef, pGroupNode, &groupNodeRef );
	if ( dirStatus != eDSNoErr )
		return 1;
	//End Search Lookup

	if ( recName != NULL )
	{
		recType = ::dsDataNodeAllocateString( dsRef, kDSStdRecordTypeGroups);
		recTypeList = ::dsBuildListFromStrings(dsRef, kDSStdRecordTypeGroups, NULL);

		if ( recType != NULL )
		{
			dirStatus = ::dsOpenRecord( groupNodeRef, recType, recName, &recRef );

			if ( dirStatus == eDSNoErr )
			{
				attrType = ::dsDataNodeAllocateString(dsRef, kDSNAttrGroupMembership );
				groupMember = ::dsDataNodeAllocateString(dsRef, kDSNAttrGroupMembership );
				searchValue = ::dsDataNodeAllocateString(dsRef, inUsername );

				dirStatus = ::dsBuildListFromStringsAlloc ( dsRef, &searchAttrs, kDSNAttrRecordName, NULL );

				if ( attrType != NULL )
				{
					dirStatus = ::dsDoAttributeValueSearchWithData(groupNodeRef, dataBuffer, recTypeList, attrType, eDSExact, searchValue,  &searchAttrs, attrInfoOnly, &recordCount, currentContextData);
					if (dirStatus == eDSNoErr)
					{
						::qtss_printf( "Records found %lu\n", recordCount);
					}

					for (recordIndex = 1; recordIndex <= recordCount; recordIndex++)
					{
						dirStatus = ::dsGetRecordEntry(groupNodeRef, dataBuffer, recordIndex, &attributeList, &recordEntry);
						if (dirStatus != eDSNoErr) 
						{
							::qtss_printf( "dsGetRecordEntry error (%ld)",dirStatus);
							break; 
						}
						for (attributeIndex = 1; attributeIndex <= recordEntry->fRecordAttributeCount; attributeIndex++) 
						{
							dirStatus = ::dsGetAttributeEntry(groupNodeRef, dataBuffer, attributeList, attributeIndex, &valueList, &attributeEntry);
							if (dirStatus != eDSNoErr)
							{
								::qtss_printf( "dsGetAttributeEntry error (%ld)",dirStatus);
								break; 
							}
							for (valueIndex = 1; valueIndex <= attributeEntry->fAttributeValueCount; valueIndex++) 
							{
								dirStatus = ::dsGetAttributeValue(groupNodeRef, dataBuffer, valueIndex, valueList, &valueEntry);
								if (dirStatus != eDSNoErr)
								{
									::qtss_printf( "dsGetAttributeValue error (%ld)",dirStatus);
									break; 
								}
								if (valueEntry->fAttributeValueData.fBufferLength != 0)
								{
									if( std::strcmp(inGroupName, (const char*)valueEntry->fAttributeValueData.fBufferData) == 0 )
									{
										::qtss_printf( "Found it! The user is a member of %s\n", (const char*)valueEntry->fAttributeValueData.fBufferData);
										retVal = true;
										goto done;
									}
									else
									{   
										::qtss_printf( "Failed! The user is not a member of %s\n", inGroupName);
										retVal = false;
									}
								}

							}
						}
					}
					::dsDeallocAttributeValueEntry(groupNodeRef, valueEntry);
					valueEntry = NULL;
				}
				dirStatus = ::dsDataNodeDeAllocate( dsRef, attrType );
				attrType = NULL;
			}
		}
		dirStatus = ::dsDataNodeDeAllocate( dsRef, recType );
		recType = NULL;
	}

	dirStatus = ::dsDataNodeDeAllocate( dsRef, recName );
	recName = NULL;

done:
	if( valueEntry != NULL)
	{
		::dsDeallocAttributeValueEntry(groupNodeRef, valueEntry);
		valueEntry = NULL;
	}
	if( attrType != NULL)
	{
		::dsDataNodeDeAllocate( dsRef, attrType );
		attrType = NULL;
	}
	if( recType != NULL)
	{
		::dsDataNodeDeAllocate( dsRef, recType );
		recType = NULL;
	}
	if( recName != NULL)
	{
		dirStatus = ::dsDataNodeDeAllocate( dsRef, recName );
		recName = NULL;
	}
	if( valueList )
	{
		::dsCloseAttributeValueList(valueList);
		valueList = 0;
	}
	if( dataBuffer != NULL)
	{
		std::memset(dataBuffer, 0, dataBuffer->fBufferSize);
		::dsDataBufferDeAllocate( dsRef, dataBuffer );
		dataBuffer = NULL;
	}
	if( nodePath != NULL)
	{
		::dsDataListDeallocate( dsRef, nodePath );
		std::free( nodePath );
		nodePath = NULL;
	}
	if( recRef )
	{
	 //dsCloseRecord
	}
	if( attributeList )
	{
		::dsCloseAttributeList( attributeList );
		//free( attributeList);
		attributeList = 0;
	}
	if( attributeEntry != NULL)
	{
		attributeEntry = NULL;
	}
	if( groupNodeRef != 0)
	{
		::dsCloseDirNode(groupNodeRef);
		nodeRef = 0;
	}
	if (dsRef != 0)
	{
		::dsCloseDirService(dsRef);
		dsRef = 0;
	}

	return retVal;
}

bool AccessChecker::GetAccessFile(const char* dirPath)
{
	char* currentDir= NULL;
	char* lastSlash = NULL;
	int movieRootDirLen = fMovieRootDir.length();

	currentDir = new char[std::strlen(dirPath) + fQTAccessFileName.length()];

	std::strcpy(currentDir, dirPath);

	//strip off filename
	lastSlash = ::strrchr(currentDir, '/');
	if (lastSlash != NULL)
		lastSlash[0] = '\0';

	//check qtaccess files

	while ( true )  //walk backward up the dir tree?
	{
		std::strcat(currentDir, "/");
		std::strcat(currentDir, fQTAccessFileName.c_str());

		fAccessFile = std::fopen(currentDir, "r");

		//strip off the "/qtaccess"
		lastSlash = std::strrchr(currentDir, '/');
		lastSlash[0] = '\0';


		if ( fAccessFile != NULL )
		{
			::qtss_printf("QTSSDemoODAuthModule: Found dsqtaccess file\n");
			this->GetAccessFileInfo(currentDir);	
			delete[] currentDir;
			return true;
		}
		else
		{   
			//strip of the tailing directory
			lastSlash = std::strrchr(currentDir, '/');
			if (lastSlash == NULL)
				break;
			else
				lastSlash[0] = '\0';
		}

		if ( (lastSlash-currentDir) < movieRootDirLen ) //bail if we start eating our way out of fMovieRootDir
			break;
	}

	delete[] currentDir;
	return false;
}

void AccessChecker::GetAccessFileInfo(const  char* inQTAccessDir)
{
	Assert( fAccessFile != NULL);

	const int kBufLen = 2048;
	char buf[kBufLen];
	StrPtrLen bufLine;
	::qtss_printf("QTSSDemoODAuthModule: File Info\n");
	while ( std::fgets(buf, kBufLen, fAccessFile) != NULL )
	{
		bufLine.Set(buf, strlen(buf));
		StringParser bufParser(&bufLine);

		//skip over leading whitespace
		bufParser.ConsumeUntil(NULL, StringParser::sWhitespaceMask);

		//skip over comments and blank lines...

		if ( (bufParser.GetDataRemaining() == 0) || (bufParser[0] == '#') || (bufParser[0] == '\0') )
			continue;

		StrPtrLen word;
		bufParser.ConsumeWord(&word);
		bufParser.ConsumeWhitespace();

		if ( word.Equal("AuthName") ) //realm name
		{
			bufParser.GetThruEOL(&word);
			fRealmHeader = word.Ptr;
		}
		else if ( word.Equal("AuthUserFile" ) ) //users name
		{
			char filePath[kBufLen];
			bufParser.GetThruEOL(&word); 
			if (word.Ptr[0] == '/') //absolute path
			{
				std::memcpy(filePath, word.Ptr, word.Len);
				filePath[word.Len] = '\0';
			}
			else
			{
				std::snprintf(filePath, sizeof(filePath), "%s/%s", inQTAccessDir, word.Ptr);
			}
			fUsersFile = std::fopen(filePath, "r");
		}
		else if ( word.Equal("AuthGroupFile") ) //groups name
		{
			char filePath[kBufLen];
			bufParser.GetThruEOL(&word); 
			if (word.Ptr[0] == '/') //absolute path
			{
				std::memcpy(filePath, word.Ptr, word.Len);
				filePath[word.Len] = '\0';
			}
			else
			{
				std::snprintf(filePath, sizeof(filePath), "%s/%s", inQTAccessDir, word.Ptr);
			}
			fGroupsFile = std::fopen(filePath, "r");
		}
	}

	if (fUsersFile == NULL)
	{
		fUsersFile = std::fopen(fUsersFilePath.c_str(), "r");
	}

	if (fGroupsFile == NULL)
	{
		fGroupsFile = std::fopen(fGroupsFilePath.c_str(), "r");
	}
}


