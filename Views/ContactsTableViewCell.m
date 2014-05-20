//
//  ContactListTableViewCell.m
//  zirgoo
//
//  Created by Peter Kosztolanyi on 12/01/2014.
//
//

#import "ContactsTableViewCell.h"
#import "LinphoneHelper.h"

@implementation ContactsTableViewCell

@synthesize contactsViewController;
@synthesize contact;

@synthesize contactImage;
@synthesize statusImage;
@synthesize contactEmailLabel;
@synthesize contactFullNameLabel;

@synthesize sendMessageButton;



#pragma mark - Initialisers

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        contactImage = [[UIImageView alloc] initWithFrame:(CGRectMake(20, 0, 55, 60))];
        statusImage = [[UIImageView alloc] initWithFrame:(CGRectMake(60, 43, 15, 15))];
        
        contactEmailLabel = [[UILabel alloc] initWithFrame:(CGRectMake(85, 5, 160, 34))];
        contactEmailLabel.font = [UIFont systemFontOfSize:14];
        contactEmailLabel.numberOfLines = 2;
        
        contactFullNameLabel = [[UILabel alloc] initWithFrame:(CGRectMake(85, 36, 160, 21))];
        contactFullNameLabel.font = [UIFont systemFontOfSize:11];
        contactFullNameLabel.numberOfLines = 1;
       
        sendMessageButton = [[UIButton alloc] initWithFrame:(CGRectMake(248, 0, 58, 60))];
        [sendMessageButton setBackgroundImage:[UIImage imageNamed:@"textbubble.png"]
                                     forState:UIControlStateNormal];
        [sendMessageButton addTarget:self
                              action:@selector(sendMessageButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.contentView addSubview:contactImage];
        [self.contentView addSubview:statusImage];
        [self.contentView addSubview:contactEmailLabel];
        [self.contentView addSubview:contactFullNameLabel];
        
        [self.contentView addSubview:sendMessageButton];
    }
    
    return self;
}



#pragma mark -

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)sendMessageButtonTapped:(id)sender {
    
    contactsViewController.selectedContact = contact;
    [contactsViewController performSegueWithIdentifier:@"StartSecureChatSegue"
                                         sender:contactsViewController];
}

- (void)refresh {
    
    contactEmailLabel.text = contact.email;
    
    // Set status image
    if (contact.isActivated) {
        if (contact.isLoggedIn) {
            statusImage.image = [UIImage imageNamed:@"status_online.png"];
            contactEmailLabel.textColor = [UIColor blackColor];
            contactFullNameLabel.textColor = [UIColor blackColor];
            sendMessageButton.hidden = NO;
        }
        else {
            statusImage.image = [UIImage imageNamed:@"status_offline.png"];
            contactEmailLabel.textColor = [UIColor lightGrayColor];
            contactFullNameLabel.textColor = [UIColor lightGrayColor];
            sendMessageButton.hidden = YES;
        }
    }
    else {
        statusImage.image = [UIImage imageNamed:@"status_unregistered.png"];
        contactEmailLabel.textColor = [UIColor lightGrayColor];
        contactFullNameLabel.textColor = [UIColor lightGrayColor];
        sendMessageButton.hidden = YES;
    }
    
    if (contact.hasUnreadMessages)
        contactEmailLabel.font = [UIFont boldSystemFontOfSize:14];
    else
        contactEmailLabel.font = [UIFont systemFontOfSize:14];
    
    contactFullNameLabel.text = contact.fullName;
    contactImage.image = [LinphoneHelper imageAsCircle:contact.image];
}

@end
