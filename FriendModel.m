//
//  FriendModel.m
//  通讯录
//
//  Created by 王双龙 on 16/7/25.
//  Copyright © 2016年 王双龙. All rights reserved.
//

#import "FriendModel.h"
#import "NSString+Utils.h"//category

@implementation FriendModel

- (void)setNameStr:(NSString *)nameStr{
    
    if (nameStr) {
        _nameStr= nameStr;
        _pinyin=_nameStr.pinyin;
    }
}

@end
