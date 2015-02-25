//
//  PinBoardViewController.m
//  PinBoard
//
//  Created by Alison Clarke on 21/07/2014.
//
//  Copyright 2014 Scott Logic
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "PinBoardViewController.h"
#import "PinBoardColumn.h"
#import "PinBoardTaskView.h"
#import "ShinobiPlayUtils/UIFont+SPUFont.h"
#import "ShinobiPlayUtils/UIColor+SPUColor.h"

typedef NS_ENUM(NSInteger, PinBoardSortFunc) {
  SORT_TASK = 0,
  SORT_TIME,
  SORT_TYPE
};

@interface PinBoardViewController ()

@property (strong, nonatomic) NSMutableArray *flowLayouts;
@property (strong, nonatomic) NSMutableArray *tasksByColumn;
@property (strong, nonatomic) UILongPressGestureRecognizer *gestureInProgress;
@property (assign, nonatomic) BOOL descending;
@property (assign, nonatomic) PinBoardSortFunc selectedSort;
@property (assign, nonatomic) BOOL initialLoad;

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIView *placeholder;
@property (weak, nonatomic) IBOutlet UILabel *sortByLabel;
@property (weak, nonatomic) IBOutlet UILabel *viewTitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *binImageView;
@property (strong, nonatomic) IBOutletCollection(UIControl) NSArray *allControls;
@property (strong, nonatomic) IBOutlet UISegmentedControl *sortOrderControl;

- (IBAction)sortAscending:(id)sender;
- (IBAction)sortDescending:(id)sender;
- (IBAction)reset;
- (IBAction)sortControlChanged:(id)sender;

@end


@implementation PinBoardViewController

#pragma mark Default configuration

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Style the segmented control
  NSDictionary *attributes = @{ NSFontAttributeName : [UIFont boldShinobiFontOfSize:15],
                                NSForegroundColorAttributeName : [UIColor shinobiDarkGrayColor] };
  [self.sortOrderControl setTitleTextAttributes:attributes forState:UIControlStateNormal];
  NSDictionary *highlightedAttributes = @{ NSForegroundColorAttributeName : [UIColor whiteColor]};
  [self.sortOrderControl setTitleTextAttributes:highlightedAttributes forState:UIControlStateHighlighted];
  
  // Set its frame and rotate it so we've got a vertical version
  self.sortOrderControl.frame = CGRectMake(-15, 44, 120, 90);
  self.sortOrderControl.transform = CGAffineTransformMakeRotation(M_PI / 2.0);
}

- (void)viewDidAppear:(BOOL)animated {
  // Rotate the labels within the segmented control in the opposite direction to the way we
  // rotated the control itself, so they're the right way round again
  for (UIView *segment in [self.sortOrderControl subviews]) {
    for (UIView *subview in [segment subviews]) {
      if ([subview isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel*) subview;
        label.transform = CGAffineTransformMakeRotation(-M_PI / 2.0);
      }
    }
  }
  
  // Make the control appear now it's properly rotated
  self.sortOrderControl.alpha = 1;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  if (!self.flowLayouts) {
    self.initialLoad = YES;
    [self createFlows];
    self.initialLoad = NO;
  }
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  
  // Tear down the flow layouts to save on memory, after saving the current position of
  // the items
  for (int i = 0; i < self.flowLayouts.count; i++) {
    PinBoardColumn *flow = self.flowLayouts[i];
    self.tasksByColumn[i] = [NSMutableArray new];
    
    for (PinBoardTaskView *view in [flow.managedViews copy]) {
      // Save the task data against the relevant column
      [self.tasksByColumn[i] addObject:@{ @"Number" : @(view.taskNumber),
                                          @"Name" : view.taskName,
                                          @"Color" : view.taskColor,
                                          @"Minutes" : @(view.taskMins) }];
      
      // Remove the view from the flow layout
      [flow removeManagedSubview:view animated:NO];
    }
                         
    [flow removeFromSuperview];
  }
  self.flowLayouts = nil;
}


#pragma mark Multiflow-specific functions

- (void)createFlows {
  if (!self.flowLayouts) {
    self.flowLayouts = [NSMutableArray new];
    
    float borderWidth = 2.f;
    CGSize flowSize = CGSizeMake(floorf((self.placeholder.frame.size.width - borderWidth*2)/3.f),
                                 self.placeholder.frame.size.height);
    
    PinBoardColumn *column1 = [[PinBoardColumn alloc] initWithFrame:CGRectMake(0,
                                                                               0,
                                                                               flowSize.width,
                                                                               flowSize.height)
                                                           andTitle:@"To Do"];
    [self configureFlow:column1];
    
    PinBoardColumn *column2 = [[PinBoardColumn alloc] initWithFrame:CGRectMake(borderWidth+flowSize.width,
                                                                               0,
                                                                               flowSize.width,
                                                                               flowSize.height)
                                                           andTitle:@"In Progress"];
    [self configureFlow:column2];
    
    PinBoardColumn *column3 = [[PinBoardColumn alloc] initWithFrame:CGRectMake((borderWidth+flowSize.width)*2,
                                                                               0,
                                                                               flowSize.width,
                                                                               flowSize.height)
                                                           andTitle:@"Done"];
    [self configureFlow:column3];
    
    [column1 beginEditMode];
    [self createTasks];
  }
}

- (void)createTasks {
  if (!self.tasksByColumn) {
    // Get task data from property list
    NSString* path = [[NSBundle mainBundle] pathForResource:@"PinBoardTasks" ofType:@"plist"];
    NSArray* tasks = [NSArray arrayWithContentsOfFile:path];
    
    // Put all tasks in first column ("TODO")
    self.tasksByColumn = [[NSMutableArray alloc] initWithCapacity:3];
    self.tasksByColumn[0] = tasks;
  }
  
  for (int i = 0; i < [self.tasksByColumn count]; i++) {
    NSArray *tasks = self.tasksByColumn[i];
    if (tasks) {
      for (int j = 0; j < [tasks count]; j++) {
        NSDictionary* task = tasks[j];
        PinBoardTaskView *view = [[PinBoardTaskView alloc] initWithFrame:CGRectMake(0, 0, 248, 45)];
        view.taskNumber = task[@"Number"] ? [task[@"Number"] integerValue] : j+1;
        view.taskName = task[@"Name"];
        view.taskColor = task[@"Color"];
        view.taskMins = [task[@"Minutes"] longValue];
        view.clipsToBounds = NO;
        
        // Add to the relevant column
        [self.flowLayouts[i] addManagedSubview:view];
      }
    }
  }
  
  self.descending = NO;
}

- (void)configureFlow:(PinBoardColumn*)flow {
  [self.flowLayouts addObject:flow];
  flow.manager = self;
  [self.placeholder addSubview:flow];
}

#pragma mark - Delegate methods

- (void)didBeginEditInFlowLayout:(SEssentialsFlowLayout *)flow {
  // Put all columns in edit mode
  for (PinBoardColumn *column in self.flowLayouts) {
    [column beginEditMode];
  }
  // Bring this subview to the front
  [self setButtonsActive:NO];
  [self.placeholder bringSubviewToFront:flow];
}

- (void)didEndEditInFlowLayout:(SEssentialsFlowLayout *)flow {
  [self setButtonsActive:YES];
  
  // Take all columns out of edit mode
  for (PinBoardColumn *column in self.flowLayouts) {
    [column endEditMode];
  }
}

- (void)flowLayout:(SEssentialsFlowLayout *)flow didRemoveView:(UIView *)view {
  if ([flow respondsToSelector:@selector(updateFlowTotals)]) {
    [(PinBoardColumn*)flow updateFlowTotals];
  }
  self.gestureInProgress = nil;
}

- (BOOL)flowLayout:(SEssentialsFlowLayout *)flow shouldMoveView:(UIView *)view {
  // Work out if the gesture is within the bounds.
  // NB: DON'T use the dragPosition, as the view gets stuck after it leaves, but the gesture doesn't.
  UILongPressGestureRecognizer *currentGesture = view.gestureRecognizers[0];
  CGPoint touchPoint = [currentGesture locationInView:self.placeholder];
  BOOL insideBounds = CGRectContainsPoint(self.view.bounds, touchPoint);
  
  // Check that no other task views are being moved
  BOOL anotherViewInProgress = NO;
  if (self.gestureInProgress) {
    for (PinBoardColumn *column in self.flowLayouts) {
      for (UIView *taskView in column.managedViews) {
        if (view != taskView && view != self.gestureInProgress.view) {
          // For any other views (ignoring the view passed in), if we have another view
          // already in progress, we should not allow any other gestures.
          for (UIGestureRecognizer *gesture in taskView.gestureRecognizers) {
            // UIGestureRecognizerStatePossible is the "idle" state
            if (gesture.state != UIGestureRecognizerStatePossible && [gesture numberOfTouches] > 0) {
              anotherViewInProgress = YES;
            }
          }
        }
      }
    }
  }
  
  if (!anotherViewInProgress) {
    self.gestureInProgress = currentGesture;
  }
  
  return insideBounds && !anotherViewInProgress;
}

- (void)flowLayout:(PinBoardColumn *)flow didDragView:(UIView *)view {
  // Get the current position of the dragged view relative to our placeholder
  CGPoint dragPosition = [view.superview convertPoint:view.center toView:self.placeholder];
  
  // Work out which column the new position is in (if any)
  for (PinBoardColumn *column in self.flowLayouts) {
    if(CGRectContainsPoint(column.frame, dragPosition)) {
      if (column != flow) {
        // Calculate new frame for task, relative to the new column
        view.frame = [column convertRect:view.frame fromView:flow];
        // Add the task to the new column before removing it from the old, to make sure
        // the view isn't de-alloced in between
        [column addManagedSubview:view];
        [flow unmanageSubview:view];
        
        // Update the flow totals
        [flow updateFlowTotals];
        [column updateFlowTotals];
        
        // Make sure the new column is in edit mode
        [column beginEditMode];
      }
    }
  }
}

- (CGPoint)editButtonPositionInFlowLayout:(SEssentialsFlowLayout *)flow {
  CGPoint destination = CGPointMake(self.containerView.frame.origin.x + self.binImageView.center.x,
                                    self.containerView.frame.origin.y + self.binImageView.center.y);
  return [self.view convertPoint:destination toView:flow];
}

// Implement a custom animation, so we can avoid animating on the initial load
- (void)flowLayout:(SEssentialsFlowLayout *)flow animateView:(UIView *)view toTarget:(CGPoint)target {
  if (self.initialLoad) {
    view.center = target;
  } else {
    [UIView animateWithDuration:flow.movementAnimationDuration animations:^{
      view.center = target;
    }];
  }
}

- (void)setButtonsActive:(BOOL)active {
  for (UIControl *control in self.allControls) {
    control.userInteractionEnabled = active;
    control.alpha = active ? 1.f : 0.7f;
  }
}

#pragma mark Sorting functions

- (IBAction)sortAscending:(id)sender {
  self.descending = NO;
  [self doSort];
}

- (IBAction)sortDescending:(id)sender {
  self.descending = YES;
  [self doSort];
}
- (IBAction)sortControlChanged:(id)sender {
  PinBoardSortFunc sortFunc = self.sortOrderControl.selectedSegmentIndex;
  
  // Reverse the sort order if already sorted by this function
  if (self.selectedSort == sortFunc) {
    self.descending = !self.descending;
  } else {
    self.selectedSort = sortFunc;
  }
  
  [self doSort];
}

- (IBAction)doSort {
  for (PinBoardColumn *flow in self.flowLayouts) {
    switch (self.selectedSort) {
      case SORT_TASK:
        [flow sortByTask:self.descending];
        break;
      case SORT_TIME:
        [flow sortByTime:self.descending];
        break;
      case SORT_TYPE:
        [flow sortByType:self.descending];
        break;
    }
  }
}

// Wind back to factory settings
- (IBAction)reset {
  for (PinBoardColumn *flow in self.flowLayouts) {
    for (UIView *view in [flow.managedViews copy]) {
      [flow removeManagedSubview:view animated:NO];
    }
  }
  
  self.selectedSort = 0;
  self.tasksByColumn = nil;
  [self createTasks];
}

@end
