import { ChangeDetectorRef, Component, inject } from '@angular/core';
import { ImageService } from '../../services/image-service';
import { ActivatedRoute, Router } from '@angular/router';
import { ApiServiceModule } from '../../services/api-service-module';
import { ThemeService } from '../../services/theme-service-module';
import { CommonModule } from '@angular/common';
import { NavigatorService } from '../../services/navigator-service-module';

@Component({
  selector: 'app-edit-group-modal',
  imports: [
    CommonModule,
  ],
  providers: [
    ImageService,
  ],
  templateUrl: './edit-group-modal.html',
})
export class EditGroupModal {
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
