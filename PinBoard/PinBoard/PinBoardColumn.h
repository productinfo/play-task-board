//
//  PinBoardColumn.h
//  ShinobiPlay
//
//  Created by Thomas Kelly on 03/01/2013.
//  Copyright (c) 2013 Scott Logic. All rights reserved.
//

#import <ShinobiEssentials/ShinobiEssentials.h>
#import "PinBoardViewController.h"

@interface PinBoardColumn : SEssentialsFlowLayout

@property (weak, nonatomic) id<SEssentialsFlowLayoutDelegate> manager;

- (instancetype)initWithFrame:(CGRect)frame andTitle:(NSString*) title;
- (void)updateFlowTotals;

- (void)sortByTime:(BOOL)descending;
- (void)sortByType:(BOOL)descending;
- (void)sortByTask:(BOOL)descending;

@end
