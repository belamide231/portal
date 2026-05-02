import { ChangeDetectorRef, Component, inject } from '@angular/core';
import { ActivatedRoute, Router, RouterOutlet, RouterLinkWithHref } from '@angular/router';
import { CommonModule } from '@angular/common';

import { ImageService } from '../../services/image-service';
import { ThemeService } from '../../services/theme-service-module';
import { ApiServiceModule } from '../../services/api-service-module';
import { HeaderComponent } from '../../components/header-component/header-component';
import { NavigateComponent } from '../../components/navigate-component/navigate-component';
import { NavigatorService } from '../../services/navigator-service-module';
import { MainComponent } from "../../components/main-component/main-component";
import { AsideComponent } from "../../components/aside-component/aside-component";

@Component({
  selector: 'app-group-page',
  imports: [
    CommonModule,
    HeaderComponent,
    RouterOutlet,
    NavigateComponent,
    MainComponent,
    AsideComponent
],
  providers: [
    ApiServiceModule,
    ImageService,
    ThemeService,
  ],
  templateUrl: './group-page.html',
})
export class GroupPage {
  constructor(
    public readonly image: ImageService,
    public readonly router: Router,
    public readonly theme: ThemeService,
    private readonly api: ApiServiceModule,
    private readonly cdr: ChangeDetectorRef,
    public readonly navigator: NavigatorService,
  ) {

    console.log(this.router.url.split('/')[1] === 'group');


  }

  public readonly route = inject(ActivatedRoute);
}