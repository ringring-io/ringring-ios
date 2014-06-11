//
//  CallHistoryTableViewCell.m
//  ringring.io
//
//  Created by Peter Kosztolanyi on 12/01/2014.
//
//

#import "RecentsTableViewCell.h"

@implementation RecentsTableViewCell

@synthesize contactsViewController;
@synthesize contact;

@synthesize contactImage;
@synthesize contactEmailLabel;
@synthesize contactFullNameLabel;

@synthesize startTimeLabel;
@synthesize recentTypeButton;



#pragma mark - Initialisers

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}



#pragma mark -

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


@end
