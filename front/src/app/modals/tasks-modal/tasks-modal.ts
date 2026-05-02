import { ChangeDetectorRef, Component, inject } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { CommonModule } from '@angular/common';

import { ImageService } from '../../services/image-service';
import { ApiServiceModule } from '../../services/api-service-module';
import { ThemeService } from '../../services/theme-service-module';
import { NavigatorService } from '../../services/navigator-service-module';

@Component({
  selector: 'app-tasks-modal',
  imports: [
    CommonModule
  ],
  providers: [
    ImageService,
    ApiServiceModule,
  ],  
  templateUrl: './tasks-modal.html',
})
export class TasksModal {
  constructor(
    public readonly image: ImageService,
    public readonly router: Router,
    public readonly theme: ThemeService,
    private readonly api: ApiServiceModule,
    private readonly cdr: ChangeDetectorRef,
    public readonly navigator: NavigatorService
  ) {}
  public readonly route = inject(ActivatedRoute);
}
