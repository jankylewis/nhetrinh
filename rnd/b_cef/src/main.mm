// MVP B: AppKit shell (same layout/features as MVP A) + Chromium via CEF (Alloy, windowed child).
#import <Cocoa/Cocoa.h>
#include <sys/sysctl.h>
#include <sys/time.h>
#include "include/cef_app.h"
#include "include/cef_application_mac.h"
#include "include/cef_client.h"
#include "include/wrapper/cef_library_loader.h"

static const NSTimeInterval kUnloadAfter = 10 * 60;

#pragma mark - Bench (same env contract as MVP A)

static NSDictionary* Env() { return NSProcessInfo.processInfo.environment; }

static double MsSinceProcessStart() {
  struct kinfo_proc info; size_t size = sizeof info;
  int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()};
  if (sysctl(mib, 4, &info, &size, NULL, 0) != 0) return -1;
  struct timeval st = info.kp_proc.p_un.__p_starttime, now; gettimeofday(&now, NULL);
  return (now.tv_sec - st.tv_sec) * 1000.0 + (now.tv_usec - st.tv_usec) / 1000.0;
}

static void BenchFirstLoad() {
  static bool done = false;
  NSString* path = Env()[@"NHT_BENCH_OUT"];
  if (done || !path) return;
  done = true;
  NSString* line = [NSString stringWithFormat:@"{\"event\":\"first_load\",\"ms\":%.2f}\n", MsSinceProcessStart()];
  FILE* f = fopen(path.fileSystemRepresentation, "a");
  if (f) { fputs(line.UTF8String, f); fclose(f); }
}

static void BenchScore(NSString* value) {
  static bool done = false;
  NSString* path = Env()[@"NHT_BENCH_OUT"];
  if (done || !path) return;
  done = true;
  NSString* line = [NSString stringWithFormat:@"{\"event\":\"score\",\"ms\":%.2f,\"value\":\"%@\"}\n",
                                              MsSinceProcessStart(), value];
  FILE* f = fopen(path.fileSystemRepresentation, "a");
  if (f) { fputs(line.UTF8String, f); fclose(f); }
}

#pragma mark - NSApplication subclass CEF requires

@interface NhtApp : NSApplication <CefAppProtocol> { BOOL handling_; }
@end
@implementation NhtApp
- (BOOL)isHandlingSendEvent { return handling_; }
- (void)setHandlingSendEvent:(BOOL)v { handling_ = v; }
- (void)sendEvent:(NSEvent*)e { CefScopedSendingEvent s; [super sendEvent:e]; }
- (void)terminate:(id)sender { [(id)self.delegate performSelector:@selector(quitGracefully)]; }
@end

#pragma mark - Model

@class Browser;
@interface Tab : NSObject
@property(copy) NSString* url;
@property(copy) NSString* title;
@property NSView* host;  // parent NSView of the CEF browser view
@property BOOL canBack, canForward, closing;
@property NSDate* lastActive;
@end
@implementation Tab {
 @public CefRefPtr<CefBrowser> browser;
}
@end

@interface Browser : NSWindowController <NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate>
- (void)tabChanged;
- (void)openTab:(NSString*)url;
- (void)browserClosed:(Tab*)tab;
@end

#pragma mark - CEF client (one per tab; all callbacks arrive on the main thread)

class TabClient : public CefClient, CefDisplayHandler, CefLifeSpanHandler,
                  CefLoadHandler, CefKeyboardHandler {
 public:
  TabClient(Tab* t, Browser* w) : tab_(t), win_(w) {}
  CefRefPtr<CefDisplayHandler> GetDisplayHandler() override { return this; }
  CefRefPtr<CefLifeSpanHandler> GetLifeSpanHandler() override { return this; }
  CefRefPtr<CefLoadHandler> GetLoadHandler() override { return this; }
  CefRefPtr<CefKeyboardHandler> GetKeyboardHandler() override { return this; }

  void OnTitleChange(CefRefPtr<CefBrowser>, const CefString& t) override {
    tab_.title = [NSString stringWithUTF8String:t.ToString().c_str()];
    [win_ tabChanged];
  }
  void OnAddressChange(CefRefPtr<CefBrowser>, CefRefPtr<CefFrame> f, const CefString& u) override {
    if (!f->IsMain()) return;
    tab_.url = [NSString stringWithUTF8String:u.ToString().c_str()];
    [win_ tabChanged];
  }
  void OnLoadingStateChange(CefRefPtr<CefBrowser>, bool, bool back, bool fwd) override {
    tab_.canBack = back; tab_.canForward = fwd;
    [win_ tabChanged];
  }
  // NHT_BENCH_POLL_JS results come back as console messages "NHTPOLL:SCORE:<x>".
  bool OnConsoleMessage(CefRefPtr<CefBrowser>, cef_log_severity_t, const CefString& msg,
                        const CefString&, int) override {
    NSString* m = [NSString stringWithUTF8String:msg.ToString().c_str()];
    if ([m hasPrefix:@"NHTPOLL:SCORE:"]) BenchScore([m substringFromIndex:14]);
    return false;
  }
  void OnLoadEnd(CefRefPtr<CefBrowser>, CefRefPtr<CefFrame> f, int) override {
    if (f->IsMain()) BenchFirstLoad();
  }
  void OnAfterCreated(CefRefPtr<CefBrowser> b) override { tab_->browser = b; [win_ tabChanged]; }
  void OnBeforeClose(CefRefPtr<CefBrowser>) override { tab_->browser = nullptr; [win_ browserClosed:tab_]; }

  // target=_blank / window.open -> our own new tab, never a Chromium popup window.
  bool OnBeforePopup(CefRefPtr<CefBrowser>, CefRefPtr<CefFrame>, int, const CefString& url,
                     const CefString&, WindowOpenDisposition, bool, const CefPopupFeatures&,
                     CefWindowInfo&, CefRefPtr<CefClient>&, CefBrowserSettings&,
                     CefRefPtr<CefDictionaryValue>&, bool*) override {
    NSString* u = [NSString stringWithUTF8String:url.ToString().c_str()];
    Browser* w = win_;
    dispatch_async(dispatch_get_main_queue(), ^{ [w openTab:u]; });
    return true;
  }

  // Cmd-shortcuts reach our menu even while the page has focus.
  bool OnPreKeyEvent(CefRefPtr<CefBrowser>, const CefKeyEvent& e, CefEventHandle os, bool*) override {
    if (os && (e.modifiers & EVENTFLAG_COMMAND_DOWN))
      return [[NSApp mainMenu] performKeyEquivalent:(__bridge NSEvent*)os];
    return false;
  }

 private:
  __weak Tab* tab_;
  __weak Browser* win_;
  IMPLEMENT_REFCOUNTING(TabClient);
};

#pragma mark - Window

@implementation Browser {
  NSMutableArray<Tab*>* tabs_;
  NSInteger selected_;
  NSTableView* table_;
  NSTextField* address_;
  NSButton *back_, *fwd_;
  NSView* web_;
  NSSplitViewController* split_;
  BOOL updating_;
  BOOL quitting_;
}

- (instancetype)init {
  NSWindow* w = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 1280, 820)
      styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable |
                NSWindowStyleMaskResizable | NSWindowStyleMaskFullSizeContentView
      backing:NSBackingStoreBuffered defer:NO];
  w.titleVisibility = NSWindowTitleHidden;
  w.titlebarAppearsTransparent = YES;
  [w center];
  self = [super initWithWindow:w];
  tabs_ = [NSMutableArray new];
  selected_ = -1;
  [self buildLayout];
  if (![Env()[@"NHT_BENCH_LOADALL"] isEqual:@"1"])
    [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(unloadIdle) userInfo:nil repeats:YES];
  return self;
}

- (NSButton*)symbolButton:(NSString*)name action:(SEL)a {
  NSButton* b = [NSButton buttonWithImage:[NSImage imageWithSystemSymbolName:name accessibilityDescription:name]
                                   target:self action:a];
  b.bordered = NO;
  [b.widthAnchor constraintEqualToConstant:28].active = YES;
  return b;
}

- (void)buildLayout {
  // Sidebar: "+ New Tab" + tab list
  NSView* side = [NSView new];
  NSButton* plus = [NSButton buttonWithTitle:@"+  New Tab" target:self action:@selector(newTab:)];
  plus.bordered = NO; plus.alignment = NSTextAlignmentLeft; plus.contentTintColor = NSColor.secondaryLabelColor;
  table_ = [NSTableView new];
  [table_ addTableColumn:[[NSTableColumn alloc] initWithIdentifier:@"tab"]];
  table_.headerView = nil; table_.style = NSTableViewStyleSourceList; table_.rowHeight = 28;
  table_.dataSource = self; table_.delegate = self; table_.backgroundColor = NSColor.clearColor;
  table_.menu = [NSMenu new];
  [table_.menu addItemWithTitle:@"Close Tab" action:@selector(closeClicked:) keyEquivalent:@""].target = self;
  NSScrollView* scroll = [NSScrollView new];
  scroll.documentView = table_; scroll.drawsBackground = NO; scroll.hasVerticalScroller = YES;
  for (NSView* v in @[ plus, scroll ]) { v.translatesAutoresizingMaskIntoConstraints = NO; [side addSubview:v]; }
  [NSLayoutConstraint activateConstraints:@[
    [plus.topAnchor constraintEqualToAnchor:side.topAnchor constant:44],
    [plus.leadingAnchor constraintEqualToAnchor:side.leadingAnchor constant:16],
    [scroll.topAnchor constraintEqualToAnchor:plus.bottomAnchor constant:6],
    [scroll.leadingAnchor constraintEqualToAnchor:side.leadingAnchor],
    [scroll.trailingAnchor constraintEqualToAnchor:side.trailingAnchor],
    [scroll.bottomAnchor constraintEqualToAnchor:side.bottomAnchor],
  ]];

  // Main: toolbar + web container
  NSView* main = [NSView new];
  back_ = [self symbolButton:@"chevron.left" action:@selector(goBack:)];
  fwd_ = [self symbolButton:@"chevron.right" action:@selector(goForward:)];
  NSButton* reload = [self symbolButton:@"arrow.clockwise" action:@selector(reload:)];
  address_ = [NSTextField new];
  address_.placeholderString = @"Search or enter address";
  address_.bezelStyle = NSTextFieldRoundedBezel; address_.focusRingType = NSFocusRingTypeNone;
  address_.target = self; address_.action = @selector(submitAddress:);
  NSStackView* row = [NSStackView stackViewWithViews:@[ back_, fwd_, reload, address_ ]];
  row.spacing = 6;
  web_ = [NSView new];
  for (NSView* v in @[ row, web_ ]) { v.translatesAutoresizingMaskIntoConstraints = NO; [main addSubview:v]; }
  [NSLayoutConstraint activateConstraints:@[
    [row.topAnchor constraintEqualToAnchor:main.topAnchor constant:6],
    [row.heightAnchor constraintEqualToConstant:28],
    [row.leadingAnchor constraintEqualToAnchor:main.leadingAnchor constant:8],
    [row.trailingAnchor constraintEqualToAnchor:main.trailingAnchor constant:-10],
    [web_.topAnchor constraintEqualToAnchor:main.topAnchor constant:40],
    [web_.leadingAnchor constraintEqualToAnchor:main.leadingAnchor],
    [web_.trailingAnchor constraintEqualToAnchor:main.trailingAnchor],
    [web_.bottomAnchor constraintEqualToAnchor:main.bottomAnchor],
  ]];

  NSViewController* sideVC = [NSViewController new]; sideVC.view = side;
  NSViewController* mainVC = [NSViewController new]; mainVC.view = main;
  NSSplitViewItem* sideItem = [NSSplitViewItem sidebarWithViewController:sideVC];
  sideItem.minimumThickness = 180; sideItem.maximumThickness = 420; sideItem.canCollapse = YES;
  split_ = [NSSplitViewController new];
  [split_ addSplitViewItem:sideItem];
  [split_ addSplitViewItem:[NSSplitViewItem splitViewItemWithViewController:mainVC]];
  self.window.contentViewController = split_;
  [self.window setContentSize:NSMakeSize(1280, 820)];
}

#pragma mark Tabs

- (void)openInitialTabs {
  NSString* raw = Env()[@"NHT_BENCH_URLS"];
  NSArray* urls = raw.length ? [raw componentsSeparatedByString:@","] : @[ @"https://www.google.com" ];
  for (NSString* u in urls) [tabs_ addObject:[self makeTab:u]];
  if ([Env()[@"NHT_BENCH_LOADALL"] isEqual:@"1"]) for (Tab* t in tabs_) [self load:t];
  [self select:0];
  if (NSString* js = Env()[@"NHT_BENCH_POLL_JS"]) {
    NSString* wrapped = [NSString stringWithFormat:@"console.log('NHTPOLL:' + (%@))", js];
    [NSTimer scheduledTimerWithTimeInterval:2 repeats:YES block:^(NSTimer*) {
      if (auto b = [self current]) b->GetMainFrame()->ExecuteJavaScript(wrapped.UTF8String, "", 0);
    }];
  }
}

- (Tab*)makeTab:(NSString*)url {
  Tab* t = [Tab new];
  t.url = url; t.title = url.length ? ([NSURL URLWithString:url].host ?: url) : @"New Tab";
  t.lastActive = [NSDate date];
  return t;
}

// Lazy: the Chromium browser (and its renderer process) is created on first use.
- (void)load:(Tab*)t {
  if (t.host || !t.url.length) return;
  t.host = [[NSView alloc] initWithFrame:web_.bounds];
  t.host.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  t.host.hidden = YES;
  [web_ addSubview:t.host];
  CefWindowInfo info;
  NSRect r = web_.bounds;
  info.SetAsChild((__bridge void*)t.host, CefRect(0, 0, (int)r.size.width, (int)r.size.height));
  CefBrowserSettings settings;
  CefBrowserHost::CreateBrowser(info, new TabClient(t, self), t.url.UTF8String, settings, nullptr, nullptr);
}

- (void)select:(NSInteger)i {
  if (i < 0 || i >= (NSInteger)tabs_.count) return;
  if (selected_ >= 0 && selected_ < (NSInteger)tabs_.count && selected_ != i) {
    Tab* old = tabs_[selected_];
    old.host.hidden = YES;
    if (old->browser) old->browser->GetHost()->WasHidden(true);
  }
  selected_ = i;
  Tab* t = tabs_[i];
  t.lastActive = [NSDate date];
  [self load:t];
  t.host.hidden = NO;
  if (t->browser) { t->browser->GetHost()->WasHidden(false); t->browser->GetHost()->SetFocus(true); }
  if (!t.url.length) [self.window makeFirstResponder:address_];
  [self tabChanged];
}

- (void)openTab:(NSString*)url { [tabs_ addObject:[self makeTab:url]]; [self select:tabs_.count - 1]; }

- (void)unloadTab:(Tab*)t {
  if (t->browser && !t.closing) { t.closing = YES; t->browser->GetHost()->CloseBrowser(true); }
  else if (!t->browser) { [t.host removeFromSuperview]; t.host = nil; }
}

- (void)browserClosed:(Tab*)t {
  [t.host removeFromSuperview];
  t.host = nil; t.closing = NO;
  [self tabChanged];
  if (quitting_ && ![self anyBrowserAlive]) CefQuitMessageLoop();
}

- (BOOL)anyBrowserAlive {
  for (Tab* t in tabs_) if (t->browser) return YES;
  return NO;
}

- (void)closeAt:(NSInteger)i {
  if (i < 0 || i >= (NSInteger)tabs_.count) return;
  [self unloadTab:tabs_[i]];
  [tabs_ removeObjectAtIndex:i];
  if (tabs_.count == 0) { [NSApp terminate:nil]; return; }
  selected_ = -1;
  [self select:MIN(i, (NSInteger)tabs_.count - 1)];
}

- (void)unloadIdle {
  NSDate* cutoff = [NSDate dateWithTimeIntervalSinceNow:-kUnloadAfter];
  for (NSInteger i = 0; i < (NSInteger)tabs_.count; i++) {
    Tab* t = tabs_[i];
    if (i != selected_ && t.host && [t.lastActive compare:cutoff] == NSOrderedAscending) [self unloadTab:t];
  }
}

- (void)quitAll {
  quitting_ = YES;
  for (Tab* t in tabs_) [self unloadTab:t];
  if (![self anyBrowserAlive]) CefQuitMessageLoop();
}

- (void)tabChanged {
  updating_ = YES;
  [table_ reloadData];
  if (selected_ >= 0) [table_ selectRowIndexes:[NSIndexSet indexSetWithIndex:selected_] byExtendingSelection:NO];
  updating_ = NO;
  if (selected_ < 0 || selected_ >= (NSInteger)tabs_.count) return;
  Tab* t = tabs_[selected_];
  back_.enabled = t.canBack; fwd_.enabled = t.canForward;
  if (self.window.firstResponder != address_.currentEditor) address_.stringValue = t.url ?: @"";
  self.window.title = t.title ?: @"";
}

#pragma mark Table

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tv { return tabs_.count; }

- (NSView*)tableView:(NSTableView*)tv viewForTableColumn:(NSTableColumn*)c row:(NSInteger)row {
  NSTextField* f = [tv makeViewWithIdentifier:@"cell" owner:nil];
  if (!f) { f = [NSTextField labelWithString:@""]; f.identifier = @"cell"; f.lineBreakMode = NSLineBreakByTruncatingTail; }
  Tab* t = tabs_[row];
  f.stringValue = t.title ?: @"";
  f.textColor = t.host ? NSColor.labelColor : NSColor.tertiaryLabelColor;
  return f;
}

- (void)tableViewSelectionDidChange:(NSNotification*)n {
  if (!updating_ && table_.selectedRow >= 0) [self select:table_.selectedRow];
}

- (void)closeClicked:(id)s { [self closeAt:table_.clickedRow]; }

#pragma mark Actions

- (CefRefPtr<CefBrowser>)current {
  return selected_ >= 0 && selected_ < (NSInteger)tabs_.count ? tabs_[selected_]->browser : nullptr;
}

- (void)submitAddress:(id)s {
  NSString* text = [address_.stringValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
  if (!text.length || selected_ < 0) return;
  NSString* url;
  if ([text containsString:@"://"]) url = text;
  else if (![text containsString:@" "] && ([text containsString:@"."] || [text hasPrefix:@"localhost"]))
    url = [@"https://" stringByAppendingString:text];
  else url = [@"https://www.google.com/search?q=" stringByAppendingString:
      [text stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]];
  Tab* t = tabs_[selected_];
  t.url = url;
  if (t->browser) t->browser->GetMainFrame()->LoadURL(url.UTF8String);
  else [self select:selected_];
}

- (void)newTab:(id)s { [self openTab:@""]; [self.window makeFirstResponder:address_]; }
- (void)closeTab:(id)s { [self closeAt:selected_]; }
- (void)focusAddress:(id)s { [self.window makeFirstResponder:address_]; }
- (void)reload:(id)s { if (auto b = [self current]) b->Reload(); }
- (void)goBack:(id)s { if (auto b = [self current]) b->GoBack(); }
- (void)goForward:(id)s { if (auto b = [self current]) b->GoForward(); }
- (void)toggleTabSidebar:(id)s { NSSplitViewItem* i = split_.splitViewItems.firstObject; i.animator.collapsed = !i.collapsed; }
- (void)selectTabByNumber:(NSMenuItem*)m { [self select:m.tag == 9 ? (NSInteger)tabs_.count - 1 : m.tag - 1]; }
@end

#pragma mark - App delegate + menu

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property Browser* browser;
@end

static NSMenuItem* Item(NSString* t, SEL a, NSString* k) { return [[NSMenuItem alloc] initWithTitle:t action:a keyEquivalent:k]; }
static NSMenuItem* Sub(NSString* title, NSArray<NSMenuItem*>* items) {
  NSMenuItem* holder = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
  NSMenu* m = [[NSMenu alloc] initWithTitle:title];
  for (NSMenuItem* i in items) [m addItem:i];
  holder.submenu = m;
  return holder;
}

@implementation AppDelegate
- (void)start {
  NSMenu* menu = [NSMenu new];
  [menu addItem:Sub(@"nhetrinh", @[ Item(@"Quit nhetrinh", @selector(terminate:), @"q") ])];
  [menu addItem:Sub(@"File", @[ Item(@"New Tab", @selector(newTab:), @"t"), Item(@"Close Tab", @selector(closeTab:), @"w"),
                                Item(@"Open Location", @selector(focusAddress:), @"l") ])];
  [menu addItem:Sub(@"Edit", @[ Item(@"Undo", @selector(undo:), @"z"), Item(@"Redo", @selector(redo:), @"Z"),
                                Item(@"Cut", @selector(cut:), @"x"), Item(@"Copy", @selector(copy:), @"c"),
                                Item(@"Paste", @selector(paste:), @"v"), Item(@"Select All", @selector(selectAll:), @"a") ])];
  [menu addItem:Sub(@"View", @[ Item(@"Toggle Sidebar", @selector(toggleTabSidebar:), @"s"),
                                Item(@"Reload", @selector(reload:), @"r") ])];
  NSMutableArray* tabItems = [@[ Item(@"Back", @selector(goBack:), @"["), Item(@"Forward", @selector(goForward:), @"]") ] mutableCopy];
  for (int n = 1; n <= 9; n++) {
    NSMenuItem* i = Item([NSString stringWithFormat:@"Tab %d", n], @selector(selectTabByNumber:), [NSString stringWithFormat:@"%d", n]);
    i.tag = n; [tabItems addObject:i];
  }
  [menu addItem:Sub(@"Tabs", tabItems)];
  NSApp.mainMenu = menu;
  // Runtime Dock icon: drawn as-is, no system tile (bundle .icns icons get one).
  if (NSImage* icon = [[NSImage alloc] initWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"AppIcon" ofType:@"png"]])
    NSApp.applicationIconImage = icon;
  self.browser = [Browser new];
  [self.browser showWindow:nil];
  [self.browser openInitialTabs];
  [NSApp activateIgnoringOtherApps:YES];
}
- (void)quitGracefully { [self.browser quitAll]; }
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)s { return NO; }
@end

int main(int argc, char* argv[]) {
  CefScopedLibraryLoader loader;
  if (!loader.LoadInMain()) return 1;
  CefMainArgs args(argc, argv);
  @autoreleasepool {
    [NhtApp sharedApplication];
    CefSettings s;
    s.no_sandbox = true;
    s.log_severity = Env()[@"NHT_LOG"] ? LOGSEVERITY_INFO : LOGSEVERITY_DISABLE;
    if (NSString* lf = Env()[@"NHT_LOG"]) CefString(&s.log_file) = lf.UTF8String;
    NSString* root = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/nhetrinh-b"];
    CefString(&s.root_cache_path) = root.UTF8String;
    CefString(&s.cache_path) = [root stringByAppendingPathComponent:@"Default"].UTF8String;
    if (!CefInitialize(args, s, nullptr, nullptr)) return 1;
    AppDelegate* d = [AppDelegate new];
    NSApp.delegate = d;
    [d performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
    CefRunMessageLoop();
    CefShutdown();
  }
  return 0;
}
