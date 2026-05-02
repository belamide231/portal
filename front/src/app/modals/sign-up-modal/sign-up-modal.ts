import { ChangeDetectorRef, Component, inject } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { CommonModule } from '@angular/common';

import { ImageService } from '../../services/image-service';
import { ApiServiceModule } from '../../services/api-service-module';
import { ThemeService } from '../../services/theme-service-module';

@Component({
  selector: 'app-sign-up-modal',
  imports: [
    CommonModule
  ],
  providers: [
    ImageService,
    ApiServiceModule,
  ],
  templateUrl: './sign-up-modal.html',
})
export class SignUpModal {
  constructor(
    public readonly image: ImageService,
    public readonly router: Router,
    public readonly theme: ThemeService,
    private readonly api: ApiServiceModule,
    private readonly cdr: ChangeDetectorRef
  ) {}
  private readonly route = inject(ActivatedRoute);

  message: string = "";
  isLoading: boolean = false;
  registerAccount(username: string, password: string) {

    this.isLoading = true;
    const registerToken = this.route.snapshot.queryParamMap.get("registrationToken") as string;

    this.api.registerAccountAPI(registerToken, username, password).subscribe((res: any) => {

      this.message = res.message

      this.isLoading = false;;
      this.cdr.detectChanges();

    }, (err: any) => {

      err.status === 0 ? this.message = "Unable to connect to the server. Please check your internet connection." : this.message = err.error.message;

      this.isLoading = false;
      this.cdr.detectChanges();

    })
  }
}
