//
//  AudioPlayerViewController.m
//  AudioPlayer
//
//  Created by hexuan on 16/10/29.
//  Copyright © 2016年 hexuan. All rights reserved.
//

#import "AudioPlayerViewController.h"
#import "SongManager.h"
#import "SongInfo.h"
#import "UIView+Frame.h"
#import "UIButton+Public.h"
#import "CFunction.h"
#import "const.h"
#import <MJRefresh/MJRefresh.h>
#import <FreeStreamer/FSAudioStream.h>

@interface AudioPlayerViewController ()<UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate>

@end

@implementation AudioPlayerViewController {
    SongManager *songManager;
    UITableView *songListView;
    FSAudioStream *audioSream;
    UIButton *playBtn;
    CADisplayLink *displayLink;
    UILabel *currentTimeLable;
    UISlider *positionSlider;
    UILabel *totalTimeLable;
}

- (instancetype)init {
    if (self = [super init]) {
        songManager = [[SongManager alloc] init];
        FSStreamConfiguration *configure = [[FSStreamConfiguration alloc] init];
        configure.requireStrictContentTypeChecking = NO;
        audioSream = [[FSAudioStream alloc] initWithConfiguration:configure];
        
        displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateTimeControl)];
        displayLink.frameInterval = 10;
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        displayLink.paused = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, kAppStatusBarHeight, self.view.width, 60)];
    searchBar.delegate = self;
    [self.view addSubview:searchBar];
    
    UIView *bottomToolBg = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.height - 80, self.view.width, 80)];
    bottomToolBg.backgroundColor = [UIColor grayColor];
    [self.view addSubview:bottomToolBg];
    
    songListView = [[UITableView alloc] initWithFrame:CGRectMake(0, searchBar.bottomY, self.view.width, self.view.height - searchBar.bottomY - bottomToolBg.height) style:UITableViewStylePlain];
    songListView.delegate = self;
    songListView.dataSource = self;
    songListView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
            [songManager loadMoreWithComplete:^(BOOL success){
                runInMainThread(^{
                    if (success) {
                        [songListView reloadData];
                    }
                    [songListView.mj_footer endRefreshing];
                    if (![songManager hasMore]) {
                        songListView.mj_footer.hidden = YES;
                    }
                });
            }];
    }];
    songListView.mj_footer.hidden = YES;
    [self.view addSubview:songListView];
    
    playBtn = [UIButton buttonWithBgImgName:@"play"
                                               target:self
                                           upInAction:@selector(playAction)
                                            superView:bottomToolBg];
    playBtn.frame = CGRectMake(10, 10, 60, 60);
    
    
    currentTimeLable = [self timeLable];
    currentTimeLable.x = playBtn.rightX;
    [bottomToolBg addSubview:currentTimeLable];
    
    positionSlider = [[UISlider alloc] initWithFrame:CGRectMake(currentTimeLable.rightX, 0, 400, 80)];
    [positionSlider addTarget:self action:@selector(positionSliderTouchStart:) forControlEvents:UIControlEventTouchDown];
    [positionSlider addTarget:self action:@selector(positionSliderValueChange:) forControlEvents:UIControlEventValueChanged];
    [positionSlider addTarget:self action:@selector(positionSliderTouchEnd:) forControlEvents:UIControlEventTouchUpInside];
    [bottomToolBg addSubview:positionSlider];
    
    totalTimeLable = [self timeLable];
    totalTimeLable.x = positionSlider.rightX;
    [bottomToolBg addSubview:totalTimeLable];
    
    UIButton *lastSongBtn = [UIButton buttonWithBgImgName:@"last_song" target:self
                                               upInAction:@selector(lastSongAction)
                                                superView:bottomToolBg];
    lastSongBtn.frame = CGRectMake(totalTimeLable.rightX, 10, 60, 60);
    
    UIButton *nextSongBtn = [UIButton buttonWithBgImgName:@"next_song" target:self
                                               upInAction:@selector(nextSongAction)
                                                superView:bottomToolBg];
    nextSongBtn.frame = CGRectMake(lastSongBtn.rightX + 8, 10, 60, 60);
    
    UIImageView *volumeImg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"volume"]];
    volumeImg.frame = CGRectMake(nextSongBtn.rightX + 15, 20, 40, 40);
    [bottomToolBg addSubview:volumeImg];
    
    UISlider *volumeSlider = [[UISlider alloc] initWithFrame:CGRectMake(volumeImg.rightX + 20, 0, 150, 80)];
    volumeSlider.value = audioSream.volume;
    [volumeSlider addTarget:self action:@selector(changeVolumeAction:) forControlEvents:UIControlEventValueChanged];
    [bottomToolBg addSubview:volumeSlider];

    
    __block UIButton *bPlayBtn = playBtn;
    __block CADisplayLink *bDisplayLink = displayLink;
    audioSream.onStateChange = ^(FSAudioStreamState state){
        if (state == kFsAudioStreamPlaying) {
            runInMainThread(^{
                [bPlayBtn setBackgroundImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
                bDisplayLink.paused = NO;
            });
        }
        else {
            runInMainThread(^{
                [bPlayBtn setBackgroundImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
                bDisplayLink.paused = YES;
            });
        }
    };
    // Do any additional setup after loading the view.
}

- (void)updateTimeControl {
    currentTimeLable.text = [NSString stringWithFormat:@"%02d:%02d", audioSream.currentTimePlayed.minute , audioSream.currentTimePlayed.second];
    positionSlider.value = audioSream.currentTimePlayed.position;
        totalTimeLable.text = [NSString stringWithFormat:@"%02d:%02d", audioSream.duration.minute , audioSream.duration.second];
}

- (UILabel *)timeLable {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 30, 80, 20)];
    label.font = [UIFont systemFontOfSize:18];
    label.text = @"00:00";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    return label;
}

- (void)positionSliderValueChange:(UISlider *)sender {
    int currentTime = (audioSream.duration.minute * 60 + audioSream.duration.second) * sender.value;
    currentTimeLable.text = [NSString stringWithFormat:@"%02d:%02d", currentTime / 60, currentTime%60];
}

- (void)positionSliderTouchStart:(UISlider *)sender {
    displayLink.paused = YES;
}

- (void)positionSliderTouchEnd:(UISlider *)sender {
    displayLink.paused = NO;
    FSStreamPosition streamPostion;
    streamPostion.position = sender.value;
    [audioSream seekToPosition:streamPostion];
}

- (void)changeVolumeAction:(UISlider *)sender {
    audioSream.volume = sender.value;
}

- (void)lastSongAction {
    [songManager getSwitchSongUrlWithSwitchType:SMSwitchSongType_Last complete:^(BOOL success, NSString *url) {
        if (success) {
            [audioSream stop];
            [audioSream playFromURL:[NSURL URLWithString:url]];
        }
    }];
}

- (void)nextSongAction {
    [songManager getSwitchSongUrlWithSwitchType:SMSwitchSongType_next complete:^(BOOL success, NSString *url) {
        if (success) {
            [audioSream stop];
            [audioSream playFromURL:[NSURL URLWithString:url]];
        }
    }];
}

- (void)playAction {
    [audioSream pause];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [songManager.songList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *idenfier = @"song cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:idenfier];
    if (cell == 0) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:idenfier];
    }
    SongInfo *songInfo = songManager.songList[indexPath.row];
    cell.textLabel.text = [songInfo.songName stringByAppendingFormat:@"  %@", songInfo.singer];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [songManager getSongUrlWithIndex:(int)indexPath.row complete:^(BOOL success,NSString *url) {
        if (success) {
            [audioSream stop];
            [audioSream playFromURL:[NSURL URLWithString:url]];
        }
    }];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar endEditing:YES];
    [songManager getFirstPageWithKeyword:searchBar.text complete:^(BOOL success){
        runInMainThread(^{
            if ([songManager hasMore]) {
                songListView.mj_footer.hidden = NO;
            }
            if (success) {
                [songListView reloadData];
            }
        });
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
