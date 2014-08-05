//
//  PinBoardColumn.m
//  ShinobiPlay
//
//  Created by Thomas Kelly on 03/01/2013.
//  Copyright (c) 2013 Scott Logic. All rights reserved.
//

#import "PinBoardColumn.h"
#import "PinBoardTaskView.h"
#import <ShinobiEssentials/ShinobiEssentials.h>

@interface PinBoardColumn()

@property (strong, nonatomic) UIImage *corkBG;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *flowTotalLabel;

@end

@implementation PinBoardColumn

- (id)initWithFrame:(CGRect)frame andTitle:(NSString*) title {
  // Create a wrapper and style for the flow layout, which we'll use when we instantiate super
  SEssentialsFlowLayoutImagesWrapper *wrapper = [SEssentialsFlowLayoutImagesWrapper new];
  wrapper.trashcanImage = [UIImage imageNamed:@"bin"];
  wrapper.trashcanMask = [UIImage imageNamed:@"bin"];
  SEssentialsFlowLayoutStyle *style = [[SEssentialsFlowLayoutStyle alloc]
                                       initWithTheme:[ShinobiEssentials theme]
                                       customImages:wrapper];
  
  self = [super initWithFrame:frame
              withDeleteIdiom:SEssentialsFlowDeleteIdiomTrashCan
                        style:style];
  
  if (self) {
    // Tweaks to flow layout so it behaves as we want
    self.instantUpdate = YES;
    self.dragsOutsideBounds = YES;
    self.clipsToBounds = NO;
    self.verticalSubviewSpacing = -5.f;
    self.verticalPadding = 50;
    self.clipsToBounds = NO;
    self.animationType = SEssentialsAnimationUser;
    //self.flowDelegate = self;
    self.style.mainViewTintColor = [UIColor clearColor];
    
    // Add background image
    self.corkBG = [UIImage imageNamed:@"cork_left"];
    self.style.mainViewTexture = [UIColor colorWithPatternImage:self.corkBG];
    
    // Create the total at the bottom
    self.flowTotalLabel = [UILabel new];
    self.flowTotalLabel.textAlignment = NSTextAlignmentCenter;
    self.flowTotalLabel.font = [UIFont fontWithName:@"AmericanTypewriter-Bold" size:30.f];
    self.flowTotalLabel.textColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.95];
    [self.flowTotalLabel setBackgroundColor: [UIColor clearColor]];
    [self addSubview:self.flowTotalLabel];
    [self updateFlowTotals];
    
    // Create the title at the top
    self.titleLabel = [UILabel new];
    self.titleLabel.text = title;
    self.titleLabel.font = [UIFont fontWithName:@"AmericanTypewriter-Bold" size:30.f];
    self.titleLabel.textColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.95];
    [self.titleLabel setBackgroundColor:[UIColor clearColor]];
    [self.titleLabel sizeToFit];
    self.titleLabel.center = CGPointMake(self.bounds.size.width/2, 20);
    [self addSubview:self.titleLabel];
  }
  return self;
}

-(void) layoutSubviews {
  [super layoutSubviews];
  
  // Make sure the content view fills the frame to avoid scrolling effects (as we're a
  // subclass of UIScrollView)
  if (self.contentSize.height < self.frame.size.height) {
    self.contentSize = CGSizeMake(self.contentSize.width, self.frame.size.height);
  }
}

-(void) updateFlowTotals {
  float total = 0.f;
  
  for (PinBoardTaskView *task in self.managedViews) {
    if ([task respondsToSelector:@selector(taskMins)]) {
      total += task.taskMins / 60.f;
    }
  }
  
  self.flowTotalLabel.text = [NSString stringWithFormat:@"%.2f HOURS", total];
  [self.flowTotalLabel sizeToFit];
  self.flowTotalLabel.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height - 20);
}

- (void)setManager:(id<SEssentialsFlowLayoutDelegate>)manager {
  _manager = manager;
  self.flowDelegate = manager;
}

#pragma mark Sorting

-(void)sortByTask:(BOOL)descending {
  NSArray *reordered = [self.managedViews sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    PinBoardTaskView *view1 = (PinBoardTaskView*)obj1;
    PinBoardTaskView *view2 = (PinBoardTaskView*)obj2;
    
    int taskNum1 = view1.taskNumber;
    int taskNum2 = view2.taskNumber;
    
    return (descending) ? taskNum2 - taskNum1 : taskNum1 - taskNum2;
  }];
  
  [self reorderManagedSubviews:reordered animated:YES];
}

-(void)sortByTime:(BOOL)descending {
  NSArray *reordered = [self.managedViews sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    PinBoardTaskView *view1 = (PinBoardTaskView*)obj1;
    PinBoardTaskView *view2 = (PinBoardTaskView*)obj2;
    
    float taskNum1 = view1.taskMins;
    float taskNum2 = view2.taskMins;
    
    return (descending) ? taskNum2 - taskNum1 : taskNum1 - taskNum2;
  }];
  
  [self reorderManagedSubviews:reordered animated:YES];}

-(void)sortByType:(BOOL)descending {
  NSArray *reordered = [self.managedViews sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    PinBoardTaskView *view1 = (PinBoardTaskView*)obj1;
    PinBoardTaskView *view2 = (PinBoardTaskView*)obj2;
    
    NSComparisonResult result = [view1.taskColor compare:view2.taskColor];
    return (descending) ? -result : result;
  }];
  
  [self reorderManagedSubviews:reordered animated:YES];}

#pragma mark Flow Layout methods

-(void)addManagedSubview:(UIView *)subview {
  [super addManagedSubview:subview];
  [self updateFlowTotals];
}

#pragma mark Delegate methods
// These methods mostly just pass calls on to the manager to cope with switching views
// between flow layouts

/*-(BOOL)flowLayout:(SEssentialsFlowLayout *)flow shouldMoveView:(UIView *)view {
  return [self.manager flowLayout:flow shouldMoveView:view];
}

-(void)flowLayout:(SEssentialsFlowLayout *)flow didDragView:(UIView *)view {
  [self.manager flowLayout:flow didDragView:view];
}

-(void)didBeginEditInFlowLayout:(SEssentialsFlowLayout *)flow {
  [self.manager didBeginEditInFlowLayout:flow];
}

-(void)didEndEditInFlowLayout:(SEssentialsFlowLayout *)flow {
  [self.manager didEndEditInFlowLayout:flow];
}

-(void)flowLayout:(SEssentialsFlowLayout *)flow didRemoveView:(UIView *)view {
  [self updateFlowTotals];
  [self.manager flowLayout:flow didRemoveView:view];
}

-(CGPoint)editButtonPositionInFlowLayout:(SEssentialsFlowLayout *)flow {
  CGPoint destination = ((PinBoardViewController*)self.manager).binImage.center;
  return [((PinBoardViewController*)self.manager).view convertPoint:destination toView:self];
}*/

@end
