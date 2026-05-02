import { ChangeDetectorRef, Component, inject } from '@angular/core';
import { ActivatedRoute, Router, RouterOutlet } from '@angular/router';
import { CommonModule } from '@angular/common';

import { ImageService } from '../../services/image-service';
import { ApiServiceModule } from '../../services/api-service-module';
import { ThemeService } from '../../services/theme-service-module';
@Component({
  selector: 'app-task-page',
  providers: [
    ImageService,
    ApiServiceModule,
  ],
  imports: [
    RouterOutlet, 
    CommonModule, 
  ],
  templateUrl: './task-page.html',
})
export class TaskPage {
  constructor(
    public readonly router: Router,
    public readonly image: ImageService,
    private readonly api: ApiServiceModule,
    private readonly cdr: ChangeDetectorRef,
    public readonly theme: ThemeService
  ) {}
  public readonly route = inject(ActivatedRoute);
  
  public isLoading: boolean = false;
  public message: string = "";
}
