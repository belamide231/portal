import { ChangeDetectorRef, Component, inject } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { CommonModule } from '@angular/common';

import { ImageService } from '../../services/image-service';
import { ThemeService } from '../../services/theme-service-module';
import { ApiServiceModule } from '../../services/api-service-module';
import { NavigatorService } from '../../services/navigator-service-module';

@Component({
  selector: 'app-membership-requests-modal',
  imports: [
    CommonModule
  ],
  providers: [
    ImageService,
    ApiServiceModule
  ],
  templateUrl: './membership-requests-modal.html',
})
export class MembershipRequestsModal {
  constructor(
    public readonly image: ImageService,
    public readonly router: Router,
    public readonly theme: ThemeService,
    private readonly api: ApiServiceModule,
    private readonly cdr: ChangeDetectorRef,
    public readonly navigator: NavigatorService,
  ) {}
  public readonly route = inject(ActivatedRoute);

  public message: string = "";
  public isLoading: boolean = false;
}
