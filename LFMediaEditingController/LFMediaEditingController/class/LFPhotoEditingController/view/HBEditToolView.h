//
//  HBEditToolView.h
//  LFMediaEditingController
//
//  Created by BingYan on 2021/6/22.
//  Copyright © 2021 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 图片编辑底部
@interface HBEditToolView : UIView

+ (instancetype)initFromNib;

@property (nonatomic, copy) void (^tapCancelBlock)(void);
@property (nonatomic, copy) void (^tapConfirmBlock)(void);

@end

NS_ASSUME_NONNULL_END
