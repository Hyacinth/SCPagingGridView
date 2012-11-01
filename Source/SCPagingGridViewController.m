//
//  SCPagingGridViewController.m
//  iScribd
//
//  Created by Jesse Andersen on 9/27/12.
//  Copyright (c) 2012 Scribd. All rights reserved.
//

#import "SCPagingGridViewController.h"
#import "SCViewRecycler.h"
#import "SCGridView.h"
#import "SCPageView.h"

@interface SCPagingGridViewController ()

@property (nonatomic, strong) NSArray *pageSizes;
@property (nonatomic, assign) NSUInteger totalPageSizes;
@property (nonatomic, strong) SCViewRecycler *gridRecycler;
@property (nonatomic, strong) SCViewRecycler *cellRecycler;

@end

@implementation SCPagingGridViewController

- (id)init {
    if (self = [super init]) {
        _gridRecycler = [[SCViewRecycler alloc] initWithViewClass:[SCGridView class]];
        _cellRecycler = [[SCViewRecycler alloc] initWithViewClass:[self cellClass]];
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.pageView.direction = SCPagingDirectionHorizontal;
}

#pragma mark - SCPageViewDelegate

- (NSUInteger)numberOfPagesInPageView:(SCPageView *)pageView {
    NSInteger numberOfCells = [self numberOfCellsInPageView:pageView];
    NSInteger numberOfPages = 0;
    while (numberOfCells > 0 && self.totalPageSizes > 0 && (_maxNumberOfPages <= 0 || numberOfPages < _maxNumberOfPages)) {
        for (NSNumber *pageSize in self.pageSizes) {
            ++numberOfPages;
            numberOfCells -= [pageSize integerValue];
            if (numberOfCells <= 0 || (_maxNumberOfPages > 0 && numberOfPages >= _maxNumberOfPages)) {
                break;
            }
        }
    }
    return numberOfPages;
}

- (NSInteger)numberOfCellsInPageView:(SCPageView *)pageView {
    return 0;
}

- (UIView *)pageForPageNumber:(NSUInteger)pageNumber inPageView:(SCPageView *)pageView {
    SCGridView *result = [self.gridRecycler generateView];
    [self configureGridView:result forPageNumber:pageNumber];
    result.delegate = self;
    NSArray *schema = [self schemaForPageNumber:pageNumber];
    NSUInteger offset = [self offsetForPageNumber:pageNumber];
    NSUInteger count = [self numberOfCellsInPageView:pageView];
    NSMutableArray *cells = [NSMutableArray array];
    for (int i = 0; i < [[self sizeForPageSchema:schema] integerValue]; ++i) {
        NSUInteger position = offset + i;
        if (position < count) {
            UIView *view = [self.cellRecycler generateView];
            [self configureCell:view atPosition:position];
            [cells addObject:view];
        } else {
            schema = [self schemaForShortPage:pageNumber numberOfCells:i originalSchema:schema inGridView:result];
            break;
        }
    }
    result.schema = schema;
    result.cells = cells;
    return result;
}

#pragma mark - SCGridViewDelegate

- (void)gridView:(SCGridView *)gridView didSelectCell:(UIView *)cell atIndex:(NSUInteger)index {
    [self didSelectCell:cell atPosition:index + [self offsetForPageNumber:self.pageView.currentPageNumber]];
}

#pragma mark - Public Methods

- (void)setSchema:(NSArray *)schema {
    _totalPageSizes = 0;
    NSMutableArray *sizes = [NSMutableArray arrayWithCapacity:[schema count]];
    for (id obj in schema) {
        NSNumber *size = [self sizeForPageSchema:obj];
        [sizes addObject:size];
        _totalPageSizes += [size integerValue];

    }
    _pageSizes = [sizes copy];
    _schema = schema;
    [self.pageView reloadData];
}

#pragma mark - Calcumalations

- (NSUInteger)offsetForPageNumber:(NSUInteger)pageNumber {
    NSUInteger numberOfPageTypes = [self.schema count];
    if (numberOfPageTypes > 0) {
        // say there are 3 schema types [2,1,2], [3,3,3], and [1,2,3,4], how many times have we cycled through these?
        NSUInteger numberOfSchemaCycles = floor(pageNumber / numberOfPageTypes);
        NSUInteger result = numberOfSchemaCycles * self.totalPageSizes;
        NSUInteger remainder = pageNumber % numberOfPageTypes;
        if (remainder > 0) {
            for (NSUInteger i = 0; i < remainder; ++i) {
                result += [[self.pageSizes objectAtIndex:i] integerValue];
            }
        }
        return result;
    }
    return 0;
}

- (NSNumber *)sizeForPageSchema:(NSArray *)schema {
    NSInteger result = 0;
    for (NSNumber *pageSchema in schema) {
        result += [pageSchema integerValue];
    }
    return @(result);
}

- (NSArray *)schemaForPageNumber:(NSUInteger)pageNumber {
    return [self.schema objectAtIndex:pageNumber % [self.schema count]];
}

#pragma mark - Methods for subclass to override

- (Class)cellClass {
    return [UIView class];
}

- (void)configureGridView:(SCGridView *)gridView forPageNumber:(NSUInteger)pageNumber {
    gridView.backgroundColor = [UIColor blackColor];
    gridView.rowSpacing = 1.0f;
    gridView.colSpacing = 1.0f;
}

- (void)configureCell:(UIView *)cell atPosition:(NSUInteger)position {
    // do nothing by default
}

- (void)didSelectCell:(UIView *)cell atPosition:(NSUInteger)position {
    // do nothing by default
}

- (NSArray *)schemaForShortPage:(NSUInteger)pageNumber numberOfCells:(NSUInteger)numberOfCells originalSchema:(NSArray *)original inGridView:(SCGridView *)gridView {
    // sublcass can override to provide for better handling of short pages
    return original;
}

@end
