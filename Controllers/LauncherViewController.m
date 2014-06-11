//
//  LauncherViewController.m
//  ringring.io
//
//  Created by Peter Kosztolanyi on 18/01/2014.
//
//

#import "LauncherViewController.h"
#import "LinphoneHelper.h"



@interface LauncherViewController ()

@end



@implementation LauncherViewController

#pragma mark - Initialisers

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}



#pragma mark - Lifecycle Functions

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated
{
    // Show the login wizard if the user is not registered
    if ([LinphoneHelper isRegistered]) {
        [self performSegueWithIdentifier:@"showMainScreenSegue" sender:self];
    }
    else {
        [self performSegueWithIdentifier:@"showLoginScreenSegue" sender:self];
    }
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
