import { ChangeDetectorRef, Component, inject } from '@angular/core';
import { ImageService } from '../../services/image-service';
import { ActivatedRoute, Router } from '@angular/router';
import { ThemeService } from '../../services/theme-service-module';
import { ApiServiceModule } from '../../services/api-service-module';
import { CommonModule } from '@angular/common';
@Component({
  selector: 'app-aside-component',
  imports: [
    CommonModule
  ],
  providers: [
    ImageService,
    ApiServiceModule
  ],
  templateUrl: './aside-component.html',
})
export class AsideComponent {
  constructor(
    public readonly image: ImageService,
    public readonly router: Router,
    public readonly theme: ThemeService,
    private readonly api: ApiServiceModule,
    private readonly cdr: ChangeDetectorRef
  ) {}
  
  public readonly route = inject(ActivatedRoute)
}
