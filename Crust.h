//
//  Crust.h
//

#define METHOD_GET @"GET"
#define METHOD_POST @"POST"
#define METHOD_PUT @"PUT"
#define METHOD_DELETE @"DELETE"

typedef enum
{
    DEBUG_SILENT = 0,
    DEBUG_NORMAL = 1,
    DEBUG_INFO = 2,
    DEBUG_WARNING = 3,
    DEBUG_ERROR = 4,
    DEBUG_CRITICAL = 5
} DEBUG_LEVEL;

typedef enum
{
    GET = 0,
    POST = 1,
    PUT = 2,
    DELETE = 3,
    CUSTOM = 4
} REQUEST_METHOD;

@class Crust;
@protocol CrustDelegate <NSObject>
@optional

-(void)requestStarted:(Crust*)request;
-(void)requestFailed:(Crust*)request;
-(void)requestFinished:(Crust*)request;
-(void)uploadProgress:(Crust*)request progress:(NSInteger)progress totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;
@end

@interface CrustResponse : NSObject
{
    NSString *text;
    NSMutableData *data;
    id json;
    NSDictionary *headers;
    int status;
}

@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) NSMutableData *data;
@property (nonatomic, retain) id json;
@property (nonatomic, retain) NSDictionary *headers;
@property int status;

-(id)getJSONResponse;

@end

@interface Crust : NSObject <NSURLConnectionDelegate>
{
    NSURLConnection *connection;
}

@property (nonatomic, retain) NSString *method;
@property (nonatomic, retain) NSString *path;

@property (nonatomic, retain) NSMutableDictionary *parameters;
@property (nonatomic, retain) NSMutableDictionary *headers;
@property (nonatomic, retain) NSMutableDictionary *files;

@property int timeout;
@property int tag;

@property (assign) BOOL cache;

@property (nonatomic, retain) CrustResponse *response;

@property (weak) id <CrustDelegate> delegate;

/* Other parameters begin */
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *password;

@property (retain) NSString *userAgent;

@property (assign) BOOL permanentAuthentication;
@property (assign) BOOL activityIndicator;
/* Other parameters end */

-(void)start;
-(void)start:(id)aDelegate;

-(void)cancel;

-(void)log:(NSString*)message level:(int)level;

/* Static methods begin */
+(id)get:(NSString*)aPath parameters:(NSDictionary*)aParams delegate:(id)aDelegate;
+(id)post:(NSString*)aPath parameters:(NSDictionary*)aParams delegate:(id)aDelegate;
+(id)put:(NSString*)aPath parameters:(NSDictionary*)aParams delegate:(id)aDelegate;
+(id)delete:(NSString*)aPath parameters:(NSDictionary*)aParams delegate:(id)aDelegate;
+(id)custom:(NSString*)aMethod path:(NSString*)aPath parameters:(NSDictionary*)aParams delegate:(id)aDelegate;

+(id)get:(NSString*)aPath;
+(id)post:(NSString*)aPath;
+(id)put:(NSString*)aPath;
+(id)delete:(NSString*)aPath;
+(id)custom:(NSString*)aMethod path:(NSString*)aPath;
/* Static methods end */

/* Utilities begin */
+(NSString*)dataToBase64String:(NSData*)aData;
+(NSString*)pathToBase64String:(NSString*)aPath;
+(NSString*)urlToBase64String:(NSURL*)aUrl;
/* Utilities end */

@end

@interface Crust (Private)

-(id)initWithMethod:(NSString*)aMethod path:(NSString*)aPath parameters:(NSDictionary*)aParams delegate:(id)aDelegate;
-(void)setup;

-(NSMutableArray*)requestPool;
-(void)addToPool;
-(void)removeFromPool;

@end
