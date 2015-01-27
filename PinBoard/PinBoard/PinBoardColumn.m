//
//  PinBoardColumn.m
//  ShinobiPlay
//
//  Created by Thomas Kelly on 03/01/2013.
//  Copyright (c) 2013 Scott Logic. All rights reserved.
//

#import "PinBoardColumn.h"
#import "PinBoardTaskView.h"
#import "ShinobiPlayUtils/UIColor+SPUColor.h"
#import "ShinobiPlayUtils/UIFont+SPUFont.h"

@interface PinBoardColumn()

@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *flowTotalLabel;

@end

@implementation PinBoardColumn

- (instancetype)initWithFrame:(CGRect)frame andTitle:(NSString*) title {
  // Create a wrapper and style for the flow layout, which we'll use when we instantiate super
  SEssentialsFlowLayoutImagesWrapper *wrapper = [SEssentialsFlowLayoutImagesWrapper new];
  wrapper.trashcanMask = [UIImage imageNamed:@"bin"];
  SEssentialsFlowLayoutStyle *style = [[SEssentialsFlowLayoutStyle alloc]
                                       initWithTheme:[ShinobiEssentials theme]
                                       customImages:wrapper];
  style.trashcanTintColor = [UIColor shinobiDarkGrayColor];
  
  self = [super initWithFrame:frame
              withDeleteIdiom:SEssentialsFlowDeleteIdiomTrashCan
                        style:style];
  
  if (self) {
    // Tweaks to flow layout so it behaves as we want
    self.instantUpdate = YES;
    self.dragsOutsideBounds = YES;
    self.clipsToBounds = NO;
    self.verticalSubviewSpacing = 4.f;
    self.verticalPadding = 50;
    self.clipsToBounds = NO;
    self.animationType = SEssentialsAnimationUser;
    self.horizontalPadding = 10.f;
    self.style.mainViewTintColor = [UIColor clearColor];
    self.movementAnimationDuration = 0.1;
    
    // Create the total at the bottom
    self.flowTotalLabel = [UILabel new];
    self.flowTotalLabel.textAlignment = NSTextAlignmentCenter;
    self.flowTotalLabel.font = [UIFont lightShinobiFontOfSize:20.f];
    self.flowTotalLabel.textColor = [UIColor shinobiDarkGrayColor];
    self.flowTotalLabel.backgroundColor = [UIColor clearColor];
    [self addSubview:self.flowTotalLabel];
    [self updateFlowTotals];
    
    // Create the title at the top
    self.titleLabel = [UILabel new];
    self.titleLabel.text = title;
    self.titleLabel.font = [UIFont lightShinobiFontOfSize:24.f];
    self.titleLabel.textColor = [UIColor shinobiDarkGrayColor];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    [self.titleLabel sizeToFit];
    self.titleLabel.center = CGPointMake(self.bounds.size.width/2, 28);
    [self addSubview:self.titleLabel];
    
    // Add a subview with a border (this avoids issues with floating tasks beneath the border)
    UIView *borderView = [[UIView alloc] initWithFrame:self.bounds];
    borderView.layer.borderColor = [UIColor shinobiDarkGrayColor].CGColor;
    borderView.layer.borderWidth = 1;
    borderView.layer.cornerRadius = 4;
    [self addSubview:borderView];
    [self sendSubviewToBack:borderView];
  }
  
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
  // Make sure the content view fills the frame to avoid scrolling effects (as we're a
  // subclass of UIScrollView)
  if (self.contentSize.height < self.frame.size.height) {
    self.contentSize = CGSizeMake(self.contentSize.width, self.frame.size.height);
  }
}

- (void)updateFlowTotals {
  float total = 0.f;
  
  for (PinBoardTaskView *task in self.managedViews) {
    if ([task respondsToSelector:@selector(taskMins)]) {
      total += task.taskMins / 60.f;
    }
  }
  
  self.flowTotalLabel.text = [NSString stringWithFormat:@"%.2f hours", total];
  [self.flowTotalLabel sizeToFit];
  self.flowTotalLabel.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height - 23);
}

- (void)setManager:(id<SEssentialsFlowLayoutDelegate>)manager {
  _manager = manager;
  self.flowDelegate = manager;
}

#pragma mark Sorting

- (void)sortByTask:(BOOL)descending {
  NSArray *reordered = [self.managedViews sortedArrayUsingComparator:^NSComparisonResult(PinBoardTaskView *view1, PinBoardTaskView *view2) {
    return (descending ? -1 : 1) * (view1.taskNumber - view2.taskNumber);
  }];
  
  [self reorderManagedSubviews:reordered animated:YES];
}

- (void)sortByTime:(BOOL)descending {
  NSArray *reordered = [self.managedViews sortedArrayUsingComparator:^NSComparisonResult(PinBoardTaskView *view1, PinBoardTaskView *view2) {
    return (descending ? -1 : 1) * (view1.taskMins - view2.taskMins);
  }];
  
  [self reorderManagedSubviews:reordered animated:YES];
}

- (void)sortByType:(BOOL)descending {
  NSArray *reordered = [self.managedViews sortedArrayUsingComparator:^NSComparisonResult(PinBoardTaskView *view1, PinBoardTaskView *view2) {
    return (descending ? -1 : 1) * [view1.taskColor compare:view2.taskColor];
  }];
  
  [self reorderManagedSubviews:reordered animated:YES];
}

#pragma mark Flow Layout methods

- (void)addManagedSubview:(UIView *)subview {
  [super addManagedSubview:subview];
  [self updateFlowTotals];
}

@end
