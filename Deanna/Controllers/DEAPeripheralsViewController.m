// 
// Copyright 2013 Yummy Melon Software LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  Author: Charles Y. Choi <charles.choi@yummymelon.com>
//

#import "DEAPeripheralsViewController.h"
#import "DEASensorTag.h"
#import "DEASensorTagViewController.h"
#import "DEAPeripheralTableViewCell.h"

@interface DEAPeripheralsViewController ()
- (void)editButtonAction:(id)sender;
@end

@implementation DEAPeripheralsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Deanna";
    
    DEACentralManager *centralManager = [DEACentralManager sharedService];
    

    [self.navigationController setToolbarHidden:NO];


    self.scanButton = [[UIBarButtonItem alloc] initWithTitle:@"Start Scanning" style:UIBarButtonItemStyleBordered target:self action:@selector(scanButtonAction:)];
    
    self.toolbarItems = @[self.scanButton];
    
    [self.peripheralsTableView reloadData];
    
    [centralManager addObserver:self
                  forKeyPath:@"isScanning"
                     options:NSKeyValueObservingOptionNew
                     context:NULL];
    
    
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editButtonAction:)];
    
    self.navigationItem.rightBarButtonItem = editButton;


}

- (void)viewWillAppear:(BOOL)animated {
    DEACentralManager *centralManager = [DEACentralManager sharedService];
    centralManager.delegate = self;
    
}

- (void)viewDidDisappear:(BOOL)animated {
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    DEACentralManager *centralManager = [DEACentralManager sharedService];
    
    if (object == centralManager) {
        if ([keyPath isEqualToString:@"isScanning"]) {
            if (centralManager.isScanning) {
                self.scanButton.title = @"Stop Scanning";
            } else {
                self.scanButton.title = @"Start Scan";
            }
        }
    } else if ([keyPath isEqualToString:@"RSSI"]) {
        for (UITableViewCell *cell in [self.peripheralsTableView visibleCells]) {
            if ([cell isKindOfClass:[DEAPeripheralTableViewCell class]]) {
                DEAPeripheralTableViewCell *pcell = (DEAPeripheralTableViewCell *)cell;
                if (pcell.sensorTag.cbPeripheral == object) {
                    pcell.rssiLabel.text = [NSString stringWithFormat:@"%@", change[@"new"]];
                    break;
                }
            }
        }
   }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)scanButtonAction:(id)sender {
    DEACentralManager *centralManager = [DEACentralManager sharedService];
    
    if (centralManager.isScanning == NO) {
        [centralManager startScan];
        
        //[centralManager performSelectorInBackground:@selector(startScan) withObject:nil];
    }
    else {
        [centralManager stopScan];
    }
}


- (void)editButtonAction:(id)sender {
    UIBarButtonItem *button = nil;
    
    [self.peripheralsTableView setEditing:(!self.peripheralsTableView.editing) animated:YES];
    
    if (self.peripheralsTableView.editing) {
        button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(editButtonAction:)];
    } else {
        button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editButtonAction:)];
        
    }
    self.navigationItem.rightBarButtonItem = button;
        
}

#pragma mark - CBCentralManagerDelegate Methods


- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    [peripheral addObserver:self
                 forKeyPath:@"RSSI"
                    options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                    context:NULL];
    
    
    for (UITableViewCell *cell in [self.peripheralsTableView visibleCells]) {
        if ([cell isKindOfClass:[DEAPeripheralTableViewCell class]]) {
            DEAPeripheralTableViewCell *pcell = (DEAPeripheralTableViewCell *)cell;
            [pcell updateDisplay:peripheral];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    /*
     cchoi comment:
     I sympathize with the notion that adding and removing observers should always be
     strictly symmetric. However, in the case of cancelling a connection request:
     using an exception to catch a failed attempt to remove an observer
     is syntactically the cleanest way to go because observers are only added after
     a successful connection.
     */
    @try {
        [peripheral removeObserver:self forKeyPath:@"RSSI"];
    }
    @catch (NSException *exception) {
    }

    for (UITableViewCell *cell in [self.peripheralsTableView visibleCells]) {
        if ([cell isKindOfClass:[DEAPeripheralTableViewCell class]]) {
            DEAPeripheralTableViewCell *pcell = (DEAPeripheralTableViewCell *)cell;
            [pcell updateDisplay:peripheral];
        }
    }
    
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    BOOL test = YES;
    
    for (UITableViewCell *cell in [self.peripheralsTableView visibleCells]) {
        if ([cell isKindOfClass:[DEAPeripheralTableViewCell class]]) {
            DEAPeripheralTableViewCell *pcell = (DEAPeripheralTableViewCell *)cell;
            if (pcell.sensorTag.cbPeripheral == peripheral) {
                test = NO;
                break;
            }
        }
    }
    
    if (test) {
        [self.peripheralsTableView reloadData];
    }
    
    
    
}


- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals {
    BOOL test = YES;
    
    for (UITableViewCell *cell in [self.peripheralsTableView visibleCells]) {
        for (CBPeripheral *peripheral in peripherals) {
            if ([cell isKindOfClass:[DEAPeripheralTableViewCell class]]) {
                DEAPeripheralTableViewCell *pcell = (DEAPeripheralTableViewCell *)cell;
                if (pcell.sensorTag.cbPeripheral == peripheral) {
                    test = NO;
                    break;
                }
            }
        }
        
        if (!test) {
            break;
        }
        
    }
    
    if (test) {
        for (CBPeripheral *peripheral in peripherals) {
            if (peripheral.isConnected) {
                [peripheral addObserver:self
                             forKeyPath:@"RSSI"
                                options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                                context:NULL];
            }
            
        }

        [self.peripheralsTableView reloadData];
    }
    

}


- (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals {
    BOOL test = YES;
    
    for (UITableViewCell *cell in [self.peripheralsTableView visibleCells]) {
        for (CBPeripheral *peripheral in peripherals) {
            if ([cell isKindOfClass:[DEAPeripheralTableViewCell class]]) {
                DEAPeripheralTableViewCell *pcell = (DEAPeripheralTableViewCell *)cell;
                if (pcell.sensorTag.cbPeripheral == peripheral) {
                    test = NO;
                    break;
                }
            }
        }
        
        if (!test) {
            break;
        }
        
    }
    
    if (test) {
        for (CBPeripheral *peripheral in peripherals) {
            [peripheral addObserver:self
                         forKeyPath:@"RSSI"
                            options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                            context:NULL];

        }
        
        [self.peripheralsTableView reloadData];
    }

}



#pragma mark - UITableViewDelegate and UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat result;
    DEACentralManager *centralManager = [DEACentralManager sharedService];
    YMSCBPeripheral *yp = [centralManager peripheralAtIndex:indexPath.row];
    if ([centralManager isKnownPeripheral:yp.cbPeripheral]) {
        result = 107.0;
    } else {
        result = 44.0;
    }
    return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *SensorTagCellIdentifier = @"SensorTagCell";
    static NSString *UnknownPeripheralCellIdentifier = @"UnknownPeripheralCell";

    DEACentralManager *centralManager = [DEACentralManager sharedService];
    YMSCBPeripheral *yp = [centralManager peripheralAtIndex:indexPath.row];
    
    UITableViewCell *cell = nil;
    
    if ([centralManager isKnownPeripheral:yp.cbPeripheral]) {
        DEAPeripheralTableViewCell *pcell = (DEAPeripheralTableViewCell *)[tableView dequeueReusableCellWithIdentifier:SensorTagCellIdentifier];
        
        if (pcell == nil) {
            [[NSBundle mainBundle] loadNibNamed:@"DEAPeripheralTableViewCell" owner:self options:nil];
            pcell = self.tvCell;
            self.tvCell = nil;
        }
        
        [pcell configureWithSensorTag:(DEASensorTag *)yp];
        
        pcell.nameLabel.text = yp.cbPeripheral.name;
        cell = pcell;
        
    } else {
        
        cell = [tableView dequeueReusableCellWithIdentifier:UnknownPeripheralCellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:UnknownPeripheralCellIdentifier];
        }
        cell.textLabel.text = yp.cbPeripheral.name;
        cell.detailTextLabel.text = @"Unknown Peripheral";
    }
    
    return cell;

}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    

    switch (editingStyle) {
        case UITableViewCellEditingStyleDelete: {
            DEACentralManager *centralManager = [DEACentralManager sharedService];
            YMSCBPeripheral *yp = [centralManager peripheralAtIndex:indexPath.row];
            if ([yp isKindOfClass:[DEASensorTag class]]) {
                if (yp.cbPeripheral.isConnected) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                    message:@"Disconnect the peripheral before deleting."
                                                                   delegate:nil cancelButtonTitle:@"Dismiss"
                                                          otherButtonTitles:nil];
                    
                    [alert show];
                    
                    break;
                }
            }
            [centralManager removePeripheral:yp];
            
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        }
            
        case UITableViewCellEditingStyleInsert:
        case UITableViewCellEditingStyleNone:
            break;
            
        default:
            break;
    }
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    DEACentralManager *centralManager = [DEACentralManager sharedService];
    NSInteger result;
    result = centralManager.count;
    return result;
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    DEACentralManager *centralManager = [DEACentralManager sharedService];
    
    DEASensorTag *sensorTag = (DEASensorTag *)[centralManager.ymsPeripherals objectAtIndex:indexPath.row];
    
    DEASensorTagViewController *stvc = [[DEASensorTagViewController alloc] initWithNibName:@"DEASensorTagViewController" bundle:nil];
    stvc.sensorTag = sensorTag;

    
    [self.navigationController pushViewController:stvc animated:YES];
    
    
}


- (void)viewDidUnload {
    [self setTvCell:nil];
    [super viewDidUnload];
}
@end