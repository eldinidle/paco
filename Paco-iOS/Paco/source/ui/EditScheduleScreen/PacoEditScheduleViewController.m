/* Copyright 2013 Google Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "PacoEditScheduleViewController.h"

#import "PacoClient.h"
#import "PacoModel.h"
#import "PacoScheduleEditView.h"
#import "PacoScheduler.h"
#import "PacoService.h"
#import "PacoTableView.h"
#import "PacoExperimentDefinition.h"
#import "PacoEventManager.h"
#import "PacoEvent.h"
#import "PacoEventUploader.h"
#import "PacoExperimentSchedule.h"
#import "PacoFindExperimentsViewController.h"
#import "PacoPublicExperimentController.h"

@interface PacoEditScheduleViewController ()<UIAlertViewDelegate>

@property(nonatomic, assign) BOOL isJoinSuccessful;

@end

@implementation PacoEditScheduleViewController
@synthesize definition = _definition;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.navigationItem.title = NSLocalizedString(@"Scheduling", nil);
  }
  return self;
}
- (void)viewDidLoad {
  [super viewDidLoad];

  PacoScheduleEditView* editView = [[PacoScheduleEditView alloc] initWithFrame:CGRectZero];
  [editView.joinButton addTarget:self action:@selector(onJoin) forControlEvents:UIControlEventTouchUpInside];
  self.view = editView;
  editView.schedule = self.definition.schedule;
}

- (void)setDefinition:(PacoExperimentDefinition *)definition {
  _definition = definition;
  self.title = definition.title;
  [(PacoScheduleEditView *)self.view setSchedule:_definition.schedule];
}

- (void)onJoin {
  NSString* errorMsg = [[(PacoScheduleEditView*)self.view schedule] evaluateSchedule];
  if (errorMsg) {
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops", nil)
                                message:errorMsg
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
    return;
  }

  PacoExperimentSchedule* modifiedSchedule = [(PacoScheduleEditView*)self.view schedule];
  [[PacoClient sharedInstance] joinExperimentWithDefinition:self.definition
                                                andSchedule:modifiedSchedule];

  NSString* title = NSLocalizedString(@"Congratulations!", nil);
  NSString* message = NSLocalizedString(@"You've successfully joined this experiment!", nil);
  [[[UIAlertView alloc] initWithTitle:title
                              message:message
                             delegate:self
                    cancelButtonTitle:@"OK"
                    otherButtonTitles:nil] show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;  // after animation
{
  for (UIViewController *controller in [self.navigationController viewControllers]){
    if ([controller isKindOfClass:[PacoFindExperimentsViewController class]]) {
      PacoFindExperimentsViewController* vController = (PacoFindExperimentsViewController*)controller;
      [self.navigationController popToViewController:vController animated:YES];
      return;
    }
    if ([controller isKindOfClass:[PacoPublicExperimentController class]]) {
      PacoPublicExperimentController* vController = (PacoPublicExperimentController*)controller;
      [self.navigationController popToViewController:vController animated:YES];
      return;
    }
  }
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

@end
