import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@NgModule({
  imports: [
    CommonModule
  ]
})
export class ApiServiceModule { 
  constructor(
    private readonly http: HttpClient
  ) {}

  private readonly host: string = "http://localhost:5205";
  private url(endpoint: string): string {
    return this.host + "/api/" + endpoint;
  }

  public registerAccountAPI(registrationToken: string, username: string, password: string): Observable<any> {
    return this.http.post(this.url("account/register-account"), {
      registrationToken, username, password
    });
  }

  public loginAccountAPI(username: string, password: string): Observable<any> {
    return this.http.post(this.url("account/login-account"), {
      username, password
    });
  }

  public recoverAccountAPI(input: string): Observable<any> {
    return this.http.post(this.url("account/recover-account"), {
      input
    });
  }

  public resetPasswordAPI(resetToken: string, newPassword: string): Observable<any> {
    return this.http.post(this.url("account/reset-password"), {
      resetToken, newPassword
    });
  }
}
