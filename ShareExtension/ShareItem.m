/**
 * @copyright Copyright (c) 2020 Marcel Müller <marcel-mueller@gmx.de>
 *
 * @author Marcel Müller <marcel-mueller@gmx.de>
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

#import "ShareItem.h"

@implementation ShareItem


+ (instancetype)initWithURL:(NSURL *)fileURL withName:(NSString *)fileName withPlaceholderImage:(UIImage *)placeholderImage
{
    ShareItem* item = [[ShareItem alloc] init];
    item.fileURL = fileURL;
    item.filePath = fileURL.path;
    item.fileName = fileName;
    item.placeholderImage = placeholderImage;
    item.uploadProgress = 0;
    
    return item;
}

@end
