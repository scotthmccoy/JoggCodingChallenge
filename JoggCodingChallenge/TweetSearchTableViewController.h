//
//  ViewController.h
//  JoggCodingChallenge
//
//  Created by Scott McCoy on 2/22/15.
//  Copyright (c) 2015 ScottSoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TweetSearchTableViewController : UITableViewController <UIAlertViewDelegate, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@end

