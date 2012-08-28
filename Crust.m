//
//  Crust.m
//

#import "Crust.h"

#import "JSONKit.h"

// TODO DEBUG
#define DEBUG_LEVEL DEBUG_NORMAL

#define DEFAULT_TIMEOUT 120

@implementation CrustResponse
@synthesize text, data, json, headers, status;

-(id)getJSONResponse
{
    self.json = [self.data objectFromJSONData];
    return self.json;
}

@end

@implementation Crust
@synthesize method, path, parameters, headers, files, response, timeout, tag, cache;
@synthesize delegate;
@synthesize username, password;
@synthesize userAgent;
@synthesize permanentAuthentication, activityIndicator;

-(void)start
{
    self.response.data = [NSMutableData data];
    self.response.json = nil;
    self.response.status = 0;
    self.response.headers = [[NSDictionary alloc] init];
    
    NSMutableData *body = [NSMutableData data];
    
    if([parameters count] > 0)
    {
        NSString *parameterString = [[NSString alloc] init];
        for(NSString *parameter in parameters)
            parameterString = [parameterString stringByAppendingFormat:@"%@=%@&", parameter, [parameters objectForKey:parameter]];
        parameterString = [parameterString substringToIndex:[parameterString length] - 1];
        
        if(self.method == METHOD_GET)
            self.path = [self.path stringByAppendingFormat:@"?%@", parameterString];
        else
            [body appendData:[parameterString dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.path]];
    [request setHTTPShouldHandleCookies:YES];
    [request setHTTPMethod:method];
    
    if(!self.cache) [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    else [request setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
    
    for(NSString *header in headers)
        [request addValue:[headers objectForKey:header] forHTTPHeaderField:header];
    
    request.timeoutInterval = self.timeout;
    
    if(self.userAgent)
        [request addValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
    
    NSLog(@"BODY: %@", [[NSString alloc] initWithData:body encoding:NSASCIIStringEncoding]);
    
    [request setHTTPBody:body];
    [request addValue:[NSString stringWithFormat:@"%d", [body length]] forHTTPHeaderField:@"Content-Length"];
    
	connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [self addToPool];
    
    [self log:@"Request started" level:DEBUG_NORMAL];
    
    if(delegate && [delegate respondsToSelector:@selector(requestStarted:)])
        [delegate requestStarted:self];
}

-(void)start:(id)aDelegate
{
    delegate = aDelegate;
    [self start];
}

-(void)cancel
{
    [self log:@"Cancel request" level:DEBUG_NORMAL];
    [connection cancel];
}

-(void)log:(NSString*)message level:(int)level
{
    if(level >= DEBUG_LEVEL)
        NSLog(@"[Crust] %@", message);
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)urlResponse
{
    [self log:@"didReceiveResponse" level:DEBUG_INFO];
    self.response.status = [((NSHTTPURLResponse *)urlResponse) statusCode];
    self.response.headers = [((NSHTTPURLResponse *)urlResponse) allHeaderFields];
    [self.response.data setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self log:@"didReceiveData" level:DEBUG_INFO];
    [self.response.data appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self log:[NSString stringWithFormat:@"didFailWithError: %@", [error description]] level:DEBUG_ERROR];
    [self removeFromPool];
    
    [self log:@"Request failed" level:DEBUG_ERROR];
    
    if(delegate && [delegate respondsToSelector:@selector(requestFailed:)])
        [delegate requestFailed:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self log:@"connectionDidFinishLoading" level:DEBUG_INFO];
    self.response.text = [[NSString alloc] initWithData:self.response.data encoding:NSASCIIStringEncoding];
    self.response.json = [self.response.data objectFromJSONData];
    [self log:[NSString stringWithFormat:@"Response: %@", self.response.text] level:DEBUG_INFO];
    
    [self removeFromPool];
    if(delegate && [delegate respondsToSelector:@selector(requestFinished:)])
        [delegate requestFinished:self];
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    [self log:@"didSendBodyData" level:DEBUG_INFO];
    if(delegate && [delegate respondsToSelector:@selector(uploadProgress:progress:totalBytesWritten:totalBytesExpectedToWrite:)])
    {
        NSInteger progress = [[NSNumber numberWithFloat:((float)totalBytesWritten / (float)totalBytesExpectedToWrite) * 100.0f] integerValue];
        [delegate uploadProgress:self progress:progress totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if([challenge previousFailureCount] == 0 && self.username && self.password)
    {
        NSURLCredentialPersistence persistence;
        if(self.permanentAuthentication) persistence = NSURLCredentialPersistencePermanent;
        else persistence = NSURLCredentialPersistenceForSession;
        
        [self log:@"Received authentication challenge" level:DEBUG_NORMAL];
        NSURLCredential *credentials = [NSURLCredential credentialWithUser:self.username
                                                                  password:self.password
                                                               persistence:persistence];        
        [[challenge sender] useCredential:credentials forAuthenticationChallenge:challenge];  
    }
    else
        [self log:@"Authentication failure" level:DEBUG_ERROR];
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
    return YES;
}

/* Static methods begin */
+(id)get:(NSString*)aPath parameters:(NSDictionary*)aParams delegate:(id)aDelegate { return [[Crust alloc] initWithMethod:METHOD_GET path:aPath parameters:aParams delegate:aDelegate]; }
+(id)post:(NSString*)aPath parameters:(NSDictionary*)aParams delegate:(id)aDelegate { return [[Crust alloc] initWithMethod:METHOD_POST path:aPath parameters:aParams delegate:aDelegate]; }
+(id)put:(NSString*)aPath parameters:(NSDictionary*)aParams delegate:(id)aDelegate { return [[Crust alloc] initWithMethod:METHOD_PUT path:aPath parameters:aParams delegate:aDelegate]; }
+(id)delete:(NSString*)aPath parameters:(NSDictionary*)aParams delegate:(id)aDelegate { return [[Crust alloc] initWithMethod:METHOD_DELETE path:aPath parameters:aParams delegate:aDelegate]; }
+(id)custom:(NSString*)aMethod path:(NSString*)aPath parameters:(NSDictionary*)aParams delegate:(id)aDelegate
{
    return [[Crust alloc] initWithMethod:aMethod path:aPath parameters:aParams delegate:aDelegate];
}

+(id)get:(NSString*)aPath { return [[Crust alloc] initWithMethod:METHOD_GET path:aPath parameters:nil delegate:nil]; }
+(id)post:(NSString*)aPath { return [[Crust alloc] initWithMethod:METHOD_POST path:aPath parameters:nil delegate:nil]; }
+(id)put:(NSString*)aPath { return [[Crust alloc] initWithMethod:METHOD_PUT path:aPath parameters:nil delegate:nil]; }
+(id)delete:(NSString*)aPath { return [[Crust alloc] initWithMethod:METHOD_DELETE path:aPath parameters:nil delegate:nil]; }
+(id)custom:(NSString*)aMethod path:(NSString*)aPath { return [[Crust alloc] initWithMethod:aMethod path:aPath parameters:nil delegate:nil]; }
/* Static methods end */

/* Utilities begin */
+(NSString*)dataToBase64String:(NSData*)aData
{
    const uint8_t* input = (const uint8_t*)[aData bytes];
    NSInteger length = [aData length];
    
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;
    
    NSInteger i;
    for(i=0; i < length; i += 3)
    {
        NSInteger value = 0;
        NSInteger j;
        for(j = i; j < (i + 3); j++)
        {
            value <<= 8;
            
            if(j < length)
                value |= (0xFF & input[j]);
        }
        
        NSInteger theIndex = (i / 3) * 4;
        output[theIndex + 0] =                    table[(value >> 18) & 0x3F];
        output[theIndex + 1] =                    table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}

+(NSString*)pathToBase64String:(NSString*)aPath
{
    return [Crust dataToBase64String:[NSData dataWithContentsOfFile:aPath]];
}

+(NSString*)urlToBase64String:(NSURL*)aUrl
{
     return [Crust dataToBase64String:[NSData dataWithContentsOfURL:aUrl]];
}
/* Utilities end */

@end

@implementation Crust (Private)

-(id)initWithMethod:(NSString*)aMethod path:(NSString*)aPath parameters:(NSDictionary*)aParams delegate:(id)aDelegate
{
    if([self init])
    {
        [self setup];
        self.method = aMethod;
        self.path = aPath;
        self.parameters = [[NSMutableDictionary alloc] initWithDictionary:aParams];
        delegate = aDelegate;
    }
    return self;
}

-(void)setup
{
    self.method = METHOD_GET;
    self.headers = [[NSMutableDictionary alloc] init];
    self.response = [[CrustResponse alloc] init];
    self.timeout = DEFAULT_TIMEOUT;
    self.activityIndicator = YES;
}

-(NSMutableArray*)requestPool
{
    static NSMutableArray* requests = nil;
    if(requests == nil)
        requests = [[NSMutableArray alloc] init];
    return requests;
}

-(void)addToPool
{
    [[self requestPool] addObject:self];
    if(self.activityIndicator)
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

-(void)removeFromPool
{
    [[self requestPool] removeObject:self];
    if([[self requestPool] count] == 0)
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

@end
