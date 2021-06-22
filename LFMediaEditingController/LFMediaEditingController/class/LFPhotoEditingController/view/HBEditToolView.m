//
//  HBEditToolView.m
//  LFMediaEditingController
//
//  Created by BingYan on 2021/6/22.
//  Copyright © 2021 LamTsanFeng. All rights reserved.
//

#import "HBEditToolView.h"

@implementation HBEditToolView

+ (instancetype)initFromNib {
    HBEditToolView *view = [[NSBundle mainBundle] loadNibNamed:@"HBEditToolView" owner:self options:nil].firstObject;
    view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 200);
    return view;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (void)setup {
    
}

//MARK:- Action
- (IBAction)tapConcelBtn:(UIButton *)sender {
    if (self.tapCancelBlock) {
        self.tapCancelBlock();
    }
}

- (IBAction)tapConfirmBtn:(UIButton *)sender {
    if (self.tapConfirmBlock) {
        self.tapConfirmBlock();
    }
}


@end
