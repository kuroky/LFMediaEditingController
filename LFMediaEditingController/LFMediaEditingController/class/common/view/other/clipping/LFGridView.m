//
//  LFGridView.m
//  ClippingText
//
//  Created by LamTsanFeng on 2017/3/7.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFGridView.h"
#import "LFGridLayer.h"
#import "LFGridMaskLayer.h"
#import "LFResizeControl.h"
#import <AVFoundation/AVFoundation.h>

/** 可控范围 */
const CGFloat kControlWidth = 30.f;

@interface LFGridView () <lf_resizeConrolDelegate>

@property (nonatomic, weak) LFResizeControl *topLeftCornerView;
@property (nonatomic, weak) LFResizeControl *topRightCornerView;
@property (nonatomic, weak) LFResizeControl *bottomLeftCornerView;
@property (nonatomic, weak) LFResizeControl *bottomRightCornerView;
@property (nonatomic, weak) LFResizeControl *topEdgeView;
@property (nonatomic, weak) LFResizeControl *leftEdgeView;
@property (nonatomic, weak) LFResizeControl *bottomEdgeView;
@property (nonatomic, weak) LFResizeControl *rightEdgeView;

@property (nonatomic, weak) LFGridMaskLayer *gridMaskLayer;

@property (nonatomic, assign) CGRect initialRect;

@property (nonatomic, weak) LFGridLayer *gridLayer;

@property (nonatomic, readonly) CGSize aspectRatioSize;

@property (nonatomic, strong) NSArray <NSString *> *extraAspectRatioVerticalDescs;
@property (nonatomic, strong) NSArray <NSString *> *extraAspectRatioHorizontallyDescs;

@end

@implementation LFGridView

@synthesize dragging = _dragging;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)customInit
{
    /** 遮罩 */
    LFGridMaskLayer *gridMaskLayer = [[LFGridMaskLayer alloc] init];
    gridMaskLayer.frame = self.bounds;
    gridMaskLayer.maskColor = [UIColor colorWithWhite:.0f alpha:.5f].CGColor;
    [self.layer addSublayer:gridMaskLayer];
    self.gridMaskLayer = gridMaskLayer;
    
    /** 宫格 */
    LFGridLayer *gridLayer = [[LFGridLayer alloc] init];
    gridLayer.frame = self.bounds;
    gridLayer.lineWidth = 2.f;
    gridLayer.bgColor = [UIColor clearColor];
    gridLayer.gridColor = [UIColor colorWithRed:80.0/255 green:249.0/255 blue:193.0/255 alpha:1.0];
    //gridLayer.gridColor = [UIColor whiteColor];

    [self.layer addSublayer:gridLayer];
    self.gridLayer = gridLayer;
    
    self.gridRect = CGRectInset(self.bounds, 20, 20);
    self.controlMinSize = CGSizeMake(80, 80);
    self.controlMaxRect = CGRectInset(self.bounds, 20, 20);
    self.controlSize = CGSizeZero;
    /** 遮罩范围 */
    self.showMaskLayer = YES;
    
    self.topLeftCornerView = [self createResizeControl];
    self.topRightCornerView = [self createResizeControl];
    self.bottomLeftCornerView = [self createResizeControl];
    self.bottomRightCornerView = [self createResizeControl];
    
    self.topEdgeView = [self createResizeControl];
    self.leftEdgeView = [self createResizeControl];
    self.bottomEdgeView = [self createResizeControl];
    self.rightEdgeView = [self createResizeControl];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.gridLayer.frame = self.bounds;
    self.gridMaskLayer.frame = self.bounds;
    
    CGRect rect = self.gridRect;
    
    self.topLeftCornerView.frame = (CGRect){CGRectGetMinX(rect) - CGRectGetWidth(self.topLeftCornerView.bounds) / 2, CGRectGetMinY(rect) - CGRectGetHeight(self.topLeftCornerView.bounds) / 2, self.topLeftCornerView.bounds.size};
    self.topRightCornerView.frame = (CGRect){CGRectGetMaxX(rect) - CGRectGetWidth(self.topRightCornerView.bounds) / 2, CGRectGetMinY(rect) - CGRectGetHeight(self.topRightCornerView.bounds) / 2, self.topRightCornerView.bounds.size};
    self.bottomLeftCornerView.frame = (CGRect){CGRectGetMinX(rect) - CGRectGetWidth(self.bottomLeftCornerView.bounds) / 2, CGRectGetMaxY(rect) - CGRectGetHeight(self.bottomLeftCornerView.bounds) / 2, self.bottomLeftCornerView.bounds.size};
    self.bottomRightCornerView.frame = (CGRect){CGRectGetMaxX(rect) - CGRectGetWidth(self.bottomRightCornerView.bounds) / 2, CGRectGetMaxY(rect) - CGRectGetHeight(self.bottomRightCornerView.bounds) / 2, self.bottomRightCornerView.bounds.size};
    
    self.topEdgeView.frame = (CGRect){CGRectGetMaxX(self.topLeftCornerView.frame), CGRectGetMinY(rect) - CGRectGetHeight(self.topEdgeView.frame) / 2, CGRectGetMinX(self.topRightCornerView.frame) - CGRectGetMaxX(self.topLeftCornerView.frame), CGRectGetHeight(self.topEdgeView.bounds)};
    self.leftEdgeView.frame = (CGRect){CGRectGetMinX(rect) - CGRectGetWidth(self.leftEdgeView.frame) / 2, CGRectGetMaxY(self.topLeftCornerView.frame), CGRectGetWidth(self.leftEdgeView.bounds), CGRectGetMinY(self.bottomLeftCornerView.frame) - CGRectGetMaxY(self.topLeftCornerView.frame)};
    self.bottomEdgeView.frame = (CGRect){CGRectGetMaxX(self.bottomLeftCornerView.frame), CGRectGetMinY(self.bottomLeftCornerView.frame), CGRectGetMinX(self.bottomRightCornerView.frame) - CGRectGetMaxX(self.bottomLeftCornerView.frame), CGRectGetHeight(self.bottomEdgeView.bounds)};
    self.rightEdgeView.frame = (CGRect){CGRectGetMaxX(rect) - CGRectGetWidth(self.rightEdgeView.bounds) / 2, CGRectGetMaxY(self.topRightCornerView.frame), CGRectGetWidth(self.rightEdgeView.bounds), CGRectGetMinY(self.bottomRightCornerView.frame) - CGRectGetMaxY(self.topRightCornerView.frame)};
}

- (void)setShowMaskLayer:(BOOL)showMaskLayer
{
    if (_showMaskLayer != showMaskLayer) {
        _showMaskLayer = showMaskLayer;
        if (showMaskLayer) {
            /** 还原遮罩 */
            [self.gridMaskLayer setMaskRect:self.gridRect animated:YES];
        } else {
            /** 扩大遮罩范围 */
            [self.gridMaskLayer clearMaskWithAnimated:YES];
        }
    }
    /** 简单粗暴的禁用拖动事件 */
    self.userInteractionEnabled = showMaskLayer;
}

- (BOOL)isDragging
{
    return _dragging;
}

#pragma mark - lf_resizeConrolDelegate

- (void)lf_resizeConrolDidBeginResizing:(LFResizeControl *)resizeConrol
{
    self.initialRect = self.gridRect;
    _dragging = YES;
//    self.showMaskLayer = NO;
    if ([self.delegate respondsToSelector:@selector(lf_gridViewDidBeginResizing:)]) {
        [self.delegate lf_gridViewDidBeginResizing:self];
    }
}
- (void)lf_resizeConrolDidResizing:(LFResizeControl *)resizeConrol
{
    CGRect gridRect = [self cropRectMakeWithResizeControlView:resizeConrol];
    [self setGridRect:gridRect maskLayer:NO];
    
    if ([self.delegate respondsToSelector:@selector(lf_gridViewDidResizing:)]) {
        [self.delegate lf_gridViewDidResizing:self];
    }
}
- (void)lf_resizeConrolDidEndResizing:(LFResizeControl *)resizeConrol
{
    [self enableCornerViewUserInteraction:nil];
//    self.showMaskLayer = YES;
    if ([self.delegate respondsToSelector:@selector(lf_gridViewDidEndResizing:)]) {
        [self.delegate lf_gridViewDidEndResizing:self];
    }
    _dragging = NO;
}

- (void)setGridRect:(CGRect)gridRect
{
    [self setGridRect:gridRect maskLayer:YES];
}
- (void)setGridRect:(CGRect)gridRect maskLayer:(BOOL)isMaskLayer
{
    [self setGridRect:gridRect maskLayer:isMaskLayer animated:NO];
}
- (void)setGridRect:(CGRect)gridRect animated:(BOOL)animated
{
    [self setGridRect:gridRect maskLayer:NO animated:animated];
}
- (void)setGridRect:(CGRect)gridRect maskLayer:(BOOL)isMaskLayer animated:(BOOL)animated
{
    [self setGridRect:gridRect maskLayer:isMaskLayer animated:animated completion:nil];
}
- (void)setGridRect:(CGRect)gridRect maskLayer:(BOOL)isMaskLayer animated:(BOOL)animated completion:(void (^)(BOOL finished))completion
{
    CGSize size = self.aspectRatioSize;
    if (!CGSizeEqualToSize(size, CGSizeZero)) {
        /** 计算比例后高度 */
        CGFloat newHeight = gridRect.size.width * (size.height/size.width);
        /** 超出最大高度计算 */
        if (newHeight > _controlMaxRect.size.height) {
            CGFloat newWidth = gridRect.size.width * (_controlMaxRect.size.height/newHeight);
            CGFloat diffWidth = gridRect.size.width - newWidth;
            gridRect.size.width = newWidth;
            gridRect.origin.x = gridRect.origin.x + diffWidth/2;
            newHeight = _controlMaxRect.size.height;
        }
        CGFloat diffHeight = gridRect.size.height - newHeight;
        gridRect.size.height = newHeight;
        gridRect.origin.y = gridRect.origin.y + diffHeight/2;
    }
    
    _gridRect = gridRect;
    [self setNeedsLayout];
    [self.gridLayer setGridRect:gridRect animated:animated completion:completion];
    if (isMaskLayer && _showMaskLayer) {
        [self.gridMaskLayer setMaskRect:gridRect animated:YES];
    }
}

- (void)setCircle:(BOOL)circle
{
    self.gridLayer.circle = circle;
    self.gridMaskLayer.circle = circle;
}

- (void)setAspectRatioWithoutDelegate:(LFGridViewAspectRatioType)aspectRatio
{
    if (_aspectRatio != aspectRatio) {
        _aspectRatio = aspectRatio;
    }
}

- (void)setAspectRatio:(LFGridViewAspectRatioType)aspectRatio
{
    [self setAspectRatio:aspectRatio animated:NO];
}

- (void)setAspectRatio:(LFGridViewAspectRatioType)aspectRatio animated:(BOOL)animated
{
    if (self.extraAspectRatioList && aspectRatio != LFGridViewAspectRatioType_None) {
        aspectRatio += LFGridViewAspectRatioType_Extra;
    }
    if (_aspectRatio != aspectRatio) {
//        LFGridViewAspectRatioType prevAspectRatio = _aspectRatio;
        _aspectRatio = aspectRatio;
//        [self setCircle:(_aspectRatio == LFGridViewAspectRatioType_Circle)];
        
        CGSize size = self.aspectRatioSize;
        if (!CGSizeEqualToSize(size, CGSizeZero)) {
            __weak typeof(self) weakSelf = self;
            [self setGridRect:self.gridRect maskLayer:NO animated:animated completion:^(BOOL finished) {
                if ([weakSelf.delegate respondsToSelector:@selector(lf_gridViewDidAspectRatio:)]) {
                    [weakSelf.delegate lf_gridViewDidAspectRatio:weakSelf];
                }
            }];
        }
//        else if (prevAspectRatio == LFGridViewAspectRatioType_Circle) {
//            /** 方形仅需要取消固定约束，如果上次是圆形，需要取消圆形的绘制显示 */
//            __weak typeof(self) weakSelf = self;
//            [self setGridRect:self.gridRect maskLayer:NO animated:animated completion:^(BOOL finished) {
//                if ([weakSelf.delegate respondsToSelector:@selector(lf_gridViewDidAspectRatio:)]) {
//                    [weakSelf.delegate lf_gridViewDidAspectRatio:weakSelf];
//                }
//            }];
//        }
    }
}

- (NSArray <NSString *>*)aspectRatioDescs
{
    /** 优先判断自定义纵横比 */
    if (self.extraAspectRatioList) {
        if (_aspectRatioHorizontally) {
            if (_extraAspectRatioHorizontallyDescs == nil) {
                NSMutableArray *m_array = [NSMutableArray arrayWithCapacity:self.extraAspectRatioList.count];
                for (id <LFExtraAspectRatioProtocol> extraAspectRatio in self.extraAspectRatioList) {
                    if (extraAspectRatio.autoAspectRatio) {
                        [m_array addObject:[NSString stringWithFormat:@"%d%@%d", abs(extraAspectRatio.lf_aspectHeight), extraAspectRatio.lf_aspectDelimiter ?: @"x", abs(extraAspectRatio.lf_aspectWidth)]];
                    } else {
                        [m_array addObject:[NSString stringWithFormat:@"%d%@%d", abs(extraAspectRatio.lf_aspectWidth), extraAspectRatio.lf_aspectDelimiter ?: @"x", abs(extraAspectRatio.lf_aspectHeight)]];
                    }
                }
                _extraAspectRatioHorizontallyDescs = [m_array copy];
            }
            return _extraAspectRatioHorizontallyDescs;
        } else {
            if (_extraAspectRatioVerticalDescs == nil) {
                NSMutableArray *m_array = [NSMutableArray arrayWithCapacity:self.extraAspectRatioList.count];
                for (id <LFExtraAspectRatioProtocol> extraAspectRatio in self.extraAspectRatioList) {
                    [m_array addObject:[NSString stringWithFormat:@"%d%@%d", abs(extraAspectRatio.lf_aspectWidth), extraAspectRatio.lf_aspectDelimiter ?: @"x", abs(extraAspectRatio.lf_aspectHeight)]];
                }
                _extraAspectRatioVerticalDescs = [m_array copy];
            }
            return _extraAspectRatioVerticalDescs;
        }
    }
    
    if (_aspectRatioHorizontally) {
        static NSArray <NSString *> *aspectRatioHorizontallyDescs = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            aspectRatioHorizontallyDescs = @[@"Original", @"1x1", @"3x2", @"4x3", @"5x3", @"15x9", @"16x9", @"16x10"];
        });
        return aspectRatioHorizontallyDescs;
    } else {
        static NSArray <NSString *> *aspectRatioVerticalDescs = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            aspectRatioVerticalDescs = @[@"Original", @"1x1", @"2x3", @"3x4", @"3x5", @"9x15", @"9x16", @"10x16"];
        });
        return aspectRatioVerticalDescs;
    }
}

#pragma mark - private

- (CGSize)aspectRatioSize
{
    BOOL aspectRatioHorizontally = self.aspectRatioHorizontally;
    BOOL angleAspectRatioHorizontally = NO;
    switch (self.angle) {
        case 90:
        case -90:
        case 270:
        case -270:
        {
            angleAspectRatioHorizontally = YES;
            aspectRatioHorizontally = !aspectRatioHorizontally;
        }
            break;
        default:
            break;
    }
    
    switch (self.aspectRatio) {
        case LFGridViewAspectRatioType_None:
            return CGSizeZero;
        case LFGridViewAspectRatioType_Original:
            if (self.controlSize.width == 0 || self.controlSize.height == 0) {
                return CGSizeZero;
            }
            if (aspectRatioHorizontally) {
                return CGSizeMake(1, self.controlSize.height/self.controlSize.width);
            } else {
                return CGSizeMake(self.controlSize.width/self.controlSize.height, 1);
            }
        case LFGridViewAspectRatioType_1x1:
            return CGSizeMake(1, 1);
        case LFGridViewAspectRatioType_3x2:
            if (aspectRatioHorizontally) {
                return CGSizeMake(3, 2);
            } else {
                return CGSizeMake(2, 3);
            }
        case LFGridViewAspectRatioType_4x3:
            if (aspectRatioHorizontally) {
                return CGSizeMake(4, 3);
            } else {
                return CGSizeMake(3, 4);
            }
        case LFGridViewAspectRatioType_5x3:
            if (aspectRatioHorizontally) {
                return CGSizeMake(5, 3);
            } else {
                return CGSizeMake(3, 5);
            }
        case LFGridViewAspectRatioType_15x9:
            if (aspectRatioHorizontally) {
                return CGSizeMake(15, 9);
            } else {
                return CGSizeMake(9, 15);
            }
        case LFGridViewAspectRatioType_16x9:
            if (aspectRatioHorizontally) {
                return CGSizeMake(16, 9);
            } else {
                return CGSizeMake(9, 16);
            }
        case LFGridViewAspectRatioType_16x10:
            if (aspectRatioHorizontally) {
                return CGSizeMake(16, 10);
            } else {
                return CGSizeMake(10, 16);
            }
        default:
        {
            NSUInteger index = self.aspectRatio - LFGridViewAspectRatioType_Extra - 1;
            if (index < self.extraAspectRatioList.count) {
                id <LFExtraAspectRatioProtocol> extraAspectRatio = self.extraAspectRatioList[index];
                if (extraAspectRatio.autoAspectRatio) {
                    if (aspectRatioHorizontally) { /** 使用适配视图纵横比例，根据aspectRatioHorizontally判断 */
                        return CGSizeMake(abs(extraAspectRatio.lf_aspectHeight), abs(extraAspectRatio.lf_aspectWidth));
                    } else {
                        return CGSizeMake(abs(extraAspectRatio.lf_aspectWidth), abs(extraAspectRatio.lf_aspectHeight));
                    }
                } else {
                    if (angleAspectRatioHorizontally) { /** 禁用适配视图纵横比例，根据angleAspectRatioHorizontally判断，旋转界面需要改变比例。 */
                        return CGSizeMake(abs(extraAspectRatio.lf_aspectHeight), abs(extraAspectRatio.lf_aspectWidth));
                    } else {
                        return CGSizeMake(abs(extraAspectRatio.lf_aspectWidth), abs(extraAspectRatio.lf_aspectHeight));
                    }
                }
            }
            return CGSizeZero;
        }
    }
        
    return CGSizeZero;
}

- (LFResizeControl *)createResizeControl
{
    LFResizeControl *control = [[LFResizeControl alloc] initWithFrame:(CGRect){CGPointZero, CGSizeMake(kControlWidth, kControlWidth)}];
    control.delegate = self;
    [self addSubview:control];
    return control;
}

- (CGRect)cropRectMakeWithResizeControlView:(LFResizeControl *)resizeControlView
{
    CGRect rect = self.gridRect;
    
    CGSize aspectRatioSize = self.aspectRatioSize;
    CGFloat widthRatio = aspectRatioSize.height == 0 ? 0 : aspectRatioSize.width/aspectRatioSize.height;
    CGFloat heightRatio = aspectRatioSize.width == 0 ? 0 : aspectRatioSize.height/aspectRatioSize.width;
    
    if (resizeControlView == self.topEdgeView) {
        rect = CGRectMake(CGRectGetMinX(self.initialRect) + resizeControlView.translation.y * widthRatio / 2,
                          CGRectGetMinY(self.initialRect) + resizeControlView.translation.y,
                          CGRectGetWidth(self.initialRect) - resizeControlView.translation.y * widthRatio,
                          CGRectGetHeight(self.initialRect) - resizeControlView.translation.y);
    } else if (resizeControlView == self.leftEdgeView) {
        rect = CGRectMake(CGRectGetMinX(self.initialRect) + resizeControlView.translation.x,
                          CGRectGetMinY(self.initialRect) + resizeControlView.translation.x * heightRatio / 2,
                          CGRectGetWidth(self.initialRect) - resizeControlView.translation.x,
                          CGRectGetHeight(self.initialRect) - resizeControlView.translation.x * heightRatio);
    } else if (resizeControlView == self.bottomEdgeView) {
        rect = CGRectMake(CGRectGetMinX(self.initialRect) - resizeControlView.translation.y * widthRatio / 2,
                          CGRectGetMinY(self.initialRect),
                          CGRectGetWidth(self.initialRect) + resizeControlView.translation.y * widthRatio,
                          CGRectGetHeight(self.initialRect) + resizeControlView.translation.y);
    } else if (resizeControlView == self.rightEdgeView) {
        rect = CGRectMake(CGRectGetMinX(self.initialRect),
                          CGRectGetMinY(self.initialRect) - resizeControlView.translation.x * heightRatio / 2,
                          CGRectGetWidth(self.initialRect) + resizeControlView.translation.x,
                          CGRectGetHeight(self.initialRect) + resizeControlView.translation.x * heightRatio);
    } else if (resizeControlView == self.topLeftCornerView) {
        /** 固定大小比例 */
        if (heightRatio && widthRatio) {
            CGFloat trans = self.aspectRatioHorizontally ? MAX(resizeControlView.translation.x, resizeControlView.translation.y) : MIN(resizeControlView.translation.x, resizeControlView.translation.y);
            rect = CGRectMake(CGRectGetMinX(self.initialRect) + trans,
                              CGRectGetMinY(self.initialRect) + trans * heightRatio,
                              CGRectGetWidth(self.initialRect) - trans,
                              CGRectGetHeight(self.initialRect) - trans * heightRatio);
        } else {
            rect = CGRectMake(CGRectGetMinX(self.initialRect) + resizeControlView.translation.x,
                              CGRectGetMinY(self.initialRect) + resizeControlView.translation.y,
                              CGRectGetWidth(self.initialRect) - resizeControlView.translation.x,
                              CGRectGetHeight(self.initialRect) - resizeControlView.translation.y);
        }
    } else if (resizeControlView == self.topRightCornerView) {
        /** 固定大小比例 */
        if (heightRatio && widthRatio) {
            CGFloat trans = self.aspectRatioHorizontally ? MAX(resizeControlView.translation.x * -1, resizeControlView.translation.y) : MIN(resizeControlView.translation.x * -1, resizeControlView.translation.y);
            rect = CGRectMake(CGRectGetMinX(self.initialRect),
                              CGRectGetMinY(self.initialRect) + trans * heightRatio,
                              CGRectGetWidth(self.initialRect) - trans,
                              CGRectGetHeight(self.initialRect) - trans * heightRatio);
        } else {
            rect = CGRectMake(CGRectGetMinX(self.initialRect),
                              CGRectGetMinY(self.initialRect) + resizeControlView.translation.y,
                              CGRectGetWidth(self.initialRect) + resizeControlView.translation.x,
                              CGRectGetHeight(self.initialRect) - resizeControlView.translation.y);
        }
    } else if (resizeControlView == self.bottomLeftCornerView) {
        /** 固定大小比例 */
        if (heightRatio && widthRatio) {
            CGFloat trans = self.aspectRatioHorizontally ? MAX(resizeControlView.translation.x, resizeControlView.translation.y * -1) : MIN(resizeControlView.translation.x, resizeControlView.translation.y * -1);
            rect = CGRectMake(CGRectGetMinX(self.initialRect) + trans,
                              CGRectGetMinY(self.initialRect),
                              CGRectGetWidth(self.initialRect) - trans,
                              CGRectGetHeight(self.initialRect) - trans * heightRatio);
        } else {
            rect = CGRectMake(CGRectGetMinX(self.initialRect) + resizeControlView.translation.x,
                              CGRectGetMinY(self.initialRect),
                              CGRectGetWidth(self.initialRect) - resizeControlView.translation.x,
                              CGRectGetHeight(self.initialRect) + resizeControlView.translation.y);
        }
    } else if (resizeControlView == self.bottomRightCornerView) {
        /** 固定大小比例 */
        if (heightRatio && widthRatio) {
            CGFloat trans = self.aspectRatioHorizontally ? MAX(resizeControlView.translation.x * -1, resizeControlView.translation.y * -1) : MIN(resizeControlView.translation.x * -1, resizeControlView.translation.y * -1);
            rect = CGRectMake(CGRectGetMinX(self.initialRect),
                              CGRectGetMinY(self.initialRect),
                              CGRectGetWidth(self.initialRect) - trans,
                              CGRectGetHeight(self.initialRect) - trans * heightRatio);
        } else {
            rect = CGRectMake(CGRectGetMinX(self.initialRect),
                              CGRectGetMinY(self.initialRect),
                              CGRectGetWidth(self.initialRect) + resizeControlView.translation.x,
                              CGRectGetHeight(self.initialRect) + resizeControlView.translation.y);
        }
    }
    
    if (heightRatio && widthRatio) {
        /** 限制长宽同时少于最小值，不处理 */
        if (ceil(rect.size.width) < ceil(_controlMinSize.width) && ceil(rect.size.height) < ceil(_controlMinSize.height)) {
            return self.gridRect;
        }
    }
    
    /** ps：
        此处判断 不能使用CGRectGet开头的方法，计算会有问题；
        当rect = (origin = (x = 50, y = 618), size = (width = 61, height = -488)) 时，
        CGRectGetMaxY(rect) = 618；CGRectGetHeight(rect) = 488
     */
    
    /** 限制x/y 超出左上角 最大限度 */
    if (ceil(rect.origin.x) < ceil(CGRectGetMinX(_controlMaxRect))) {
        rect.origin.x = _controlMaxRect.origin.x;
        rect.size.width = CGRectGetMaxX(self.initialRect)-rect.origin.x;
    }
    if (ceil(rect.origin.y) < ceil(CGRectGetMinY(_controlMaxRect))) {
        rect.origin.y = _controlMaxRect.origin.y;
        rect.size.height = CGRectGetMaxY(self.initialRect)-rect.origin.y;
    }
    
    /** 限制宽度／高度 超出 最大限度 */
    if (ceil(rect.origin.x+rect.size.width) > ceil(CGRectGetMaxX(_controlMaxRect))) {
        rect.size.width = CGRectGetMaxX(_controlMaxRect) - CGRectGetMinX(rect);
    }
    if (ceil(rect.origin.y+rect.size.height) > ceil(CGRectGetMaxY(_controlMaxRect))) {
        rect.size.height = CGRectGetMaxY(_controlMaxRect) - CGRectGetMinY(rect);
    }
    
    /** 限制宽度／高度 小于 最小限度 */
    if (ceil(rect.size.width) <= ceil(_controlMinSize.width)) {
        /** 左上、左、左下 处理x最小值 */
        if (resizeControlView == self.topLeftCornerView || resizeControlView == self.leftEdgeView || resizeControlView == self.bottomLeftCornerView) {
            rect.origin.x = CGRectGetMaxX(self.initialRect) - _controlMinSize.width;
        }
        rect.size.width = _controlMinSize.width;
        if (heightRatio && widthRatio) {
            rect.size.height = rect.size.width * heightRatio;
            /** 左、右 处理x最小值中间 */
            if (resizeControlView == self.leftEdgeView || resizeControlView == self.rightEdgeView) {
                rect.origin.y = CGRectGetMaxY(self.initialRect) - CGRectGetHeight(self.initialRect)/2 - rect.size.height/2;
            }
            /** 上、下 处理y最小值中间 */
            if (resizeControlView == self.topEdgeView || resizeControlView == self.bottomEdgeView) {
                rect.origin.x = CGRectGetMaxX(self.initialRect) - CGRectGetWidth(self.initialRect)/2 - _controlMinSize.width/2;
            }
            /** 左上、上、右上 处理y最小值底部 */
            if (resizeControlView == self.topLeftCornerView || resizeControlView == self.topEdgeView || resizeControlView == self.topRightCornerView) {
                rect.origin.y = CGRectGetMaxY(self.initialRect) - rect.size.height;
            }
        }
    }
    if (ceil(rect.size.height) <= ceil(_controlMinSize.height)) {
        /** 左上、上、右上 处理y最小值底部 */
        if (resizeControlView == self.topLeftCornerView || resizeControlView == self.topEdgeView || resizeControlView == self.topRightCornerView) {
            rect.origin.y = CGRectGetMaxY(self.initialRect) - _controlMinSize.height;
        }
        rect.size.height = _controlMinSize.height;
        if (heightRatio && widthRatio) {
            rect.size.width = rect.size.height * widthRatio;
            /** 左、右 处理y最小值中间 */
            if (resizeControlView == self.leftEdgeView || resizeControlView == self.rightEdgeView) {
                rect.origin.y = CGRectGetMaxY(self.initialRect) - CGRectGetHeight(self.initialRect)/2 - _controlMinSize.height/2;
            }
            /** 上、下 处理x最小值中间 */
            if (resizeControlView == self.topEdgeView || resizeControlView == self.bottomEdgeView) {
                rect.origin.x = CGRectGetMaxX(self.initialRect) - CGRectGetWidth(self.initialRect)/2 - rect.size.width/2;
            }
            
            /** 左上、左、左下 处理x最小值 */
            if (resizeControlView == self.topLeftCornerView || resizeControlView == self.leftEdgeView || resizeControlView == self.bottomLeftCornerView) {
                rect.origin.x = CGRectGetMaxX(self.initialRect) - rect.size.width;
            }
        }
    }
    
    /** 固定大小比例 */
    if (heightRatio && widthRatio) {
        if (rect.size.width == _controlMaxRect.size.width) {
            rect.origin.y = self.initialRect.origin.y;
            rect.size.height = rect.size.width * heightRatio;
        } else if (rect.size.height == _controlMaxRect.size.height) {
            rect.origin.x = self.initialRect.origin.x;
            rect.size.width = rect.size.height * widthRatio;
        }
    }
    
    return rect;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    if (self == view) {
        return nil;
    }
    [self enableCornerViewUserInteraction:view];
    return view;
}

- (void)enableCornerViewUserInteraction:(UIView *)view
{
    for (UIView *control in self.subviews) {
        if ([control isKindOfClass:[LFResizeControl class]]) {
            if (view) {
                if (control == view) {
                    control.userInteractionEnabled = YES;
                } else {
                    control.userInteractionEnabled = NO;
                }
            } else {
                control.userInteractionEnabled = YES;
            }
        }
    }
}

@end
