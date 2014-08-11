//
//  PinBoardViewController.m
//  PinBoard
//
//  Created by Alison Clarke on 21/07/2014.
//  Copyright (c) 2014 Alison Clarke. All rights reserved.
//

#import "PinBoardViewController.h"
#import "PinBoardColumn.h"
#import "PinBoardTaskView.h"

typedef NS_ENUM(NSInteger, PinBoardSortFunc) {
  SORT_TASK = 1,
  SORT_TYPE,
  SORT_TIME
};

@interface PinBoardViewController ()

@property (strong, nonatomic) NSMutableArray *flowLayouts;
@property (strong, nonatomic) UILongPressGestureRecognizer *gestureInProgress;
@property (assign, nonatomic) BOOL descending;
@property (assign, nonatomic) PinBoardSortFunc selectedSort;
@property (assign, nonatomic) BOOL initialLoad;

@property (weak, nonatomic) IBOutlet UIView *placeholder;
@property (weak, nonatomic) IBOutlet UILabel *startOverLabel;
@property (weak, nonatomic) IBOutlet UILabel *sortByLabel;
@property (weak, nonatomic) IBOutlet UILabel *viewTitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *taskSortButton;
@property (weak, nonatomic) IBOutlet UIButton *timeSortButton;
@property (weak, nonatomic) IBOutlet UIButton *typeSortButton;
@property (weak, nonatomic) IBOutlet UIImageView *binImageView;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *allButtons;

- (IBAction)sortAscending:(id)sender;
- (IBAction)sortDescending:(id)sender;
- (IBAction)sortTime:(id)sender;
- (IBAction)sortTask:(id)sender;
- (IBAction)sortType:(id)sender;
- (IBAction)reset;

@end


@implementation PinBoardViewController

#pragma mark Default configuration

- (void)viewDidLoad {
  [super viewDidLoad];
  self.initialLoad = YES;
  [self createFlows];
  self.initialLoad = NO;
}

#pragma mark Multiflow-specific functions

- (void)createFlows {
  self.flowLayouts = [NSMutableArray new];
  
  float borderWidth = 2.f;
  CGSize flowSize = CGSizeMake(floorf((self.placeholder.frame.size.width - borderWidth*2)/3.f),
                               self.placeholder.frame.size.height);
  
  PinBoardColumn *column1 = [[PinBoardColumn alloc] initWithFrame:CGRectMake(0,
                                                                             0,
                                                                             flowSize.width,
                                                                             flowSize.height)
                                                         andTitle:@"TO DO"];
  [self configureFlow:column1];
  
  PinBoardColumn *column2 = [[PinBoardColumn alloc] initWithFrame:CGRectMake(borderWidth+flowSize.width,
                                                                             0,
                                                                             flowSize.width,
                                                                             flowSize.height)
                                                         andTitle:@"IN PROGRESS"];
  [self configureFlow:column2];
  
  PinBoardColumn *column3 = [[PinBoardColumn alloc] initWithFrame:CGRectMake((borderWidth+flowSize.width)*2,
                                                                             0,
                                                                             flowSize.width,
                                                                             flowSize.height)
                                                         andTitle:@"DONE"];
  [self configureFlow:column3];
  
  [column1 beginEditMode];
  [self createTasks];
}

- (void)createTasks {
  // Get task data from property list
  NSString* path = [[NSBundle mainBundle] pathForResource:@"Tasks" ofType:@"plist"];
  NSArray* tasks = [NSArray arrayWithContentsOfFile:path];
  for (int i = 0; i < [tasks count]; i++) {
    NSDictionary* task = tasks[i];
    UIImage *image = [UIImage imageNamed:task[@"Image"]];
    PinBoardTaskView *view = [[PinBoardTaskView alloc] initWithImage:image];
    
    view.taskNumber = i+1;
    view.taskColor = task[@"Color"];
    view.taskMins = [task[@"Minutes"] floatValue];
    
    // Get rid of jagged edges
    view.layer.shouldRasterize = YES;
    view.layer.rasterizationScale = [UIScreen mainScreen].scale;
    view.clipsToBounds = NO;
    
    // Add to the first column ("TODO")
    [self.flowLayouts[0] addManagedSubview:view];
  }
  
  self.descending = NO;
  [self sortTask:nil];
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
  CGPoint destination = self.binImageView.center;
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
  for (UIButton *button in _allButtons) {
    button.userInteractionEnabled = active;
    button.alpha = active ? 1.f : 0.7f;
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

- (IBAction)sortTime:(id)sender {
  [self doSortByFunc:SORT_TIME selectedButton:self.timeSortButton];
}

- (IBAction)sortTask:(id)sender {
  [self doSortByFunc:SORT_TASK selectedButton:self.taskSortButton];
}

- (IBAction)sortType:(id)sender {
  [self doSortByFunc:SORT_TYPE selectedButton:self.typeSortButton];
}

- (IBAction)doSortByFunc:(PinBoardSortFunc)sortFunc selectedButton:(UIButton*)selectedButton {
  // Put ring around relevant sort button (and clear the rest)
  for (UIButton* button in self.allButtons) {
    if (button == selectedButton) {
      [button setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"select_sort"]]];
    } else {
      [button setBackgroundColor:[UIColor clearColor]];
    }
  }
  
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
  [self createTasks];
}

@end
