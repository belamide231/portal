import { Injectable } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';

@Injectable({
  providedIn: 'root'
})
export class NavigatorService { 
  constructor(private router: Router) {}

  public descend(currentRoute: ActivatedRoute): void {
    this.router.navigate(['../'], { relativeTo: currentRoute });
  }

  public ascend(currentRoute: ActivatedRoute, path: string): void {
    this.router.navigate([path], { relativeTo: currentRoute });
  }
}