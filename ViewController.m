//
//  ViewController.m
//  通讯录
//
//  Created by 王双龙 on 16/7/25.
//  Copyright © 2016年 王双龙. All rights reserved.
//

#import "ViewController.h"
#import "FriendModel.h"
#import "contactsTableViewCell.h"

#import "ContactDataHelper.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate,UISearchDisplayDelegate>
{
    NSString * _addName;
    BOOL _isSearch;
}
@property (nonatomic,strong) UITableView * tableView;
@property (nonatomic,strong) NSMutableArray *sectionTitles;
@property (nonatomic,strong) NSMutableArray *contactsSource;
@property (nonatomic,strong) NSMutableArray * foldArray;

@property (nonatomic,strong) UISearchBar *searchBar;//搜索框

@property (nonatomic,strong) NSMutableArray *searchResultArr;//搜索结果

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor purpleColor];
    
    _sectionTitles = [[NSMutableArray alloc] init];
    _contactsSource = [[NSMutableArray alloc] init];
    _foldArray = [[NSMutableArray alloc] init];
    _searchResultArr = [[NSMutableArray alloc] init];
    
    //从plist文件里获取假数据
    [self getDataSource];

    
    //用ContactDataHelper进行排序
    [self sortDataArrayWithContactDataHelper];
    
    //获得折叠状态数组
    [self getFoldStateArray];
    
    [self setupUI];
}


#pragma mark -- setupUI

- (void)setupUI{
    
    UILabel * titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    titleLabel.text = @"通讯录";
    titleLabel.center = CGPointMake(self.view.frame.size.width/2, 39);
    titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.view addSubview:titleLabel];
    

    UIButton * addBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 60, 14, 50, 50)];
    [addBtn setImage:[UIImage imageNamed:@"contacts_add_friend"] forState:UIControlStateNormal];
    [addBtn addTarget:self action:@selector(addBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [addBtn setImage:[UIImage imageNamed:@"contacts_add_friend"] forState:UIControlStateHighlighted];
    addBtn.adjustsImageWhenHighlighted = NO;
    [self.view addSubview:addBtn];
    
    
    UIButton * editBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 110, 20, 40, 40)];
    [editBtn setTitle:@"排序" forState:UIControlStateNormal];
    [editBtn setTitle:@"完成" forState:UIControlStateSelected];
    [editBtn addTarget:self action:@selector(editBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:editBtn];
    
    
    [self.view addSubview:self.tableView];
}


#pragma mark -- Help Methods

- (void)getDataSource{
 
    NSString * plistPath = [[NSBundle mainBundle] pathForResource:@"friendInfo" ofType:@"plist"];
    NSDictionary * friendDict = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    
    for (NSString * ID in friendDict) {
        
        NSDictionary * dict = friendDict[ID];
        FriendModel * model = [[FriendModel alloc] init];
        model.nameStr = dict[@"nameStr"];
        model.imageName = dict[@"imageName"];
        [self.contactsSource addObject:model];
        //NSLog(@"%@\n",model.pinyin);
    }
}

- (void)getFoldStateArray{
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"fold"] == nil) {
        for (int i = 0; i < self.sectionTitles.count - 1; i++) {
            NSNumber * isHidden = @0;
            [self.foldArray addObject:isHidden];
        }
        NSArray * foldArr = [NSArray arrayWithArray:self.foldArray];
        [[NSUserDefaults standardUserDefaults] setObject:foldArr forKey:@"fold"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }else{

        NSArray * foldArr = [[NSUserDefaults standardUserDefaults] objectForKey:@"fold"];
        self.foldArray = [NSMutableArray arrayWithArray:foldArr];
    }
}

/**
 *  通讯录排序
 *
 */

- (void)sortDataArrayWithContactDataHelper{

    NSMutableArray *contactsSource = [NSMutableArray arrayWithArray:self.contactsSource];
    [self.contactsSource removeAllObjects];
    [self.sectionTitles removeAllObjects];
    
    self.contactsSource = [ContactDataHelper getFriendListDataBy:contactsSource];
    
    self.sectionTitles = [ContactDataHelper getFriendListSectionBy:[self.contactsSource mutableCopy]];
}

#pragma mark -- Events Handel

- (void)addBtnClick:(UIButton *)addBtn{
    
    __weak ViewController * weakSelf = self;
    UIAlertController * alertView = [UIAlertController alertControllerWithTitle:@"提示" message:@"骚年，请输入你要添加的名字" preferredStyle: UIAlertControllerStyleAlert];
    UIAlertAction * action1 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
       UIAlertAction * action2 = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
           
           FriendModel * model = [[FriendModel alloc] init];
           model.nameStr = _addName;
           model.imageName = @"mr";
           
           NSMutableArray * contactsSource = [[NSMutableArray alloc] initWithArray:weakSelf.contactsSource];
           [weakSelf.contactsSource removeAllObjects];
           
           for (NSArray * array in contactsSource) {
               for (FriendModel * model in array) {
                   [weakSelf.contactsSource addObject:model];
               }
           }
           [weakSelf.contactsSource  addObject:model];
           
           [weakSelf sortDataArrayWithContactDataHelper];
           
           [weakSelf.tableView reloadData];
           
       }];
    
    [alertView addAction:action1];
    [alertView addAction:action2];
    
    [alertView addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTextFieldTextDidChangeNotification:) name:UITextFieldTextDidChangeNotification object:textField];
        
        // 可以在这里对textfield进行定制，例如改变背景色
        textField.backgroundColor = [UIColor orangeColor];
    }];
    
    [self presentViewController:alertView animated:YES completion:nil];
}

- (void)editBtnClick:(UIButton *)editBtn{
    //设置tableview编辑状态
    BOOL flag = !_tableView.editing;
    [_tableView setEditing:flag animated:YES];
    editBtn.selected = flag;
    
}
- (void)btnClicked:(UIButton *)btn{
    
    NSInteger section = btn.tag;
    BOOL isHidden = ![self.foldArray[section] boolValue];
    [self.foldArray removeObjectAtIndex:section];
    [self.foldArray insertObject:[NSNumber numberWithBool:isHidden] atIndex:section];
    NSArray * foldArr = [NSArray arrayWithArray:self.foldArray];
    [[NSUserDefaults standardUserDefaults] setObject:foldArr forKey:@"fold"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:NO];

}


//监听UITextField中内容变化
- (void)handleTextFieldTextDidChangeNotification:(NSNotification *)notification {
    UITextField *textField = notification.object;
    _addName = textField.text;
    
}

#pragma mark -- Getter

- (UITableView *)tableView{
    
    if(_tableView == nil){
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64) style:UITableViewStylePlain];
        //设置索引部分为透明
    [_tableView setSectionIndexBackgroundColor:[UIColor clearColor]];
    [_tableView setSectionIndexColor:[UIColor darkGrayColor]];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [_tableView registerNib:[UINib nibWithNibName:@"contactsTableViewCell" bundle:nil] forCellReuseIdentifier:@"cellID"];
    _tableView.tableHeaderView = self.searchBar;
     }
    return _tableView;
}
- (UISearchBar *)searchBar{
    if (!_searchBar) {
        _searchBar=[[UISearchBar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
        [_searchBar setBackgroundImage:[UIImage imageNamed:@"ic_searchBar_bgImage"]];
        [_searchBar sizeToFit];
        [_searchBar setPlaceholder:@"搜索"];
        [_searchBar.layer setBorderWidth:0.5];
        [_searchBar.layer setBorderColor:[UIColor whiteColor].CGColor];
        _searchBar.barTintColor = [UIColor whiteColor];
        _searchBar.translucent = YES;
        [_searchBar setDelegate:self];
        [_searchBar setKeyboardType:UIKeyboardTypeDefault];
    }
    return _searchBar;
}

#pragma mark -- Delegate Methods

#pragma mark -- UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if (self.contactsSource.count == 0) {
        return 0;
    }
    if (_isSearch == 1) {
        return 1;
    }
    return self.sectionTitles.count - 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (([self.foldArray[section] boolValue] == YES ||self.contactsSource.count == 0) && _isSearch == 0) {
        return 0;
    }
    
    if (_isSearch == 1) {
        return self.searchResultArr.count;
    }
    return [self.contactsSource[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    contactsTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cellID" forIndexPath:indexPath];
    if (_isSearch == 1) {
        
        FriendModel * model = self.searchResultArr[indexPath.row];
        cell.nameLabel.text = model.nameStr;
        cell.headImageView.image = [UIImage imageNamed:model.imageName];
        return cell;
    }
       FriendModel * model = self.contactsSource[indexPath.section][indexPath.row];
        cell.nameLabel.text = model.nameStr;
        cell.headImageView.image = [UIImage imageNamed:model.imageName];
    return cell;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if (_isSearch == 1) {
        return nil;
    }
    return self.sectionTitles;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (_isSearch == 1) {
        return 0;
    }
    return 30;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return 80;
    
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    if(_isSearch == 1){
        return nil;
    }
    UIView * view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
    view.backgroundColor = [UIColor orangeColor];
    UIButton * btn = [[UIButton alloc] initWithFrame:CGRectMake(25, 0, 30, 30)];
    [btn setTitle:self.sectionTitles[section + 1] forState:UIControlStateNormal];
    btn.tag = section;
    [btn addTarget:self action:@selector(btnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [view addSubview:btn];
    return view;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    if (_isSearch == 1) {
        return NO;
    }
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.editing == NO) {
        return UITableViewCellEditingStyleDelete;
    }else{
      return UITableViewCellEditingStyleNone;
    }
}

-(NSString*)tableView:(UITableView*)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath*)indexpath{
    return @"删除";
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        [self.contactsSource[indexPath.section] removeObjectAtIndex:indexPath.row];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationBottom];
        
        if ([self.contactsSource[indexPath.section] count] == 0) {
            [self.sectionTitles removeObjectAtIndex:indexPath.section + 1];
            [self.contactsSource removeObjectAtIndex:indexPath.section];
        }
        
        [tableView reloadData];
    }
}
-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    // 取出要拖动的模型数据
    FriendModel *model = self.contactsSource[sourceIndexPath.section][sourceIndexPath.row];
    //删除之前行的数据
    [self.contactsSource[sourceIndexPath.section] removeObject:model];
    // 插入数据到新的位置
    [self.contactsSource[destinationIndexPath.section] insertObject:model atIndex:destinationIndexPath.row];
    if([self.contactsSource[sourceIndexPath.section] count] == 0){
        [self.sectionTitles removeObjectAtIndex:sourceIndexPath.section + 1];
        [self.contactsSource removeObjectAtIndex:sourceIndexPath.section];
        [tableView reloadData];
    }
}

#pragma mark searchBar delegate
//searchBar开始编辑时改变取消按钮的文字
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
    
    searchBar.showsCancelButton = YES;
    for(UIView *view in  [[[searchBar subviews] objectAtIndex:0] subviews]) {
        if([view isKindOfClass:[NSClassFromString(@"UINavigationButton") class]]) {
            UIButton * cancel =(UIButton *)view;
            [cancel setTitle:@"取消" forState:UIControlStateNormal];
            cancel.titleLabel.font = [UIFont systemFontOfSize:14];
        }
    }
}
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar{
    return YES;
}
- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar{
    return YES;
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    //取消
    [searchBar resignFirstResponder];
    searchBar.text = nil;
    _isSearch = 0;
    searchBar.showsCancelButton = NO;
    [self.tableView reloadData];
}
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    _isSearch = 1;
    [self.searchResultArr removeAllObjects];
    
    NSMutableArray *tempResults = [NSMutableArray array];
    NSUInteger searchOptions = NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch;
    
    NSMutableArray *contactsSource = [NSMutableArray arrayWithArray:self.contactsSource];
    
    for (NSArray * array in contactsSource) {
        for (FriendModel * model in array) {
            [tempResults addObject:model];
        }
    }
    
    for (int i = 0; i < tempResults.count; i++) {
        NSString *storeString = [(FriendModel *)tempResults[i] nameStr];
        
        NSRange storeRange = NSMakeRange(0, storeString.length);
        
        NSRange foundRange = [storeString rangeOfString:searchText options:searchOptions range:storeRange];
        if (foundRange.length) {
            
            [self.searchResultArr addObject:tempResults[i]];
        }
    }
    NSLog(@"%ld",self.searchResultArr.count);
    
    [self.tableView reloadData];
    
    NSLog(@"wowoow");
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    NSLog(@"ninini");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
