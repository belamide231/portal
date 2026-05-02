import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, inject } from '@angular/core';
import { ImageService } from '../../services/image-service';
import { ApiServiceModule } from '../../services/api-service-module';
import { ThemeService } from '../../services/theme-service-module';
import { ActivatedRoute, Router } from '@angular/router';
import { NavigatorService } from '../../services/navigator-service-module';

@Component({
  selector: 'app-create-pool-modal',
  imports: [
    CommonModule
  ],
  providers: [
    ImageService,
    ApiServiceModule,
    ThemeService
  ],
  templateUrl: './create-pool-modal.html',
})
export class CreatePoolModal {
  constructor(
    public readonly image: ImageService,
    public readonly router: Router,
    private readonly api: ApiServiceModule,
    public readonly theme: ThemeService,
    private readonly cdr: ChangeDetectorRef,
    public readonly navigator: NavigatorService
  ) {}
  public readonly route = inject(ActivatedRoute);
}
