import { ChangeDetectorRef, Component, inject } from '@angular/core';
import { ImageService } from '../../services/image-service';
import { ActivatedRoute, Router } from '@angular/router';
import { ThemeService } from '../../services/theme-service-module';
import { ApiServiceModule } from '../../services/api-service-module';
import { CommonModule } from '@angular/common';


@Component({
  selector: 'app-header-component',
  imports: [
    CommonModule
  ],
  providers: [
    ImageService,
    ApiServiceModule
  ],
  templateUrl: './header-component.html',
})
export class HeaderComponent {
  constructor(
    public readonly image: ImageService,
    public readonly router: Router,
    public readonly theme: ThemeService,
    private readonly api: ApiServiceModule,
    private readonly cdr: ChangeDetectorRef
  ) {}
  
  private readonly route = inject(ActivatedRoute);
}
