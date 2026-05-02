import { ChangeDetectorRef, Component, inject } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';

import { ImageService } from '../../services/image-service';
import { ThemeService } from '../../services/theme-service-module';
import { ApiServiceModule } from '../../services/api-service-module';
import { CommonModule } from '@angular/common';
import { NavigatorService } from '../../services/navigator-service-module';

@Component({
  selector: 'app-create-post-modal',
  imports: [
    CommonModule,
  ],
  providers: [
    ImageService,
  ],
  templateUrl: './create-post-modal.html',
})
export class CreatePostModal {
  constructor(
    public readonly image: ImageService,
    public readonly router: Router,
    private readonly api: ApiServiceModule,
    public readonly theme: ThemeService,
    private readonly cdr: ChangeDetectorRef,
    public readonly navigator: NavigatorService
  ) {}
  public readonly route = inject(ActivatedRoute);
  public isLoading: boolean = false;
  public message: string = "";
}
