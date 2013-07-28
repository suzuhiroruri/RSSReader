//
//  ViewController.m
//  RSSReader
//
//  Created by Hiromasa Suzuki on 13/07/28.
//  Copyright (c) 2013年 Hiromasa Suzuki. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController{
    
    //XMLオブジェクト
    TBXML *rssXML;
    
    //最新ニュースを格納する配列
    NSMutableArray* elementList;
    
    //Table Viewインスタンス
    IBOutlet UITableView *table;
    
    //Safariに渡すURL
    NSURL *urlForSafari;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    //XMLを取得・解析
    [self getXML];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
//HTTP通信を利用してXMLを取得
- (void) getXML {
    
    NSString *urlString =
    @"http://rss.dailynews.yahoo.co.jp/fc/rss.xml";
    NSURL *url = [NSURL URLWithString:urlString];
    
    //成功時のコールバック処理
    TBXMLSuccessBlock successBlock = ^(TBXML *tbxmlDocument) {
        NSLog(@"「%@」の取得に成功しました。", url);
        
        //XMLを解析
        [self parseXML];
    };
    
    //失敗時のコールバック処理
    TBXMLFailureBlock failureBlock =
    ^(TBXML *tbxmlDocument, NSError * error) {
        NSLog(@"「%@」の取得に失敗しました。", url);
    };
    
    //ステータスバーのActivity Indicatorを起動
    [UIApplication
     sharedApplication].networkActivityIndicatorVisible = YES;
    
    //URLで指定したRSSのXMLをバックグラウンドでダウンロード
    rssXML = [TBXML tbxmlWithURL:url
                         success:successBlock failure:failureBlock];
}
//取得したXMLをパース（解析）
- (void) parseXML {
    //elementListを初期化
    elementList = [[NSMutableArray alloc] init];
    
    //XMLの最初の要素<rss>を取得
    TBXMLElement *rssElement = rssXML.rootXMLElement;
    
    //<rss>以下の<channel>を取得
    TBXMLElement *channelElement = [TBXML
                                    childElementNamed:@"channel" parentElement:rssElement];
    
    //実際のニュース項目を記録した<item>を取得
    TBXMLElement *itemElement = [TBXML
                                 childElementNamed:@"item" parentElement:channelElement];
    
    //<item>の数だけ繰り返し
    while (itemElement) {
        
        //<item>以下の<title>を取得
        TBXMLElement *titleElement = [TBXML
                                      childElementNamed:@"title" parentElement:itemElement];
        //<item>以下の<link>を取得
        TBXMLElement *urlElement = [TBXML
                                    childElementNamed:@"link" parentElement:itemElement];
        //<item>以下の<pubDate>を取得
        TBXMLElement *dateElement = [TBXML
                                     childElementNamed:@"pubDate" parentElement:itemElement];
        
        
        //それぞれの要素のテキスト内容をNSStringとして取得
        NSString *title = [TBXML textForElement:titleElement];
        NSString *url = [TBXML textForElement:urlElement];
        NSString *date = [TBXML textForElement:dateElement];
        
        NSLog(@"%@ %@", title, url);
        
        //新しいNewsクラスのインスタンス生成
        News *n = [[News alloc] init];
        
        //nにタイトル・URL・日時を格納
        n.title = title;
        n.url = url;
        n.date = date;
        
        //nをelementListに追加
        [elementList addObject:n];
        
        //次の<item>要素へ移動
        itemElement = itemElement->nextSibling;

    }
    
    //バックグラウンドでの処理完了に伴い、フロント側でリストを更新
    [self refreshTableOnFront];
}
//Table Viewのセクション数を指定
- (NSInteger)numberOfSectionsInTableView:
(UITableView *)tableView {
    return 1;
}

//Table Viewのセルの数を指定
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return [elementList count];
}

//各セルにタイトルをセット
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //セルのスタイルを標準のものに指定
    static NSString *CellIdentifier = @"NewsCell";
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    //カスタムセル上のラベル
    UILabel *titleLabel = (UILabel*)[cell viewWithTag:1];
    UILabel *dateLabel = (UILabel*)[cell viewWithTag:2];
    
    //セルにお気に入りサイトのタイトルを表示
    News *f = [elementList objectAtIndex:[indexPath row]];
    titleLabel.text = f.title;
    dateLabel.text = f.date;
    
    return cell;
}

//フロント側でテーブルを更新
- (void) refreshTableOnFront {
    [self performSelectorOnMainThread:@selector(refreshTable)
                           withObject:self waitUntilDone:TRUE];
}


//テーブルの内容をセット
- (void)refreshTable {
    
    //ステータスバーのActivity Indicatorを停止
    [UIApplication
     sharedApplication].networkActivityIndicatorVisible = NO;
    
    //最新の内容にテーブルをセット
    [table reloadData];
}
//リスト中のお気に入りアイテムが選択された時の処理
- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //選択された項目のURLを参照
    News *n = [elementList objectAtIndex:[indexPath row]];
    NSString *selectedURL = n.url;
    
    urlForSafari = [NSURL URLWithString:selectedURL];
    
    //Safariを起動するかどうかを確認
    [self goToSafari];
}
//本当にSafariにを起動するかを確認するalert View表示
- (void)goToSafari {
    //メッセージを表示
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Safariの起動"
                          message:@"このニュースをSafariで開きますか？"
                        delegate:self
                        cancelButtonTitle:@"いいえ"
                          otherButtonTitles:@"はい", nil];
    [alert show];    
}

//alert View上のボタンがクリックされた時の処理
//「はい」が押されたときはSafariを起動
- (void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    if([title isEqualToString:@"いいえ"]) {
        NSLog(@"Safari起動キャンセル");
    } else if([title isEqualToString:@"はい"]) {
        NSLog(@"Safari起動");
        //アプリからSafariを起動
        [[UIApplication sharedApplication] openURL:urlForSafari];
    }
}


//フィードを更新
-(IBAction)refreshList:(id)sender {
    //最新のRSSフィードを取得
    [self getXML];
}

@end
