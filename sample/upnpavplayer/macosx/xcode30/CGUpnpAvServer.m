//
//  CGUpnpAvServer.m
//  CyberLink for C
//
//  Created by Satoshi Konno on 08/07/02.
//  Copyright 2008 Satoshi Konno. All rights reserved.
//

#import "CGXmlNode.h"
#import "CGUpnpAvObject.h"
#import "CGUpnpAvContainer.h"
#import "CGUpnpAvItem.h"
#import "CGUpnpAvResource.h"
#import "CGUpnpAvContentDirectory.h"
#import "CGUpnpAvServer.h"

@implementation CGUpnpAvServer

@synthesize contentDirectory;

- (id) init
{
	if ((self = [super init]) == nil)
		return nil;
	contentDirectory = [[CGUpnpAvContentDirectory alloc] init];
	return self;
}

- (id) initWithCObject:(CgUpnpDevice *)cobj
{
	if ((self = [super initWithCObject:cobj]) == nil)
		return nil;
	contentDirectory = [[CGUpnpAvContentDirectory alloc] init];
	return self;
}

- (void)setUserObject:(id)aUserObj;
{
	id userObj = [self userObject];
	if (userObj != aUserObj) {
		[userObj release];
		[aUserObj retain];
		[self setUserData:aUserObj];
	}
}

- (id)userObject
{
	void *userData = [self userData];
	if (!userData)
		return nil;
	return (id)userData;
}

- (void)dealloc
{
	id userObj = [self userObject];
	if (userObj)
		[userObj release];
	[contentDirectory release];
	[super dealloc];
}

- (void)finalize
{
	id userObj = [self userObject];
	if (userObj)
		[userObj release];
	[contentDirectory release];
	[super finalize];
}

- (CGUpnpAvObject *)objectForId:(NSString *)aObjectId
{
	return [contentDirectory objectForId:aObjectId];
}

- (CGUpnpAvObject *)objectForTitlePath:(NSString *)aTitlePath
{
	return [contentDirectory objectForTitlePath:aTitlePath];
}

- (NSArray *)browse:(NSString *)aObjectId;
{
	CGUpnpService *conDirService = [self getServiceForType:@"urn:schemas-upnp-org:service:ContentDirectory:1"];
	if (!conDirService)
		return nil;

	CGUpnpAction *browseAction = [conDirService getActionForName:@"Browse"];
	if (!browseAction)
		return nil;

	[browseAction setArgumentValue:aObjectId forName:@"ObjectID"];
	[browseAction setArgumentValue:@"BrowseDirectChildren" forName:@"BrowseFlag"];
	[browseAction setArgumentValue:@"*" forName:@"Filter"];
	[browseAction setArgumentValue:@"0" forName:@"StartingIndex"];
	[browseAction setArgumentValue:@"0" forName:@"RequestedCount"];
	[browseAction setArgumentValue:@"" forName:@"SortCriteria"];
	
	if (![browseAction post])
		return nil;
	
	NSString *resultStr = [browseAction argumentValueForName:@"Result"];
	NSArray *avObjArray =  [CGUpnpAvObject arrayWithXMLString:resultStr];
	
	/* Update Content Manager */
	CGUpnpAvObject *parentObj = [self objectForId:aObjectId];
	if (parentObj != nil && [parentObj isContainer]) {
		CGUpnpAvContainer *parentCon = (CGUpnpAvContainer *)parentObj;
		[parentCon removeAllChildren];
		[parentCon addChildren:avObjArray];
	}
	
	return avObjArray;	
}

@end
