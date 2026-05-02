import { ChangeDetectorRef, Component } from '@angular/core';
import { Router, RouterOutlet } from '@angular/router';
import { CommonModule } from '@angular/common';

import { ImageService } from '../../services/image-service';
import { ApiServiceModule } from '../../services/api-service-module';
import { ThemeService } from '../../services/theme-service-module';

@Component({
  selector: 'app-login-page',
  providers: [
    ImageService,
    ApiServiceModule,
  ],
  imports: [
    RouterOutlet, 
    CommonModule, 
  ],
  templateUrl: './login-page.html',
})
export class LoginPage {
  constructor(
    public readonly router: Router,
    public readonly image: ImageService,
    private readonly api: ApiServiceModule,
    private readonly cdr: ChangeDetectorRef,
    public readonly theme: ThemeService
  ) {}

  public isLoading: boolean = false;
  public message: string = "";
  public loginAccount(username: string, password: string): void {
    this.message = "";
    this.isLoading = true;
    this.cdr.detectChanges();

    this.api.loginAccountAPI(username, password).subscribe((res: any) => {

      this.isLoading = false;

      if(res.role === "admin") {
        this.router.navigate(["dashboard"]);
        return;
      }
      
      this.router.navigate([""]);

    }, (err) => {

      err.status === 0 ? this.message = "Unable to connect to the server. Please check your internet connection." : this.message = err.error.message;
      
      this.isLoading = false;
      this.cdr.detectChanges();
    })
  }
}
