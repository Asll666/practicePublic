//
//  LZSwipeableView.m
//  ZLSwipeCardableView
//
//  Created by 周济 on 16/4/6.
//  Copyright © 2016年 LeoZ. All rights reserved.
//

#import "LZSwipeableView.h"

// 通用性父类cell,集成此父类即可自定义cell

@class LZSwipeableViewCell;
@protocol LZSwipeableViewCellDelagate <NSObject>
@optional
/**
 从哪个方向移除一个卡片
 
 @param cell cell
 @param direction 方向
 */
- (void)swipeableViewCellDidRemoveFromSuperView:(LZSwipeableViewCell *)cell withDirection:(LZSwipeableViewCellSwipeDirection)direction;
/**
 添加一个cell
 
 @param currentCell 当前的cell 在当前的基础上进行添加cell
 @param centerX x的坐标
 @param centerY y的坐标
 @param direction 方向
 */
- (void)swipeableViewCellDidAddFromSuperView:(LZSwipeableViewCell *)currentCell withCenterX:(CGFloat)centerX withCenterY:(CGFloat)centerY withDirection:(LZSwipeableViewCellSwipeDirection)direction;
/**
 向右滑动结束但是没有达到标准的
 
 @param currentCell 当前的cell 在当前的基础上进行添加cell
 */
- (void)swipeableViewDealWithRightAction:(LZSwipeableViewCell *)currentCell;
/**
 向右滑动的动画结束
 
 @param currentCell currentCell
 */
- (void)swipeableViewRightActionFinish:(LZSwipeableViewCell *)currentCell;

/**
 当cell变化时候改变coverview的透明度
 
 @param currentCell 当前的cell
 @param offsetX 偏移量
 */
- (void)changeNextCellCoverViewAlpha:(LZSwipeableViewCell *)currentCell withOffsetX:(CGFloat)offsetX;


@end

@interface LZSwipeableViewCell ()
@property (nonatomic, assign) CGPoint originalPoint;
@property (nonatomic, weak) id<LZSwipeableViewCellDelagate> LZPrivateDelegate;
@end


@implementation LZSwipeableViewCell{
    CGFloat xFromCenter;
    CGFloat yFromCenter;
    UIPanGestureRecognizer *pan;
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier{
    // 为防止在初始化cell时 采用masonry布局子控件设置固定高度产生的约束冲突 初始化cell的时候提供初始化尺寸 在reloadData时会对cell进行重新布局
    if(self = [super initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH)]){
        self.reuseIdentifier = reuseIdentifier;
        
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)addSnapshotView:(UIView*)snapshotView {
    [self removeSnapshotView];
    
    UIView *view = snapshotView;
    view.tag = INTMAX_MAX;
    view.frame = self.bounds;
    if (view) {
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self addSubview:view];
    }
}

- (void)removeSnapshotView {
    [[self viewWithTag:INTMAX_MAX] removeFromSuperview];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    return self;
}


- (void)setup{
    pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self addGestureRecognizer:pan];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.contentView.frame = self.bounds;
    self.originalPoint = CGPointMake(self.width/2, self.height/2);
}


// 拖拽手势事件处理
- (void)pan:(UIPanGestureRecognizer *)gestureRecognizer{
    
    xFromCenter = [gestureRecognizer translationInView:self].x;
    yFromCenter = [gestureRecognizer translationInView:self].y;
    
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:{
            self.originalPoint = self.center;
            break;
        };
        case UIGestureRecognizerStateChanged:{
            if (xFromCenter <= 0) { // 左滑动
                [self.layer removeAllAnimations];
                CGFloat translateX = xFromCenter*1.3;
                if (translateX <= -self.frame.size.width*0.9) {
                    translateX = -self.frame.size.width*0.9;
                }
                self.transform = CGAffineTransformMakeTranslation(translateX, 0);
                if ([self.LZPrivateDelegate respondsToSelector:@selector(changeNextCellCoverViewAlpha:withOffsetX:)]) {
                    [self.LZPrivateDelegate changeNextCellCoverViewAlpha:self withOffsetX:xFromCenter];
                }
            }else{ // 右滑动
                if (!self.isFirst) {
                    if ([self.LZPrivateDelegate respondsToSelector:@selector(swipeableViewCellDidAddFromSuperView:withCenterX:withCenterY:withDirection:)]) {
                        [self.LZPrivateDelegate swipeableViewCellDidAddFromSuperView:self withCenterX:xFromCenter withCenterY:yFromCenter withDirection:LZSwipeableViewCellSwipeDirectionRight];
                    }
                }else{
                    self.transform = CGAffineTransformMakeTranslation(xFromCenter, 0);
                }
            }
            break;
        };
        case UIGestureRecognizerStateEnded: {
            [self afterSwipeAction];
            break;
        };
        case UIGestureRecognizerStatePossible:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:{
            [UIView animateWithDuration:0.3
                             animations:^{
                                 self.center = self.originalPoint;
                                 self.transform = CGAffineTransformIdentity;
                             }];
            break;
        };
    }
}
// 拖拽手势结束时 处理当前卡片的位置
- (void)afterSwipeAction
{
    if (self.isFirst) { // 第一个
        if (xFromCenter < -ACTION_MARGIN) {
            [self leftAction];
        }else {//不飞走 回复原来位置
            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.transform = CGAffineTransformIdentity;
                self.center = self.originalPoint;
            }completion:nil];
        }
    }else if(self.isLast){// 最后一个
        if (xFromCenter > ACTION_MARGIN) {
            if ([self.LZPrivateDelegate respondsToSelector:@selector(swipeableViewRightActionFinish:)]) {
                [self.LZPrivateDelegate swipeableViewRightActionFinish:self];
            }
        }else if(xFromCenter > 0){
            if ([self.LZPrivateDelegate respondsToSelector:@selector(swipeableViewDealWithRightAction:)]) {
                [self.LZPrivateDelegate swipeableViewDealWithRightAction:self];
            }
        }else{// 不飞走 回复原来位置
            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.transform = CGAffineTransformIdentity;
                self.center = self.originalPoint;
            }completion:nil];
        }
    }else{ // 中间的
        if (xFromCenter < -ACTION_MARGIN) {
            [self leftAction];
        }else if(xFromCenter <= 0){// 不飞走 回复原来位置
            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.transform = CGAffineTransformIdentity;
                self.center = self.originalPoint;
            }completion:nil];
        }else if(xFromCenter > ACTION_MARGIN){ // 右边飞走
            if ([self.LZPrivateDelegate respondsToSelector:@selector(swipeableViewRightActionFinish:)]) {
                [self.LZPrivateDelegate swipeableViewRightActionFinish:self];
            }
        }else{
            if ([self.LZPrivateDelegate respondsToSelector:@selector(swipeableViewDealWithRightAction:)]) {
                [self.LZPrivateDelegate swipeableViewDealWithRightAction:self];
            }
        }
    }
}
-(void)leftAction
{
    [self.layer removeAllAnimations];
    
    self.layer.anchorPoint = CGPointMake(1, 1);
    self.layer.position = CGPointMake(self.frame.size.width, (self.center.y - self.frame.size.height/2.0+self.frame.size.height));
    [UIView animateWithDuration:0.25 animations:^{
        self.transform = CGAffineTransformMakeTranslation(-self.frame.size.width*0.9, 0);
        if ([self.LZPrivateDelegate respondsToSelector:@selector(changeNextCellCoverViewAlpha:withOffsetX:)]) {
            [self.LZPrivateDelegate changeNextCellCoverViewAlpha:self withOffsetX:-self.frame.size.width*0.9];
        }
    }completion:^(BOOL finished) {
        CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
        CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scaleAnimation.fromValue = @(1.0);
        scaleAnimation.toValue = @(0.8);
        
        CABasicAnimation *rotationamation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rotationamation.fromValue = [NSNumber numberWithFloat:0];
        rotationamation.toValue = [NSNumber numberWithFloat:-M_PI_4/2.0];
        animationGroup.duration = 0.5;
        
        animationGroup.removedOnCompletion = NO;
        animationGroup.fillMode = kCAFillModeForwards;
        animationGroup.animations = @[scaleAnimation,rotationamation];
        [self.layer addAnimation:animationGroup forKey:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self didCellRemoveFromSuperview:LZSwipeableViewCellSwipeDirectionLeft];
        });
    }];
}

-(void)topAction
{
    CGFloat pointY = _originalPoint.y - (SCREEN_HEIGHT + self.height) / 2;
    CGFloat pointX = _originalPoint.x - (SCREEN_HEIGHT + self.height) / 2 * xFromCenter / yFromCenter;
    CGPoint finishPoint = CGPointMake(pointX,pointY);
    [UIView animateWithDuration:0.25 animations:^{
        self.transform = CGAffineTransformIdentity;
        self.center = finishPoint;
    } completion:^(BOOL finished) {
        [self didCellRemoveFromSuperview:LZSwipeableViewCellSwipeDirectionTop];
    }];
}

-(void)bottomAction
{
    CGFloat pointY = _originalPoint.y + (SCREEN_HEIGHT + self.height) / 2;
    CGFloat pointX = _originalPoint.x + (SCREEN_HEIGHT + self.height) / 2 * xFromCenter / yFromCenter;
    CGPoint finishPoint = CGPointMake(pointX,pointY);
    [UIView animateWithDuration:0.25 animations:^{
        self.transform = CGAffineTransformIdentity;
        self.center = finishPoint;
    } completion:^(BOOL finished) {
        [self didCellRemoveFromSuperview:LZSwipeableViewCellSwipeDirectionBottom];
    }];
}

- (void)removeFromSuperviewWithDirection:(LZSwipeableViewCellSwipeDirection)direction{
    if (direction == LZSwipeableViewCellSwipeDirectionLeft) {
        xFromCenter = -200;
        yFromCenter = -1;
        self.transform = CGAffineTransformMakeTranslation(xFromCenter, yFromCenter);
    }else if (direction == LZSwipeableViewCellSwipeDirectionRight){
        xFromCenter = 200;
        yFromCenter = -1;
    }
    
    [self afterSwipeAction];
}

// 卡片飞走后调用代理方法
- (void)didCellRemoveFromSuperview:(LZSwipeableViewCellSwipeDirection)direction{
    [self removeFromSuperview];
    if ([self.LZPrivateDelegate respondsToSelector:@selector(swipeableViewCellDidRemoveFromSuperView:withDirection:)]) {
        [self.LZPrivateDelegate swipeableViewCellDidRemoveFromSuperView:self withDirection:direction];
    }
}

@end


@interface LZSwipeableView ()<UIGestureRecognizerDelegate,LZSwipeableViewCellDelagate>
/** 容器视图  */
@property (nonatomic, strong) UIView *containerView;
/** 最大显示卡片数  */
@property (nonatomic, assign) NSInteger maxCardsShowNumber;
/** 当前显示的卡片视图数组  */
@property (nonatomic, strong) NSArray *cardViewArray;
/** 所有卡片数组  */
@property (nonatomic, assign) NSInteger totalCardViewArrayCount;
/** 重用卡片数组  */
@property (nonatomic, strong) NSMutableArray *reuseCardViewArray;
/** 删除卡片的数组  */
@property (nonatomic, strong) NSMutableArray *deleteCardArray;
/** 初始中心点  */
@property (nonatomic, assign) CGPoint originalPoint;
/** 结束中心点 */
@property (nonatomic, assign) CGPoint endPoint;
/** 注册cell  */
@property (nonatomic, assign) BOOL hasRegisterNib;
@property (nonatomic, assign) BOOL hasRegisterClass;
/** 重用标示  */
@property (nonatomic, strong) NSString *reuserNibIdentifier;
@property (nonatomic, strong) NSString *reuserClassIdentifier;
/** nib */
@property (nonatomic, strong) NSString *nibName;
/** class  */
@property (nonatomic, assign) Class cellClass;
// 头部和尾部视图
@property (nonatomic, strong,readwrite) UIView *headerView;
@property (nonatomic, strong,readwrite) UIView *footerView;
/** 正在创建cell  */
@property (nonatomic, assign) BOOL isCreating;
/** 数据源  */
@property (nonatomic, assign) NSInteger datasourceCount;
/** 卡片四边间距设置  */
@property (nonatomic, assign) CGFloat cardLeftMargin;
@property (nonatomic, assign) CGFloat cardRightMargin;
@property (nonatomic, assign) CGFloat cardTopMargin;
@property (nonatomic, assign) CGFloat cardBottomMargin;
/** 前一个cell  */
@property (strong, nonatomic) LZSwipeableViewCell *currentPreviousCell;

@end

@implementation LZSwipeableView

#pragma mark - 懒加载
- (NSMutableArray *)reuseCardViewArray{
    if (!_reuseCardViewArray) {
        _reuseCardViewArray = [NSMutableArray array];
    }
    return _reuseCardViewArray;
}
-(NSMutableArray *)deleteCardArray {
    if (!_deleteCardArray) {
        _deleteCardArray = [NSMutableArray array];
    }
    return _deleteCardArray;
}
- (void)setTopCardInset:(UIEdgeInsets)topCardInset{
    _topCardInset = topCardInset;
    _cardLeftMargin = topCardInset.left;
    _cardRightMargin = topCardInset.right;
    _cardTopMargin = topCardInset.top;
    _cardBottomMargin = topCardInset.bottom;
}
- (CGFloat)bottomCardInsetHorizontalMargin{
    CGFloat bottomCardHorizontalInsetMargin = _bottomCardInsetHorizontalMargin;
    if (bottomCardHorizontalInsetMargin == 0) {
        bottomCardHorizontalInsetMargin = Bottom_Card_Inset_Margin;
    }
    return bottomCardHorizontalInsetMargin;
}

- (CGFloat)bottomCardInsetVerticalMargin{
    CGFloat bottomCardVerticalInsetMargin = _bottomCardInsetVerticalMargin;
    if (bottomCardVerticalInsetMargin == 0) {
        bottomCardVerticalInsetMargin = Bottom_Card_Inset_Margin;
    }
    return bottomCardVerticalInsetMargin;
}

#pragma mark - initialize
- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setupSubViews];
    }
    return self;
}
-(void)awakeFromNib {
    [super awakeFromNib];
    [self setupSubViews];
}

- (void)setupSubViews{
    // 初始化容器视图
    self.containerView = [UIView new];
    self.containerView.backgroundColor = [UIColor greenColor];
    if (self.containViewColor) {
        self.containerView.backgroundColor = self.containViewColor;
    }
    [self addSubview:self.containerView];
}
/**
 设置颜色
 
 @param containViewColor 颜色
 */
-(void)setContainViewColor:(UIColor *)containViewColor {
    _containViewColor = containViewColor;
    self.containerView.backgroundColor = containViewColor;
}
#pragma mark - 注册方法
- (void)registerNibName:(NSString *)nibName forCellReuseIdentifier:(NSString *)identifier{
    self.hasRegisterNib = YES;
    self.nibName = nibName;
    self.reuserNibIdentifier = identifier;
}

- (void)registerClass:(Class)cellClass forCellReuseIdentifier:(NSString *)identifier{
    self.hasRegisterClass = YES;
    self.cellClass = cellClass;
    self.reuserClassIdentifier = identifier;
}

- (__kindof LZSwipeableViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier{
    if (_hasRegisterNib) { // 注册nib
        BOOL hasNibCell = NO;
        //        for (LZSwipeableViewCell *cell in self.reuseCardViewArray) {
        //            if ([cell.reuseIdentifier isEqualToString:identifier]) {
        //                hasNibCell = YES;
        //                [self.reuseCardViewArray removeObject:cell];
        //                return cell;
        //            }
        //        }
        if (!hasNibCell) {
            LZSwipeableViewCell *cell = [[NSBundle mainBundle] loadNibNamed:self.nibName owner:nil options:nil].lastObject;
            cell.reuseIdentifier = identifier;
            return cell;
        }
    }else if(_hasRegisterClass){ // 注册class
        BOOL hasCellClass = NO;//  这个带我以后研究
        //        for (LZSwipeableViewCell *cell in self.reuseCardViewArray) {
        //            if ([cell.reuseIdentifier isEqualToString:identifier]) {
        //                hasCellClass = YES;
        //                [self.reuseCardViewArray removeObject:cell];
        //                return cell;
        //            }
        //        }
        if (!hasCellClass) {
            LZSwipeableViewCell *cell = [[self.cellClass alloc] initWithReuseIdentifier:identifier];
            cell.reuseIdentifier = identifier;
            return cell;
        }
    }
    return nil;
}

#pragma mark - 代理设置
- (void)setDelegate:(id<LZSwipeableViewDelegate>)delegate{
    _delegate = delegate;
    
    if ([self.delegate respondsToSelector:@selector(headerViewForSwipeableView:)]) {
        self.headerView = [self.delegate headerViewForSwipeableView:self];
        [self insertSubview:self.headerView belowSubview:self.containerView];
    }
    
    if ([self.delegate respondsToSelector:@selector(footerViewForSwipeableView:)]) {
        self.footerView = [self.delegate footerViewForSwipeableView:self];
        [self insertSubview:self.footerView belowSubview:self.containerView];
    }
}
#pragma mark - 位置处理
// 获取顶部卡片位置
- (CGRect)getTopCardFrame{
    
    CGFloat cardLeftMargin = self.cardLeftMargin;
    CGFloat cardRightMargin = self.cardRightMargin;
    CGFloat cardTopMargin = self.cardTopMargin;
    CGFloat cardBottomMargin = self.cardBottomMargin;
    CGFloat bottomCardVerticalInsetMargin = self.bottomCardInsetVerticalMargin;
    CGSize normalTopCardSize = CGSizeMake(self.containerView.width - cardLeftMargin - cardRightMargin, self.containerView.height - cardTopMargin - cardBottomMargin - (self.maxCardsShowNumber - 1) * bottomCardVerticalInsetMargin);
    return CGRectMake(cardLeftMargin, cardTopMargin + (self.maxCardsShowNumber - 1) * bottomCardVerticalInsetMargin, normalTopCardSize.width, normalTopCardSize.height);
}
// 获取当前的显示卡片数组
- (NSArray *)cardViewArray{
    NSMutableArray *cellArray = [NSMutableArray array];
    
    for (UIView *subView in self.containerView.subviews) {
        if ([subView isKindOfClass:[LZSwipeableViewCell class]]) {
            [cellArray insertObject:subView atIndex:0];
        }
    }
    return cellArray;
}

// 强制刷新界面
- (void)setLayoutSubViews{
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    [self layoutCardViews];
}

// 刷新位置(用于父控件位置改变时调用)
- (void)layoutCardViews{
    
    CGSize size = [self getTopCardFrame].size;
    CGPoint point = [self getTopCardFrame].origin;
    
    for (int i = 0; i < self.cardViewArray.count; i++) {
        LZSwipeableViewCell *cell = self.cardViewArray[i];
        if (i == 0) {
            if ([self.delegate respondsToSelector:@selector(swipeableView:didTopCardShow:)]) {
                [self.delegate swipeableView:self didTopCardShow:cell];
            }
            cell.userInteractionEnabled = YES;
        }
        CGSize cellSize = CGSizeMake(size.width -  self.bottomCardInsetHorizontalMargin * 2 * i, size.height * (size.width - self.bottomCardInsetHorizontalMargin * 2 * i) / size.width);
        CGFloat x = point.x + i * self.bottomCardInsetHorizontalMargin;
        CGFloat y = point.y - self.bottomCardInsetVerticalMargin * i;
        cell.frame = CGRectMake(x, y, cellSize.width, cellSize.height);
    }
}

#pragma mark - 界面处理
// 刷新界面(第一次刷新视图时使用)
- (void)reloadData{
    if (self.datasourceCount <= 0) return;
    self.cardViewArray = nil;
    self.reuseCardViewArray = nil;
    self.totalCardViewArrayCount = 0;
    
    for (UIView *subView in self.containerView.subviews) {
        if ([subView isKindOfClass:[LZSwipeableViewCell class]]) {
            [subView removeFromSuperview];
        }
    }
    
    NSInteger showNumber = self.datasourceCount - self.beginIndex < self.maxCardsShowNumber ? (self.datasourceCount - self.beginIndex) : self.maxCardsShowNumber;
    for (NSInteger index = 0; index < self.beginIndex; index++) {
        LZSwipeableViewCell *cell = [self.datasource swipeableView:self cellForIndex:index];
        cell.tag = index;
        cell.LZPrivateDelegate = self;
        cell.userInteractionEnabled = NO;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        [cell addGestureRecognizer:tap];
        [self.deleteCardArray addObject:cell];
    }
    
    NSInteger number = 0;
    for (NSInteger i = self.deleteCardArray.count; i < self.datasourceCount; i++) {
        number ++;
        [self createSwipeableCardCellWithIndex:i];
        if (number == showNumber) {
            break;
        }
    }
    
    [self layoutHeaderFooterContainerViewFrame];
    [self layoutCardViews];
    
    CGSize size = [self getTopCardFrame].size;
    // 添加屏幕截图
    for (int index = 0; index < self.cardViewArray.count; index++) {
        if (index != 0) {
            if ([self.delegate respondsToSelector:@selector(swipeableView:substituteCellForIndex:)]) {
                LZSwipeableViewCell *cell = self.cardViewArray[index];
                LZSwipeableViewCell *subCell = [self.delegate swipeableView:self substituteCellForIndex:cell.tag];
                // 若是设置过阴影效果 需要在此处将阴影效果去除
                subCell.frame = CGRectMake(0, 0, size.width, size.height);
                [subCell setNeedsLayout];
                [subCell layoutIfNeeded];
                
                UIView *coverView = [[UIView alloc] initWithFrame:subCell.bounds];
                coverView.backgroundColor = [UIColor whiteColor];
                [cell addSnapshotView:coverView];
            }
        }
    }
}
// 创建新的cell
- (void)createSwipeableCardCellWithIndex:(NSInteger)index{
    
    self.isCreating = YES;
    LZSwipeableViewCell *cell = [self.datasource swipeableView:self cellForIndex:index];
    cell.tag = index;
    cell.LZPrivateDelegate = self;
    cell.userInteractionEnabled = NO;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [cell addGestureRecognizer:tap];
    [self.containerView insertSubview:cell atIndex:0];
    // self.totalCardViewArrayCount += 1;
    self.isCreating = NO;
}



// 布局子控件
- (void)layoutSubviews{
    [super layoutSubviews];
    [self layoutHeaderFooterContainerViewFrame];
}

- (void)layoutHeaderFooterContainerViewFrame{
    
    // 头部视图存在
    if (self.headerView) {
        if([self.delegate respondsToSelector:@selector(heightForHeaderView:)]){
            self.headerView.height = [self.delegate heightForHeaderView:self];
        }else{
            self.headerView.height = HeaderFooterToolViewDefaultHeight;
        }
        self.headerView.frame = CGRectMake(0, 0, self.width, self.headerView.height);
    }
    if (self.footerView) { // 底部视图存在
        if([self.delegate respondsToSelector:@selector(heightForFooterView:)]){
            self.footerView.height = [self.delegate heightForFooterView:self];
        }else{
            self.footerView.height = HeaderFooterToolViewDefaultHeight;
        }
    }
    
    CGRect containerFrame = self.bounds;
    if(self.headerView && self.footerView == nil){
        containerFrame = CGRectMake(0, self.headerView.height, self.width, self.height - self.headerView.height);
    }else if(self.headerView == nil && self.footerView){
        containerFrame = CGRectMake(0, 0, self.width, self.height - self.footerView.height);
    }else if (self.headerView && self.footerView){
        containerFrame = CGRectMake(0, self.headerView.height, self.width, self.height - self.headerView.height - self.footerView.height);
    }
    self.containerView.frame = containerFrame;
    
    if (self.footerView) {
        self.footerView.frame = CGRectMake(0, CGRectGetMaxY(self.containerView.frame), self.width, self.footerView.height);
    }
}
/**
 卡片位置重排
 */
- (void)updateSubViews{
    [self layoutHeaderFooterContainerViewFrame];
    CGSize size = [self getTopCardFrame].size;
    CGPoint point = [self getTopCardFrame].origin;
    
    // 添加屏幕截图
    for (int i = 0; i < self.cardViewArray.count; i++) {
        LZSwipeableViewCell *cell = self.cardViewArray[i];
        if ([self.delegate respondsToSelector:@selector(swipeableView:substituteCellForIndex:)]) {
            LZSwipeableViewCell *subCell = [self.delegate swipeableView:self substituteCellForIndex:cell.tag];
            subCell.frame = CGRectMake(0, 0, size.width, size.height);
            [subCell setNeedsLayout];
            [subCell layoutIfNeeded];
            
            UIView *coverView = [[UIView alloc] initWithFrame:subCell.bounds];
            coverView.backgroundColor = [UIColor whiteColor];
            [cell addSnapshotView:coverView];
        }
    }
    
    if (self.cardViewArray.count == self.maxCardsShowNumber) {
        // 位置重排 为动画前位置调整
        for (int i = 0; i < self.cardViewArray.count; i++) {
            LZSwipeableViewCell *cell = self.cardViewArray[i];
            CGSize cellSize = CGSizeMake(size.width -  self.bottomCardInsetHorizontalMargin * 2 * i, size.height * (size.width - self.bottomCardInsetHorizontalMargin * 2 * i) / size.width);
            CGFloat x = point.x + i * self.bottomCardInsetHorizontalMargin;
            CGFloat y = point.y - self.bottomCardInsetVerticalMargin * i;
            cell.frame = CGRectMake(x, y, cellSize.width, cellSize.height);
        }
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
    // 动画
    [UIView animateWithDuration:0.15
                          delay:0
                        options:UIViewAnimationOptionLayoutSubviews
                     animations:^{
                         for (int i = 0; i < self.cardViewArray.count; i++) {
                             LZSwipeableViewCell *cell = self.cardViewArray[i];
                             CGSize cellSize = CGSizeMake(size.width -  self.bottomCardInsetHorizontalMargin * 2 * i, size.height * (size.width - self.bottomCardInsetHorizontalMargin * 2 * i) / size.width);
                             CGFloat x = point.x + i * self.bottomCardInsetHorizontalMargin;
                             CGFloat y = point.y - self.bottomCardInsetVerticalMargin * i;
                             cell.frame = CGRectMake(x, y, cellSize.width, cellSize.height);
                         }
                         
                     } completion:^(BOOL finished) {
                         for (int i = 0; i < self.cardViewArray.count; i++) {
                             LZSwipeableViewCell *cell = self.cardViewArray[i];
                             if (i == 0) {
                                 if ([self.delegate respondsToSelector:@selector(swipeableView:didTopCardShow:)]) {
                                     [self.delegate swipeableView:self didTopCardShow:cell];
                                 }
                                 [cell removeSnapshotView];
                                 cell.userInteractionEnabled = YES;
                             }
                         }
                     }];
}
#pragma mark - gesture
- (void)tap:(UITapGestureRecognizer *)tap{
    if([self.delegate  respondsToSelector:@selector(swipeableView:didTapCellAtIndex:)]){
        [self.delegate swipeableView:self didTapCellAtIndex:tap.view.tag];
    }
}
// 获取当前要显示的卡片数
- (NSInteger)maxCardsShowNumber{
    CGFloat maxCardsShowNumber = LZSwipeableViewDefaultMaxShowCardNumber;
    if ([self.datasource respondsToSelector:@selector(swipeableViewMaxCardNumberWillShow:)]) {
        maxCardsShowNumber = [self.datasource swipeableViewMaxCardNumberWillShow:self] > 0 ? [self.datasource swipeableViewMaxCardNumberWillShow:self] : maxCardsShowNumber;
    }
    return maxCardsShowNumber;
}
// 获取数据源数组数量
- (NSInteger)datasourceCount{
    return [self.datasource swipeableViewNumberOfRowsInSection:self];
}
#pragma mark - LZSwipeableViewCellDelagate
/**
 添加一个cell
 
 @param currentCell 当前的cell 在当前的基础上进行添加cell
 @param centerX x的坐标
 @param centerY y的坐标
 @param direction 方向
 */
- (void)swipeableViewCellDidAddFromSuperView:(LZSwipeableViewCell *)currentCell withCenterX:(CGFloat)centerX withCenterY:(CGFloat)centerY withDirection:(LZSwipeableViewCellSwipeDirection)direction{
    
    if (!self.currentPreviousCell) {
        LZSwipeableViewCell *previousCell = [self.deleteCardArray lastObject];
        [previousCell.layer removeAllAnimations];
        previousCell.transform = CGAffineTransformIdentity;
        self.deleteCardArray.count > 0?(previousCell.tag = self.deleteCardArray.count - 1):(previousCell.tag = 0);
        self.currentPreviousCell = previousCell;
        self.currentPreviousCell.layer.anchorPoint = CGPointMake(1, 1);
        self.currentPreviousCell.layer.position = CGPointMake(currentCell.frame.size.width, currentCell.frame.size.height);
        [self.containerView addSubview:self.currentPreviousCell];
        self.currentPreviousCell.frame = CGRectMake(currentCell.origin.x - currentCell.frame.size.width *0.9, currentCell.origin.y, currentCell.frame.size.width, currentCell.frame.size.height);
        self.currentPreviousCell.transform = CGAffineTransformMakeRotation(-M_PI_4/2.0);
        self.currentPreviousCell.transform = CGAffineTransformScale(self.currentPreviousCell.transform, 0.5 ,0.5);
    }
    if(centerX <= ACTION_MARGIN){
        self.currentPreviousCell.transform = CGAffineTransformMakeRotation(-(1- centerX/ACTION_MARGIN)*M_PI_4/2.0);
        CGFloat scale = centerX/2.0/ACTION_MARGIN+0.5;
        if (scale >= 1.0) {
            scale = 1.0;
        }
        self.currentPreviousCell.transform = CGAffineTransformScale(self.currentPreviousCell.transform, scale, scale);
    }else{
        self.currentPreviousCell.transform = CGAffineTransformIdentity;
    }
}
/**
 从哪个方向上删除一个cell
 
 @param cell cell
 @param direction 方向
 */
- (void)swipeableViewCellDidRemoveFromSuperView:(LZSwipeableViewCell *)cell withDirection:(LZSwipeableViewCellSwipeDirection)direction{
    // 防止右边的动画在
    if (self.currentPreviousCell) {
        [self.currentPreviousCell removeFromSuperview];
        self.currentPreviousCell = nil;
    }
    [self.deleteCardArray addObject:cell];
    
    // 当cell被移除时重新刷新视图
    [self.reuseCardViewArray addObject:cell];
    // 通知代理 移除了当前cell
    if ([self.delegate respondsToSelector:@selector(swipeableView:didCardRemovedOrAddtIndex:withDirection:)]) {
        [self.delegate swipeableView:self didCardRemovedOrAddtIndex:cell.tag withDirection:direction];
    }
    NSInteger shouldNumber = (self.datasourceCount - self.deleteCardArray.count) < self.maxCardsShowNumber ? self.datasourceCount - self.deleteCardArray.count : self.maxCardsShowNumber;
    // 当前数据源还有数据 继续创建cell
    if (self.cardViewArray.count < shouldNumber) { // 当显示总数
        [self createSwipeableCardCellWithIndex:(self.deleteCardArray.count + self.cardViewArray.count)];
    }
    // 更新位置
    [self updateSubViews];
    // 更新first and last
    [self calculationFirstAndLast];
}
/**
 向右滑动结束但是没有达到标准的
 
 @param currentCell 当前的cell 在当前的基础上进行添加cell
 */
- (void)swipeableViewDealWithRightAction:(LZSwipeableViewCell *)currentCell{
    
    [self.currentPreviousCell removeFromSuperview];
    self.currentPreviousCell = nil;
}
/**
 向右滑动的动画结束
 
 @param currentCell currentCell
 */
- (void)swipeableViewRightActionFinish:(LZSwipeableViewCell *)currentCell{
    // 如果点击按钮可能会没有
    if (!self.currentPreviousCell) {
        LZSwipeableViewCell *previousCell = [self.deleteCardArray lastObject];
        [previousCell.layer removeAllAnimations];
        previousCell.transform = CGAffineTransformIdentity;
        self.deleteCardArray.count > 0?(previousCell.tag = self.deleteCardArray.count - 1):(previousCell.tag = 0);
        self.currentPreviousCell = previousCell;
        self.currentPreviousCell.layer.anchorPoint = CGPointMake(1, 1);
        self.currentPreviousCell.layer.position = CGPointMake(currentCell.frame.size.width, currentCell.frame.size.height);
        [self.containerView addSubview:self.currentPreviousCell];
        self.currentPreviousCell.frame = CGRectMake(currentCell.origin.x - currentCell.frame.size.width *0.9, currentCell.origin.y, currentCell.frame.size.width, currentCell.frame.size.height);
        self.currentPreviousCell.transform = CGAffineTransformMakeRotation(-M_PI_4/2.0);
        self.currentPreviousCell.transform = CGAffineTransformScale(self.currentPreviousCell.transform, 0.5 ,0.5);
    }
    [UIView animateWithDuration:0.25 animations:^{
        self.currentPreviousCell.transform = CGAffineTransformMakeRotation(0);
        self.currentPreviousCell.transform = CGAffineTransformScale(self.currentPreviousCell.transform, 1.0, 1.0);
        
    }completion:^(BOOL finished) {
        self.currentPreviousCell.layer.anchorPoint = CGPointMake(0.5, 0.5);
        self.currentPreviousCell.layer.position = currentCell.layer.position;
        // 添加一个平移的动画
        CABasicAnimation *translateAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
        translateAnimation.fromValue = @(currentCell.center.x - currentCell.frame.size.width *0.9);
        translateAnimation.toValue = @(currentCell.center.x);
        translateAnimation.duration = 0.5;
        translateAnimation.removedOnCompletion = NO;
        translateAnimation.fillMode = kCAFillModeForwards;
        translateAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [self.currentPreviousCell.layer addAnimation:translateAnimation forKey:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.currentPreviousCell.center = currentCell.center;
            // 开始进行重新布局以及相关
            [self updateUIAndSendDelegate:self.currentPreviousCell withDirection:LZSwipeableViewCellSwipeDirectionRight];
            [self.deleteCardArray removeLastObject];
            self.currentPreviousCell = nil;
        });
    }];
    
    
    
}
- (void)updateUIAndSendDelegate:(LZSwipeableViewCell *)previousCell withDirection:(LZSwipeableViewCellSwipeDirection)direction{
    
    // 当cell被移除时重新刷新视图
    //    [self.reuseCardViewArray addObject:previousCell];
    // 通知代理 移除了当前cell
    if ([self.delegate respondsToSelector:@selector(swipeableView:didCardRemovedOrAddtIndex:withDirection:)]) {
        [self.delegate swipeableView:self didCardRemovedOrAddtIndex:previousCell.tag withDirection:direction];
    }
    // 当前数据源还有数据 继续创建cell
    //self.totalCardViewArrayCount --;
    
    NSInteger shouldNumber = self.datasourceCount - (self.deleteCardArray.count-1) < self.maxCardsShowNumber ? self.datasourceCount - (self.deleteCardArray.count-1) : self.maxCardsShowNumber;
    if (self.cardViewArray.count > shouldNumber) {
        LZSwipeableViewCell *firstCell = (LZSwipeableViewCell *)[self.containerView.subviews firstObject];
        [firstCell removeFromSuperview];
    }
    // 更新位置
    [self updateSubViews];
    // 更新first and last
    [self calculationFirstAndLast];
}
/**
 计算上一个下一个的标示
 */
- (void)calculationFirstAndLast{
    // 移除最后一个cell的代理方法
    if (self.cardViewArray.count == 0) { // 当前移除的cell是最后一个
        if ([self.delegate respondsToSelector:@selector(swipeableViewDidLastCardRemoved:)]) {
            [self.delegate swipeableViewDidLastCardRemoved:self];
        }
    }
    // 移除后的卡片是最后一张时调用代理方法
    if(self.cardViewArray.count == 1){ // 只有最后一张卡片的时候
        LZSwipeableViewCell *cell = [self.cardViewArray lastObject];
        if ([self.delegate respondsToSelector:@selector(swipeableView:didLastCardShow:)]) {
            [self.delegate swipeableView:self didLastCardShow:cell];
        }
        cell.isLast = YES;
    }else{
        LZSwipeableViewCell *cell = [self.cardViewArray lastObject];
        cell.isLast = NO;
    }
    // 判断是第一张
    if (self.cardViewArray.count) {
        LZSwipeableViewCell *cell = [self.cardViewArray firstObject];
        cell.tag == 0 ?(cell.isFirst = YES):( cell.isFirst = NO);
    }
}
#pragma mark - 一般的方法响应
/**
 生成一个imageview
 
 @param view view
 @return imageview
 */
-(UIImageView *)creatSnapImageView:(UIView *)view{
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.frame = view.bounds;
    imageView.image = [self convertViewToImage:view];
    //imageView.contentMode = UIViewContentModeScaleAspectFit;
    return imageView;
}
/**
 传递一个view来进行生成图片的方法
 
 @param view 传递的view
 @return 图片
 */
- (UIImage *)convertViewToImage:(UIView *)view
{
    // 第二个参数表示是否非透明。如果需要显示半透明效果，需传NO，否则YES。第三个参数就是屏幕密度了
    UIGraphicsBeginImageContextWithOptions(view.bounds.size,YES,[UIScreen mainScreen].scale);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
/**
 当cell变化时候改变coverview的透明度
 
 @param currentCell 当前的cell
 @param offsetX 偏移量
 */
- (void)changeNextCellCoverViewAlpha:(LZSwipeableViewCell *)currentCell withOffsetX:(CGFloat)offsetX{
    if (self.cardViewArray.count > 1) {
        LZSwipeableViewCell *secondCell = self.cardViewArray[1];
        UIView *coverView = [secondCell.subviews lastObject];
        CGFloat shouldAplah = 1 - ABS(offsetX)/(self.frame.size.width *0.7);
        
        if (shouldAplah <= 0) {
            shouldAplah = 0;
        }
        coverView.alpha = shouldAplah;
    }
}
#pragma mark 其他的方法 手动点击移除的方法
- (void)removeTopCardViewFromSwipe:(LZSwipeableViewCellSwipeDirection)direction{
    if (self.cardViewArray.count == 0) {
        return;
    }
    LZSwipeableViewCell *topcell = self.cardViewArray[0];
    if (topcell.isFirst && direction ==LZSwipeableViewCellSwipeDirectionRight) {
        return;
    }
    if (topcell.isLast && direction ==LZSwipeableViewCellSwipeDirectionLeft) {
        return;
    }
    [topcell removeFromSuperviewWithDirection:direction];
}
#pragma mark - 刷新数据源  这个方法我没有验证（目前也用不到）
- (void)refreshDataSource{
    
    self.datasourceCount = [self.datasource swipeableViewNumberOfRowsInSection:self];
    // 当总数变化大于当前总数时(且当前显示卡片小于最大卡片数时继续创建)，继续创建cell
    if (self.datasourceCount - self.totalCardViewArrayCount > 0 && self.cardViewArray.count < self.maxCardsShowNumber) {
        NSInteger moreCount = self.datasourceCount - self.cardViewArray.count;
        NSInteger needCount = 0;
        if (moreCount >= self.maxCardsShowNumber - 1) { // 能创建全部的cell
            needCount = self.maxCardsShowNumber - self.cardViewArray.count;
            for (NSInteger i = 0; i < needCount; i++) {
                if (!self.isCreating) {
                    [self createSwipeableCardCellWithIndex:self.totalCardViewArrayCount];
                }
            }
        }else{ // 不能全部创建cell
            needCount = self.maxCardsShowNumber - 1 - self.cardViewArray.count;
            for (NSInteger i = 0; i < needCount; i++) {
                if (!self.isCreating) {
                    [self createSwipeableCardCellWithIndex:self.totalCardViewArrayCount];
                }
            }
        }
        [self updateSubViews];
    }
}
@end

