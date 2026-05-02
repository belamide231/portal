import { ChangeDetectorRef, Component, inject } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { CommonModule } from '@angular/common';

import { ApiServiceModule } from '../../services/api-service-module';
import { ImageService } from '../../services/image-service';
import { ThemeService } from '../../services/theme-service-module';
import { NavigatorService } from '../../services/navigator-service-module';

@Component({
  selector: 'app-reset-password-modal',
  imports: [
    CommonModule
  ],
  providers: [
    ImageService,
    ApiServiceModule,
    ThemeService
  ],
  templateUrl: './reset-password-modal.html',
})
export class ResetPasswordModal {
  constructor(
    public readonly router: Router,
    public readonly image: ImageService,
    public readonly theme: ThemeService,
    private readonly api: ApiServiceModule,
    private readonly cdr: ChangeDetectorRef,
    public readonly navigator: NavigatorService,
  ) {}
  public readonly route = inject(ActivatedRoute);

  public message: string = "";
  public isLoading: boolean = false;
  public resetPassword(newPassword: string): void {

    this.isLoading = true;
    const resetToken = this.route.snapshot.queryParamMap.get("resetToken") as string;

    console.log(resetToken);

    this.api.resetPasswordAPI(resetToken, newPassword).subscribe((res: any) => {

      this.message = res.message;

      this.isLoading = false;
      this.cdr.detectChanges();

    }, (err: any) => {

      err.status === 0 ? this.message = "Unable to connect to the server. Please check your internet connection." : this.message = err.error.message;

      this.isLoading = false;
      this.cdr.detectChanges();
    });
  }
}
