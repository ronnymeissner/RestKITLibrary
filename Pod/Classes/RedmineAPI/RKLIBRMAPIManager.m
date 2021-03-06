//
//  RKLIBRMAPIManager.m
//  Pods
//
//  Created by Ronny Meissner on 25/09/14.
//
//

#import "RKLIBRMAPIManager.h"
#import "RKLIBDef.h"
#import "RKLIBRMMappingHelper.h"


@implementation RKLIBRMAPIManager {
	NSString *_password;
	NSString *_user;
	NSString *_url;
}

/**
 *  Create a Singleton instance.
 *
 *  @return A Singleton instance of RKLIBRMAPIManager.
 */
+ (instancetype)sharedManager {
	static RKLIBRMAPIManager *sharedMapper = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedMapper = [[RKLIBRMAPIManager alloc] init];
	});
	return sharedMapper;
}

/**
 *  Configrure the RKLIBRMAPIManager instance with url and login. Throws assert if one parameter is missing.
 *
 *  @param url      Define the redmine host url as NSString.
 *  @param username Define a specific user name as NSString.
 *  @param password Define a specific user password as NSString.
 */
- (void)configureWithUrl:(NSString *)url withUser:(NSString *)username withPassword:(NSString *)password {
	NSParameterAssert(url);
	NSParameterAssert(username);
	NSParameterAssert(password);
	NSAssert(url.length != 0, @"configureWithUrl:withUser:withPassword - url is empty");
	NSAssert(username.length != 0, @"configureWithUrl:withUser:withPassword - username is empty");
	NSAssert(password.length != 0, @"configureWithUrl:withUser:withPassword - password is empty");
	_url = url;
	_user = username;
	_password = password;
}

- (RKObjectManager *)objectManager {
	// check if exists
	if (!_objectManager) {
		// create new manager
		[self _initObjectManager];
	}
	return _objectManager;
}

/*!
 *  Configure a RKObjectManager for Redmine requests.
 */
- (void)_initObjectManager {
	RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:[AFHTTPClient clientWithBaseURL:[NSURL URLWithString:_url]]];

	// set user and password
	[objectManager.HTTPClient setAuthorizationHeaderWithUsername:_user password:_password];

	// set json minetype
	[objectManager setAcceptHeaderWithMIMEType:RKMIMETypeJSON];


	// define projects response
	RKResponseDescriptor *projectsResponse = [RKResponseDescriptor responseDescriptorWithMapping:[RKLIBRMMappingHelper projectsMapping] method:RKRequestMethodGET pathPattern:@"/projects.json" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:RKStatusCodeClassSuccessful]];

	// define projects response
	RKResponseDescriptor *projectResponse = [RKResponseDescriptor responseDescriptorWithMapping:[RKLIBRMMappingHelper projectMapping] method:RKRequestMethodGET pathPattern:@"/projects/:id.json" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:RKStatusCodeClassSuccessful]];

	// define issues response
	RKResponseDescriptor *issuesResponse = [RKResponseDescriptor responseDescriptorWithMapping:[RKLIBRMMappingHelper issuesMapping] method:RKRequestMethodGET pathPattern:@"/issues.json" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:RKStatusCodeClassSuccessful]];

	// define a project request
	RKRequestDescriptor *projectRequest = [RKRequestDescriptor requestDescriptorWithMapping:[RKLIBRMMappingHelper projectMapping].inverseMapping objectClass:[RKLIBRMProject class] rootKeyPath:nil method:RKRequestMethodPOST];

	// define a issue request
	RKRequestDescriptor *issueRequest = [RKRequestDescriptor requestDescriptorWithMapping:[RKLIBRMMappingHelper issueMapping].inverseMapping objectClass:[RKLIBRMIssue class] rootKeyPath:nil method:RKRequestMethodPOST];

	// register projects response
	[objectManager addResponseDescriptor:projectsResponse];

	// register single project response
	[objectManager addResponseDescriptor:projectResponse];

	// register issues response
	[objectManager addResponseDescriptor:issuesResponse];

	// register project request
	[objectManager addRequestDescriptor:projectRequest];

	// register issue request
	[objectManager addRequestDescriptor:issueRequest];

	_objectManager = objectManager;
}

#pragma mark project entity

/*!
 *  Listing projects
 *
 *  @param success A block object to be executed when the object request operation finishes successfully. The block has two arguments the a `RKObjectRequestOperation` object and a `RKLIBRMProject` object.
 *  @param failure <#failure description#>
 */
- (void)getProjectWithId:(NSNumber *)projectId
             withInclude:(NSString *)includes
                 Success:(void (^)(RKObjectRequestOperation *operation, RKLIBRMProject *project))success
                 failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
	NSString *path = [NSString stringWithFormat:@"/projects.%@", kJson];
	NSDictionary *dict  = nil;
	if (includes)
		dict = @{ @"include":includes };
	[self.objectManager getObjectsAtPath:path parameters:dict success: ^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
	    if ([mappingResult.firstObject isKindOfClass:[RKLIBRMProject class]]) {
	        success(operation, mappingResult.firstObject);
		}
	} failure: ^(RKObjectRequestOperation *operation, NSError *error) {
	    failure(operation, error);
	}];
}

- (void)getProjectsWithSuccess:(void (^)(RKObjectRequestOperation *operation,  RKLIBRMProjects *projects))success
                       failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
	NSString *path = [NSString stringWithFormat:@"/projects.%@", kJson];
	[self.objectManager getObjectsAtPath:path parameters:nil success: ^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
	    if ([mappingResult.firstObject isKindOfClass:[RKLIBRMProjects class]]) {
	        success(operation, mappingResult.firstObject);
		}
	} failure: ^(RKObjectRequestOperation *operation, NSError *error) {
	    failure(operation, error);
	}];
}

/*!
 *  Get a single project.
 *
 *  @param success <#success description#>
 *  @param failure <#failure description#>
 */
- (void)getProjectsWithName:(NSString *)projectName success:(void (^)(RKObjectRequestOperation *operation, RKLIBRMProject *project))success
                    failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
	NSString *path = [NSString stringWithFormat:@"/projects/%@.%@", projectName, kJson];
	[self.objectManager getObjectsAtPath:path parameters:nil success: ^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
	    if ([mappingResult.array isKindOfClass:[NSMutableArray class]]) {
	        success(operation, mappingResult.firstObject);
		}
	} failure: ^(RKObjectRequestOperation *operation, NSError *error) {
	    failure(operation, error);
	}];
}

/*!
 *  Create new project
 *  http://www.redmine.org/projects/redmine/wiki/Rest_Projects
 *  @param name              <#name description#>
 *  @param identifier        <#identifier description#>
 *  @param descriptionString <#descriptionString description#>
 *  @param success A block object to be executed when the project delete request operation finishes successfully.
 *  @param failure A block object to be executed when the project delete request operation finishes unsuccessfully.
 */
- (void)postProjectWithName:(NSString *)name
             withIdentifier:(NSString *)identifier
            withDescription:(NSString *)descriptionString
                    success:(void (^)(RKObjectRequestOperation *operation, RKLIBRMProject *project))success
                    failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
	NSString *path = [NSString stringWithFormat:@"/projects.%@", kJson];

	RKLIBRMProject *project = [RKLIBRMProject new];
	if (name) {
		project.name = name;
	}
	if (identifier) {
		project.identifier = identifier;
	}
	if (descriptionString) {
		project.descriptionString = descriptionString;
	}

	[self.objectManager postObject:project path:path parameters:nil success: ^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
	    success(operation, mappingResult.firstObject);
	} failure: ^(RKObjectRequestOperation *operation, NSError *error) {
	    failure(operation, error);
	}];
}

/**
 *  Edit a existing project.
 *
 *  @param project The updated project object.
 *  @param success A block object to be executed when the project put request operation finishes successfully.
 *  @param failure A block object to be executed when the project put request operation finishes unsuccessfully.
 */
- (void)putWithProject:(RKLIBRMProject *)project
               success:(void (^)(RKObjectRequestOperation *operation, RKLIBRMProject *updatedProject))success
               failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
	NSString *path = [NSString stringWithFormat:@"/projects/%@.%@", project.projectId, kJson];
	[self.objectManager putObject:project path:path parameters:nil success: ^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
	    success(operation, mappingResult.firstObject);
	} failure: ^(RKObjectRequestOperation *operation, NSError *error) {
	    failure(operation, error);
	}];
}

/**
 *  Delete a project by it's project id.
 *
 *  @param projectId A project id as number.
 *  @param success A block object to be executed when the project delete request operation finishes successfully.
 *  @param failure A block object to be executed when the project delete request operation finishes unsuccessfully.
 */
- (void)deleteProjectWithID:(NSNumber *)projectId
                    success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                    failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
	NSString *path = [NSString stringWithFormat:@"/projects/%@.%@", projectId, kJson];

	[self.objectManager deleteObject:nil path:path parameters:nil success: ^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
	    success(operation, mappingResult);
	} failure: ^(RKObjectRequestOperation *operation, NSError *error) {
	    failure(operation, error);
	}];
}

#pragma mark issue entity

/*!
 *  List all issues.
 *
 *  @param success A block object to be executed when the issues request operation finishes successfully.
 *  @param failure A block object to be executed when the issues request operation finishes unsuccessfully.
 */
- (void)getIssuesWithSuccess:(void (^)(RKObjectRequestOperation *operation, RKLIBRMIssues *issues))success
                     failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
	NSString *path = [NSString stringWithFormat:@"/issues.%@", kJson];
	[self.objectManager getObjectsAtPath:path parameters:nil success: ^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
	    if ([mappingResult.firstObject isKindOfClass:[RKLIBRMIssues class]]) {
	        success(operation, mappingResult.firstObject);
		}
	} failure: ^(RKObjectRequestOperation *operation, NSError *error) {
	    failure(operation, error);
	}];
}

//http://www.redmine.org/projects/redmine/wiki/Rest_api#Attaching-files

- (NSString *)uploadTokenFromImage:(UIImage *)image withFileName:(NSString *)fileName {
	NSData *imgData = UIImagePNGRepresentation(image);

	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

	AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:_url]];
	[httpClient setAuthorizationHeaderWithUsername:_user password:_password];

	NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:@"/uploads.json" parameters:nil constructingBodyWithBlock: ^(id < AFMultipartFormData > formData) {
	    [formData appendPartWithFileData:imgData name:fileName fileName:fileName mimeType:@"image/png"];
	}];
	AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
	[operation setCompletionBlockWithSuccess: ^(AFHTTPRequestOperation *operation, id responseObject) {
	    NSString *result = [operation responseString];
	    NSLog(@"response: [%@]", result);
	} failure: ^(AFHTTPRequestOperation *operation, NSError *error) {
	    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	    if ([operation.response statusCode] == 403) {
	        NSLog(@"Upload Failed");
	        return;
		}
	    NSLog(@"error: %@", [operation error]);
	}];
	[operation setUploadProgressBlock: ^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
	    NSLog(@"Sent %lld of %lld bytes", totalBytesWritten, totalBytesExpectedToWrite);
	    //float width = totalBytesWritten / totalBytesExpectedToWrite;
	}];
	[operation start];

//    [operation waitUntilFinished];

	NSString *result = [operation responseString];
	NSLog(@"response: [%@]", result);

	return result;
}

@end
