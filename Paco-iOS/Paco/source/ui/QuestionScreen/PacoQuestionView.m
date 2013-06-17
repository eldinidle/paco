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

#import "PacoQuestionView.h"

#import <MapKit/MapKit.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "PacoCheckboxView.h"
#import "PacoColor.h"
#import "PacoFont.h"
#import "PacoLayout.h"
#import "PacoModel.h"
#import "PacoSliderView.h"

@interface PacoQuestionView () <MKMapViewDelegate,
                                PacoCheckboxViewDelegate,
                                PacoSliderViewDelegate,
                                UITextFieldDelegate,
                                UINavigationControllerDelegate,
                                UIImagePickerControllerDelegate>

@property (retain, readwrite) PacoCheckboxView *checkboxes;
@property (retain, readwrite) UIButton *choosePhotoButton;
@property (retain, readwrite) UIImage *image;
@property (retain, readwrite) UIImageView *imageView;
@property (retain, readwrite) UIImagePickerController *imagePicker;
@property (retain, readwrite) MKMapView *map;
@property (retain, readwrite) NSArray *numberButtons;
@property (retain, readwrite) PacoSliderView *numberSlider;
@property (retain, readwrite) UILabel *questionText;
@property (retain, readwrite) NSArray *smileysButtons;
@property (retain, readwrite) UITextField *textField;

// TODO(gregvance): add location and photo

- (void)clearUI;
- (void)setupUIForQuestion;

// Likert Smileys
- (void)selectSmiley:(int)index;

// Likert
- (void)selectNumberButton:(int)index;

@end

@implementation PacoQuestionView

@synthesize imageView;
@synthesize question = question_;

- (void)dealloc {
  [self clearUI];
}


- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = [PacoColor pacoLightBlue];
  }
  return self;
}

- (PacoExperimentInput *)question {
  return question_;
}

- (void)updateConditionals {
  if (self.question.isADependencyForOthers) {
    [self.tableDelegate reloadTable];
  }
}

- (void)setQuestion:(PacoExperimentInput *)question {
  question_ = question;
  [self clearUI];
  [self setupUIForQuestion];
  [self setNeedsLayout];
}

- (void)clearUI {
  [self.choosePhotoButton removeFromSuperview];
  [self.checkboxes removeFromSuperview];
  for (UIButton *button in self.numberButtons) {
    [button removeFromSuperview];
  }
  [self.imageView removeFromSuperview];
  [self.imagePicker dismissViewControllerAnimated:NO completion:nil];
  [self.map removeFromSuperview];
  [self.numberSlider removeFromSuperview];
  [self.questionText removeFromSuperview];
  for (UIButton *button in self.smileysButtons) {
    [button removeFromSuperview];
  }
  [self.textField removeFromSuperview];

  self.choosePhotoButton = nil;
  self.checkboxes = nil;
  self.image = nil;
  self.imageView = nil;
  self.imagePicker = nil;
  //self.map = nil;  // Dont clear the map, it takes too much time to refresh
  self.numberButtons = nil;
  self.numberSlider = nil;
  self.questionText = nil;
  self.smileysButtons = nil;
  self.textField = nil;
}

- (void)selectSmiley:(int)index {
  for (int i = 0; i < 5; ++i) {
    UIImage *smileyOn = [UIImage imageNamed:[NSString stringWithFormat:@"smile_icon%d_re.png", i+1]];
    UIImage *smileyOff = [UIImage imageNamed:[NSString stringWithFormat:@"smile_icon%d.png", i+1]];
    assert(smileyOn);
    assert(smileyOff);

    UIButton *button = [self.smileysButtons objectAtIndex:i];
    if (i == index) {
      [button setImage:smileyOn forState:UIControlStateNormal];
      [button setImage:smileyOn forState:UIControlStateHighlighted];
    } else {
      [button setImage:smileyOff forState:UIControlStateNormal];
      [button setImage:smileyOff forState:UIControlStateHighlighted];
    }
  }
  //[self updateConditionals];
}

- (void)selectNumberButton:(int)index {
  UIColor *highlightedColor = [UIColor blackColor];
  UIColor *normalColor = [UIColor blackColor];
  for (int i = 0; i < self.question.likertSteps; ++i) {
    UIButton *button = [self.numberButtons objectAtIndex:i];
    if (i == index) {
      UIFont *font = [PacoFont pacoTableCellFont];
      UIFont *boldFont = [UIFont boldSystemFontOfSize:(font.pointSize + 1)];
      button.titleLabel.font = boldFont;
      [button setTitleColor:highlightedColor forState:UIControlStateNormal];
      [button setTitleColor:highlightedColor forState:UIControlStateHighlighted];
    } else {
      button.titleLabel.font = [PacoFont pacoTableCellFont];
      [button setTitleColor:normalColor forState:UIControlStateNormal];
      [button setTitleColor:normalColor forState:UIControlStateHighlighted];

    }
  }
  //[self updateConditionals];
}

- (void)onSmiley:(UIButton *)button {
  int buttonIndex = [self.smileysButtons indexOfObject:button];
  assert(buttonIndex != NSNotFound);
  [self selectSmiley:buttonIndex];
  self.question.responseObject = [NSNumber numberWithInt:buttonIndex];
  [self updateConditionals];
}

- (void)onNumber:(UIButton *)button {
  int buttonIndex = [self.numberButtons indexOfObject:button];
  assert(buttonIndex != NSNotFound);
  [self selectNumberButton:buttonIndex];
  self.question.responseObject = [NSNumber numberWithInt:buttonIndex];
  [self updateConditionals];
}

- (void)choosePhoto {
  self.imagePicker = [[UIImagePickerController alloc] init];
  self.imagePicker.delegate = self;
  [[UIApplication sharedApplication].keyWindow.rootViewController
     presentViewController:self.imagePicker
     animated:YES
     completion:nil];
  [self updateConditionals];
}

- (void)setupUIForQuestion {
  if ([self.question.questionType isEqualToString:@"question"]) {
    // Question Label
    self.questionText = [[UILabel alloc] initWithFrame:CGRectZero];
    self.questionText.text = self.question.text;
    self.questionText.backgroundColor = [UIColor clearColor];
    self.questionText.textColor = [PacoColor pacoDarkBlue];
    self.questionText.font = [PacoFont pacoTableCellFont];
    self.questionText.numberOfLines = 0;  // Number of lines limited to view size
    [self addSubview:self.questionText];
    [self.questionText sizeToFit];
    

    if ([self.question.responseType isEqualToString:@"likert_smileys"]) {
      // Smiley Buttons
      NSMutableArray *buttons = [NSMutableArray array];
      for (int i = 1; i <= 5; ++i) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [buttons addObject:button];
        [self addSubview:button];
        [button sizeToFit];
        [button addTarget:self action:@selector(onSmiley:) forControlEvents:UIControlEventTouchUpInside];
      }
      
      self.smileysButtons = buttons;
      if (self.question.responseObject) {
        NSNumber *number = self.question.responseObject;
        [self selectSmiley:[number intValue]];
      } else {
        [self selectSmiley:3];
      }
    } else if ([self.question.responseType isEqualToString:@"likert"]) {
      // Number Steps
      NSMutableArray *buttons = [NSMutableArray array];
      for (NSInteger i = 0; i < self.question.likertSteps; ++i) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:[NSString stringWithFormat:@"%d", (i + 1)] forState:UIControlStateNormal];
        [buttons addObject:button];
        [self addSubview:button];
        [button sizeToFit];
        [button addTarget:self action:@selector(onNumber:) forControlEvents:UIControlEventTouchUpInside];
      }
      self.numberButtons = buttons;
      if (self.question.responseObject) {
        NSNumber *number = self.question.responseObject;
        [self selectNumberButton:[number intValue]];
      } else {
        int mid = self.question.likertSteps / 2;
        [self selectNumberButton:mid];
      }
    } else if ([self.question.responseType isEqualToString:@"open text"]) {
      // Open Text Field
      self.textField = [[UITextField alloc] initWithFrame:CGRectZero];
      self.textField.placeholder = @"<type response here>";
      self.textField.borderStyle = UITextBorderStyleRoundedRect;
      
      [self addSubview:self.textField];
      self.textField.delegate = self;
      if (self.question.responseObject) {
        if (![self.question.responseObject isKindOfClass:[NSString class]]) {
          //NSString *reponseType = NSStringFromClass([self.question.responseObject class]);
          assert(0); // should clear map thing for sure between table instantiations, or sometinng, make sure either way
        }
        self.textField.text = self.question.responseObject;
      }
    } else if ([self.question.responseType isEqualToString:@"list"]) {
      // TODO: radio list or multi checkboxes
      // TODO: modify checkboxes to be vertical
      PacoCheckboxView *checkboxes = [[PacoCheckboxView alloc] initWithStyle:UITableViewStylePlain reuseIdentifier:@"question_list"];
      checkboxes.optionLabels = self.question.listChoices;
      checkboxes.bitFlags = [NSNumber numberWithUnsignedLongLong:0];
      checkboxes.radioStyle = NO;  // TODO(gregvance): get this from the server
      checkboxes.vertical = YES;
      checkboxes.delegate = self;
      self.checkboxes = checkboxes;
      [self addSubview:checkboxes];
      if (self.question.responseObject) {
        checkboxes.bitFlags = self.question.responseObject;
      }
    } else if ([self.question.responseType isEqualToString:@"number"]) {
      PacoSliderView *slider = [[PacoSliderView alloc] initWithStyle:UITableViewStylePlain reuseIdentifier:@"question_number"];
      slider.format = @"%d";
      if (self.question.responseObject) {
        slider.value = self.question.responseObject;
      } else {
        slider.value = [NSNumber numberWithInt:0];
      }
      slider.minValue = 0;
      slider.maxValue = 100;
      slider.delegate = self;
      self.numberSlider = slider;
      [self addSubview:slider];

    } else if ([self.question.responseType isEqualToString:@"location"]) {
      if ([self.question.text length] == 0) {
        self.questionText.text = @"Attaching your location ...";
        [self.questionText sizeToFit];
      }
      if (!self.map) {
        self.map = [[MKMapView alloc] initWithFrame:CGRectZero];
        self.map.delegate = self;
        self.map.showsUserLocation = YES;
        self.map.zoomEnabled = NO;
        self.map.userInteractionEnabled = NO;
        self.map.userTrackingMode = MKUserTrackingModeFollow;
        self.map.mapType = MKMapTypeHybrid;// MKMapTypeStandard,MKMapTypeSatellite,MKMapTypeHybrid
      }
      [self addSubview:self.map];
    } else if ([self.question.responseType isEqualToString:@"photo"]) {
      if ([self.question.text length] == 0) {
        self.questionText.text = @"Attach a photo.";
        [self.questionText sizeToFit];
      }
      self.choosePhotoButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
      [self.choosePhotoButton setTitle:@"Choose Photo" forState:UIControlStateNormal];
      [self.choosePhotoButton setTitle:@"Choose Photo" forState:UIControlStateHighlighted];
      [self.choosePhotoButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
      [self.choosePhotoButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
      [self addSubview:self.choosePhotoButton];
      if (self.question.responseObject) {
        //NSString *classType = self.question.responseObject ? NSStringFromClass([self.question.responseObject class]) : nil;
        assert(self.question.responseObject == nil || [self.question.responseObject isKindOfClass:[UIImage class]]);
        UIImage *image = self.question.responseObject;
        [self.choosePhotoButton setImage:image forState:UIControlStateNormal];
      }
//      [self.choosePhotoButton sizeToFit];
      [self.choosePhotoButton addTarget:self action:@selector(choosePhoto) forControlEvents:UIControlEventTouchUpInside];
      if (self.question.responseObject) {
        assert(self.question.responseObject == nil || [self.question.responseObject isKindOfClass:[UIImage class]]);
        self.image = self.question.responseObject;
      }
    } else {

      NSLog(@"TODO: implement response type \"%@\"", self.question.responseType);
    }
  } else {
    NSLog(@"TODO: implement question type \"%@\" [%@]", self.question.questionType, self.question.text);
  }
}

- (CGSize)sizeThatFits:(CGSize)size {
  NSNumber *height = [self.class heightForData:[NSArray arrayWithObjects:@"", self.question, nil]];
  return CGSizeMake(320, height.integerValue);
}

- (void)sizeToFit {
  [super sizeToFit];
}
//calculate text size in a func that uses .frame then a sizeTOFit
+ (CGSize)textSizeToFitSize:(CGSize)bounds
                       text:(NSString *)text
                       font:(UIFont *)font {
  UIView *parent = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, FLT_MAX)];
  UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, FLT_MAX)];
  label.numberOfLines = 0;
  [parent addSubview:label];
  label.text = text;
  if (font) {
    label.font = font;
  }
  [label sizeToFit];
  return label.frame.size;
}

+ (NSNumber *)heightForData:(id)data {
  NSArray *array = (NSArray *)data;
  PacoExperimentInput *question = (PacoExperimentInput *)[array objectAtIndex:1];
  CGSize textSize = [self textSizeToFitSize:CGSizeMake(320, 10000) text:question.text font:nil];
  
  if ([question.questionType isEqualToString:@"question"]) {
    if ([question.responseType isEqualToString:@"likert_smileys"]) {
      return [NSNumber numberWithInt:100 + (textSize.height)];
    } else if ([question.responseType isEqualToString:@"likert"]) {
      return [NSNumber numberWithInt:100 + (textSize.height)];
    } else if ([question.responseType isEqualToString:@"open text"]) {
    } else if ([question.responseType isEqualToString:@"list"]) {
      // radio list or multi checkboxes
      int numChoices = question.listChoices.count;
      return [NSNumber numberWithInt:(numChoices*60) + (textSize.height)];
    } else if ([question.responseType isEqualToString:@"number"]) {
      return [NSNumber numberWithInt:100 + (textSize.height)];
    } else if ([question.responseType isEqualToString:@"location"]) {
      return [NSNumber numberWithInt:300 + (textSize.height)];
    } else if ([question.responseType isEqualToString:@"photo"]) {
      return [NSNumber numberWithInt:300 + (textSize.height)];
    }
  } else {
    NSLog(@"TODO: implement question type \"%@\" [%@]", question.questionType, question.text);
  }


  return [NSNumber numberWithInt:140 + (textSize.height)];
}

- (void)layoutSubviews {
  [super layoutSubviews];

  self.questionText.frame = self.bounds;
  [self.questionText sizeToFit];
  CGSize textsize = [self.class textSizeToFitSize:self.questionText.frame.size
                                             text:self.questionText.text
                                             font:self.questionText.font];
  if ([self.question.questionType isEqualToString:@"question"]) {
    if ([self.question.responseType isEqualToString:@"likert_smileys"]) {
      int numSmileys = self.smileysButtons.count;
      CGRect bounds = CGRectMake(0, textsize.height + 10, self.frame.size.width, self.frame.size.height - textsize.height - 20);
      NSArray *smileys = [PacoLayout splitRectHorizontally:bounds numSections:numSmileys];
      //for (NSValue *valueRect in smileys) {
      for (int i = 0; i < numSmileys; ++i) {
        UIButton *button = [self.smileysButtons objectAtIndex:i];
        NSValue *valueRect = [smileys objectAtIndex:i];
        CGRect rect = [valueRect CGRectValue];
        button.frame = rect;
      }
    } else if ([self.question.responseType isEqualToString:@"likert"]) {
      int numValues = self.numberButtons.count;
      CGRect bounds = CGRectMake(0, textsize.height + 10, self.frame.size.width, self.frame.size.height - textsize.height - 20);
      NSArray *numbers = [PacoLayout splitRectHorizontally:bounds numSections:numValues];
      //for (NSValue *valueRect in smileys) {
      for (int i = 0; i < numValues; ++i) {
        UIButton *button = [self.numberButtons objectAtIndex:i];
        NSValue *valueRect = [numbers objectAtIndex:i];
        CGRect rect = [valueRect CGRectValue];
        button.frame = rect;
      }
    } else if ([self.question.responseType isEqualToString:@"open text"]) {
      CGRect bounds = CGRectMake(10, textsize.height + 10, self.frame.size.width - 20, self.frame.size.height - textsize.height - 20);
      self.textField.frame = bounds;
    } else if ([self.question.responseType isEqualToString:@"list"]) {
      // radio list or multi checkboxes
      CGRect bounds = CGRectMake(10, textsize.height + 10, self.frame.size.width - 20, self.frame.size.height - textsize.height - 20);
      self.checkboxes.frame = bounds;
//      int numChoices = self.question.listChoices.count;
//      NSArray *choices = [PacoLayout splitRectVertically:bounds numSections:numChoices];
//      for (int i = 0; i < numChoices; ++i) {
//
//      }
    } else if ([self.question.responseType isEqualToString:@"number"]) {
      CGRect bounds = CGRectMake(10, textsize.height + 10, self.frame.size.width - 20, self.frame.size.height - textsize.height - 20);

      self.numberSlider.frame = bounds;
    } else if ([self.question.responseType isEqualToString:@"location"]) {
      CGRect bounds = CGRectMake(10, textsize.height + 10, self.frame.size.width - 20, self.frame.size.height - textsize.height - 20);

      self.map.frame = bounds;
    } else if ([self.question.responseType isEqualToString:@"photo"]) {
      CGRect bounds = CGRectMake(10, textsize.height + 10, self.frame.size.width - 20, self.frame.size.height - textsize.height - 20);
      self.choosePhotoButton.frame = bounds;
    }
  } else {
    NSLog(@"TODO: implement question type \"%@\" [%@]", self.question.questionType, self.question.text);
  }
}

#pragma mark - UINavigationControllerDelegate
// Called when the navigation controller shows a new top view controller via a push, pop or setting of the view controller stack.
//- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated;
//- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated;

#pragma mark - UIImagePickerControllerDelegate

// The picker does not dismiss itself; the client dismisses it in these callbacks.
// The delegate will receive one or the other, but not both, depending whether the user
// confirms or cancels.
- (void)imagePickerController:(UIImagePickerController *)picker
        didFinishPickingImage:(UIImage *)image
                  editingInfo:(NSDictionary *)editingInfo {
  self.question.responseObject = image;
  self.image = image;
  [self updateConditionals];
  [self.choosePhotoButton setImage:image forState:UIControlStateNormal];
  [self.choosePhotoButton setImage:image forState:UIControlStateHighlighted];
  [self.choosePhotoButton setNeedsLayout];
  [[UIApplication sharedApplication].keyWindow.rootViewController
      dismissViewControllerAnimated:YES
      completion:^{
        self.imagePicker = nil;
      }];
}

- (void)imagePickerController:(UIImagePickerController *)picker
    didFinishPickingMediaWithInfo:(NSDictionary *)info {
  
  NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
  if ([mediaType isEqualToString:(__bridge NSString*)kUTTypeImage]) {
    UIImage *orig = [info objectForKey:UIImagePickerControllerOriginalImage];
    UIImage *edited = [info objectForKey:UIImagePickerControllerEditedImage];
    self.image = edited ? edited : orig;
    self.question.responseObject = self.image;
    [self updateConditionals];
    [self.choosePhotoButton setImage:self.image forState:UIControlStateNormal];
    [self.choosePhotoButton setImage:self.image forState:UIControlStateHighlighted];
    [self.choosePhotoButton setNeedsLayout];
  } else if ([mediaType isEqualToString:(__bridge NSString*)kUTTypeMovie]) {
    NSURL *movieURL = [info objectForKey:UIImagePickerControllerMediaURL];
    self.question.responseObject = movieURL;
  }

  [[UIApplication sharedApplication].keyWindow.rootViewController
      dismissViewControllerAnimated:YES
      completion:^{
        self.imagePicker = nil;
      }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  self.question.responseObject = nil;
  [[UIApplication sharedApplication].keyWindow.rootViewController
      dismissViewControllerAnimated:YES
      completion:^{
        self.imagePicker = nil;
      }];
}


#pragma mark - UITextFieldDelegate

//- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField;        // return NO to disallow editing.
//- (void)textFieldDidBeginEditing:(UITextField *)textField;           // became first responder
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
  // return YES to allow editing to stop and to resign first responder status.
  //        NO to disallow the editing session to end
  return YES;
}

//- (void)textFieldDidEndEditing:(UITextField *)textField;             // may be called if forced even if shouldEndEditing returns NO (e.g. view removed from window) or endEditing:YES called

//- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;   // return NO to not change text

//- (BOOL)textFieldShouldClear:(UITextField *)textField;               // called when clear button pressed. return NO to ignore (no notifications)

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  // called when 'return' key pressed. return NO to ignore.
  [textField endEditing:YES];
  self.question.responseObject = textField.text;
  [self updateConditionals];
  return YES;
}

#pragma mark - PacoCheckboxViewDelegate

- (void)onCheckboxChanged:(PacoCheckboxView *)checkbox {
  self.question.responseObject = checkbox.bitFlags;
  [self updateConditionals];
}

#pragma mark - PacoSliderViewDelegate

- (void)onSliderChanged:(PacoSliderView *)slider {
  int value = [slider.value intValue];
  self.question.responseObject = [NSNumber numberWithInt:value];
  [self updateConditionals];
}

#pragma mark MKMapViewDelegate

//- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated;
//- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated;

//- (void)mapViewWillStartLoadingMap:(MKMapView *)mapView;
- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView {
  NSLog(@"Found Location %f,%f", self.map.userLocation.location.coordinate.latitude, self.map.userLocation.location.coordinate.longitude);
  self.question.responseObject = self.map.userLocation.location;
  [self updateConditionals];
}
//- (void)mapViewDidFailLoadingMap:(MKMapView *)mapView withError:(NSError *)error;

// mapView:viewForAnnotation: provides the view for each annotation.
// This method may be called for all or some of the added annotations.
// For MapKit provided annotations (eg. MKUserLocation) return nil to use the MapKit provided annotation view.
//- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation;

// mapView:didAddAnnotationViews: is called after the annotation views have been added and positioned in the map.
// The delegate can implement this method to animate the adding of the annotations views.
// Use the current positions of the annotation views as the destinations of the animation.
//- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views;

// mapView:annotationView:calloutAccessoryControlTapped: is called when the user taps on left & right callout accessory UIControls.
//- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control;

//- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view NS_AVAILABLE(NA, 4_0);
//- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view NS_AVAILABLE(NA, 4_0);

//- (void)mapViewWillStartLocatingUser:(MKMapView *)mapView NS_AVAILABLE(NA, 4_0);
//- (void)mapViewDidStopLocatingUser:(MKMapView *)mapView NS_AVAILABLE(NA, 4_0);
//- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation NS_AVAILABLE(NA, 4_0);
//- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error NS_AVAILABLE(NA, 4_0);

//- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState
  // fromOldState:(MKAnnotationViewDragState)oldState NS_AVAILABLE(NA, 4_0);

//- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay NS_AVAILABLE(NA, 4_0);

// Called after the provided overlay views have been added and positioned in the map.
//- (void)mapView:(MKMapView *)mapView didAddOverlayViews:(NSArray *)overlayViews NS_AVAILABLE(NA, 4_0);

//- (void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated NS_AVAILABLE(NA, 5_0);

/*

inputs =         (
                        {
  conditional = 0;
  id = 3;
  invisibleInput = 0;
  leftSideLabel = "<left>";
  likertSteps = 5;
  listChoices =                 (
      ""
  );
  mandatory = 1;
  name = "<name1>";
  questionType = question;
  responseType = "likert_smileys";
  rightSideLabel = "<right>";
  text = "<input_prompt1>";
},
          {
  conditional = 0;
  id = 5;
  invisibleInput = 0;
  leftSideLabel = left;
  likertSteps = 7;
  listChoices =                 (
  );
  mandatory = 1;
  name = "<name2>";
  questionType = question;
  responseType = likert;
  rightSideLabel = right;
  text = "<input_prompt2>";
},
          {
  conditional = 0;
  id = 6;
  invisibleInput = 0;
  likertSteps = 5;
  listChoices =                 (
  );
  mandatory = 1;
  name = "<name3>";
  questionType = question;
  responseType = "open text";
  text = "<input prompt3>";
},
          {
  conditional = 0;
  id = 7;
  invisibleInput = 0;
  likertSteps = 5;
  listChoices =                 (
      "choice 1",
      "choice 2",
      "choice 3",
      "choice 4"
  );
  mandatory = 1;
  name = "<name4>";
  questionType = question;
  responseType = list;
  text = "<input prompt4>";
},
          {
  conditional = 0;
  id = 8;
  invisibleInput = 0;
  likertSteps = 5;
  listChoices =                 (
  );
  mandatory = 1;
  name = "<name 5>";
  questionType = question;
  responseType = number;
  text = "<input prompt5>";
},
          {
  conditional = 0;
  id = 9;
  invisibleInput = 1;
  likertSteps = 5;
  listChoices =                 (
  );
  mandatory = 1;
  name = "<name 6>";
  questionType = question;
  responseType = location;
  text = "";
},
          {
  conditional = 0;
  id = 10;
  invisibleInput = 1;
  likertSteps = 5;
  listChoices =                 (
  );
  mandatory = 1;
  name = "<name 7>";
  questionType = question;
  responseType = photo;
  text = "";
},
          {
  conditional = 0;
  id = 11;
  invisibleInput = 0;
  likertSteps = 5;
  listChoices =                 (
  );
  mandatory = 1;
  name = root;
  questionType = question;
  responseType = "likert_smileys";
  text = "<input prompt root>";
},
          {
  conditionExpression = "root < 3";
  conditional = 1;
  id = 12;
  invisibleInput = 0;
  likertSteps = 5;
  listChoices =                 (
  );
  mandatory = 0;
  name = "<leafL>";
  questionType = question;
  responseType = "likert_smileys";
  text = "<input prompt leafL>";
},
          {
  conditionExpression = "root >= 3";
  conditional = 1;
  id = 13;
  invisibleInput = 0;
  likertSteps = 5;
  listChoices =                 (
  );
  mandatory = 0;
  name = "<leafR>";
  questionType = question;
  responseType = "likert_smileys";
  text = "<input prompt leafR>";
}
);


*/



@end