/**
 * @copyright Copyright (c) 2020 Ivan Sein <ivan@nextcloud.com>
 *
 * @author Ivan Sein <ivan@nextcloud.com>
 *
 * @license GNU GPL version 3 or any later version
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#import "RoomSearchTableViewController.h"

@import NextcloudKit;

#import "NCAPIController.h"
#import "NCAppBranding.h"
#import "NCDatabaseManager.h"
#import "NCRoom.h"
#import "NCSettingsController.h"
#import "NCUtils.h"
#import "PlaceholderView.h"
#import "RoomTableViewCell.h"

#import "NextcloudTalk-Swift.h"

typedef enum RoomSearchSection {
    RoomSearchSectionFiltered = 0,
    RoomSearchSectionUsers,
    RoomSearchSectionListable,
    RoomSearchSectionMessages
} RoomSearchSection;

@interface RoomSearchTableViewController ()
{
    PlaceholderView *_roomSearchBackgroundView;
}
@end

@implementation RoomSearchTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerNib:[UINib nibWithNibName:kRoomTableCellNibName bundle:nil] forCellReuseIdentifier:kRoomCellIdentifier];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    // Align header's title to ContactsTableViewCell's label
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 52, 0, 0);
    self.tableView.separatorInsetReference = UITableViewSeparatorInsetFromAutomaticInsets;
    // Contacts placeholder view
    _roomSearchBackgroundView = [[PlaceholderView alloc] init];
    [_roomSearchBackgroundView setImage:[UIImage imageNamed:@"conversations-placeholder"]];
    [_roomSearchBackgroundView.placeholderTextView setText:NSLocalizedString(@"No results found", nil)];
    [_roomSearchBackgroundView.placeholderView setHidden:YES];
    [_roomSearchBackgroundView.loadingView startAnimating];
    self.tableView.backgroundView = _roomSearchBackgroundView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setRooms:(NSArray *)rooms
{
    _rooms = rooms;
    [self reloadAndCheckSearchingIndicator];
}

- (void)setUsers:(NSArray *)users
{
    _users = users;
    [self reloadAndCheckSearchingIndicator];
}

- (void)setListableRooms:(NSArray *)listableRooms
{
    _listableRooms = listableRooms;
    [self reloadAndCheckSearchingIndicator];
}

- (void)setMessages:(NSArray *)messages
{
    _messages = messages;
    [self reloadAndCheckSearchingIndicator];
}

- (void)setSearchingMessages:(BOOL)searchingMessages
{
    _searchingMessages = searchingMessages;
    [self reloadAndCheckSearchingIndicator];
}


#pragma mark - User Interface

- (void)reloadAndCheckSearchingIndicator
{
    [self.tableView reloadData];
    
    if (_searchingMessages) {
        if ([self searchSections].count > 0) {
            [_roomSearchBackgroundView.loadingView stopAnimating];
            [_roomSearchBackgroundView.loadingView setHidden:YES];
            [self showSearchingFooterView];
        } else {
            [_roomSearchBackgroundView.loadingView startAnimating];
            [_roomSearchBackgroundView.loadingView setHidden:NO];
            [self hideSearchingFooterView];
        }
        [_roomSearchBackgroundView.placeholderView setHidden:YES];
    } else {
        [_roomSearchBackgroundView.loadingView stopAnimating];
        [_roomSearchBackgroundView.loadingView setHidden:YES];
        [_roomSearchBackgroundView.placeholderView setHidden:[self searchSections].count > 0];
    }
}

- (void)showSearchingFooterView
{
    UIActivityIndicatorView *loadingMoreView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    loadingMoreView.color = [UIColor darkGrayColor];
    [loadingMoreView startAnimating];
    self.tableView.tableFooterView = loadingMoreView;
}

- (void)hideSearchingFooterView
{
    self.tableView.tableFooterView = nil;
}

- (void)clearSearchedResults
{
    _rooms = @[];
    _users = @[];
    _listableRooms = @[];
    _messages = @[];
    
    [self reloadAndCheckSearchingIndicator];
}


#pragma mark - Utils

- (NSArray *)searchSections
{
    NSMutableArray *sections = [NSMutableArray new];
    if (_rooms.count > 0) {
        [sections addObject:@(RoomSearchSectionFiltered)];
    }
    if (_users.count > 0) {
        [sections addObject:@(RoomSearchSectionUsers)];
    }
    if (_listableRooms.count > 0) {
        [sections addObject:@(RoomSearchSectionListable)];
    }
    if (_messages.count > 0) {
        [sections addObject:@(RoomSearchSectionMessages)];
    }
    return [NSArray arrayWithArray:sections];
}

- (NCRoom *)roomForIndexPath:(NSIndexPath *)indexPath
{
    NSInteger searchSection = [[[self searchSections] objectAtIndex:indexPath.section] integerValue];
    if (searchSection == RoomSearchSectionFiltered && indexPath.row < _rooms.count) {
        return [_rooms objectAtIndex:indexPath.row];
    } else if (searchSection == RoomSearchSectionListable && indexPath.row < _listableRooms.count) {
        return [_listableRooms objectAtIndex:indexPath.row];
    }
    
    return nil;
}

- (NKSearchEntry *)messageForIndexPath:(NSIndexPath *)indexPath
{
    NSInteger searchSection = [[[self searchSections] objectAtIndex:indexPath.section] integerValue];
    if (searchSection == RoomSearchSectionMessages && indexPath.row < _messages.count) {
        return [_messages objectAtIndex:indexPath.row];;
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForMessageAtIndexPath:(NSIndexPath *)indexPath
{
    NKSearchEntry *messageEntry = [_messages objectAtIndex:indexPath.row];
    RoomTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kRoomCellIdentifier];
    if (!cell) {
        cell = [[RoomTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kRoomCellIdentifier];
    }
    
    cell.titleLabel.text = messageEntry.title;
    cell.subtitleLabel.text = messageEntry.subline;
    
    // Thumbnail image
    NSURL *thumbnailURL = [[NSURL alloc] initWithString:messageEntry.thumbnailURL];
    NSString *actorId = [messageEntry.attributes objectForKey:@"actorId"];
    NSString *actorType = [messageEntry.attributes objectForKey:@"actorType"];
    if ([actorType isEqualToString:@"users"] && actorId) {
        [cell.roomImage setUserAvatarFor:actorId with:self.traitCollection.userInterfaceStyle];
    } else if ([actorType isEqualToString:@"guests"]) {
        UIImage *image = [NCUtils getImageWithString:@"?" withBackgroundColor:[UIColor clearColor] withBounds:cell.roomImage.bounds isCircular:YES];
        [cell.roomImage setImage:image];
        cell.roomImage.contentMode = UIViewContentModeScaleAspectFit;
    } else if (thumbnailURL) {
        [cell.roomImage setImageWithURL:thumbnailURL placeholderImage:nil];
        cell.roomImage.contentMode = UIViewContentModeScaleToFill;
    } else {
        [cell.roomImage setImage:[UIImage imageNamed:@"navigationLogo"]];
        cell.roomImage.contentMode = UIViewContentModeCenter;
    }
    
    // Clear possible content not removed by cell reuse
    cell.dateLabel.text = @"";
    [cell setUnreadMessages:0 mentioned:NO groupMentioned:NO];
    
    // Add message date (if it is included in attributes)
    NSInteger timestamp = [[messageEntry.attributes objectForKey:@"timestamp"] integerValue];
    if (timestamp > 0) {
        NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:timestamp];
        cell.dateLabel.text = [NCUtils readableTimeOrDateFromDate:date];
    }
    
    return cell;
}

- (NCUser *)userForIndexPath:(NSIndexPath *)indexPath
{
    NSInteger searchSection = [[[self searchSections] objectAtIndex:indexPath.section] integerValue];
    if (searchSection == RoomSearchSectionUsers && indexPath.row < _users.count) {
        return [_users objectAtIndex:indexPath.row];
    }

    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForUserAtIndexPath:(NSIndexPath *)indexPath
{
    NCUser *user = [_users objectAtIndex:indexPath.row];
    RoomTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kRoomCellIdentifier];
    if (!cell) {
        cell = [[RoomTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kRoomCellIdentifier];
    }

    cell.titleLabel.text = user.name;
    cell.titleOnly = YES;
    [cell.roomImage setUserAvatarFor:user.userId with:self.traitCollection.userInterfaceStyle];

    return cell;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self searchSections].count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger searchSection = [[[self searchSections] objectAtIndex:section] integerValue];
    switch (searchSection) {
        case RoomSearchSectionFiltered:
            return _rooms.count;
        case RoomSearchSectionUsers:
            return _users.count;
        case RoomSearchSectionListable:
            return _listableRooms.count;
        case RoomSearchSectionMessages:
            return _messages.count;
        default:
            return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kRoomTableCellHeight;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSInteger searchSection = [[[self searchSections] objectAtIndex:section] integerValue];
    switch (searchSection) {
        case RoomSearchSectionFiltered:
            return NSLocalizedString(@"Conversations", @"");
        case RoomSearchSectionUsers:
            return NSLocalizedString(@"Users", @"");
        case RoomSearchSectionListable:
            return NSLocalizedString(@"Open conversations", @"TRANSLATORS 'Open conversations' as a type of conversation. 'Open conversations' are conversations that can be found by other users");
        case RoomSearchSectionMessages:
            return NSLocalizedString(@"Messages", @"");
        default:
            return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger searchSection = [[[self searchSections] objectAtIndex:indexPath.section] integerValue];
    // Messages
    if (searchSection == RoomSearchSectionMessages) {
        return [self tableView:tableView cellForMessageAtIndexPath:indexPath];
    }
    // Contacts
    if (searchSection == RoomSearchSectionUsers) {
        return [self tableView:tableView cellForUserAtIndexPath:indexPath];
    }
    
    NCRoom *room = [self roomForIndexPath:indexPath];
    
    RoomTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kRoomCellIdentifier];
    if (!cell) {
        cell = [[RoomTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kRoomCellIdentifier];
    }
    
    // Set room name
    cell.titleLabel.text = room.displayName;
    
    // Set last activity
    if (room.lastMessage) {
        cell.titleOnly = NO;
        cell.subtitleLabel.text = room.lastMessageString;
    } else {
        cell.titleOnly = YES;
    }
    NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:room.lastActivity];
    cell.dateLabel.text = [NCUtils readableTimeOrDateFromDate:date];
    
    // Set unread messages
    if ([[NCDatabaseManager sharedInstance] serverHasTalkCapability:kCapabilityDirectMentionFlag]) {
        BOOL mentioned = room.unreadMentionDirect || room.type == kNCRoomTypeOneToOne || room.type == kNCRoomTypeFormerOneToOne;
        BOOL groupMentioned = room.unreadMention && !room.unreadMentionDirect;
        [cell setUnreadMessages:room.unreadMessages mentioned:mentioned groupMentioned:groupMentioned];
    } else {
        BOOL mentioned = room.unreadMention || room.type == kNCRoomTypeOneToOne || room.type == kNCRoomTypeFormerOneToOne;
        [cell setUnreadMessages:room.unreadMessages mentioned:mentioned groupMentioned:NO];
    }

    [cell.roomImage setAvatarFor:room with:self.traitCollection.userInterfaceStyle];

    // Set favorite or call image
    if (room.hasCall) {
        [cell.favoriteImage setTintColor:[UIColor systemRedColor]];
        [cell.favoriteImage setImage:[UIImage systemImageNamed:@"video.fill"]];
    } else if (room.isFavorite) {
        [cell.favoriteImage setTintColor:[UIColor systemYellowColor]];
        [cell.favoriteImage setImage:[UIImage systemImageNamed:@"star.fill"]];
    }
    
    return cell;
}

@end
