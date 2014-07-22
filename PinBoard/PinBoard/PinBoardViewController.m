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

typedef enum sortFuncSelection {
  SORT_TASK = 1,
  SORT_TYPE,
  SORT_TIME
} sortFunc;

@interface PinBoardViewController ()

@property (strong, nonatomic) NSMutableArray *flowLayouts;
@property (strong, nonatomic) UILongPressGestureRecognizer *gestureInProgress;
@property (assign, nonatomic) BOOL descending;
@property (assign, nonatomic) sortFunc selectedSort;

@property (strong, nonatomic) IBOutlet UIView *placeholder;
@property (strong, nonatomic) IBOutlet UILabel *startOverLabel;
@property (strong, nonatomic) IBOutlet UILabel *sortByLabel;
@property (strong, nonatomic) IBOutlet UILabel *viewTitleLabel;
@property (strong, nonatomic) IBOutlet UIButton *taskSortButton;
@property (strong, nonatomic) IBOutlet UIButton *timeSortButton;
@property (strong, nonatomic) IBOutlet UIButton *typeSortButton;
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
  [self createFlows];
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

-(void) createTasks {
  // Get task data from property list
  NSString* path = [[NSBundle mainBundle] pathForResource:@"Tasks" ofType:@"plist"];
  if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
    NSArray* tasks = [[NSArray alloc] initWithContentsOfFile:path];
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
  }
  
  self.descending = NO;
  [self sortTask:nil];
}

-(void) configureFlow:(PinBoardColumn*)flow {
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
  [self deactivateButtons];
  [self.placeholder bringSubviewToFront:flow];
}

- (void)didEndEditInFlowLayout:(SEssentialsFlowLayout *)flow {
  [self reactivateButtons];
  
  // Take all columns out of edit mode
  for (PinBoardColumn *column in self.flowLayouts) {
    [column endEditMode];
  }
}

-(void)flowLayout:(SEssentialsFlowLayout *)flow didRemoveView:(UIView *)view {
  if ([flow respondsToSelector:@selector(updateFlowTotals)]) {
    [(PinBoardColumn*)flow updateFlowTotals];
  }
  self.gestureInProgress = nil;
}

-(BOOL)flowLayout:(SEssentialsFlowLayout *)flow shouldMoveView:(UIView *)view {
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

-(void)flowLayout:(PinBoardColumn *)flow didDragView:(UIView *)view {
  // Get the current position of the dragged view relative to our placeholder
  CGPoint dragPosition = [view.superview convertPoint:view.center toView:self.placeholder];
  
  // Work out which column the new position is in (if any)
  for (PinBoardColumn *column in self.flowLayouts) {
    if(CGRectContainsPoint(column.frame, dragPosition)) {
      if (column != flow) {
        // Calculate new frame for task, remove it from old column and add to new column
        view.frame = [column convertRect:view.frame fromView:flow];
        [flow unmanageSubview:view];
        [column addManagedSubview:view];
        
        // Update the flow totals
        [flow updateFlowTotals];
        [column updateFlowTotals];
        
        // Make sure the new column is in edit mode
        [column beginEditMode];
      }
    }
  }
}

-(CGPoint)editButtonPositionInFlowLayout:(SEssentialsFlowLayout *)flow {
  CGPoint destination = self.binImage.center;
  return [self.view convertPoint:destination toView:flow];
}

-(void) deactivateButtons {
  for (UIButton *button in _allButtons) {
    button.userInteractionEnabled = NO;
    button.alpha = 0.7f;
  }
}

-(void) reactivateButtons {
  for (UIButton *button in _allButtons) {
    button.userInteractionEnabled = YES;
    button.alpha = 1.f;
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

- (IBAction) doSortByFunc:(sortFunc)sortFunc selectedButton:(UIButton*)selectedButton {
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

- (IBAction) doSort {
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
-(IBAction) reset {
  for (PinBoardColumn *flow in self.flowLayouts) {
    for (UIView *view in [flow.managedViews copy]) {
      [flow removeManagedSubview:view animated:NO];
    }
  }
  
  self.selectedSort = 0;
  [self createTasks];
}

#pragma mark Parent functions

- (void)viewDidUnload {
  [self setPlaceholder:nil];
  [self setBinImage:nil];
  [self setTaskSortButton:nil];
  [self setTimeSortButton:nil];
  [self setTypeSortButton:nil];
  [self setSortByLabel:nil];
  [self setStartOverLabel:nil];
  [self setAllButtons:nil];
  [super viewDidUnload];
}

@end