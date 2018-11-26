//
//  DGCacheMusicPlayer.m
//  播放器sdk
//
//  Created by apple on 2018/11/22.
//  Copyright © 2018年 apple. All rights reserved.
//

#import "DGCacheMusicPlayer.h"
#import <AVFoundation/AVFoundation.h>

#define DGPlayerStatusKey @"status"
#define DGPlayerRateKey @"rate"
#define DGPlayerLoadTimeKey @"loadedTimeRanges"
#define DGPlayerBufferEmty @"playbackBufferEmpty"
#define DGPlayerLikelyToKeepUp @"playbackLikelyToKeepUp"

@interface DGCacheMusicPlayer ()

/** 当前的播放的模型*/
@property (strong, nonatomic) DGCacheMusicModel *currentModel;
/** 当前的播放模式*/
@property (assign, nonatomic) DGCacheMusicMode innerCurrentMode;
/** 当前的播放器状态*/
@property (assign, nonatomic) DGCacheMusicState innerPlayState;
/** 是否需要缓存*/
@property (assign, nonatomic) BOOL isNeedCache;
/** 播放器*/
@property (strong, nonatomic) AVPlayer *player;
/** 播放的item*/
@property (strong, nonatomic) AVPlayerItem *playerItem;
/** 播放的数组*/
@property (strong, nonatomic) NSMutableArray *playList;
/** 播放进度的观察者*/
@property (strong, nonatomic) id playerObserver;


@end
@implementation DGCacheMusicPlayer
#pragma mark - 懒加载的创建
-(NSMutableArray *)playList {
    if (!_playList) {
        _playList = [[NSMutableArray alloc] init];
    }
    return _playList;
}
#pragma mark - 初始化
+(instancetype)shareInstance{
    
    static DGCacheMusicPlayer * _manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[self alloc] init];
    });
    return _manager;
}
- (instancetype)init{
    
    self = [super init];
    if (self) {
        
        self.innerPlayState = DGCacheMusicStateStop;
        self.innerCurrentMode = DGCacheMusicModeListRoop;
        self.currentModel = nil;

    }
    return self;
}
#pragma mark - 设置相关的方法
/**
 设置播放列表没有设置播放列表播放器没有播放地址
 
 @param playList 需要播放的模型数组
 @param offset 偏移量
 @param cache 是否需要缓存 YES：边下边播 NO:不缓存 在线播放
 */
- (void)setPlayList:(NSArray<DGCacheMusicModel *> *)playList
             offset:(NSUInteger)offset
            isCache:(BOOL)cache{
    
    NSAssert(playList.count != 0, @"对不起播放数组不能为空");
    NSAssert(!(offset > playList.count - 1 || offset < 0), @"offset不合法，大于播放列表的个数或者小于0了");
    if (offset > playList.count - 1 || offset < 0 || playList.count == 0) return;
    [self.playList addObjectsFromArray:playList];
    self.currentModel = self.playList[offset];
    if (self.currentModel.listenUrl.length == 0) return;
    self.isNeedCache = cache;
    if (self.isNeedCache == NO) { // 不需要缓存的情况
        if (!self.player) {
            self.playerItem = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:self.currentModel.listenUrl]];
            self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
            [self.player play];
            [self addMyObserver];
        }else{
            [self removeMyObserver];
            self.playerItem = self.playerItem = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:self.currentModel.listenUrl]];
            [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
            [self.player play];
            [self addMyObserver];
        }
    }else{ // 需要缓存的情况
        
    }
}
/**
 点击下一首播放
 
 @param isNeedSingRoopJump 当单曲循环的时候是否需要跳转到下一首（只有在单曲循环的情况下才有用）
 如果传递是yes的情况下，那么单曲循环就会跳转到下一首循环播放
 */
- (void)playNextSong:(BOOL)isNeedSingRoopJump{
    
    NSAssert(self.playList.count != 0, @"没有播放列表，无法播放下一首");
    if (self.playList.count == 0 || self.currentModel == nil){
        
        return;
    }
    if (self.currentModel == nil) {
        self.currentModel = [self.playList firstObject];
    }
    if (self.isNeedCache == NO) { // 不需要缓存的
        // 单曲循环不需要跳转的
        if (self.innerCurrentMode == DGCacheMusicModeSingleRoop && isNeedSingRoopJump == NO) {
            
            [self removeMyObserver];
            self.playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:self.currentModel.listenUrl]];
            [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
            [self.player play];
            [self addMyObserver];
            self.innerPlayState = DGCacheMusicStatePlay;
            return;
        }
        // 随机播放的情况
        if (self.innerCurrentMode == DGCacheMusicModeRandom) {
            NSUInteger nextIndex = arc4random_uniform((int32_t)self.playList.count -1);
            DGCacheMusicModel *randNextModel = self.playList[nextIndex];
            if (randNextModel.listenUrl.length > 0) {
                [self removeMyObserver];
                self.playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:randNextModel.listenUrl]];
                [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
                [self.player play];
                [self addMyObserver];
                self.currentModel = randNextModel;
                self.innerPlayState = DGCacheMusicStatePlay;
                return;
            }
         // 其他情况直接下一首
            DGCacheMusicModel *nextModel = [self getNextModel];
            if (nextModel.listenUrl.length > 0) {
                [self removeMyObserver];
                self.playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:nextModel.listenUrl]];
                [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
                [self.player play];
                [self addMyObserver];
                self.currentModel = nextModel;
                self.innerPlayState = DGCacheMusicStatePlay;
                return;
            }
        }
    }else{ // 需要缓存的
        
        
        
    }
}
/**
 播放上一首歌曲
 
 @param isNeedSingRoopJump 当单曲循环的时候是否需要跳转到下一首（只有在单曲循环的情况下才有用）
 如果传递是yes的情况下，那么单曲循环就会跳转到下一首循环播放
 */
- (void)playPreviousSong:(BOOL)isNeedSingRoopJump{
    
    NSAssert(self.playList.count != 0, @"对不起播放列表不能为空");
    if (self.playList.count == 0) {
        
        return;
    }
    if (self.currentModel == nil) {
        self.currentModel = [self.playList firstObject];
    }
    if (self.isNeedCache == NO) { // 不需要缓存的
        // 单曲循环不需要跳转的
        if (self.innerCurrentMode == DGCacheMusicModeSingleRoop && isNeedSingRoopJump == NO) {
            
            [self removeMyObserver];
            self.playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:self.currentModel.listenUrl]];
            [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
            [self.player play];
            [self addMyObserver];
            self.innerPlayState = DGCacheMusicStatePlay;
            return;
        }
        // 随机播放的情况
        if (self.innerCurrentMode == DGCacheMusicModeRandom) {
            NSUInteger nextIndex = arc4random_uniform((int32_t)self.playList.count -1);
            DGCacheMusicModel *randNextModel = self.playList[nextIndex];
            if (randNextModel.listenUrl.length > 0) {
                [self removeMyObserver];
                self.playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:randNextModel.listenUrl]];
                [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
                [self.player play];
                [self addMyObserver];
                self.currentModel = randNextModel;
                self.innerPlayState = DGCacheMusicStatePlay;
                return;
            }
            // 其他情况直接上一首
            DGCacheMusicModel *previousModel = [self getPreviousModel];
            if (previousModel.listenUrl.length > 0) {
                [self removeMyObserver];
                self.playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:previousModel.listenUrl]];
                [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
                [self.player play];
                [self addMyObserver];
                self.currentModel = previousModel;
                self.innerPlayState = DGCacheMusicStatePlay;
                return;
            }
        }
    }else{ // 需要缓存的
        
        
        
    }
    
    
    
    
}
/**
 设置当前的播放动作
 
 @param operate 动作： 播放、暂停、停止
 停止：清空播放列表，如果在要播放需要重新设置播放列表
 */
- (void)playOperate:(DGCacheMusicOperate)operate{
    
    NSAssert(self.currentModel.listenUrl.length != 0, @"对不起当前歌曲没有链接");
    if (self.currentModel.listenUrl.length == 0) {
        self.innerPlayState = DGCacheMusicStateStop;
        return;
    }
    switch (operate) {
        case DGCacheMusicOperatePlay:
        {
            if (self.player) {
                [self.player play];
                self.innerPlayState = DGCacheMusicStatePlay;
            }
        }
            break;
        case DGCacheMusicOperatePause:
        {
            if (self.player) {
                [self.player pause];
                self.innerPlayState = DGCacheMusicStatePause;
            }
        }
            break;
        case DGCacheMusicOperateStop:
        {
            if (self.isNeedCache == NO) { // 不需要缓存的
                if (self.player) {
                    [self.player pause];
                    [self removeMyObserver];
                    self.player = nil;
                    self.playerItem = nil;
                    self.innerPlayState = DGCacheMusicStateStop;
                    self.currentModel = nil;
                }
            }else{ // 需要缓存的 取消下载
                
            }
        }
            break;
        default:
            break;
    }
}
/**
 设置当前的播放模式
 
 @param mode 自己要设置的模式
 */
- (void)updateCurrentPlayMode:(DGCacheMusicMode)mode{
    
    self.innerCurrentMode = mode;
}
/**
 清空播放列表
 
 @param isStopPlay YES:停止播放 NO:不停止播放
 */
- (void)clearPlayList:(BOOL)isStopPlay{
    
    [self.playList removeAllObjects];
    if (isStopPlay) {
        [self removeMyObserver];
        self.currentModel = nil;
        self.playerItem = nil;
        self.player = nil;
        self.innerPlayState = DGCacheMusicStateStop;
    }
}
/**
 删除一个播放列表
 
 @param deleteList 要删除的播放列表
 */
- (void)deletePlayList:(NSArray<DGCacheMusicModel *>*)deleteList{
    
    NSAssert(deleteList.count != 0, @"要删除的数组不能为空");
    NSAssert(deleteList.count < self.playList.count, @"要删除的数组不能大于播放列表");
    if (deleteList.count == 0 || deleteList.count > self.playList.count ) return;
    
    NSMutableArray *needDeleteArray = [NSMutableArray array];
    [deleteList enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.playList enumerateObjectsUsingBlock:^(DGCacheMusicModel * _Nonnull innerObj, NSUInteger idx, BOOL * _Nonnull innerStop) {
            if ([obj isKindOfClass:[DGCacheMusicModel class]]) {
                DGCacheMusicModel *model = (DGCacheMusicModel *)obj;
                if ([model.musicId isEqualToString:innerObj.musicId]) {
                    [needDeleteArray addObject:innerObj];
                    *innerStop = YES;
                }
            }
        }];
    }];
    if (needDeleteArray.count == 0) return;
    if ([needDeleteArray containsObject:self.currentModel]) {
        [self.player pause];
        self.innerPlayState = DGCacheMusicStatePause;
        [self removeMyObserver];
        self.currentModel = nil;
    }
    [self.playList removeObjectsInArray:needDeleteArray];
}
/**
 添加一个新的歌单到播放列表
 
 @param addList 新的歌曲的数组
 */
- (void)addPlayList:(NSArray<DGCacheMusicModel *>*)addList{
    
}
/**
 快进或者快退
 
 @param time 要播放的那个时间点
 */
- (void)seekTime:(NSUInteger)time{
    
}

#pragma mark - 自己方法的实现
/**
 获取下一首歌曲的坐标model

 @return 下一首歌曲有的d坐标model
 */
-(DGCacheMusicModel *)getNextModel{
    
    if (self.currentModel == nil) self.currentModel = [self.playList firstObject];
    NSInteger currentIndex = [self.playList indexOfObject:self.currentModel];
    NSInteger nextIndex = currentIndex + 1;
    if (nextIndex > self.playList.count - 1) {
        nextIndex = 0;
    }
    DGCacheMusicModel *nextModel = self.playList[nextIndex];
    return nextModel;
}
/**
 获取上一首歌曲的model

 @return 获取上一首歌曲的model
 */
- (DGCacheMusicModel *)getPreviousModel{
    
    if (self.currentModel == nil) self.currentModel = [self.playList firstObject];
    NSInteger currentIndex = [self.playList indexOfObject:self.currentModel];
    NSInteger previousIndex = currentIndex - 1;
    if (previousIndex < 0) {
        previousIndex = self.playList.count - 1;
    }
    DGCacheMusicModel *previousModel = self.playList[previousIndex];
    return previousModel;
}
/**
 移除观察者
 */
- (void)removeMyObserver{
    if (self.playerItem) {
        [self.playerItem removeObserver:self forKeyPath:DGPlayerStatusKey];
        [self.playerItem removeObserver:self forKeyPath:DGPlayerLoadTimeKey];
        [self.playerItem removeObserver:self forKeyPath:DGPlayerBufferEmty];
        [self.playerItem removeObserver:self forKeyPath:DGPlayerLikelyToKeepUp];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    if (self.player) {
        [self.player removeObserver:self forKeyPath:DGPlayerRateKey];
    }
    if (self.playerObserver && self.player) {
        [self.playerObserver removeObserver:self];
        self.playerObserver = nil;
    }
    
}
/**
 添加我的观察者
 */
- (void)addMyObserver{
    
    // 添加在播放器开始播放后的通知
    if (self.playerItem) {
        [self.playerItem addObserver:self forKeyPath:DGPlayerStatusKey options:NSKeyValueObservingOptionNew context:nil];
        [self.playerItem addObserver:self forKeyPath:DGPlayerLoadTimeKey options:NSKeyValueObservingOptionNew context:nil];
        [self.playerItem addObserver:self forKeyPath:DGPlayerBufferEmty options:NSKeyValueObservingOptionNew context:nil];
        [self.playerItem addObserver:self forKeyPath:DGPlayerLikelyToKeepUp options:NSKeyValueObservingOptionNew context:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishAction:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    }
    if (self.player) {
        // 监听播放进度等等
      self.playerObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            
      }];
        // 播放速度
        [self.player addObserver:self forKeyPath:DGPlayerRateKey options:NSKeyValueObservingOptionNew context:nil];
    }
}
/**
 播放完成

 @param info 信息
 */
- (void)didFinishAction:(NSNotification *)info{
    
    [self playNextSong:NO];
}


@end
