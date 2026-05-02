import { ChangeDetectorRef, Component, inject } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';

import { ImageService } from '../../services/image-service';
import { ApiServiceModule } from '../../services/api-service-module';
import { ThemeService } from '../../services/theme-service-module';
import { CommonModule } from '@angular/common';
import { NavigatorService } from '../../services/navigator-service-module';

@Component({
  selector: 'app-recover-account-modal',
  providers: [
    ImageService,
    ApiServiceModule,
    ThemeService
  ],
  imports: [
    CommonModule
  ],
  templateUrl: './recover-account-modal.html',
})
export class RecoverAccountModal {
  
  constructor(
    public readonly image: ImageService,
    public readonly router: Router,
    private readonly api: ApiServiceModule,
    public readonly theme: ThemeService,
    private readonly cdr: ChangeDetectorRef,
    public readonly navigator: NavigatorService
  ) {}
  public readonly route = inject(ActivatedRoute);
  
  public message: string = "";
  public isLoading: boolean = false;
  public recoverAccount(input: string): void {

    this.isLoading = true;

    this.api.recoverAccountAPI(input).subscribe((res: any) => {

      this.message = res.message;

      this.isLoading = false;
      this.cdr.detectChanges();

    }, (err: any) => {

      err.status === 0 ? this.message = "Unable to connect to the server. Please check your internet connection." : this.message = err.error.message;

      this.isLoading = false;
      this.cdr.detectChanges();

    })
  }

  public navigateGmail(): void {

    window.location.href = "https://mail.google.com/";
  }
}
