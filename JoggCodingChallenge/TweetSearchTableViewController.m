//
//  ViewController.m
//  JoggCodingChallenge
//
//  Created by Scott McCoy on 2/22/15.
//  Copyright (c) 2015 ScottSoft. All rights reserved.
//

//Header
#import "TweetSearchTableViewController.h"

//Twitter Stuff
@import Accounts;
@import Social;

@interface TweetSearchTableViewController ()
@property NSArray* statusArray;
@property UIView* activityIndicatorOverlay;
@end

@implementation TweetSearchTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Get rid of line break in separator
    [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    
    //Set up overlay
    self.activityIndicatorOverlay = [[UIView alloc] initWithFrame:self.view.frame];
    self.activityIndicatorOverlay.backgroundColor = [UIColor colorWithHue:0 saturation:0 brightness:0.5 alpha:0.25];
    
    //Set up activity indicator
    UIActivityIndicatorView* activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [activityIndicator startAnimating];
    activityIndicator.center = self.activityIndicatorOverlay.center;
    [self.activityIndicatorOverlay addSubview:activityIndicator];
}

- (BOOL) prefersStatusBarHidden {
    return YES;
}


#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.statusArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] init];
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:12.0];

        // Remove seperator inset
        if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
            [cell setSeparatorInset:UIEdgeInsetsZero];
        }
        
        // Prevent the cell from inheriting the Table View's margin settings
        if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
            [cell setPreservesSuperviewLayoutMargins:NO];
        }
        
        // Explictly set your cell's layout margins
        if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
            [cell setLayoutMargins:UIEdgeInsetsZero];
        }
    }
    
    NSDictionary* status = [self.statusArray objectAtIndex:indexPath.row];
    //TODO: Get user's icon at user->profile_image_url
    
    //Set the label
    cell.textLabel.text = status[@"text"];
    
    return cell;
}

#pragma mark - UISearchBarDelegate
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    DebugLog(@"Text = [%@]", searchBar.text);
    
    [searchBar resignFirstResponder];
    [self performSearchWithSearchString:searchBar.text];
    [self showSpinner];
}

- (void) showSpinner {
    DebugLogWhereAmI();
    [self.view addSubview:self.activityIndicatorOverlay];
    self.tableView.scrollEnabled = NO;
    self.tableView.userInteractionEnabled = NO;
}

- (void) hideSpinner {
    DebugLogWhereAmI();
    [self.activityIndicatorOverlay removeFromSuperview];
    self.tableView.scrollEnabled = YES;
    self.tableView.userInteractionEnabled = YES;
}


#pragma mark - AlertViews
- (void) presentStatusAppAlertViewWithTitle:(NSString*) title andMessage:(NSString*)message {
    UIAlertView* av = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"No Thanks" otherButtonTitles:@"Okay", nil];
    [av show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != 1)
        return;
    
    //Open the Settings App to Twitter
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=TWITTER"]];
}



#pragma mark - Twitter Interaction
- (void) performSearchWithSearchString:(NSString*)searchString
{
    //Prompt the user to have access to their Twitter account
    ACAccountStore *account = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [account accountTypeWithAccountTypeIdentifier: ACAccountTypeIdentifierTwitter];
    [account requestAccessToAccountsWithType: accountType
                                     options: nil
                                  completion: ^(BOOL granted, NSError *error) {
                       
        //If they say no...
        if (!granted) {
            //Show an alert view on the main queue
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self presentStatusAppAlertViewWithTitle:@"Unable to Continue" andMessage:@"You have blocked access to Twitter for this app. Would you like to go to the Settings App to enable access?"];
            });
            return;
        }
        

        //Get their Twitter accounts
        NSArray *arrayOfAccounts = [account accountsWithAccountType:accountType];

        if ([arrayOfAccounts count] == 0) {
            DebugLog(@"No Accounts!");
            //TODO: Have this prompt the user to go to the Settings app to add Twitter accounts
            
            //Show an alert view on the main queue
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self presentStatusAppAlertViewWithTitle:@"No Accounts!" andMessage:@"You have no Twitter accounts on this device. Would you like to go to the Settings App to log in to a Twitter account?"];
            });
            return;
        }

        //Get one account
        ACAccount *twitterAccount = [arrayOfAccounts lastObject];

                                      
        //Create a request
        //TODO: Sanitize search string
        NSDictionary *params = @{@"q":searchString};
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
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    NSDictionary* jsonDict = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:nil];
                    self.statusArray = [jsonDict objectForKey:@"statuses"];
                    [self.tableView reloadData];
                    
                    DebugLog(@"HideSpinner");
                    [self hideSpinner];
                });
            }
        }];
    }];
}



@end
