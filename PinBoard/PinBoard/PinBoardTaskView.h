//
//  EssentialsArrangeTaskView.h
//  ShinobiPlay
//
//  Created by Thomas Kelly on 08/01/2013.
//  Copyright (c) 2013 Scott Logic. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PinBoardTaskView : UIImageView

@property (nonatomic, assign) int taskNumber;
@property (nonatomic, strong) NSString *taskColor;
@property (nonatomic, assign) float taskMins;

@end
