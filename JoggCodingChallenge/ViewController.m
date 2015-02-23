//
//  ViewController.m
//  JoggCodingChallenge
//
//  Created by Scott McCoy on 2/22/15.
//  Copyright (c) 2015 ScottSoft. All rights reserved.
//

//Header
#import "ViewController.h"

//Twitter Stuff
@import Accounts;
@import Social;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void) viewDidAppear:(BOOL)animated {

    [self postTweet];
}

#pragma mark - Twitter Interaction
- (void) postTweet
{
    ACAccountStore *account = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [account accountTypeWithAccountTypeIdentifier: ACAccountTypeIdentifierTwitter];
    
    [account requestAccessToAccountsWithType: accountType
                                     options: nil
                                  completion: ^(BOOL granted, NSError *error) {
                                      
        if (granted == YES) {
        
            // Get account and communicate with Twitter API
            NSLog(@"Access Granted");

            NSArray *arrayOfAccounts = [account
            accountsWithAccountType:accountType];

            if ([arrayOfAccounts count] == 0) {
            DebugLog(@"You have no Twitter accounts on this device!");
            return;
            }

            //Get one account
            ACAccount *twitterAccount = [arrayOfAccounts lastObject];

            //Create a request
            NSDictionary *params = @{@"q": @"cheese"};
            NSURL *requestURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/search/tweets.json?"];
            SLRequest *postRequest = [SLRequest requestForServiceType: SLServiceTypeTwitter
                                                        requestMethod: SLRequestMethodGET
                                                                  URL: requestURL
                                                           parameters: params];
            postRequest.account = twitterAccount;

            //Post the Request
            [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
            {
                if (error) {
                    DebugLog(@"error = [%@]", error);
                    //TODO: "Could not connect to Twitter" alertView
                } else {
                    NSDictionary* jsonDict = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
                    NSArray* statuses = [jsonDict objectForKey:@"statuses"];
                    DebugLog(@"statuses = [%@]", statuses);
                }
            }];

        } else {
        
            DebugLog(@"Access Not Granted");
        }
    }];
}

@end
