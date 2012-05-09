//
//  Crust.h
//

#import <Foundation/Foundation.h>

@class Crust;
@protocol CrustDelegate <NSObject>
@optional
-(void)request:(Crust*)sofa started:(BOOL)flag;
-(void)request:(Crust*)sofa failed:(BOOL)flag;
-(void)request:(Crust*)sofa finished:(BOOL)flag;
@end

@interface CrustResponse : NSObject
{
    NSString *text;
    NSMutableData *data;
    NSDictionary *headers;
    int statusCode;
}

@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) NSMutableData *data;
@property (nonatomic, retain) NSDictionary *headers;
@property int statusCode;

@end

@interface Crust : NSObject <NSURLConnectionDelegate>
{
    NSString *method;
    NSString *path;
    
    NSMutableDictionary *parameters;
    NSMutableDictionary *headers;
    
    int timeout;
    int tag;
    
    CrustResponse *response;
    
    id <CrustDelegate> delegate;
}

@property (nonatomic, retain) NSString *method;
@property (nonatomic, retain) NSString *path;

@property (nonatomic, retain) NSMutableDictionary *parameters;
@property (nonatomic, retain) NSMutableDictionary *headers;

@property int timeout;
@property int tag;

@property (nonatomic, retain) CrustResponse *response;

@property (nonatomic, assign) id <CrustDelegate> delegate;

-(void)start;
-(void)start:(id)aDelegate;

/* Static methods begin */
+(id)get:(NSString*)aPath parameters:(NSDictionary*)aParams delegate:(id)aDelegate;
+(id)post:(NSString*)aPath parameters:(NSDictionary*)aParams delegate:(id)aDelegate;
+(id)put:(NSString*)aPath parameters:(NSDictionary*)aParams delegate:(id)aDelegate;
+(id)delete:(NSString*)aPath parameters:(NSDictionary*)aParams delegate:(id)aDelegate;

+(id)get:(NSString*)aPath;
+(id)post:(NSString*)aPath;
+(id)put:(NSString*)aPath;
+(id)delete:(NSString*)aPath;
/* Static methods end */

@end
