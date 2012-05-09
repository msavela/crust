//
//  Crust.m
//

#import "Crust.h"

#define DEFAULT_TIMEOUT 120

@interface Crust (Private)

-(id)initWithMethod:(NSString*)aMethod path:(NSString*)aPath parameters:(NSDictionary*)aParams delegate:(id)aDelegate;
-(void)setup;

-(NSMutableArray*)requestPool;
-(void)addToPool;
-(void)removeFromPool;

@end

@implementation CrustResponse
@synthesize text, data, headers, statusCode;
@end

@implementation Crust
@synthesize method, path, parameters, headers, response, timeout, tag;
@dynamic delegate;

-(void)start
{
    self.response.data = [NSMutableData data];
    self.response.statusCode = 0;
    self.response.headers = [[NSDictionary alloc] init];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:path]];
    [request setHTTPShouldHandleCookies:YES];
    [request setHTTPMethod:method];
    
    for(NSString *header in headers)
        [request addValue:[headers objectForKey:header] forHTTPHeaderField:header];
    
    request.timeoutInterval = self.timeout;
    
    NSString *parameterString = [[NSString alloc] init];
    if([parameters count] > 0)
    {
        for(NSString *parameter in parameters)
            parameterString = [parameterString stringByAppendingFormat:@"%@=%@&", parameter, [parameters objectForKey:parameter]];
        parameterString = [parameterString substringToIndex:[parameterString length] - 1];
        [request setHTTPBody:[parameterString dataUsingEncoding:NSASCIIStringEncoding]];
    }
    
	(void)[[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    [self addToPool];
    
    if(delegate) [delegate request:self started:YES];
}

-(void)start:(id)aDelegate
{
    delegate = aDelegate;
    [self start];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)urlResponse
{
    NSLog(@"didReceiveResponse");
    self.response.statusCode = [((NSHTTPURLResponse *)urlResponse) statusCode];
    self.response.headers = [((NSHTTPURLResponse *)urlResponse) allHeaderFields];
    [self.response.data setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"didReceiveData");
    [self.response.data appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", [error description]);
    [self removeFromPool];
    if(delegate) [delegate request:self failed:YES];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"connectionDidFinishLoading");
    self.response.text = [[NSString alloc] initWithData:self.response.data encoding:NSASCIIStringEncoding];
    NSLog(@"Response: %@", self.response.text);
    
    [self removeFromPool];
    if(delegate) [delegate request:self finished:YES];
}

/* Static methods begin */
+(id)get:(NSString*)aPath parameters:(NSDictionary*)aParams delegate:(id)aDelegate { return [[Crust alloc] initWithMethod:@"GET" path:aPath parameters:aParams delegate:aDelegate]; }
+(id)post:(NSString*)aPath parameters:(NSDictionary*)aParams delegate:(id)aDelegate { return [[Crust alloc] initWithMethod:@"POST" path:aPath parameters:aParams delegate:aDelegate]; }
+(id)put:(NSString*)aPath parameters:(NSDictionary*)aParams delegate:(id)aDelegate { return [[Crust alloc] initWithMethod:@"PUT" path:aPath parameters:aParams delegate:aDelegate]; }
+(id)delete:(NSString*)aPath parameters:(NSDictionary*)aParams delegate:(id)aDelegate { return [[Crust alloc] initWithMethod:@"DELETE" path:aPath parameters:aParams delegate:aDelegate]; }

+(id)get:(NSString*)aPath { return [[Crust alloc] initWithMethod:@"GET" path:aPath parameters:nil delegate:nil]; }
+(id)post:(NSString*)aPath { return [[Crust alloc] initWithMethod:@"POST" path:aPath parameters:nil delegate:nil]; }
+(id)put:(NSString*)aPath { return [[Crust alloc] initWithMethod:@"PUT" path:aPath parameters:nil delegate:nil]; }
+(id)delete:(NSString*)aPath { return [[Crust alloc] initWithMethod:@"DELETE" path:aPath parameters:nil delegate:nil]; }
/* Static methods end */

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
    self.method = @"GET";
    self.headers = [[NSMutableDictionary alloc] init];
    self.response = [[CrustResponse alloc] init];
    self.timeout = DEFAULT_TIMEOUT;
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
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

-(void)removeFromPool
{
    [[self requestPool] removeObject:self];
    if([[self requestPool] count] == 0)
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

@end
