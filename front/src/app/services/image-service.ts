import { DomSanitizer, SafeHtml, SafeResourceUrl } from '@angular/platform-browser';
import { Component, inject } from '@angular/core';

@Component({
  standalone: true,
  template: '',
})
export class ImageService {
  private readonly sanitizer = inject(DomSanitizer);

  cecLogoPath: string = "logos/cec-logo.png";
  gmailLogoPath: string = "logos/gmail-logo.png";
  
  cecGaisanoBuildingPath: string = "backgrounds/cec-gaisano-building.png";
  cecSsgPath: string = "extras/cec-ssg.jpg";
  cecLandMarkPath: string = "extras/cec-landmark.png";
  pointFingerBelowPath: string = "extras/point-finger-below.png";
  cecLocationPath: string = "extras/location-icon.png";

  facebookLogoPath: string = "extras/facebook-logo.png";
  messengerLogoPath: string = "extras/messenger-logo.png";

  showIconPath: string = "icons/shown icon.png";

  crimPath: string = "extras/crim.jpg";
  crimPath1: string = "extras/crim1.png";
  crimPath2: string = "extras/crim2.png";
  crimPath3: string = "extras/crim3.png";
  crimPath4: string = "extras/crim4.png";

  itPath: string = "extras/bsit.png";
  itPath1: string = "extras/bsit1.png";
  itPath2: string = "extras/bsit2.png";
  itPath3: string = "extras/bsit3.png";
  itPath4: string = "extras/bsit4.png";

  educPath: string = "extras/educ.png";
  educPath1: string = "extras/educ1.png";
  educPath2: string = "extras/educ2.png";
  educPath3: string = "extras/educ3.png";
  educPath4: string = "extras/educ4.png";
  educStudentPngPath: string = "extras/educ-students.png";


  tourismPath: string = "extras/tourism.png";
  tourismPath1: string = "extras/tourism1.png";
  tourismPath2: string = "extras/tourism2.png";
  tourismPath3: string = "extras/tourism3.png";
  tourismPath4: string = "extras/tourism4.png";

  hmPath: string = "extras/hm.png";
  hmPath1: string = "extras/hm1.png";
  hmPath2: string = "extras/hm2.png";
  hmPath3: string = "extras/hm3.png";
  hmPath4: string = "extras/hm4.png";

  graduationBackgroundPath: string = "extras/graduation-background.jpg";
  graduationStudnet1Path: string = "extras/graduated-students1.png";
  graduationStudnet2Path: string = "extras/graduated-students2.png";
  graduationStudnet3Path: string = "extras/graduated-students3.png";

  public readonly videoPath = 'vids/cec_vid.mp4';
}
