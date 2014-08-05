//
//  EssentialsArrangeTaskView.h
//  ShinobiPlay
//
//  Created by Thomas Kelly on 08/01/2013.
//  Copyright (c) 2013 Scott Logic. All rights reserved.
//

@import UIKit;

@interface PinBoardTaskView : UIImageView

@property (nonatomic, assign) NSInteger taskNumber;
@property (nonatomic, strong) NSString *taskColor;
@property (nonatomic, assign) CGFloat taskMins;

@end
