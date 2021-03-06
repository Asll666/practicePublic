//
//  ViewController.m
//  基本动画的练习
//
//  Created by apple on 2018/3/14.
//  Copyright © 2018年 apple. All rights reserved.
//

#import "ViewController.h"
#import "DrewView.h"

#define angele(x) (x/180.0*M_PI)

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *heartimageView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) UIView *frontView;
@property (strong, nonatomic) UIImageView *backView;
@property (weak, nonatomic) IBOutlet UIImageView *bottomImageView;
@property (nonatomic, assign) CGFloat opit;
@property (nonatomic, strong) UIView *view2;
@property (nonatomic, strong) CAGradientLayer *grandientLayer;
@property (weak, nonatomic) IBOutlet DrewView *drawView;



@end

@implementation ViewController
static int index_ = 1;

-(void)viewDidLoad {
    [super viewDidLoad];
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    
    

}

/**
 开始的方法

 @param sender 按钮
 */
- (IBAction)beginAction:(UIButton *)sender {
    [self.drawView startAction];
}

/**
 重绘的方法

 @param sender 按钮
 */
- (IBAction)redrewAction:(id)sender {
    [self.drawView redrewAction];
    
}
/**
 折叠的动画
 */
- (void)zhediePicture {
    
    self.heartimageView.layer.contentsRect = CGRectMake(0, 0, 1, 0.5);
    self.bottomImageView.layer.contentsRect = CGRectMake(0, 0.5, 1, 0.5);
    
    self.heartimageView.layer.anchorPoint = CGPointMake(0.5, 1);
    self.bottomImageView.layer.anchorPoint = CGPointMake(0.5, 0);
    // 添加拖拽的手势
    UIPanGestureRecognizer *panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
    [self.view addGestureRecognizer:panGes];
    // 添加隐影的操作(梯度的layer )
    CAGradientLayer *grandientLayer = [CAGradientLayer layer];
    grandientLayer.frame = self.bottomImageView.bounds;
    grandientLayer.colors = @[(id)[UIColor blackColor].CGColor,(id)[UIColor clearColor].CGColor];
    // 确定颜色的渐变方向
    grandientLayer.startPoint = CGPointMake(0, 0);
    grandientLayer.endPoint = CGPointMake(1.0, 1.0);
    // 一个颜色到下一个颜色开始渐变的位置
    grandientLayer.locations = @[@(0.2),@(0.8)];
    // 暗影
    grandientLayer.shadowOpacity = 0.0;
    // 不透明度
    grandientLayer.opacity = 0.0;
    self.grandientLayer = grandientLayer;
    [self.bottomImageView.layer addSublayer:grandientLayer];
}

/**
 添加拖拽的手势

 @param panGes 手势的点击
 */
- (void)panAction:(UIPanGestureRecognizer *)panGes {
    
    CGPoint point = [panGes locationInView:self.view];
    CGFloat angle =  M_PI * 1.0 * point.y /self.view.bounds.size.height;
    
    CATransform3D transform = CATransform3DIdentity;
    // 立体效果 离你眼睛越近 看的越清楚 离你眼睛越远 看的越小
    transform.m34 = -1.0/500.0;
    self.heartimageView.layer.transform = CATransform3DRotate(transform, -angle, 1.0, 0, 0);
    // 改变透明度
    self.grandientLayer.opacity = 1.0 * point.y /self.view.bounds.size.height;
    
    
    // 结束了进行反弹回去
    if (panGes.state == UIGestureRecognizerStateEnded) {
        // 一个动画
        // delay:动画开始时的等待时间，默认为0
        // usingSpringWithDamping: 反弹系数
        // initialSpringVelocity:动画的速度
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            // 去掉所有的动画 回去
            self.heartimageView.layer.transform = CATransform3DIdentity;
            self.grandientLayer.opacity = 0.0;
        } completion:nil];
        
    }
}
-(void)animationGroup {
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    animation.fromValue = @(0);
    animation.toValue = @(1.5);
    
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.fromValue = @(0);
    rotationAnimation.toValue = @(M_PI);
    group.animations = @[animation,rotationAnimation];
    group.duration = 1.5;
    group.repeatCount = NSIntegerMax;
    group.removedOnCompletion = NO;
    group.fillMode = kCAFillModeForwards;
    [self.heartimageView.layer addAnimation:group forKey:nil];
    
}
-(void)view4 {
    //  前台页面
    UIView *frontView = [[UIView alloc] initWithFrame:self.view.bounds];
    frontView.backgroundColor = [UIColor colorWithRed:0.345 green:0.349 blue:0.365 alpha:1.000];
    UIImageView *caLogoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"1"]];
    caLogoView.frame = CGRectMake(70, 80, caLogoView.bounds.size.width, caLogoView.bounds.size.height);
    [frontView addSubview:caLogoView];
    self.frontView = frontView;
    
    //  后台页面
    UIImage *backImage = [UIImage imageNamed:@"2"];
    UIImageView *backView = [[UIImageView alloc] initWithImage:backImage];
    backView.userInteractionEnabled = YES;
    self.backView = backView;
    
    [self.view addSubview:backView];
    [self.view addSubview:frontView];
    // formcview ：在执行动画的过程中，他将会从superview 删除
    // toView ：执行动画结束添加到fromview的父视图
    [UIView transitionFromView:self.frontView    // 从原来视图转到新视图的动画效果设置
                        toView:self.backView  duration:1.0f
                       options:UIViewAnimationOptionTransitionFlipFromLeft
                    completion:nil];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
   
}
/**
 基本动画 系统自带的
 */
-(void)view1{
    [UIView transitionWithView:self.heartimageView duration:2.0 options:UIViewAnimationOptionTransitionFlipFromBottom animations:^{
        index_ ++;
        if (index_ > 3 ) {
            index_ = 1;
        }
        NSString *imageName = [NSString stringWithFormat:@"%d",index_];
        self.heartimageView.image = [UIImage imageNamed:imageName];
    } completion:nil];
}
/**
 转场动画的 翻页效果
 */
-(void)pageAnimation{
    index_ ++;
    if (index_ > 3 ) {
        index_ = 1;
    }
    NSString *imageName = [NSString stringWithFormat:@"%d",index_];
    self.heartimageView.image = [UIImage imageNamed:imageName];
    
    CATransition *animation = [CATransition animation];
    /*
     type：动画过渡类型
     subtype：动画过渡方向
     startProgress：动画起点(在整体动画的百分比)
     endProgress：动画终点(在整体动画的百分比)
     */
    // 动画的过度类型
    // animation.type = kCATransitionMoveIn;
    // 或者这个方式也行
    /*
     关于type的总结 后面的一张图片
     */
    animation.type = @"pageCurl";
    // 动画的过度方向
    animation.subtype = kCATransitionFromRight;
    animation.startProgress = 0.1;
    animation.endProgress = 0.7;
    [self.heartimageView.layer addAnimation:animation forKey:nil];
}
/**
 图片抖动
 */
-(void)doudong{
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation"];
    animation.values = @[@(angele(-10)),@(angele(0))];
    animation.duration = 1.0;
    animation.repeatCount = NSIntegerMax;
    // 自动恢复原位
    animation.autoreverses = YES;
    //  动画结束后停在最后位置状态的解决方法
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    // 线性起搏，可使动画在其持续时间内均匀发生
    // kCAMediaTimingFunctionEaseInEaseOut： 轻松放松起搏，可以使动画开始缓慢，在其持续时间的中间加速，然后在完成之前再次放慢速度。
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.heartimageView.layer addAnimation:animation forKey:nil];
}
/**
 转场动画的围绕着一个圆旋转
 */
- (void)keyPathFrameRotation{
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(100, 100, 100, 100)];
    animation.path = path.CGPath;
    animation.duration = 3.0;
    animation.repeatCount = NSIntegerMax;
    // 自动恢复原位
    animation.autoreverses = YES;
    //  动画结束后停在最后位置状态的解决方法
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    // 线性起搏，可使动画在其持续时间内均匀发生
    // kCAMediaTimingFunctionEaseInEaseOut： 轻松放松起搏，可以使动画开始缓慢，在其持续时间的中间加速，然后在完成之前再次放慢速度。
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.heartimageView.layer addAnimation:animation forKey:nil];
}

/**
 改变透明度
 */
- (void)opacity{
    //opacity 指layer的透明度
    
    CABasicAnimation *basicAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    
    basicAnimation.fromValue = @(1.0);
    
    basicAnimation.toValue  = @(0.0);//[NSNumber numberWithFloat:0.0]
    
    basicAnimation.duration = 1.5;
    
    [self.heartimageView.layer addAnimation:basicAnimation forKey:@"op"];
}
-(void)rotation{
    // 对Y轴进行旋转（指定Z轴的话，就和UIView的动画一样绕中心旋转）
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.y"];
    animation.duration = 2;
    
    animation.repeatCount = NSIntegerMax;
    
    animation.beginTime = CACurrentMediaTime() + 1; // 1秒后执行
    
    animation.fromValue = [NSNumber numberWithFloat:0.0]; // 起始角度
    // 动画结束后停在最后位置状态的解决方法
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    
    animation.toValue = [NSNumber numberWithFloat:M_PI]; // 终止角度
    
    [self.heartimageView.layer addAnimation:animation forKey:@"rotate-layer"];
}
/**
 旋转的动画
 */
- (void)position{
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    animation.duration = 2;
    animation.repeatCount = NSIntegerMax;
    animation.beginTime =CACurrentMediaTime() + 1;// 1秒后执行
    
    animation.fromValue = [NSValue valueWithCGPoint:self.heartimageView.layer.position]; // 起始帧
    
    animation.toValue = [NSValue valueWithCGPoint:CGPointMake(300, 300)]; // 终了帧
    
    // 视图添加动画
    
    [self.heartimageView.layer addAnimation:animation forKey:@"move-layer"];
}

/**
 心跳的动画
 */
- (void)heart{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    animation.duration = 1.5;
    animation.fromValue = @(0);
    animation.toValue = @(2);
    // 无限重复
    animation.repeatCount = NSIntegerMax;
    // 自动恢复原来的位置（有一个恢复的动画）
    animation.autoreverses = YES;
    // 确定完成后动画是否从目标图层的动画中移除。
    // 当“是”时，一旦活动持续时间过去，动画将从目标图层的动画中移除。 默认为YES
    animation.removedOnCompletion = NO;
    [self.heartimageView.layer addAnimation:animation forKey:nil];
}

@end
