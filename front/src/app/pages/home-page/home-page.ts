import { ChangeDetectorRef, Component, inject } from '@angular/core';
import { ActivatedRoute, Router, RouterOutlet } from '@angular/router';
import { CommonModule } from '@angular/common';

import { ImageService } from '../../services/image-service';
import { ThemeService } from '../../services/theme-service-module';
import { ApiServiceModule } from '../../services/api-service-module';
import { HeaderComponent } from '../../components/header-component/header-component';
import { NavigateComponent } from "../../components/navigate-component/navigate-component";
import { MainComponent } from "../../components/main-component/main-component";
import { AsideComponent } from "../../components/aside-component/aside-component";

@Component({
  selector: 'app-home-page',
  imports: [
    CommonModule,
    RouterOutlet,
    HeaderComponent,
    NavigateComponent,
    MainComponent,
    AsideComponent
],
  providers: [
    ApiServiceModule,
    ImageService,
  ],
  templateUrl: './home-page.html',
})
export class HomePage {
  constructor(
    public readonly image: ImageService,
    public readonly router: Router,
    public readonly theme: ThemeService,
    private readonly api: ApiServiceModule,
    private readonly cdr: ChangeDetectorRef
  ) {}
  
  private readonly route = inject(ActivatedRoute);
}