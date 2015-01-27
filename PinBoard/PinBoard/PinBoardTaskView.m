//
//  EssentialsArrangeTaskView.m
//  ShinobiPlay
//
//  Created by Thomas Kelly on 08/01/2013.
//  Copyright (c) 2013 Scott Logic. All rights reserved.
//

#import "PinBoardTaskView.h"
#import "ShinobiPlayUtils/UIFont+SPUFont.h"
#import "ShinobiPlayUtils/UIColor+SPUColor.h"

@interface PinBoardTaskView ()

@property (strong, nonatomic) UILabel *timeNumberLabel;
@property (strong, nonatomic) UILabel *timeUnitsLabel;
@property (strong, nonatomic) UILabel *numberLabel;
@property (strong, nonatomic) UILabel *taskNameLabel;

@end

@implementation PinBoardTaskView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.layer.borderWidth = 2;
    CGFloat padding = 2;
    CGFloat innerHeight = frame.size.height - 2 * padding;
    
    // Add a square label to display the task number, on the left taking up the full height
    self.numberLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding,
                                                                 padding,
                                                                 innerHeight,
                                                                 innerHeight)];
    self.numberLabel.font = [UIFont shinobiFontOfSize:20];
    self.numberLabel.textColor = [UIColor shinobiDarkGrayColor];
    self.numberLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.numberLabel];
    
    // Add a label to display the task time number, on the right, leaving a gap beneath
    // for the task time units
    self.timeNumberLabel = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width - innerHeight - padding,
                                                                     padding,
                                                                     innerHeight,
                                                                     innerHeight - 10 - padding)];
    self.timeNumberLabel.font = [UIFont shinobiFontOfSize:26];
    self.timeNumberLabel.textColor = [UIColor shinobiDarkGrayColor];
    self.timeNumberLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.timeNumberLabel];
    
    // Add a label for the units beneath the task time
    self.timeUnitsLabel = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width - innerHeight - padding,
                                                                    innerHeight - 10 - padding,
                                                                    innerHeight,
                                                                    10)];
    self.timeUnitsLabel.font = [UIFont shinobiFontOfSize:14];
    self.timeUnitsLabel.textColor = [UIColor shinobiDarkGrayColor];
    self.timeUnitsLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.timeUnitsLabel];
    
    // Add the label for the task name, in the middle of the view
    self.taskNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(innerHeight + 2 * padding,
                                                                   padding,
                                                                   frame.size.width - 2 * innerHeight - 4 * padding,
                                                                   innerHeight)];
    self.taskNameLabel.font = [UIFont shinobiFontOfSize:11];
    self.taskNameLabel.textColor = [UIColor shinobiDarkGrayColor];
    self.taskNameLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.taskNameLabel.numberOfLines = 0;
    [self addSubview:self.taskNameLabel];
  }
  return self;
}

- (void)setTaskNumber:(NSInteger)taskNumber {
  _taskNumber = taskNumber;
  self.numberLabel.text = [NSString stringWithFormat:@"#%li", (long)taskNumber];
}

- (void)setTaskName:(NSString *)taskName {
  _taskName = taskName;
  self.taskNameLabel.text = taskName;
}

- (void)setTaskMins:(NSInteger)taskMins {
  _taskMins = taskMins;
  if (taskMins >= 60) {
    self.timeNumberLabel.text = [NSString stringWithFormat:@"%.f", taskMins / 60.f];
    self.timeUnitsLabel.text = @"hours";
  } else {
    self.timeNumberLabel.text = [NSString stringWithFormat:@"%li", (long)taskMins];
    self.timeUnitsLabel.text = @"mins";
  }
}

- (void)setTaskColor:(NSString *)taskColor {
  _taskColor = taskColor;
  NSString *lowerCaseColor = [taskColor lowercaseString];
  UIColor *color = [UIColor shinobiDarkGrayColor];
  
  if ([lowerCaseColor isEqualToString:@"red"]) {
    color = [UIColor shinobiPlayRedColor];
  } else if ([lowerCaseColor isEqualToString:@"orange"]) {
    color = [UIColor shinobiPlayOrangeColor];
  } else if ([lowerCaseColor isEqualToString:@"blue"]) {
    color = [UIColor shinobiPlayBlueColor];
  } else if ([lowerCaseColor isEqualToString:@"green"]) {
    color = [UIColor shinobiPlayGreenColor];
  }
  
  self.layer.borderColor = color.CGColor;
  self.backgroundColor = [color shinobiBackgroundColor];
}

@end
