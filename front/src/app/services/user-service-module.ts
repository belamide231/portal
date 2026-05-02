import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ApiServiceModule } from './api-service-module';
import { MD_Account } from '../models/account-model';


@NgModule({
  declarations: [],
  providers: [
    ApiServiceModule
  ],
  imports: [
    CommonModule
  ]
})
export class UserServiceModule { 
  constructor(
    private readonly api: ApiServiceModule
  ) {}

  private userInformation: MD_Account[] = [];
}
