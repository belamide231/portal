import { ChangeDetectorRef, Component, inject } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { CommonModule } from '@angular/common';

import { ImageService } from '../../services/image-service';
import { ThemeService } from '../../services/theme-service-module';
import { ApiServiceModule } from '../../services/api-service-module';

@Component({
  selector: 'app-navigate-component',
  imports: [
    CommonModule
  ],
  providers: [
    ImageService,
    ApiServiceModule
  ],
  templateUrl: './navigate-component.html',
})
export class NavigateComponent {
  constructor(
    public readonly image: ImageService,
    public readonly router: Router,
    public readonly theme: ThemeService,
    private readonly api: ApiServiceModule,
    private readonly cdr: ChangeDetectorRef
  ) {}
  
  private readonly route = inject(ActivatedRoute);
}
